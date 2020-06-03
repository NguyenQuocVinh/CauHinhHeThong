echo '**************************'

ls
su - oracle <<EOF
. ./.db
cd /u01/app/export_2014
rman target / cmdfile=Duplicate.rcv log=Duplicate.log
