#!/bin/bash
# 4/6/2020
# chay file :
# sh change.sh "Message Here"
git add .
git commit -m "$1"
git push -f origin master
