su - oracle <<EOF
. ./.db
cd /u01/app/export_2012
rm -f ./dpump_files/ccbsYYYYMM*.dmp

set  DATA_PUMP_DIR DPUMP_DIR
# truoc do phai set lai vi tri thu muc qua lenh sau:
# CREATE OR REPLACE DIRECTORY DPUMP_DIR AS '/u01/app/export_2012/dpump_files';
expdp /@ccbs1 parfile=tables_YYYYMM.par

# copy file dump sang o dia Buffalo 52.100
chmod 777 ./dpump_files/ccbs*
mv -f ./dpump_files/ccbsYYYYMM*.dmp /mnt/nfs52100/Data2015/
mv -f ./dpump_files/ccbsYYYYMM*.log /mnt/nfs52100/Data2015/

#Don dep
#rm -f ./dpump_files/ccbsYYYYMM*.dmp
mv -f ./expdp_tables_YYYYMM.sh ./logs/
mv -f ./tables_YYYYMM.par ./logs/