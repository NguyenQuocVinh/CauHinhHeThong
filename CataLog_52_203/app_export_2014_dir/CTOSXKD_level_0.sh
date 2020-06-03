_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014
rman target /@CTOSXKD catalog /@dbcata cmdfile=CTOSXKD_level_0.rcv log=CTOSXKD_level_0.log
mv -f CTOSXKD_level_0.log ./logs/CTOSXKD/CTOSXKD_level_0_${_ngay}.log
sh Warning_Error_V3.sh ./logs/CTOSXKD/CTOSXKD_level_0_${_ngay}.log 0919653007
EOF
