#!/bin/bash

git add -A
git commit -m "first commit"
git remote add origin https://github.com/ktdocker90/heroku-buildpack-php-vinacart.git
git push -u origin master
