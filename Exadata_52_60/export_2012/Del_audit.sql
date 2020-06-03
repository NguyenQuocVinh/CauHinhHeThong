-- Created: 	01/2/2014
-- Updated: 	11/3/2014
-- Tao table tam audit_tmp 
-- insert du lieu can export cua aud$ vao audit_tmp; sau do export audit_tmp 
--(do expdp chi duoc export cac table ngoai sys nen phai tao table tam de export ra)
-- xoa bot aud$

conn / as sysdba
create table vinhnq.audit_tmp as select * from dba_audit_trail where 1=0;
delete from vinhnq.audit_tmp;
insert into vinhnq.audit_tmp select * from dba_audit_trail where timestamp<=sysdate-4;
commit;
delete from sys.aud$ where ntimestamp#<sysdate-4;
COMMIT;
exit
/

