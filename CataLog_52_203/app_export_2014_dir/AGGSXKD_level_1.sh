_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"
su - oracle <<EOF
cd /u01/app/export_2014
rman target /@AGGSXKD1 catalog /@dbcata cmdfile=AGGSXKD_level_1.rcv log=AGGSXKD_level_1.log
mv -f AGGSXKD_level_1.log ./logs/AGGSXKD/AGGSXKD_level_1_${_ngay}.log