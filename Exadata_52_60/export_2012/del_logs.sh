# delete cac file audit/log cua asm trong vong 15 ngay
find /u01/app/11.2.0.2/grid/rdbms/audit -ctime +15 -mtime +15 -type f |xargs rm -f

find /u01/app/oracle/diag/ -ctime +15 -mtime +15 -type f | xargs rm -f
find /u01/app/11.2.0.2/grid/log/ -ctime +15 -mtime +15 -type f | xargs rm -f

# update ngay 21-2-2013, xoa file listener.log trong vong 100 ngay
find /u01/app/oracle/diag/tnslsnr/dm01db01/listener/trace/ -ctime +100 -type f | xargs rm -f

#mhuy
find /u01/app/oracle/diag/rdbms/ccbs/ccbs1/trace/ -ctime +2 -type f | xargs rm -f
