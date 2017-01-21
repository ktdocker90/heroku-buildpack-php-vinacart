#!/usr/bin/env bash
set -e # fail fast
set -o pipefail # don't ignore exit codes when piping output
# set -x # enable debugging
# Configure directories
build_dir=$1
cache_dir=$2
env_dir=$3
bp_dir=$(cd $(dirname $0); cd ..; pwd)
# Load some convenience functions like status(), echo(), and indent()
source $bp_dir/bin/common.sh
# Fix leak
status "Resetting git environment"
unset GIT_DIR
# Output npm debug info on error
trap cat_npm_debug_log ERR
# Look in package.json's engines.node field for a semver range
chmod +x $bp_dir/bin/jq
semver_range=$(cat $build_dir/package.json | $bp_dir/bin/jq -r .engines.node)
# Resolve node version using semver.io
node_version=$(curl --silent --get --data-urlencode "range=${semver_range}" https://semver.io/node/resolve)
# Recommend using semver ranges in a safe manner
if [ "$semver_range" == "null" ]; then
protip "Specify a node version in package.json"
semver_range=""
elif [ "$semver_range" == "*" ]; then
protip "Avoid using semver ranges like '*' in engines.node"
elif [ ${semver_range:0:1} == ">" ]; then
protip "Avoid using semver ranges starting with '>' in engines.node"
fi
# Output info about requested range and resolved node version
if [ "$semver_range" == "" ]; then
status "Defaulting to latest stable node: $node_version"
else
status "Requested node range: $semver_range"
status "Resolved node version: $node_version"
fi
# Download node from Heroku's S3 mirror of nodejs.org/dist
status "Downloading and installing node"
node_url="http://s3pository.heroku.com/node/v$node_version/node-v$node_version-linux-x64.tar.gz"
curl $node_url -s -o - | tar xzf - -C $build_dir
# Move node (and npm) into ./vendor and make them executable
mkdir -p $build_dir/vendor
mv $build_dir/node-v$node_version-linux-x64 $build_dir/vendor/node
chmod +x $build_dir/vendor/node/bin/*
PATH=$build_dir/vendor/node/bin:$PATH
# Run subsequent node/npm commands from the build path
cd $build_dir
# If node_modules directory is checked into source control then
# rebuild any native deps. Otherwise, restore from the build cache.
if test -d $build_dir/node_modules; then
status "Found existing node_modules directory; skipping cache"
status "Rebuilding any native dependencies"
npm rebuild 2>&1 | indent
elif test -d $cache_dir/node/node_modules; then
status "Restoring node_modules directory from cache"
cp -r $cache_dir/node/node_modules $build_dir/
status "Pruning cached dependencies not specified in package.json"
npm prune --production 2>&1 | indent
if test -f $cache_dir/node/.heroku/node-version && [ $(cat $cache_dir/node/.heroku/node-version) != "$node_version" ]; then
status "Node version changed since last build; rebuilding dependencies"
npm rebuild 2>&1 | indent
fi
fi
# Scope config var availability only to `npm install`
(
if [ -d "$env_dir" ]; then
status "Exporting config vars to environment"
export_env_dir $env_dir
fi
status "Installing dependencies"
# Make npm output to STDOUT instead of its default STDERR
npm install --userconfig $build_dir/.npmrc --production 2>&1 | indent
)
# Persist goodies like node-version in the slug
mkdir -p $build_dir/.heroku
# Save resolved node version in the slug for later reference
echo $node_version > $build_dir/.heroku/node-version
# Purge node-related cached content, being careful not to purge the top-level
# cache, for the sake of heroku-buildpack-multi apps.
rm -rf $cache_dir/node_modules # (for apps still on the older caching strategy)
rm -rf $cache_dir/node
mkdir -p $cache_dir/node
# If app has a node_modules directory, cache it.
if test -d $build_dir/node_modules; then
status "Caching node_modules directory for future builds"
cp -r $build_dir/node_modules $cache_dir/node
fi
# Copy goodies to the cache
cp -r $build_dir/.heroku $cache_dir/node
status "Cleaning up node-gyp and npm artifacts"
rm -rf "$build_dir/.node-gyp"
rm -rf "$build_dir/.npm"
# Update the PATH
status "Building runtime environment"
mkdir -p $build_dir/.profile.d
echo "export PATH=\"\$HOME/vendor/node/bin:\$HOME/bin:\$HOME/node_modules/.bin:\$PATH\";" > $build_dir/.profile.d/nodejs.sh
# Post package.json to nomnom service
# Use a subshell so failures won't break the build.
(
curl \
--data @$build_dir/package.json \
--fail \
--silent \
--request POST \
--header "content-type: application/json" \
https://nomnom.heroku.com/?request_id=$REQUEST_ID \
> /dev/null
) &