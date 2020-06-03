_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014
rman target /@vtusxkd1 catalog /@dbcata cmdfile=VTUSXKD_level_1.rcv log=VTUSXKD_level_1.log
mv -f VTUSXKD_level_1.log ./logs/VTUSXKD/VTUSXKD_level_1_${_ngay}.log >>VTUSXKD_level_1.log
sh Warning_Error_V2.sh ./logs/VTUSXKD/VTUSXKD_level_1_${_ngay}.log &

