#!/bin/bash
# Created: 	01/2/2014
# Updated: 	11/5/2015
# export 1 phan du lieu aud$ ra, don dep bot aud$.
# Doi mod cac file aud*.dmp de no cho phep xoa.

_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

. /home/oracle/.bash_profile
export ORAENV_ASK=NO
export ORACLE_SID=dhsxkd1

. /usr/local/bin/oraenv

cd /home/oracle/export_2012

rm -f ./dpump_files/aud_*.dmp
rm -f ./dpump_files/aud.log
rm -f ./dpump_files/aud*.tar
rm -f ./dpump_files/aud*.tar.bz*


sqlplus "/@dhsxkd1 as sysdba" @Del_audit.sql

expdp \"/@dhsxkd1 as sysdba \" parfile=/home/oracle/export_2012/aud.par

# neu muon unzip thi : cat aud.tar.bz_* | tar -xzv
cd ./dpump_files
tar --remove-files -cvzf - aud_*.dmp | split -b 4096m - ./tars/aud_dhsxkd${_ngay}.tar.bz_

#copy file log
#mv -f aud.log ../logs/aud_dhsxkd${_ngay}.log
cp /home/oracle/export_2012/dpump_files/aud.log	/home/oracle/export_2012/logs/aud_dhsxkd${_ngay}.log

#audit tat ca - 8/9/2015
#Audit all by access WHENEVER NOT SUCCESSFUL;