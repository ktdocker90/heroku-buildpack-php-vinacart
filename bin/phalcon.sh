#!/bin/bash

dep_url=git://github.com/phalcon/cphalcon.git
phalcon_dir=cphalcon
cwd=$(pwd)

echo "-----> Building Phalcon..."

git clone $dep_url -q

if [ ! -d "$phalcon_dir" ]; then
  echo "       Failed to find Phalcon directory '$phalcon_dir'."
  exit
fi

cd $phalcon_dir
git checkout phalcon-v1.3.4
cd build/64bits
phpize
export CFLAGS="-O2 -g"
export PATH=$BUILD_DIR/.heroku/php/bin:$PATH
./configure
make
make install

cd $cwd
