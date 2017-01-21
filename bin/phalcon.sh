#!/bin/bash

dep_url=git://github.com/phalcon/cphalcon.git
phalcon_dir=cphalcon
cwd=$(pwd)



check_phalcon() {
	local php_bin=`which php`
	local phalcon_detect=$($php_bin -r "echo var_export(extension_loaded('phalcon') ,true);")

	if [[ "$phalcon_detect" == "false" ]];then
		echo "-----> Building Phalcon..."
		install_phalcon
	else
		echo "phalcon installed on this machine."
	fi	
}

function install_phalcon() {
	if [[ ! -f $PHP_EXT_DIR/phalcon.so ]]; then

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

	else
		echo "----> phalcon already exist"
	fi

}

#check_phalcon