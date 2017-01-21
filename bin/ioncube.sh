#!/usr/bin/env bash

install_ioncube_ext() {
  #if [[ ( ${#exts[@]} -eq 0 || ! ${exts[*]} =~ "ioncube" ) ]]; then
  if [[ ! -f $PHP_EXT_DIR/ioncube.so ]];then
    #install_ext "ioncube" "automatic" "http://heroku-buildpack-php-with-ioncube.s3.amazonaws.com/ioncube.tar.gz"
    #exts+=("ioncube")
    curl --silent --location "http://heroku-buildpack-php-with-ioncube.s3.amazonaws.com/ioncube.tar.gz" | tar xz -C $BUILD_DIR/.heroku/php
    echo "- ioncube automatic; downloaded, using 'php.ini')" | indent
	
	ln -s $PHP_EXT_DIR/ioncube_loader_lin_${PHP_VERSION%.*}.so $PHP_EXT_DIR/ioncube.so

    local PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    PHP_VERSION="5.6"
    #cp "ioncube/ioncube_loader_lin_${PHP_VERSION}.so" "$extension_dir"

    sed -i '1 a zend_extension = "ioncube_loader_lin_'${PHP_VERSION}'.so"' \
    ${BUILD_DIR}/.heroku/php/etc/php/php.ini

    # test
    local ioncube_version=`${php_bin} -r "echo var_export(extension_loaded('ionCube Loader') ,true);"`
    echo "---> Current ioncube version => $ioncube_version"
    
  fi
}
function check_ioncube_ext() {
	local php_bin=${OPENSHIFT_RUNTIME_DIR}/php5/bin/php
    local ioncube_version=`${php_bin} -r "echo var_export(extension_loaded('ionCube Loader') ,true);"`

    if [[ ${ioncube_version} == "false" ]]; then
        echo "Ioncube not installed or old version ${ioncube_version}"
        install_ioncube_ext
    else
        echo "Ioncube up to date, version: ${ioncube_version}."
        # reinstall
        #build_ioncube
    fi
}
