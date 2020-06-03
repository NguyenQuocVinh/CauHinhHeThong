Rem
Rem $Header: rdbms/admin/preupgrd.sql /main/5 2012/09/19 13:50:55 bmccarth Exp $
Rem
Rem preupgrd.sql
Rem
Rem Copyright (c) 2011, 2012, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      preupgrd.sql - Script used to load and execute the pre upgrade checks.
Rem
Rem    DESCRIPTION
Rem      Loads utluppkg.sql (defines the dbms_preup package) and then
Rem      makes calls to the pre-upgrade package functions to determine
Rem      the status of the to-be-upgraded database.
Rem
Rem      Accepts two optional arguments:
Rem
Rem      @preupgrd {TERMINAL|FILE} {TEXT|XML} 
Rem
Rem         TERMINAL = Output goes to the default output device
Rem         FILE     = Output goes to file defined by 
Rem                    either 
Rem         TEXT = Generate normal text output
Rem         XML  = Generate an XML document (for DBUA use)
Rem
Rem   For example, to have the text output go to the screen:
Rem
Rem     @preupgrd TERMINAL TEXT
Rem
Rem    NOTES
Rem      
Rem      Requires the utluppkg.sql be present in the same directory
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    bmccarth    08/08/12 - noverify, new output
Rem    bmccarth    05/30/12 - fix nvl syntax 14119666
Rem                         - clarify comments
Rem                         - Call output_prolog
Rem    bmccarth    03/28/12 - increase linesize to deal with buffer wrapping
Rem    bmccarth    12/12/11 - Pre Upgrade Check Driver Script
Rem    bmccarth    12/12/11 - Created
Rem


Rem The below code will prevent any prompting if the script is 
Rem invoked without any parameters.
Rem

SET FEEDBACK OFF
SET TERMOUT OFF   

COLUMN 1 NEW_VALUE  1
SELECT NULL "1" FROM SYS.DUAL WHERE ROWNUM = 0;
SELECT NVL('&&1', 'FILE') FROM SYS.DUAL;

COLUMN 2 NEW_VALUE  2
SELECT NULL "2" FROM SYS.DUAL WHERE ROWNUM = 0;
SELECT NVL('&&2', 'TEXT') FROM SYS.DUAL;
SET FEEDBACK ON
SET TERMOUT ON

SET SERVEROUTPUT ON FORMAT WRAPPED;
SET ECHO OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 5000;


BEGIN
  dbms_output.put_line ('Loading Pre-Upgrade Package...');
END;
/

Rem
Rem Run this from the current area as we will be asking customers to 
Rem bring both the package and this driving script from the new 
Rem software installation.
Rem
@@utluppkg.sql


Rem
Rem Supressed parameter replacement output 
Rem 
SET VERIFY OFF

DECLARE
 stat          NUMBER;
 output_target VARCHAR2(10) := 'FILE';
 output_type   VARCHAR2(10) := 'TEXT';

BEGIN
  --
  -- Allow optional parameter to script 
  -- 
  -- Known Values (all others ignored):
  --
  --    Value         Action
  --
  --    FILE     - Output goes into log file (Default)
  --    TERMINAL - Output goes to terminal (or redirected output)
  --    - no arg - Same as FILE
  --
  --    TEXT     - Output TEXT (not XML) (Default)
  --    XML      - Generate an XML document
  --    - no arg - Same as TEXT
  --

  IF UPPER('&&1') = 'TERMINAL' THEN
    output_target := 'TERMINAL';
  ELSIF ( '&&1'IS NULL OR UPPER('&&1') = 'FILE') THEN 
    output_target := 'FILE';
  END IF;

  IF UPPER('&&2') = 'XML' THEN
    output_type := 'XML';
  ELSIF ( '&&2'IS NULL OR UPPER('&&2') = 'TEXT') THEN 
    output_type := 'TEXT';
  END IF;

  IF output_target = 'FILE' THEN
    IF output_type = 'XML' THEN
      --
      -- PREUPG_OUTPUT_DIR is created by the DBUA on the source (to be upgraded)
      -- database
      dbms_preup.set_output_file('PREUPG_OUTPUT_DIR', 'upgrade.xml');
    ELSE
      --
      -- Text output, with scripts
      --
      dbms_preup.set_output_file(TRUE);
      dbms_preup.set_scripts(TRUE);
    END IF;
  ELSE
    --
    -- we will need a big buffer
    --
    DBMS_OUTPUT.ENABLE(900000);
  END IF;

  --
  -- Text or XML (from second argument, or defaulted)
  --
  dbms_preup.set_output_type(output_type);

  IF output_type = 'XML' THEN
    dbms_preup.start_xml_document;
  END IF;

  dbms_output.put_line ('Executing Pre-Upgrade Checks...');

  -- Generate information about the database

  dbms_preup.output_summary;
  dbms_preup.output_initparams;
  dbms_preup.output_components;
  dbms_preup.output_resources;

  -- Execute all the pre-upgrade checks

  stat :=  dbms_preup.run_all_checks;

  dbms_preup.output_preup_checks;

  --
  -- Get the Recommendations out
  --
  dbms_preup.output_recommendations;

  --
  -- Summary
  --
  dbms_preup.output_prolog;

  dbms_output.put_line ('Pre-Upgrade Checks Complete.'); 

  IF output_target = 'FILE' THEN

    IF output_type = 'XML' THEN
      dbms_preup.end_xml_document;
    END IF;

    --
    -- Call routine to dump out a summary 
    --
    dbms_preup.output_check_summary;

    dbms_preup.set_scripts    (FALSE);
    dbms_preup.set_output_file(FALSE); 
    dbms_preup.close_file;
  END IF;
END;
/ 

Rem
Rem Back on.
Rem
SET VERIFY ON
