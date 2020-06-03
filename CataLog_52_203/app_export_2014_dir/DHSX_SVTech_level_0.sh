_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF

cd /u01/app/export_2014

rman target /@dhsxkd1 catalog /@dbcata cmdfile=DHSX_SVTech_level_0.rcv log=DHSX_SVTech_level_0.log
mv -f DHSX_SVTech_level_0.log ./logs/DHSX_SVTech/DHSX_SVTech_level_0_${_ngay}.log
sh WarningError_V2.sh ./logs/DHSX_SVTech/DHSX_SVTech_level_0_${_ngay}.log &

