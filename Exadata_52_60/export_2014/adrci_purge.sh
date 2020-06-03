_ngay="$(date +%Y%m%d)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
. ./.db
cd /u01/app/export_2014
adrci script=adrci_purge.txt
mv adrci_purge.log ./logs/adrci_purge_${_ngay}.log