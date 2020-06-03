_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014
rman target /@qlkh1 catalog /@dbcata cmdfile=CTDC_level_1.rcv log=CTDC_level_1.log
mv -f CTDC_level_1.log ./logs/CTDC/CTDC_level_1_${_ngay}.log >>CTDC_level_1.log
sh Warning_Error_V2.sh ./logs/CTDC/CTDC_level_1_${_ngay}.log &

