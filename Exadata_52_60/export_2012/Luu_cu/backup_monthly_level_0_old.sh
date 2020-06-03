su - oracle <<EOF
. ./.db
cd /u01/app/export_2012
rman target / cmdfile=backup_monthly_level_0.rcv log=backup_monthly_level_0.log