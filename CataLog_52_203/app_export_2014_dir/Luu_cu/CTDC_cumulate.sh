_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014
rman target /@qlkh1 catalog /@dbcata cmdfile=CTDC_cumulate.rcv log=CTDC_cumulate.log
mv -f CTDC_cumulate.log ./logs/CTDC/CTDC_cumulate_${_ngay}.log >>CTDC_cumulate.log
sh Warning_Error_V2.sh ./logs/CTDC/CTDC_cumulate_${_ngay}.log &

