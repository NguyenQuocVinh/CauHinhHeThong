_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014
rman target /@ccbs1 catalog /@dbcata cmdfile=Exadata_level_0.rcv log=Exadata_level_0.log
mv -f Exadata_level_0.log ./logs/Exadata/Exadata_level_0_${_ngay}.log
sh Warning_Error_V2.sh ./logs/Exadata/Exadata_level_0_${_ngay}.log &

