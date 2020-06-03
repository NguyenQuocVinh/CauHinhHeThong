_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
. .db
set ORACLE_SID=sxkd1
cd /u01/app/export_2015
#rm -f ./dpump_files/fullnodata*.dmp
#rm -f ./dpump_files/fullnodata*.tar
#rm -f ./dpump_files/fullnodata*.tar.bz
set  DATA_PUMP_DIR MYDPUMP_DIR

# truoc do phai set lai vi tri thu muc qua lenh sau:
# CREATE OR REPLACE DIRECTORY MYDPUMP_DIR AS '/u01/app/export_2015/dumpfile';
expdp /@sxkd1 parfile=data_admin_hcm.par
expdp /@sxkd1 parfile=data_css_hcm.par
# nen file dump
cd ./dumpfile
chmod 777 admin_hcm*.dmp
chmod 777 css_hcm*.dmp
tar --remove-files -cvzf admin_hcm${_ngay}.tar.bz admin_hcm*.dmp
tar --remove-files -cvzf css_hcm${_ngay}.tar.bz css_hcm*.dmp
# copy file dump sang o dia Buffalo 52.100
chmod 777 admin_hcm*
chmod 777 css_hcm*
mv -f admin_hcm${_ngay}.tar.bz /mnt/nfs52100/Data2015/
mv -f css_hcm${_ngay}.tar.bz /mnt/nfs52100/Data2015/
mv -f admin_hcm.log admin_hcm${_ngay}.log
mv -f css_hcm.log css_hcm${_ngay}.log
mv -f admin_hcm${_ngay}.log /mnt/nfs52100/Data2015/
mv -f css_hcm${_ngay}.log /mnt/nfs52100/Data2015/

#don dep dia 
#cd /u01/app/export_2012
#rm -f ./dpump_files/fullnodata*.dmp
#rm -f ./dpump_files/fullnodata*.tar
#rm -f ./dpump_files/fullnodata*.tar.bz