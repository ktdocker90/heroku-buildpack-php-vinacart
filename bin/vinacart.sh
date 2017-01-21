#!/bin/bash

WEB_ROOT="${BUILD_DIR}/public"

function install_vinacart() {
	echo "----> install vinacart ecommerce (http://vinacart.net)"
	mkdir -p ${WEB_ROOT}
	cd ${WEB_ROOT}

	if [[ ! -d "system/" ]]; then
		echo "----> downloading & unzip vinacart"
		wget --quiet https://dl.dropboxusercontent.com/u/16994321/vinacart.zip
		unzip -o vinacart.zip &> /dev/null
		#rm vinacart.zip
	fi
	
	echo "---> set files permission"
	# set files permission
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

	echo "done !"
}

#install_vinacart
