_ngay="$(date +%Y%m%d)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
. ./.db
cd /u01/app/export_2014
rman target / cmdfile=backup_monthly_level_1_day17_31.rcv log=backup_monthly_level_1_day17_31.log
cp -f backup_monthly_level_1_day17_31.log /mnt/nfs52100/backup_monthly_level_1_day17_31_${_ngay}.log
mv -f backup_monthly_level_1_day17_31.log ./logs/backup_monthly_level_1_day17_31_${_ngay}.log