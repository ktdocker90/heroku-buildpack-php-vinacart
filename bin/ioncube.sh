#!/usr/bin/env bash

install_ioncube_ext() {
  #if [[ ( ${#exts[@]} -eq 0 || ! ${exts[*]} =~ "ioncube" ) ]]; then

  if [[ ! -f "$PHP_EXT_DIR/ioncube.so" ]];then
  	local php_bin=`which php`
    #install_ext "ioncube" "automatic" "http://heroku-buildpack-php-with-ioncube.s3.amazonaws.com/ioncube.tar.gz"
    #exts+=("ioncube")
    #curl --silent --location "http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz" | tar xz -C $BUILD_DIR/.heroku/php
    local cwd=$(pwd)

    mkdir -p $BUILD_DIR/.heroku/tmp
    cd $BUILD_DIR/.heroku/tmp/

    if [[ ! -d "$BUILD_DIR/.heroku/tmp/ioncube" ]]; then
	    wget http://downloads3.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
	    tar xvfz ioncube_loaders_lin_x86-64.tar.gz
	    rm -rf xvfz ioncube_loaders_lin_x86-64.tar.gz
	fi

    echo "- ioncube automatic; downloaded, using 'php.ini')" | indent
	
	
    #local PHP_VERSION=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
    local phpver="5.6"
    #cp "ioncube/ioncube_loader_lin_${PHP_VERSION}.so" "$extension_dir"
    cp $BUILD_DIR/.heroku/tmp/ioncube/ioncube_loader_lin_${phpver}.so $PHP_EXT_DIR/
	#ln -s $BUILD_DIR/.heroku/tmp/ioncube/ioncube_loader_lin_${PHP_VERSION%.*}.so $PHP_EXT_DIR/ioncube.so
	
    sed -i '1 a zend_extension = "ioncube_loader_lin_'${phpver}'.so"' ${BUILD_DIR}/.heroku/php/etc/php/php.ini

    # test
    #local ioncube_version=`${php_bin} -r "echo var_export(extension_loaded('ionCube Loader') ,true);"`
    #echo "---> Current ioncube version => $ioncube_version"
    
    cd ${cwd}
  fi
}

function check_ioncube_ext() {
	local php_bin=`which php`
    local ioncube_version=`${php_bin} -r "echo var_export(extension_loaded('ionCube Loader') ,true);"`

    if [[ "${ioncube_version}" == "false" ]]; then
        echo "Ioncube not installed or old version ${ioncube_version}"
        install_ioncube_ext
    else
        echo "Ioncube up to date, version: ${ioncube_version}."
        # reinstall
        #build_ioncube
    fi
}
