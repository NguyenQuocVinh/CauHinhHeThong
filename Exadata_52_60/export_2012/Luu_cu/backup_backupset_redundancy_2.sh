#sudo mount -t cifs //10.70.118.7/rman_ccbs /mnt/win7 -o username=vinhnq,password=quocvu98,domain=CCBS,iocharset=utf8,rw
su - oracle <<EOF
. ./.db
cd /u01/app/export_2012
rman target / cmdfile=backup_backupset_redundancy_2.rcv