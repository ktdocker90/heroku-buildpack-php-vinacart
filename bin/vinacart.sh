#!/bin/bash

WEB_ROOT="${BUILD_DIR}/public"

function install_vinacart() {
	local cwd=$(pwd)
	echo "----> install vinacart ecommerce (http://vinacart.net)"
	mkdir -p ${WEB_ROOT}
	cd ${WEB_ROOT}

	if [[ ! -d "admin/" ]]; then
		echo "----> downloading & unzip vinacart"
		wget --quiet https://dl.dropboxusercontent.com/u/16994321/vinacart.zip
		unzip -o vinacart.zip &> /dev/null
		#rm vinacart.zip
		touch system/config.php
		touch system/logs/error.txt
		mkdir -p system/logs/code
		mkdir -p system/logs/temp
		touch system/logs/auth_pass.txt
		touch system/logs/task_log.txt
	fi
	#: <<EOF
	echo "---> set files permission"
	# set files permission
	chmod -R 0777 system/logs/code
	chmod -R 0777 system/logs/temp
	chmod 0777 system/logs/auth_pass.txt
	chmod 0777 system/logs/task_log.txt
	chmod 0777 system/logs/error.txt

	# 0755 or 0777
	chmod -R 0777 image/
	chmod -R 0777 system/
	chmod -R 0777 system/cache/
	chmod -R 0777 system/logs/

	chmod -R 0777 admin/system
	chmod 0777 -R admin/system/uploads
	[[ -d admin/system/temp ]] && chmod -R 0777 admin/system/temp
	[[ -d admin/system/backup ]] && chmod -R 0777 admin/system/backup

	chmod -R 0755 download/
	chmod -R 0755 extensions/
	chmod -R 0755 resources/
	[[ -f "system/config.php" ]] && chmod 0777 system/config.php

	chmod 0644 caidat.php
#EOF
	
	if [[ ! -f "${BUILD_DIR}/public/index.php" ]];then
		echo "<?php phpinfo();?>" > "${BUILD_DIR}/public/index.php"
	fi
	echo "done !"

	cd ${cwd}
}

#install_vinacart
