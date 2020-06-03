su - oracle <<EOF
. ./.db
cd /u01/app/export_2012
rman target / cmdfile=backup_extra.rcv log=backup_extra.log