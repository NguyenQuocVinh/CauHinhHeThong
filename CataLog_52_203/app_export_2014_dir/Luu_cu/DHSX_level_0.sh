_ngay="$(date +%Y%m%d)"
echo "**************"
echo $_ngay
echo "**************"
su - oracle <<EOF
cd /u01/app/export_2014/
rman target /@dhhxduph1 catalog /@dbcata cmdfile=DHSX_level_0.rcv log=DHSX_level_0.log
mv -f DHSX_level_0.log ./logs/DHSX/DHSX_level_0_${_ngay}.log
sh Warning_Error_V2.sh DHSX_level_0_${_ngay}.log
