_ngay="$(date +%Y%m_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
. ./.db
cd /u01/app/export_2012
rm -f ./dpump_files/fullnodata*.dmp
rm -f ./dpump_files/fullnodata*.tar
rm -f ./dpump_files/fullnodata*.tar.bz
set  DATA_PUMP_DIR DPUMP_DIR

# truoc do phai set lai vi tri thu muc qua lenh sau:
# CREATE OR REPLACE DIRECTORY DPUMP_DIR AS '/u01/app/export_2012/dpump_files';
expdp /@ccbs1 parfile=fullnodata.par
# nen file dump
cd ./dpump_files
chmod 777 fullnodata.dmp
tar --remove-files -cvzf fullnodata${_ngay}.tar.bz fullnodata.dmp
# copy file dump sang o dia Buffalo 52.100
chmod 777 fullnodata*
mv -f fullnodata${_ngay}.tar.bz /mnt/nfs52100/Data2015/
cp -u fullnodata.log /mnt/nfs52100//Data2015/fullnodata${_ngay}.log
mv -f fullnodata.log ../logs/fullnodata${_ngay}.log

#don dep dia 
#cd /u01/app/export_2012
#rm -f ./dpump_files/fullnodata*.dmp
#rm -f ./dpump_files/fullnodata*.tar
#rm -f ./dpump_files/fullnodata*.tar.bz