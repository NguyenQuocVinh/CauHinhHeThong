_ngay="$(date +%Y%m%d%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF

cd /u01/app/export_2014

rman target /@dhsxkd1 catalog /@dbcata cmdfile=DHSX_SVTech_cumulate.rcv log=DHSX_SVTech_cumulate.log
mv -f DHSX_SVTech_cumulate.log ./logs/DHSX_SVTech/DHSX_SVTech_cumulate_${_ngay}.log
sh Warning_Error_V2.sh ./logs/DHSX_SVTech/DHSX_SVTech_cumulate_${_ngay}.log

