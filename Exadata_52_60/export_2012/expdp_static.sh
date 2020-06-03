# Created: 	01/2/2014
# Updated: 	11/5/2015
# Doi mod cac file static_*.dmp de no cho phep xoa.

_ngay="$(date +%Y%m_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
. ./.db
cd /u01/app/export_2012
rm -f ./dpump_files/static_*.dmp
rm -f ./dpump_files/static*.tar
rm -f ./dpump_files/static*.tar.bz*
set  DATA_PUMP_DIR DPUMP_DIR
# truoc do phai set lai vi tri thu muc qua lenh sau:
# CREATE OR REPLACE DIRECTORY DPUMP_DIR AS '/u01/app/export_2012/dpump_files';
expdp /@ccbs1 parfile=static.par
# neu muon unzip thi : cat static.tar.bz_* | tar -xzv
cd ./dpump_files
chmod 777 static_*.dmp
tar -cvzf - static_*.dmp | split -b 4096m - static${_ngay}.tar.bz_

# copy file dump sang 100.15
chmod 777 static*
mv -f static${_ngay}.tar.bz_* /mnt/nfs52100/Data2015/
cp -u static.log /mnt/nfs52100/Data2015/static${_ngay}.log
mv -f static.log ../logs/static${_ngay}.log

#don dep dia 
#cd /u01/app/export_2012
rm -f ./dpump_files/static_*.dmp
rm -f ./dpump_files/static*.tar
rm -f ./dpump_files/static*.tar.bz*

