_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014
rman target /@vtusxkd1 catalog /@dbcata cmdfile=VTUSXKD_cumulate.rcv log=VTUSXKD_cumulate.log
mv -f VTUSXKD_cumulate.log ./logs/VTUSXKD/VTUSXKD_cumulate_${_ngay}.log >>VTUSXKD_cumulate.log
sh Warning_Error_V2.sh ./logs/VTUSXKD/VTUSXKD_cumulate_${_ngay}.log &

