# Created: 	01/2/2014
# Updated: 	7/8/2015
# export 1 phan du lieu aud$ ra, don dep bot aud$.
# Doi mod cac file aud*.dmp de no cho phep xoa.
# 

_ngay="$(date +%Y%m%d_%H%M)"
echo "**************"
echo $_ngay
echo "**************"

if [ -e $1 ]; then
	# neu khong truyen bien vao thi audfile co gia tri la "aud"
	_audfile="aud"
else
	_audfile=$1
fi



su - oracle <<EOF
export ORAENV_ASK=NO
export ORACLE_SID=VTUSXKD1
. oraenv

cd /u01/app/export_2012
rm -f ./dpump_files/${_audfile}_*.dmp
rm -f ./dpump_files/${_audfile}*.tar
rm -f ./dpump_files/${_audfile}*.tar.bz*

sqlplus "/ as sysdba" @Del_audit.sql

set  DATA_PUMP_DIR DPUMP_DIR
# truoc do phai set lai vi tri thu muc qua lenh sau:
# CREATE OR REPLACE DIRECTORY DPUMP_DIR AS '/u01/app/export_2012/dpump_files';
expdp \"/as sysdba \" parfile=aud.par
# neu muon unzip thi : cat aud.tar.bz_* | tar -xzv
cd ./dpump_files
chmod 777 aud_*.dmp
tar --remove-files -cvzf - aud_*.dmp | split -b 4096m - ${_audfile}${_ngay}.tar.bz_
# copy file dump sang o dia Buffalo 52.100
chmod 777 aud*
mv -f ${_audfile}${_ngay}.tar.bz_* /mnt/nfs52100/Audit/
cp -u aud.log /mnt/nfs52100/Audit/${_audfile}${_ngay}.log
mv -f aud.log ../logs/${_audfile}${_ngay}.log

#Note:
# neu ko mount duoc 52.100 thi dung lenh sau:
#mount -t cifs //10.70.52.100/Data2014 /mnt/nfs52100 -o username=qvinh,password=tina...***,domain=CCBS,iocharset=utf8,rw