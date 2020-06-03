#!/bin/bash
# Wrote date	: 21/4/2015
# Updated date	: 20/8/2015

# 'Canh Bao Loi log file.'
# doc file log backup cua RMAN.
# kiem tra xem co loi RMAN-, ORA- ?
# neu co thi goi tin nhan/ goi mail tuy theo muc do canh bao ma nguoi nhan can kiem tra ngay.
# Muc do nWarningLevel=0 - khong goi tin nhan
# Muc do nWarningLevel=5 - goi tin nhan nhung ghi ro la Warning
# Muc do nWarningLevel=10 - goi tin nhan, ghi ro la loi can xu ly.

# Quet tung dong file log, neu dong nao co chuoi "RMAN-"/"ORA-" thi kiem tra.
# Tren tung dong kiem tra nhu sau
# 	Neu co chuoi "WARNING" --> khong lam gi
# 	Neu co chuoi "ORA-" --> 
#		bat lay chuoi loi ORA (ORA-12345 - chuoi co 10 ky tu)
#		Goi loi do.
# 	Neu van khong co 1 chuoi nao nam trong 2 dieu kien truoc thi 
#		bat lay chuoi loi RMAN (RMAN-12345 - chuoi co 10 ky tu)
#		Goi loi do.

# tham so truyen vao:
# $1 : ten file
# $2 : Default la "N" - Khong goi tin khi logfile la OK. Neu la "Y" thi cu goi tin cho du la OK
# cLogFile - chua ten file log can kiem tra
# nWarningLevel - muc do canh bao khi goi tin nhan. Good:0, Warning: 5, Error >=10
# st : chuoi
# SendMessageOK : goi tin khi OK

#Kiem tra 2 paramter truyen vao
# $2 co default la N --> khong goi message khi OK. Neu la "Y" thi se goi message khi OK.

cLogFile=$1

# kiem tra file, neu ko co thi bao loi.
if [ -f "$cLogFile" ]; then
	echo "Co file."
else
	cMesg="Loi-khong-co-file-log"
	echo $cMesg
	curl "http://10.70.28.200/post.aspx?ap=$cMesg&sdt=0917723636" &
	exit 0
fi

if [ -e $2 ]; then
	SendMessageOK="N"
else
	if [ "$2" == "Y" ] || [ "$2" == "y" ]; then
		SendMessageOK="Y"
	else
		exit 1
	fi
fi

nWarningLevel=0

while read line
do
	# Kiem tra xem co chuoi RMAN- o dau dong?
	#xem co chuoi RMAN- ko ?
	#neu co thi xem co chuoi WARNING ko?
	if echo $line | grep -q RMAN-; then
		if echo $line |grep -q WARNING; then	
			nWarningLevel=5
			echo "RMAN voi nWarningLevel=5, line: $line"
		else
			nWarningLevel=10
			echo "RMAN voi nWarningLevel=10, line: $line"
		fi
	fi
	#xem co chuoi ORA- ko ?
	#neu co thi xem co chuoi WARNING ko?
	if echo $line | grep -q ORA-; then	
		if echo $line | grep -q WARNING; then	
			nWarningLevel=5
			echo "ORA voi nWarningLevel=5, line: $line"
		else
			nWarningLevel=10
			echo "ORA voi nWarningLevel=5, line: $line"
		fi
	fi
	if [ 10 -eq $nWarningLevel ]; then	# neu nWarningLevel=10: thoat vong while.
		break
	fi	
done < $cLogFile

# Kiem tra goi tin nhan
case $nWarningLevel in
	10)
		cMesg="Co-loi-khi-thuc-hien-RMAN:%20$cLogFile"
		curl "http://10.70.28.200/post.aspx?ap=$cMesg&sdt=0917723636" &
		;;
	5)	
		if [ "$SendMessageOK" == "Y" ]; then		#OK cung cu send message
			cMesg="RMAN-Is-Warning:%20$cLogFile"
			curl "http://10.70.28.200/post.aspx?ap=$cMesg&sdt=0917723636" &
		fi
		;;
	0)	
		if [ "$SendMessageOK" == "Y" ]; then		#OK cung cu send message
			cMesg="RMAN-Is-OK-:%20$cLogFile"
			curl "http://10.70.28.200/post.aspx?ap=$cMesg&sdt=0917723636" &
		fi
		;;
esac



