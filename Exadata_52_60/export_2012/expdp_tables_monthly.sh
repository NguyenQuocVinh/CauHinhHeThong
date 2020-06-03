##############################
#Tao file backup
#Created: 1/3/2014
#Updated: 14/4/2014
###############################
# chay lenh sau de backup theo thang
# sh /u01/app/export_2012/expdp_tables_monthly.sh 11 2014
###############################
# Tinh so luong thang chenh lech voi hien tai
# Tham so thu 1: thang voi 2 so
# Tham so thu 2: nam voi 4 so
#VD: SoThang 09 2010
# Khai bao bien Global dung cho Function SoThang
nSoThang=0 

SoThang() {
	local cNamHTai
	local cThangHTai
	local nNamHTai
	local nThangHTai

	local nMonth
	local nYear

	local x
	# Xac dinh nam,thang hien tai.
	cNamHTai=$(date +%Y)
	cThangHTai=$(date +%m)
	nNamHTai=`expr $cNamHTai + 0`
	nThangHTai=`expr $cThangHTai + 0`

	# Xac dinh cac nam,thang duoc dua vao function
	# Neu khong co tham so nao duoc truyen vao thi set nam va thang la hien tai
	# Neu chi co 1 bien truyen vao thi dua vao thang, con nam thi lay nam hien tai
	# Neu co ca 2 bien thi bien dau la thang, bien sau la nam
	if [ -e $1 ]; then
		nMonth=$nThangHTai
		nYear=$nNamHTai
	else
		nMonth=`expr $1 + 0`
		if [ -e $2 ]; then
			nYear=$nNamHTai
		else
			nYear=`expr $2 + 0`			
		fi
	fi
	
	x=$(($nNamHTai-$nYear))
	x=$(($x*12))
	x=$(($x+$nThangHTai))
	x=$(($x-$nMonth))

	# truyen gia tri ra bien global
	nSoThang=$x
}

# Khai bao bien Global dung cho Function ChuoiMMYYYY
cChuoi=""
# Tham so truyen vao la n thang truoc thang hien tai.
# Ket qua tra ve chuoi truoc do n thang
# vi du ChuoiMMYYYY 10
ChuoiMMYYYY(){
	local nTemp
	local cTemp
	nTemp=$1
	cTemp="date +%m%Y --date='"$nTemp" months ago'"
	echo "$cTemp" > /tmp/ChuoiNgay.sh
	sh /tmp/ChuoiNgay.sh > /tmp/ChuoiNgay.txt
	cChuoi=`cat /tmp/ChuoiNgay.txt`
}
ChuoiYYYYMM(){
	local nTemp
	local cTemp
	nTemp=$1
	cTemp="date +%Y%m --date='"$nTemp" months ago'"
	echo "$cTemp" > /tmp/ChuoiNgay.sh
	sh /tmp/ChuoiNgay.sh > /tmp/ChuoiNgay.txt
	cChuoi=`cat /tmp/ChuoiNgay.txt`
}
if [ -e $1 ] && [ -e $2 ]; then
	# neu khong truyen bien vao thi backup thang truoc
	nSoThang=1
else
	SoThang $1 $2
fi
ChuoiMMYYYY $nSoThang
Pre_MMYYYY=$cChuoi
ChuoiYYYYMM $nSoThang
Pre_YYYYMM=$cChuoi

nSoThang=`expr $nSoThang + 1`
ChuoiMMYYYY $nSoThang
PreOfPre_MMYYYY=$cChuoi
ChuoiYYYYMM $nSoThang
PreOfPre_YYYYMM=$cChuoi

nSoThang=`expr $nSoThang + 1`
ChuoiMMYYYY $nSoThang
PreOfPreOfPre_MMYYYY=$cChuoi
ChuoiYYYYMM $nSoThang
PreOfPreOfPre_YYYYMM=$cChuoi

echo "*******************************"
echo $Pre_MMYYYY
echo $Pre_YYYYMM
echo $PreOfPre_MMYYYY
echo $PreOfPre_YYYYMM
echo $PreOfPreOfPre_MMYYYY
echo $PreOfPreOfPre_YYYYMM
echo "*******************************"

# Chuyen den thu muc lam viec
cd /u01/app/export_2012

# tao ra file moi de backup 
cp -u expdp_tables_CCBS.sh expdp_tables_${Pre_YYYYMM}.sh
cp -u tables_CCBS.par tables_${Pre_YYYYMM}.par

# Thay doi noi dung cua file sh va par
# Thay doi ngay thang cho thang moi.
#sed -e "s/YYYYMM/${Pre_YYYYMM}/g" expdp_tables_${Pre_YYYYMM}.sh > expdp_tables_${Pre_YYYYMM}.sh.tmp && mv expdp_tables_${Pre_YYYYMM}.sh.tmp expdp_tables_${Pre_YYYYMM}.sh 
#sed -e "s/YYYYMM/${Pre_YYYYMM}/g" tables_${Pre_YYYYMM}.par > tables_${Pre_YYYYMM}.par.tmp && mv tables_${Pre_YYYYMM}.par.tmp tables_${Pre_YYYYMM}.par
#sed -e "s/MMYYYY/${Pre_MMYYYY}/g" tables_${Pre_YYYYMM}.par > tables_${Pre_YYYYMM}.par.tmp && mv tables_${Pre_YYYYMM}.par.tmp tables_${Pre_YYYYMM}.par
#sed -e "s/${PreOfPreOfPre_YYYYMM}/${PreOfPre_YYYYMM}/g" tables_${Pre_YYYYMM}.par > tables_${Pre_YYYYMM}.par.tmp && mv tables_${Pre_YYYYMM}.par.tmp tables_${Pre_YYYYMM}.par
#sed -e "s/${PreOfPreOfPre_MMYYYY}/${PreOfPre_MMYYYY}/g" tables_${Pre_YYYYMM}.par > tables_${Pre_YYYYMM}.par.tmp && mv tables_${Pre_YYYYMM}.par.tmp tables_${Pre_YYYYMM}.par

# sua lai tham so -e --> -i : khong can phai lam file tam .tmp nua.
sed -i "s/YYYYMM/${Pre_YYYYMM}/g" expdp_tables_${Pre_YYYYMM}.sh
sed -i "s/YYYYMM/${Pre_YYYYMM}/g" tables_${Pre_YYYYMM}.par
sed -i "s/MMYYYY/${Pre_MMYYYY}/g" tables_${Pre_YYYYMM}.par
sed -i "s/${PreOfPreOfPre_YYYYMM}/${PreOfPre_YYYYMM}/g" tables_${Pre_YYYYMM}.par
sed -i "s/${PreOfPreOfPre_MMYYYY}/${PreOfPre_MMYYYY}/g" tables_${Pre_YYYYMM}.par

##############################
#Thuc hien backup
#############################
sh expdp_tables_${Pre_YYYYMM}.sh
