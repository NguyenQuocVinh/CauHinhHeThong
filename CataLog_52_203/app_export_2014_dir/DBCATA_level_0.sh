_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014
rman target / cmdfile=DBCATA_level_0.rcv log=DBCATA_level_0.log
mv -f DBCATA_level_0.log ./logs/DBCATA/DBCATA_level_0_${_ngay}.log
sh Warning_Error_V2.sh ./logs/DBCATA/DBCATA_level_0_${_ngay}.log &

