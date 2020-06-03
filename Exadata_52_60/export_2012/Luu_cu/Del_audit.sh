su - oracle <<EOF
. ./.db
cd /u01/app/export_2012/
sqlplus "/ as sysdba" @Del_audit.sql
