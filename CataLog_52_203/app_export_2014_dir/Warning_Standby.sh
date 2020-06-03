#!/bin/bash
# Wrote date	: 1/10/2015
# Updated date	: 27/10/2015
# Dung de kiem tra backup va Standby

_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

su - oracle <<EOF
cd /u01/app/export_2014

# Kiem tra archivelog cua QLKH (CT Dung Chung)
rman target /@qlkh1 catalog /@dbcata cmdfile=KiemTra_Archive.rcv log=KiemTra_Archive.log
sh Warning_Error_V3.sh ./KiemTra_Archive.log 0917723636

# Kiem tra archivelog cua 3 tinh VTU,BPC,AGG
rman target /@vtusxkd1 catalog /@dbcata cmdfile=KiemTra_Archive.rcv log=KiemTra_Archive.log
sh Warning_Error_V3.sh ./KiemTra_Archive.log 0917723636

# Kiem tra archivelog cua DHSXKD
rman target /@dhsxkd1 catalog /@dbcata cmdfile=KiemTra_Archive.rcv log=KiemTra_Archive.log
sh Warning_Error_V3.sh ./KiemTra_Archive.log 0919653007
sh Warning_Error_V3.sh ./KiemTra_Archive.log 0917723636

# Kiem tra archivelog cua Dai119
rman target /@db119 cmdfile=KiemTra_Archive.rcv log=KiemTra_Archive.log
sh Warning_Error_V3.sh ./KiemTra_Archive.log 0919653007
sh Warning_Error_V3.sh ./KiemTra_Archive.log 0917723636

# Nhan tin cho biet la server goi tin nhan OK
curl "http://10.70.28.200/post.aspx?ap=Server-Goi-Message-OK&sdt=0917723636" &

EOF




