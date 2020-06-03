_ngay="$(date +%Y%m%d%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014
rman target vinhnq/tinavu2007@dhhxduph1 catalog rman/SaiGon123@dbcata cmdfile=DHSX_level_1.rcv log=DHSX_level_1.log
mv -f DHSX_level_1.log ./logs/DHSX/DHSX_level_1_${_ngay}.log
