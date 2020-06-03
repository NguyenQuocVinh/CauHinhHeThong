_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014
rman target /@STGSXKD catalog /@dbcata cmdfile=STGSXKD_level_0.rcv log=STGSXKD_level_0.log
mv -f STGSXKD_level_0.log ./logs/STGSXKD/STGSXKD_level_0_${_ngay}.log
EOF
