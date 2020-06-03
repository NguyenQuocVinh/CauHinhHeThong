# Created: 	01/2/2014
# Updated: 	27/3/2014
# export 1 phan du lieu dba_common_audit_trail ra, don dep bot aud$,fga_log$.

_ngay="$(date +%Y%m%d)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
. ./.db

rm -f /u01/app/export_2012/dpump_files/fga_audit_*.dmp
rm -f /u01/app/export_2012/dpump_files/fga_audit*.tar
rm -f /u01/app/export_2012/dpump_files/fga_audit*.tar.bz*

sqlplus "/ as sysdba" @/u01/app/export_2014/Del_fga_audit.sql

# set  DATA_PUMP_DIR DPUMP_DIR
# truoc do phai set lai vi tri thu muc qua lenh sau:
# CREATE OR REPLACE DIRECTORY DPUMP_DIR AS '/u01/app/export_2012/dpump_files';

expdp \"/as sysdba \" parfile=/u01/app/export_2014/fga_audit.par

# neu muon unzip thi : cat fga_audit.tar.bz_* | tar -xzv
cd /u01/app/export_2012/dpump_files
tar --remove-files -cvzf - fga_audit_*.dmp | split -b 4096m - fga_audit${_ngay}.tar.bz_
# copy file dump sang o dia Buffalo 52.100
cp -u fga_audit${_ngay}.tar.bz_* /mnt/nfs52100/Audit/
cp -u /u01/app/export_2014/fga_audit.log /mnt/nfs52100/Audit/fga_audit${_ngay}.log

#don dep dia 
cd /u01/app/export_2012
rm -f /u01/app/export_2012/dpump_files/fga_audit_*.dmp
rm -f /u01/app/export_2012/dpump_files/fga_audit*.tar
rm -f /u01/app/export_2012/dpump_files/fga_audit*.tar.bz*

#Note:
# neu ko mount duoc 52.100 thi dung lenh sau:
#mount -t cifs //10.70.52.100/Data2014 /mnt/nfs52100 -o username=qvinh,password=quocvu98,domain=CCBS,iocharset=utf8,rw