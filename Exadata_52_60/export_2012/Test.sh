
if [ ! -e $1 ] && [ ! -e $2 ]; then 

	#Function NamThangNgay
	NTNday(){
		# ham tao ra kieu date
		date --date=$year$month"01" +%Y%m%d 
	}
	
	
	
	echo "Parameter 1 va 2 deu khac trong"

	month="$1"
	year="$2"

	echo $month
	echo $year
	echo "----------------------------"
	date +%m%Y --date=$(NTNday)
	date +%m%Y --date=date-100

	echo "----------------------------"
	echo "*****************"
	echo "$(NTNday)"
	echo "$(NTNday +%m%Y --date='2 months ago')"
	echo "*****************"



	Pre_MMYYYY="$(date +%m%Y --date='1 months ago')"
	Pre_YYYYMM="$(date +%Y%m --date='1 months ago')"
	
	PreOfPre_MMYYYY="$(date +%m%Y --date='2 months ago')"
	PreOfPre_YYYYMM="$(date +%Y%m --date='2 months ago')"

	PreOfPreOfPre_MMYYYY="$(date +%m%Y --date='3 months ago')"
	PreOfPreOfPre_YYYYMM="$(date +%Y%m --date='3 months ago')"
else
	echo "Parameter 1 hoac 2 Khac Trong"	
	Pre_MMYYYY="$(date +%m%Y --date='1 months ago')"
	Pre_YYYYMM="$(date +%Y%m --date='1 months ago')"

	PreOfPre_MMYYYY="$(date +%m%Y --date='2 months ago')"
	PreOfPre_YYYYMM="$(date +%Y%m --date='2 months ago')"

	PreOfPreOfPre_MMYYYY="$(date +%m%Y --date='3 months ago')"
	PreOfPreOfPre_YYYYMM="$(date +%Y%m --date='3 months ago')"
fi

echo "*******************************"
echo $Pre_MMYYYY
echo $Pre_YYYYMM
echo $PreOfPre_MMYYYY
echo $PreOfPre_YYYYMM
echo $PreOfPreOfPre_MMYYYY
echo $PreOfPreOfPre_YYYYMM
echo "*******************************"

