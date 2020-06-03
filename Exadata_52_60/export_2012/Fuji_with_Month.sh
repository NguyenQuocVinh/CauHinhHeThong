su - oracle <<EOF
. ./.db
cd /u01/app/export_2012

set  DATA_PUMP_DIR DPUMP_DIR
# truoc do phai set lai vi tri thu muc qua lenh sau:
# CREATE OR REPLACE DIRECTORY DPUMP_DIR AS '/u01/app/export_2012/dpump_files';
expdp system/tina2007@ccbs1 parfile=Fuji_with_Month.par
