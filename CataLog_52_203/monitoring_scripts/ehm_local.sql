-- even_histogram_metric, current instance
-- Luca April 2012
-- Esage: @ehm_local <delay> <event>
-- example @ehm_local 15 db%sequential

set serverout on
set verify off

prompt
prompt waiting for &1 sec (delta measurement interval = &1 sec)

DECLARE
  v_event_pattern    varchar2(100) := '%'||'&2'||'%';
  v_sleep_time       number := &1;
  v_dtime_wait_milli number; 
  v_dwaits           number;
  v_avg_wait_milli   number;

  CURSOR c1 IS
    SELECT event, wait_time_milli,wait_count,last_update_time
    FROM v$event_histogram
    WHERE event like v_event_pattern
    ORDER BY event,wait_time_milli;

  CURSOR c2 IS
    SELECT event,time_waited_micro,total_waits 
    FROM v$system_event
    WHERE event like v_event_pattern
    ORDER BY event;

  TYPE EventHisto IS TABLE OF c1%ROWTYPE;
  TYPE SysEvent   IS TABLE OF c2%ROWTYPE;

  t0_histval  EventHisto;  -- nested table of records for t0 snapshot
  t1_histval  EventHisto;  -- nested table of records for t1 snapshot
  t0_eventval SysEvent;    -- nested table of records for t0 snapshot
  t1_eventval SysEvent;    -- nested table of records for t1 snapshot

BEGIN

  -- collect t0 data
  OPEN c1;
  OPEN c2;
  FETCH c1 BULK COLLECT INTO t0_histval;
  FETCH c2 BULK COLLECT INTO t0_eventval; 
  CLOSE c1;
  CLOSE c2;

  IF t0_eventval.COUNT <=0 THEN
    RAISE_APPLICATION_ERROR(-20001,'Not enough data. Probably wrong event name');
  END IF;

  IF t0_eventval.COUNT >= 100 THEN
    RAISE_APPLICATION_ERROR(-20002,'Too many values, soft limit set to 100');
  END IF;


  -- put wait time here note user needs exec privilege on dbms_lock  
  sys.DBMS_LOCK.SLEEP (v_sleep_time);

  -- collect t1 data
  OPEN c1;
  OPEN c2;
  FETCH c1 BULK COLLECT INTO t1_histval;
  FETCH c2 BULK COLLECT INTO t1_eventval; 
  CLOSE c1;
  CLOSE c2;

  -- check and report error if number of points is different (can happen if new histogram bin is created)
  if t0_histval.COUNT <> t1_histval.COUNT then
     RAISE_APPLICATION_ERROR(-20003,'Number of histogram bins changed during collection. Cannot handle it.');
  end if;

  -- print out results
  -- compute delta values and print. 
  -- format with rpad to keep column width constant
  DBMS_OUTPUT.PUT_LINE(chr(13));
  DBMS_OUTPUT.PUT_LINE ('Wait (ms)   N#          Event                   Last update time');
  DBMS_OUTPUT.PUT_LINE ('----------- ----------- ----------------------- -----------------------------------');

  FOR i IN t1_histval.FIRST .. t1_histval.LAST LOOP
    DBMS_OUTPUT.PUT_LINE (
        rpad(t1_histval(i).wait_time_milli,13,' ')||
        rpad(to_char(t1_histval(i).wait_count - t0_histval(i).wait_count),11,' ')||
        t1_histval(i).event || ' ' ||
        t1_histval(i).last_update_time 
      );
    END LOOP;

  DBMS_OUTPUT.PUT_LINE(chr(13));
  DBMS_OUTPUT.PUT_LINE ('Avg_wait(ms) N#         Tot_wait(ms) Event');
  DBMS_OUTPUT.PUT_LINE ('------------ ---------- ------------ -------------------');

  FOR i IN t1_eventval.FIRST .. t1_eventval.LAST LOOP
    v_dtime_wait_milli := (t1_eventval(i).time_waited_micro - t0_eventval(i).time_waited_micro)/1000;
    v_dwaits := t1_eventval(i).total_waits - t0_eventval(i).total_waits;
    IF v_dwaits <> 0 then
       v_avg_wait_milli := round(v_dtime_wait_milli/v_dwaits,1);
    ELSE
       v_avg_wait_milli := 0;
    END IF;
    DBMS_OUTPUT.PUT_LINE(
        rpad(to_char(v_avg_wait_milli),13,' ') ||
        rpad(to_char(v_dwaits),11,' ')||
        rpad(to_char(round(v_dtime_wait_milli,1)),13,' ')||
        t1_eventval(i).event 
      );
    END LOOP;
     
END;
/
