#!/bin/bash

dos2unix bin/*

git add -A
git commit -m "commit the change"
#git remote add origin https://github.com/ktdocker90/heroku-buildpack-php-vinacart.git
git push -u origin master

ktdocker90
code123456837939
