#update 8/8/2015
_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

nNgay=$(date +%d)
nChanLe=`expr $nNgay % 2`

su - oracle <<EOF

cd /u01/app/export_2014

#ngay chan --> +ARCH, le --> +DATA
if [ $nChanLe -eq 0 ]; then
	rman target /@dhsxkd1 catalog /@dbcata cmdfile=DHSX_SVTech_level_1.rcv log=DHSX_SVTech_level_1.log
else
	rman target /@dhsxkd1 catalog /@dbcata cmdfile=DHSX_SVTech_level_1_Le.rcv log=DHSX_SVTech_level_1.log
fi

mv -f DHSX_SVTech_level_1.log ./logs/DHSX_SVTech/DHSX_SVTech_level_1_${_ngay}.log
sh Warning_Error_V3.sh ./logs/DHSX_SVTech/DHSX_SVTech_level_1_${_ngay}.log 0917723636

