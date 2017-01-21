#!/usr/bin/env bash

install_ioncube_ext() {
  if [[ ( ${#exts[@]} -eq 0 || ! ${exts[*]} =~ "ioncube" ) ]]; then
    install_ext "ioncube" "automatic" "http://heroku-buildpack-php-with-ioncube.s3.amazonaws.com/ioncube.tar.gz"
    exts+=("ioncube")

    ln -s $PHP_EXT_DIR/ioncube_loader_lin_${PHP_VERSION%.*}.so $PHP_EXT_DIR/ioncube.so
  fi
}
