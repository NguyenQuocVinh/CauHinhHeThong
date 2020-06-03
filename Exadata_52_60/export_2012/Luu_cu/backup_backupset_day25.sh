su - oracle <<EOF
. ./.db
cd /u01/app/export_2012
rman target / cmdfile=backup_backupset_day25.rcv log=backup_backupset_day25.log