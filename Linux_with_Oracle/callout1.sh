#!/bin/bash
#neu nhap vao nhieu bien -> dua no vao chuoi cChuoi
#thay the tat ca cac khoang trang bang chuoi "%20"
#
cChuoi=$*
cMesg=${cChuoi// /%20}
echo $cMesg >> /tmp/callout1.log
curl "http://10.70.28.200/post.aspx?ap=$cMesg&sdt=0917723636" &
curl "http://10.70.28.200/post.aspx?ap=$cMesg&sdt=0919650902" &
curl "http://10.70.28.200/post.aspx?ap=$cMesg&sdt=0916287687" &
curl "http://10.70.28.200/post.aspx?ap=$cMesg&sdt=0919653007" &

#Nhan tin den cac so dien thoai sau:
#A.Bao:0919650902
#a.Chung:0916287687
#Minh:0919653007
#Tuan Thanh:
#Vinh : 0917723636


