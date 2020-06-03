-- Created: 	01/2/2014
-- Updated: 	11/3/2014
-- Tao table tam audit_tmp 
-- insert du lieu can export cua aud$ vao audit_tmp; sau do export audit_tmp 
--(do expdp chi duoc export cac table ngoai sys nen phai tao table tam de export ra)
-- xoa bot aud$

conn / as sysdba
declare
	dTemp date;
	nSoNgay integer :=4;
begin
	select sysdate - nSoNgay into dTemp from dual;
	--create table export_ccbs.fga_audit_tmp as select * from dba_common_audit_trail where 1=0;
	delete from export_ccbs.fga_audit_tmp;
	insert into export_ccbs.audit_tmp select * from dba_audit_trail where extended_timestamp<=dTemp;
	delete from sys.aud$ where ntimestamp#<=dTemp;
	delete from sys.fga_log$ where ntimestamp#<=dTemp;
	COMMIT;
end;
/
exit


