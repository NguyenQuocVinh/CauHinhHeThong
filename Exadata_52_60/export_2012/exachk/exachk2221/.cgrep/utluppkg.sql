Rem $Header: rdbms/admin/utluppkg.sql /st_rdbms_12.1.0.1/6 2013/01/27 14:55:53 krajaman Exp $
Rem
Rem utluppkg.sql
Rem
Rem Copyright (c) 2011, 2013, Oracle and/or its affiliates. 
Rem All rights reserved. 
Rem
Rem    NAME
Rem      utluppkg.sql - Pre Upgrade Utility Package
Rem
Rem    DESCRIPTION
Rem      Procedures and functions used to perform checks on a database which 
Rem      is getting ready to be upgrade.
Rem
Rem    NOTES
Rem      This file contains both the package body and defintion.
Rem
Rem      The package has test types:
Rem         - initparams
Rem         - components
Rem         - resources
Rem         - pre-upgrade checks
Rem
Rem      which may or may not be requested by the user.
Rem      The output_<test-type> procedure will verify that the
Rem      init_<test-type> procedure has been called.
Rem
Rem      Any global variables will be initialized by 
Rem      the init_package procedure.
Rem
Rem      When using 'TEXT' output without an output file, 
Rem      the caller must turn off SERVER OUTPUT prior to calling
Rem      the _output routines.
Rem          SET SERVEROUTPUT ON FORMAT WRAPPED;
Rem          SET ECHO OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 5000;
Rem
Rem      Variable that begin with "c_" are constants for the package
Rem
REM BEGIN SQL_FILE_METADATA
REM SQL_SOURCE_FILE: rdbms/admin/utluppkg.sql
REM SQL_SHIPPED_FILE: rdbms/admin/utluppkg.sql
REM SQL_PHASE: UTLUPPKG
REM SQL_STARTUP_MODE: NORMAL
REM SQL_IGNORABLE_ERRORS: NONE
REM SQL_CALLING_FILE: rdbms/admin/catproc.sql
REM END SQL_FILE_METADATA
REM
Rem    MODIFIED   (MM/DD/YY)
Rem    cmlim       01/25/13 - update INVALID_SYS_TABLEDATA_gethelp to include
Rem                           PDB (for bug 16223659)
Rem    cmlim       01/08/13 - bug 16085743: extra: change WARNING to ERROR
Rem                           for invalid user table data
Rem    bmccarth    01/07/13 - tabledata fix for DBUA
Rem    bmccarth    01/03/13 - fix several sql statements
Rem    bmccarth    12/20/12 - bug 15899139 - rul/exf fix
Rem    bmccarth    12/01/12 - INVALID_SYS_TABLEDATA/INVALID_USR_TABLEDATA
Rem                         - rename sqlcode variable/params
Rem                         - Add condition_exists function.
Rem                         - Add sql file metadata as this will be loaded
Rem                           during db create.
Rem                         - Fix AMD check
Rem                         - Fix in-place check, if DB was never 
Rem                           upgraded, tool reported 'unsupported', also
Rem                           added several comments around that block of code
Rem                         - Unused variables removed
Rem    jerrede     11/08/12 - Make tz_fixup public
Rem    mfallen     09/23/12 - bug 14390165: check if AWR will need cleanup
Rem    bmccarth    09/27/12 - job_queue_processes check
Rem                         - remove un-used variables
Rem                         - move routine def/decl into alpha order
Rem    bmccarth    09/27/12 - bug 14684128 - protect writes when logs fail to
Rem                           open
Rem    amunnoli    09/07/12 - Bug 14560783: Raise an error if user or role
Rem                           named AUDSYS,AUDIT_ADMIN,AUDIT_VIEWER already
Rem                           exists in the source DB to be upgraded to 12.1
Rem    bmccarth    09/12/12 - bug 14608684 - ultrasearch txt
Rem                         - bug 14619362 - DMSYS text change
Rem                         - bug 14635610 - re-init resource value each 
Rem                           time through
Rem    amunnoli    09/07/12 - Bug 14560783: Raise an error if user or role
Rem                           named AUDSYS,AUDIT_ADMIN,AUDIT_VIEWER already
Rem                           exists in the source DB to be upgraded to 12.1
Rem    cmlim       09/04/12 - bug 14551710 - tablespace sizing for apex need to
Rem                           be updated for latest apex version 4.2.0
Rem                         - extra: increment archivelog and
Rem                           flashbacklog experimental numbers by 1.1
Rem                         - extra: sysaux size should not be less than 500M 
Rem                         - extra: minimum tablespace incremental size is 50M
Rem                         - extra: update description to OLS_SYS_MOVE
Rem                         - extra: prefixed 'DUAL' with 'SYS.'
Rem    bmccarth    08/17/12 - remove refreshes exist check
Rem    bmccarth    08/08/12 - bug 14469506 - rework output
Rem                         - MAX_PROCESS becomes default_process
Rem                         - bug 14619157 error count not matching
Rem                           so clear check record run info in run_check 
Rem    bmccarth    08/17/12 - remove view in progress check
Rem    bmccarth    08/07/12 - em check is incorrect
Rem    bmccarth    07/10/12 - tz to 18
Rem    bmccarth    07/09/12 - merge in cmlim archivemode size
Rem                         - Add diag info to XML doc when requested
Rem                         - sec_case_sensitive_logon gone for 12.1
Rem    bmccarth    05/09/12 - give DBUA all tablespaces
Rem                         - stop output tablespace for unsupported upgrades
Rem                         - Update error/warning text after 
Rem                           documention review
Rem                         - min process up to 300 - bug 14067986 (and 
Rem                           add manual output)
Rem                         - deprecated becomes desupported (text only change)
Rem                         - change DisplayLine so it works from 
Rem                           init procedures
Rem                         - Move tablespace debug output
Rem                         - compat recommend becomes an actual check
Rem                         - alphabetize check functions
Rem                         - add ols_sys_move check
Rem                         - all checks are no preceeded by ERROR or 
Rem                           WARNING should they fail (allow easy 
Rem                           searching for issues in log files)
Rem                         - prior code review comments: use constants for 
Rem                           return values
Rem                         - AL24UTFFSS and NCHAR_TYPE checks removed
Rem    bmccarth    04/12/12 - merge in size changes
Rem                         - Updated buffer size for utl_file
Rem                         - Ultrasearch and enableD_indexes_tbl detail are
Rem                           now text, not sql
Rem    cdilling    04/10/12 - change type_sql to type_text -bug 13946411
Rem    awesley     04/02/12 - deprecate cwm, remove AMD
Rem    bmccarth    03/07/12 - network acl check
Rem                         - Audit_Trail param changes - bug 13885449
Rem                         - Fix java cleanup from failing on mulitple loads
Rem                         - Cleanup/add comments around processing 
Rem                           special params.
Rem                         - EM warning changed
Rem                         - buffer sizes for output increase
Rem                         - remove 'IN' from  result_text of _check routines 
Rem                         - db_name to 256
Rem                         - rename a few package level variables
Rem                         - remove genFixup_info (duplicate of genFixup 
Rem                           after rework of package in last rev)
Rem                         - OCM and APPQOSSYS User check is only for 102 
Rem                           upgrades
Rem                         - bug 13819259 - refreshes_exist check was wrong
Rem                         - bug 12536056 - add params around _ event 
Rem                           check clause
Rem    bmccarth    01/19/12 - bug 13601349 - handle directory object failures
Rem                         - bug 13616875 - missing htmlentities call
Rem                         - bug 13628060 - quotes wrong for fixup of 
Rem                           displaying events
Rem                         - files_need_recovery is a manual fix (not auto)
Rem                         - When set_output_file is called with location,
Rem                           set the validated bit so the code actually does
Rem                           something.
Rem                         - Fix ocm/qos checks
Rem                         - Add missing rollback seg output back in
Rem                         - Moved recommendations into check_table for 
Rem                           consistancy 
Rem                         - Remove grants from script
Rem                         - Add missing compatability check
Rem                         - remove script_location variable (use 
Rem                           output_location for all output)
Rem                         - ensure package level output variables are cleared
Rem                         - present better errors if directory does not 
Rem                           exist (including if directory object 
Rem                           already exists)
Rem                         - Add debug procedures to force failures
Rem    bmccarth    12/28/11 - protect drop directory from errors
Rem    bmccarthy   12/15/11 - Add recommendation section
Rem    bmccarth    11/15/11 - continue adding features
Rem    bmccarth    11/09/11 - Added htmlentities so DBUA had valid xml when
Rem                           a SQL command included certain characters
Rem                         - removed ; from end of sql commands
Rem    bmccarth    09/13/11 - Merge in DBUA changes continue to add checks
Rem    bmccarth    08/17/11 - Pre Upgrade Utility Package, framework
Rem                         - testing puiu$data removed
Rem    bmccarth    08/17/11 - Created
Rem


CREATE OR REPLACE PACKAGE dbms_preup AS
--
-- preupgrd.sql will look at the version to
-- make sure things match up.
--
c_version     CONSTANT VARCHAR2(30)    := '12.1.0.1';

c_patchset    CONSTANT VARCHAR2(2)     := '.0';
c_build       CONSTANT VARCHAR2(30)    := '006';
c_supported_versions
              CONSTANT VARCHAR(50)     := '10.2.0.5, 11.1.0.7, 11.2.0.2, 11.2.0.3, 11.2.0.4';
c_tz_version  CONSTANT NUMBER          := 18;
c_max_processes CONSTANT NUMBER        := 300;

--
-- what we require for min compat, in numeric and 
-- text form
--
c_compat_min_num CONSTANT NUMBER       := 11;
c_compat_min  CONSTANT VARCHAR(30)     := '11.0.0';

c_dir_obj        CONSTANT VARCHAR2(30) := 'PREUPGRADE_DIR';  -- Default dir obj
c_output_fn      CONSTANT VARCHAR2(30) := 'preupgrade.log';  -- Default log fn
c_pre_script_fn  CONSTANT VARCHAR2(30) := 'preupgrade_fixups.sql';
c_post_script_fn CONSTANT VARCHAR2(30) := 'postupgrade_fixups.sql';

--
-- What kind of output are we doing?
--
c_output_text     CONSTANT NUMBER := 1;
c_output_xml      CONSTANT NUMBER := 2;

--
-- Used to keep track of pre-upgrade checks
-- 
--
TYPE check_record_t IS RECORD (
  name             VARCHAR2(30),   -- Name of check (and used for function 
                                   -- names also (if not too long))
  type             NUMBER,         -- see type constants for values
                    -- c_type_check = standard check for both xdb/manual
                    -- c_type_check_interactive_only = Standard check, but manual only
                    -- c_type_recommend_pre = pre-up recommendation (manual)
                    -- c_type_recommend_post = post-up recommendation (manual)
                    --
  descript         VARCHAR2(100),  -- Short description of the check
  f_name_prefix    VARCHAR2(30),   -- If name is too long to add 
                                   -- "_gethelp" and create a valid 
                                   -- function name, this is set to a 
                                   -- shorten name to be used when accessing
                                   -- a check's functions.
  level            NUMBER,         -- Check level (c_check_level_....)
  fix_type         NUMBER,         -- fix_type (by_fixup, manual)
  executed         BOOLEAN,        -- Has the test been run?
  execute_failed   BOOLEAN,        -- If the check takes an exception.
  passed           BOOLEAN,        -- Did the check pass?
  skipped          BOOLEAN,        -- Skipped, check not valid for this version
  fixup_executed   BOOLEAN,        -- Was a fixup attempted ?
  fixup_failed     BOOLEAN,        -- Did the fixup execute fail?
  fixup_status     NUMBER,         -- c_fixup_status... value
  always_fail      BOOLEAN,        -- Debug the check's failure path (generate a fixup)
  valid_versions   VARCHAR(100),   -- What versions is this check valid for?
  result_text      VARCHAR2(1500), -- result of fixup/check
  sqlcode          NUMBER          -- The sqlcode should an error occur.
);
TYPE check_table_t is TABLE of check_record_t INDEX BY BINARY_INTEGER;

--
-- This record is to index the check_table by name
--
TYPE check_record_name_t IS RECORD (
  idx            NUMBER               -- Index into check_table
);

TYPE check_names_table_t is TABLE of check_record_name_t INDEX BY VARCHAR2(30);

--
-- dbms_preup.check_table contains
-- a list of all of the checks this package (once inited)
-- has performed on the database.
--
-- Although check_table could have been indexed by name, doing so would have
-- changed the order when looping through as new checks were added or old 
-- checks removed.
--
check_table       check_table_t;

--
-- Index by name
--
check_names       check_names_table_t;


pCheckCount        NUMBER := 0;  -- Total number of checks we have available.
pCheckErrorCount   NUMBER;
pCheckWarningCount NUMBER;
pCheckInfoCount    NUMBER;

--
-- How the fix can be fixed
--
c_fix_source_manual      CONSTANT NUMBER := 0;
c_fix_source_auto        CONSTANT NUMBER := 1;  -- pre-upgrade
c_fix_target_auto_pre    CONSTANT NUMBER := 2;  -- targetpre - only new timezone
c_fix_target_auto_post   CONSTANT NUMBER := 3;  -- after upgrade process is done
c_fix_target_manual_pre  CONSTANT NUMBER := 4;  -- manual, before
c_fix_target_manual_post CONSTANT NUMBER := 5; -- manual after upgrade
--
-- Type of Check
-- 
c_type_check                   CONSTANT NUMBER := 1;
c_type_check_interactive_only  CONSTANT NUMBER := 2;
c_type_recommend_pre           CONSTANT NUMBER := 3;
c_type_recommend_post          CONSTANT NUMBER := 4;

--
-- What gethelp returns
--
c_help_overview       CONSTANT NUMBER := 1;
c_help_fixup          CONSTANT NUMBER := 2;

--
-- What a Fixup routine could return
--
c_fixup_status_failure CONSTANT NUMBER := 0;
c_fixup_status_success CONSTANT NUMBER := 1;
c_fixup_status_info    CONSTANT NUMBER := 2;

--
-- What Check/help routine could return
--
c_status_failure                 CONSTANT NUMBER := 0;
c_status_success                 CONSTANT NUMBER := 1;
c_status_passed                  CONSTANT NUMBER := 1;
c_status_not_for_this_version    CONSTANT NUMBER := 2;

-- Functions

FUNCTION  get_version    RETURN VARCHAR2;
FUNCTION  run_all_checks RETURN NUMBER;

FUNCTION  run_check (check_name IN VARCHAR2) RETURN check_record_t;
FUNCTION  run_check_simple (check_name IN VARCHAR2) RETURN check_record_t;
FUNCTION  condition_exists (check_name IN VARCHAR2) RETURN BOOLEAN;
PROCEDURE run_check (check_name IN VARCHAR2);
FUNCTION  run_fixup (check_name IN VARCHAR2) RETURN check_record_t;
PROCEDURE run_fixup_and_report (check_name VARCHAR2);
PROCEDURE run_fixup_info (check_name VARCHAR2);
PROCEDURE display_check_text (check_record check_record_t );
PROCEDURE fixup_summary (preup BOOLEAN);
PROCEDURE clear_run_flag (preup BOOLEAN);

FUNCTION  run_recommend (check_name IN VARCHAR2) RETURN check_record_t;
PROCEDURE run_all_recommend (whatType NUMBER);

PROCEDURE DisplayLine (line IN VARCHAR2);
PROCEDURE DisplayLine (uft UTL_FILE.FILE_TYPE, line IN VARCHAR2);
PROCEDURE DisplayDiagLine (line IN VARCHAR2);

PROCEDURE start_xml_document;
PROCEDURE end_xml_document;

PROCEDURE output_summary;
PROCEDURE output_components;
PROCEDURE output_flashback;
PROCEDURE output_initparams;
PROCEDURE output_preup_checks;
PROCEDURE output_prolog;
PROCEDURE output_check_summary;
PROCEDURE output_recommendations;
PROCEDURE output_resources;
PROCEDURE output_tablespaces;
PROCEDURE output_rollback_segs;

--
-- Call these to debug a certain check, 
-- debug all checks, or debug tablespace resources
--
PROCEDURE dbg_check (check_name IN VARCHAR2);
PROCEDURE dbg_all_checks;
PROCEDURE dbg_all_resources (onoff BOOLEAN);
PROCEDURE dbg_space_resources (onoff BOOLEAN);
PROCEDURE time_zone_check;
PROCEDURE tz_fixup (call_init BOOLEAN);

--
-- Set the output type to either Text or XML
--   
-- If XML is chosen, a call to  start_xml_document 
-- and close_xml_docuement must be 
-- made to ensure correct syntax of the XML output.
--
-- Output type default to TEXT
--
PROCEDURE  set_output_type (p_type VARCHAR2);

--
-- If the diag output is going to a file, use these 
-- proceduress to set, and close that output file.
--
-- The package uses utl_file, and if there is an 
-- error opening the file, the package will throw
-- an error. 
--
PROCEDURE  set_output_file (p_on_off BOOLEAN);
PROCEDURE  set_output_file (p_fn   VARCHAR2);
PROCEDURE  set_output_file (p_location VARCHAR2, p_fn VARCHAR2);

PROCEDURE  close_file;

--
-- Turn generating scripts on/off
--
PROCEDURE  set_scripts (p_on_off BOOLEAN);

--
-- Function to get path of directory used to output log/script
-- 
FUNCTION get_output_path RETURN VARCHAR2;

--
-- Display a single check record fields
--
PROCEDURE  dump_check_rec   (p_check_rec check_record_t);

--
-- Specific Check/fixup Functions 
-- 
FUNCTION  amd_exists_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE amd_exists_fixup;
FUNCTION  amd_exists_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  amd_exists_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  aar_present_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE aar_present_fixup;
FUNCTION  aar_present_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  aar_present_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  appqossys_user_present_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE appqossys_user_present_fixup;
FUNCTION  appqossys_user_present_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  appqossys_user_present_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  audsys_user_present_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE audsys_user_present_fixup;
FUNCTION  audsys_user_present_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  audsys_user_present_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  audit_viewer_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE audit_viewer_fixup;
FUNCTION  audit_viewer_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  audit_viewer_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  awr_dbids_present_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE awr_dbids_present_fixup;
FUNCTION  awr_dbids_present_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  awr_dbids_present_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  compatible_parameter_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE compatible_parameter_fixup;
FUNCTION  compatible_parameter_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  compatible_parameter_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  dbms_ldap_dep_exist_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE dbms_ldap_dep_exist_fixup;
FUNCTION  dbms_ldap_dep_exist_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  dbms_ldap_dep_exist_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  default_process_count_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE default_process_count_fixup;
FUNCTION  default_process_count_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  default_process_count_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  dv_enabled_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE dv_enabled_fixup;
FUNCTION  dv_enabled_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  dv_enabled_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  em_present_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE em_present_fixup;
FUNCTION  em_present_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  em_present_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  enabled_indexes_tbl_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE enabled_indexes_tbl_fixup;
FUNCTION  enabled_indexes_tbl_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  enabled_indexes_tbl_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  exf_rul_exists_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE exf_rul_exists_fixup;
FUNCTION  exf_rul_exists_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  exf_rul_exists_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  files_need_recovery_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE files_need_recovery_fixup;
FUNCTION  files_need_recovery_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  files_need_recovery_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  files_backup_mode_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE files_backup_mode_fixup;
FUNCTION  files_backup_mode_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  files_backup_mode_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  invalid_laf_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE invalid_laf_fixup;
FUNCTION  invalid_laf_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  invalid_laf_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  invalid_obj_exist_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE invalid_obj_exist_fixup;
FUNCTION  invalid_obj_exist_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  invalid_obj_exist_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;
FUNCTION  invalid_obj_exclude RETURN VARCHAR2;

FUNCTION  invalid_sys_tabledata_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE invalid_sys_tabledata_fixup;
FUNCTION  invalid_sys_tabledata_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  invalid_sys_tabledata_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  invalid_usr_tabledata_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE invalid_usr_tabledata_fixup;
FUNCTION  invalid_usr_tabledata_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  invalid_usr_tabledata_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  job_queue_process_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE job_queue_process_fixup;
FUNCTION  job_queue_process_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  job_queue_process_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  nacl_objects_exist_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE nacl_objects_exist_fixup;
FUNCTION  nacl_objects_exist_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  nacl_objects_exist_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  new_time_zones_exist_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE new_time_zones_exist_fixup;
FUNCTION  new_time_zones_exist_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  new_time_zones_exist_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  ocm_user_present_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE ocm_user_present_fixup;
FUNCTION  ocm_user_present_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  ocm_user_present_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  old_time_zones_exist_check  (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE old_time_zones_exist_fixup;
FUNCTION  old_time_zones_exist_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  old_time_zones_exist_fixup  (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  ols_sys_move_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE ols_sys_move_fixup;
FUNCTION  ols_sys_move_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  ols_sys_move_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  ordimageindex_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE ordimageindex_fixup;
FUNCTION  ordimageindex_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  ordimageindex_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  pending_2pc_txn_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE pending_2pc_txn_fixup;
FUNCTION  pending_2pc_txn_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  pending_2pc_txn_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  purge_recyclebin_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE purge_recyclebin_fixup;
FUNCTION  purge_recyclebin_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  purge_recyclebin_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  remove_dmsys_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE remove_dmsys_fixup;
FUNCTION  remove_dmsys_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  remove_dmsys_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  remote_redo_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE remote_redo_fixup;
FUNCTION  remote_redo_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  remote_redo_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  sync_standby_db_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE sync_standby_db_fixup;
FUNCTION  sync_standby_db_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  sync_standby_db_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  sys_def_tablespace_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE sys_def_tablespace_fixup;
FUNCTION  sys_def_tablespace_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  sys_def_tablespace_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  ultrasearch_data_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE ultrasearch_data_fixup;
FUNCTION  ultrasearch_data_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  ultrasearch_data_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

FUNCTION  unsupported_version_check (result_txt OUT VARCHAR2) RETURN number;
PROCEDURE unsupported_version_fixup;
FUNCTION  unsupported_version_gethelp (HelpType IN NUMBER) RETURN VARCHAR2;
FUNCTION  unsupported_version_fixup (result_txt IN OUT VARCHAR2, pSqlcode IN OUT NUMBER) RETURN number;

--
-- The recommendation procedures
--
PROCEDURE dictionary_stats_recommend;
PROCEDURE hidden_params_recommend;
PROCEDURE underscore_events_recommend;
PROCEDURE audit_records_recommend;
PROCEDURE fixed_objects_recommend;

END dbms_preup;
/

-- ***********************************************************************
--                         Package Body
-- ***********************************************************************
CREATE OR REPLACE PACKAGE BODY dbms_preup AS

c_output_terminal        CONSTANT NUMBER := 0;
c_output_file            CONSTANT NUMBER := 1;

--
-- Values for 'level' field
--
c_check_level_success    CONSTANT NUMBER := 1;
c_check_level_info       CONSTANT NUMBER := 3;
c_check_level_warning    CONSTANT NUMBER := 2;
c_check_level_error      CONSTANT NUMBER := 4;
c_check_level_recommend  CONSTANT NUMBER := 5;

c_check_level_warning_txt   CONSTANT VARCHAR2(7)  := 'WARNING';
c_check_level_error_txt     CONSTANT VARCHAR2(5)  := 'ERROR';
c_check_level_info_txt      CONSTANT VARCHAR2(4)  := 'INFO';
c_check_level_success_txt   CONSTANT VARCHAR2(7)  := 'SUCCESS';
c_check_level_recommend_txt CONSTANT VARCHAR2(16) := 'RECOMMENDATION';


c_dbua_detail_type_sql   CONSTANT VARCHAR2(3) := 'SQL';
c_dbua_detail_type_text  CONSTANT VARCHAR2(4) := 'TEXT';

c_dbua_fixup_type_auto   CONSTANT VARCHAR2(4) := 'AUTO';
c_dbua_fixup_type_manual CONSTANT VARCHAR2(6) := 'MANUAL';
c_dbua_fixup_stage_pre   CONSTANT VARCHAR2(11):= 'PRE_UPGRADE';
c_dbua_fixup_stage_post  CONSTANT VARCHAR2(12):= 'POST_UPGRADE';
c_dbua_fixup_stage_validation   CONSTANT VARCHAR2(11):= 'VALIDATION';

--
-- Can't used this for declaring strings but can for length
-- checks
-- 
c_str_max                CONSTANT NUMBER := 4000;

--
-- Record types
--

TYPE cursor_t  IS REF CURSOR;

TYPE minvalue_record_t IS RECORD (
  name     VARCHAR2(80),
  minvalue NUMBER,
  oldvalue NUMBER,
  newvalue NUMBER,
  display  BOOLEAN,
  diff     NUMBER  -- the positive diff of 'oldvalue - minvalue' if
                   -- sga_target or memory_target is used
);

TYPE minvalue_table_t IS TABLE of minvalue_record_t
   INDEX BY BINARY_INTEGER;

minvp_db32   minvalue_table_t;
minvp_db64   minvalue_table_t;
max_minvp    BINARY_INTEGER;

--
-- These are all indexes into the 
-- minvp arrays for the given pools
-- 
sp_idx BINARY_INTEGER;  -- shared_pool_size
jv_idx BINARY_INTEGER;  -- java_pool_size
tg_idx BINARY_INTEGER;  -- sga_target
cs_idx BINARY_INTEGER;  -- cache_size
pg_idx BINARY_INTEGER;  -- pga_aggreate_target
mt_idx BINARY_INTEGER;  -- memory_target
lp_idx BINARY_INTEGER;  -- large_pool_size
str_idx BINARY_INTEGER; -- streams_pool_size

TYPE comp_record_t IS RECORD (
  cid            VARCHAR2(30), -- component id
  cname          VARCHAR2(45), -- component name
  version        VARCHAR2(30), -- version
  status         VARCHAR2(15), -- component status
  schema         VARCHAR2(30), -- owner of component
  def_ts         VARCHAR2(30), -- name of default tablespace
  script         VARCHAR2(128), -- upgrade script name
  processed      BOOLEAN,       -- TRUE IF in the registry AND is not
                                -- status REMOVING/REMOVED, OR
                                -- TRUE IF will be in the registry because
                                -- because cmp_info().install is TRUE
  install        BOOLEAN, -- TRUE if component to be installed in upgrade
  sys_kbytes     NUMBER,  -- upgrade size needed in system tablespace
  sysaux_kbytes  NUMBER,  -- upgrade size needed in sysaux tablespace
  def_ts_kbytes  NUMBER,  -- upgrade size needed in 'other' tablespace
  ins_sys_kbytes NUMBER,  -- install size needed in system tablespace
  ins_def_kbytes NUMBER,  -- install size needed in 'other' tablespace
  archivelog_kbytes   NUMBER, -- minimum archive log space per component
  flashbacklog_kbytes NUMBER  -- minimum flashback log size per component
);
TYPE comp_table_t IS TABLE of comp_record_t INDEX BY BINARY_INTEGER;
cmp_info comp_table_t;      -- Table of component information


-- index values for components (order as in upgrade script)
catalog CONSTANT BINARY_INTEGER:=1;
catproc CONSTANT BINARY_INTEGER:=2;
javavm  CONSTANT BINARY_INTEGER:=3;
xml     CONSTANT BINARY_INTEGER:=4;
rac     CONSTANT BINARY_INTEGER:=5;
owm     CONSTANT BINARY_INTEGER:=6;
mgw     CONSTANT BINARY_INTEGER:=7;
aps     CONSTANT BINARY_INTEGER:=8;
ols     CONSTANT BINARY_INTEGER:=9;
dv      CONSTANT BINARY_INTEGER:=10;
em      CONSTANT BINARY_INTEGER:=11;
context CONSTANT BINARY_INTEGER:=12;
xdb     CONSTANT BINARY_INTEGER:=13;
catjava CONSTANT BINARY_INTEGER:=14;
ordim   CONSTANT BINARY_INTEGER:=15;
sdo     CONSTANT BINARY_INTEGER:=16;
odm     CONSTANT BINARY_INTEGER:=17;
wk      CONSTANT BINARY_INTEGER:=18;
exf     CONSTANT BINARY_INTEGER:=19;
rul     CONSTANT BINARY_INTEGER:=20;
apex    CONSTANT BINARY_INTEGER:=21;
xoq     CONSTANT BINARY_INTEGER:=22;
misc    CONSTANT BINARY_INTEGER:=23;

max_comps      CONSTANT BINARY_INTEGER := 23;-- include components + 'misc'
                                             -- for space calculations
max_components CONSTANT BINARY_INTEGER := 22;

c_kb           CONSTANT BINARY_INTEGER := 1024;       -- 1 KB
c_mb           CONSTANT BINARY_INTEGER := 1048576;    -- 1 MB
c_gb           CONSTANT BINARY_INTEGER := 1073741824; -- 1 GB

-- minimum size constants for tablespace sizing, in units of Kbytes and Mbytes
-- c_sysaux_minsz_kb : (500*1024)Kb = 500Mb -- minimum size for sysaux
-- c_undo_minsz_kb : (400*1024)Kb = 400Mb   -- minimum size for undo
-- c_incby_minsz_mb : 50Mb                  -- minimum size to increase by
c_sysaux_minsz_kb CONSTANT BINARY_INTEGER := 500 * c_kb;  -- (500*1024)kb =500M
c_undo_minsz_kb   CONSTANT BINARY_INTEGER := 400 * c_kb;  -- (400*1024)kb =400M
c_incby_minsz_mb  CONSTANT BINARY_INTEGER :=  50;         --  50Mb

TYPE obsolete_record_t IS RECORD (
  name VARCHAR2(80),
  version  VARCHAR2(20),  -- version where is was obsolete/deprecated
  deprecated BOOLEAN,    -- Has become Depreciated
  db_match BOOLEAN
);

TYPE obsolete_table_t IS TABLE of obsolete_record_t
  INDEX BY BINARY_INTEGER;

op     obsolete_table_t;
max_op BINARY_INTEGER;

TYPE renamed_record_t IS RECORD (
  oldname VARCHAR2(80),
  newname VARCHAR2(80),
  db_match BOOLEAN
);

TYPE renamed_table_t IS TABLE of renamed_record_t
  INDEX BY BINARY_INTEGER;

rp      renamed_table_t;
max_rp  BINARY_INTEGER;

TYPE special_record_t IS RECORD (
  oldname      VARCHAR2(80),
  oldvalue     VARCHAR2(80),
  newname      VARCHAR2(80),
  newvalue     VARCHAR2(80),
  dbua_OutInUpdate BOOLEAN,
  db_match     BOOLEAN
);

TYPE special_table_t IS TABLE of special_record_t
  INDEX BY BINARY_INTEGER;

sp      special_table_t;
max_sp  BINARY_INTEGER;

TYPE required_record_t IS RECORD (
  name     VARCHAR2(80),
  newnumbervalue NUMBER,
  newstringvalue VARCHAR2(4000),
  type NUMBER,
  db_match BOOLEAN
);

TYPE required_table_t IS TABLE of required_record_t
  INDEX BY BINARY_INTEGER;

reqp      required_table_t;
max_reqp  BINARY_INTEGER;

TYPE tablespace_record_t IS RECORD (
  name    VARCHAR2(128), -- tablespace name
  inuse   NUMBER,        -- kbytes inuse in tablespace
  alloc   NUMBER,        -- kbytes allocated to tbs
  auto    NUMBER,        -- autoextend kbytes available
  avail   NUMBER,        -- total kbytes available
  delta   NUMBER,        -- kbytes required for upgrade
  inc_by  NUMBER,        -- kbytes to increase tablespace by
  min     NUMBER,        -- minimum required kbytes to perform upgrade
  addl    NUMBER,        -- additional space allocated during upgrade
  fname   VARCHAR2(513), -- filename in tablespace
  fauto   BOOLEAN,       -- TRUE if there is a file to increase autoextend
  temporary BOOLEAN,     -- TRUE if Temporary tablespace
  localmanaged BOOLEAN   -- TRUE if locally managed temporary tablespace
                         -- FALSE if dictionary managed temp tablespace
);

TYPE tablespace_table_t IS TABLE OF tablespace_record_t
   INDEX BY BINARY_INTEGER;

ts_info tablespace_table_t; -- Tablespace information
max_ts  BINARY_INTEGER; -- Total number of relevant tablespaces


TYPE rollback_record_t IS RECORD (
  tbs_name VARCHAR2(30), -- tablespace name
  seg_name VARCHAR2(30), -- segment name
  status   VARCHAR(30),  -- online or offline
  inuse    NUMBER, -- kbytes in use
  next     NUMBER, -- kbytes in NEXT
  max_ext  NUMBER, -- max extents
  auto     NUMBER  -- autoextend available for tablespace
);

TYPE rollback_table_t IS TABLE of rollback_record_t
  INDEX BY BINARY_INTEGER;

rs_info    rollback_table_t;  -- Rollback segment information
max_rs     BINARY_INTEGER; -- Total number of public rollback segs

TYPE fb_record_t IS RECORD (
  active         BOOLEAN,       -- ON or OFF
  file_dest      VARCHAR2(1000), -- db_recovery_file_dest
  dsize          NUMBER,        -- db_recovery_file_dest_size
  name           VARCHAR2(513), -- name
  limit          NUMBER,        -- space limit
  used           NUMBER,        -- Used
  reclaimable    NUMBER,
  files          NUMBER         -- number of files
);
flashback_info fb_record_t;

--
-- Have we initialized the package?
-- 
p_package_inited   BOOLEAN := FALSE;

--
-- Specifics about the DB being checked
--

db_name             VARCHAR2(256);
db_compat           VARCHAR2(30);
db_version          VARCHAR2(30);     -- Complete version
db_major_vers       VARCHAR2(12);    -- Major vers xx.n.n 
db_patch_vers       VARCHAR2(12);    -- include patch 
db_n_version        BINARY_INTEGER;  -- Numeric version of db_version
db_compat_majorver  NUMBER;

db_is_XE            BOOLEAN  := FALSE;
db_VLM_enabled      BOOLEAN  := FALSE;

db_64bit            BOOLEAN := FALSE;
db_platform         VARCHAR2(128);
db_platform_id      NUMBER;
db_block_size       NUMBER;
db_undo             VARCHAR(128);
db_undo_tbs         VARCHAR(128);
db_flashback_on     BOOLEAN := FALSE;
db_log_mode         VARCHAR2(30);
db_memory_target    BOOLEAN := FALSE;
db_inplace_upgrade  BOOLEAN := FALSE;
db_invalid_state    BOOLEAN := FALSE;  -- If the DB is not in OPEN state
db_readonly         BOOLEAN := FALSE;
db_tz_version       NUMBER := 0;

db_cpus             NUMBER;     -- Number of CPUs
db_cpu_threads      NUMBER;     -- Threads per CPU
--
-- A few stand-along values that we report
--
pMinFlashbackLogGen  NUMBER;
pminArchiveLogGen    NUMBER;

--
-- Setup in init_package depending on platform
--
crlf            VARCHAR(2);
--
-- Header, centered, with "*" in it, setup in 
-- init routine.
--
pStarHeader      VARCHAR2(80);  
pActionRequired  VARCHAR2(40) := '^^^ MANUAL ACTION REQUIRED ^^^';
pActionSuggested VARCHAR2(40) := '^^^ MANUAL ACTION SUGGESTED ^^^';
--
-- If we want a check routine to ONLY do a check and
-- not generate any script /log output
--
pCheckOnly          BOOLEAN;
--
-- Make this a package variable so some of the 
-- resources are disabled should the package be
-- run on an unsupported release
--
pUnsupportedUpgrade BOOLEAN;

--
-- If we are debugging the FAILURE sitiuations
--
pDBGFailCheck    BOOLEAN;  -- For specific defined _check procedures
pDBGFailAll      BOOLEAN;  -- For checks that are not 'formal checks'
pDBGAllResources BOOLEAN;  -- Dump out all the resources as failures
pDBGSizeResources  BOOLEAN;  -- For Tablespace resource info

pOutputType      NUMBER := c_output_text;
pOutputDest      NUMBER := c_output_terminal;

--
-- Used when outputting to file
--
pOutputUFT       UTL_FILE.FILE_TYPE;     -- UTL_FILE File Type
pOutputFName     VARCHAR2(512) := NULL;
pOutputLocation  VARCHAR2(512) := NULL;  -- directory object
pOutputVerified  BOOLEAN;

--
-- Used for outputting sql scripts
--
pPreScriptUFT     UTL_FILE.FILE_TYPE;
pPostScriptUFT    UTL_FILE.FILE_TYPE;
pPreScriptFname  VARCHAR2(512) := c_pre_script_fn;
pPostScriptFname VARCHAR2(512) := c_post_script_fn;

pOutputtingScripts BOOLEAN       := FALSE;

pCreatedDirObj   BOOLEAN       := TRUE;  -- Assume we will be creating/cleaning up

--
-- Declares of local functions/procedures
--
--
-- Init all the checks and package variables,
-- If not called before a 'check' routine, will be
-- called automaticlly. 
-- 
PROCEDURE init_package;
PROCEDURE init_preupchecks;
PROCEDURE init_preuprecommend;
PROCEDURE init_initparams;
PROCEDURE init_params;
PROCEDURE init_components;
PROCEDURE init_resources;

PROCEDURE define_check (
	idx IN OUT NUMBER,
        name VARCHAR2,
        check_level NUMBER,
        descript VARCHAR2);

FUNCTION getHelp (
        name     IN VARCHAR2,
        helpType IN  NUMBER) RETURN VARCHAR2;

--
-- Used to generate  a valid dbua tag for a pre-up check
-- 
FUNCTION genDBUAXMLCheck (name VARCHAR2, 
     eseverity  NUMBER,
     etext      VARCHAR2, 
     ecause     VARCHAR2, 
     action     VARCHAR2,
     detailtype VARCHAR2,
     detailinfo VARCHAR2, 
     fixuptype  VARCHAR2,
     fixupstage VARCHAR2 ) RETURN VARCHAR2;

PROCEDURE verifyDefaultDirObj;

PROCEDURE store_comp (i       BINARY_INTEGER,
                      schema  VARCHAR2,
                      version VARCHAR2,
                      status  NUMBER);
PROCEDURE store_minval_dbbit  (dbbit  NUMBER,
                               i      IN OUT BINARY_INTEGER,
                               name   VARCHAR2,
                               minv   NUMBER);
PROCEDURE store_minvalue (i     BINARY_INTEGER,
                          name  VARCHAR2,
                          minv  NUMBER,
                          minvp IN OUT MINVALUE_TABLE_T);
PROCEDURE store_oldval (minvp  IN OUT MINVALUE_TABLE_T);
PROCEDURE store_renamed (i   IN OUT BINARY_INTEGER,
                         old VARCHAR2,
                         new VARCHAR2);
PROCEDURE store_removed (i IN OUT BINARY_INTEGER,
                         name       VARCHAR2,
                         version    VARCHAR2,
                         deprecated BOOLEAN);
PROCEDURE store_special (i    IN OUT BINARY_INTEGER,
                         old  VARCHAR2,
                         oldv VARCHAR2,
                         new  VARCHAR2,
                         newv VARCHAR2);
PROCEDURE store_required (i    IN OUT BINARY_INTEGER,
                         name  VARCHAR2,
                         newvn NUMBER,
                         newvs VARCHAR2,
                         dtype NUMBER);
FUNCTION pvalue_to_number (value_string VARCHAR2) RETURN NUMBER;
FUNCTION is_comp_tablespace (tsname VARCHAR2) RETURN BOOLEAN;
FUNCTION ts_is_SYS_temporary (tsname VARCHAR2) RETURN BOOLEAN;
FUNCTION ts_has_queues (tsname VARCHAR2) RETURN BOOLEAN;
PROCEDURE find_newval (minvp  IN OUT MINVALUE_TABLE_T,
                       dbbit  NUMBER);
PROCEDURE find_sga_mem_values (minvp  IN OUT MINVALUE_TABLE_T,
                               dbbit  NUMBER);

FUNCTION CenterLine (line IN VARCHAR2) RETURN VARCHAR2;
FUNCTION htmlentities (intxt varchar2) RETURN VARCHAR2;


-- ****************************************************************
--         Start of Code 
-- ****************************************************************

--
-- Used to execute a sql statement (for a fixup)
-- Errors are returned in sqlerrtxt and sqlerrcode
--
FUNCTION execute_sql_statement (
           statement VARCHAR2,
           sqlerrtxt IN OUT VARCHAR2,
           sqlerrcode IN OUT NUMBER) RETURN NUMBER
IS
ret_val NUMBER := c_fixup_status_success;

BEGIN
  BEGIN
    EXECUTE IMMEDIATE statement;
    EXCEPTION WHEN OTHERS THEN 
       sqlerrtxt := SQLERRM;
       sqlerrcode := SQLCODE;
       ret_val := c_fixup_status_failure;
  END;
  RETURN (ret_val);
END execute_sql_statement;

FUNCTION get_version RETURN VARCHAR2
IS
BEGIN
  return(dbms_preup.c_version);
END get_version;

FUNCTION run_all_checks RETURN NUMBER
IS
  checks_run NUMBER := 0;
BEGIN
  init_package;

  FOR i IN 1..pCheckCount LOOP
    IF check_table(i).type = c_type_check OR 
       check_table(i).type = c_type_check_interactive_only THEN
      --
      -- Only non-recommended checks
      --
      check_table(i) := run_check (check_table(i).name);
      checks_run := checks_run + 1;

      IF (check_table(i).passed = FALSE) THEN
        IF (check_table(i).level = c_check_level_error) THEN
          pCheckErrorCount := pCheckErrorCount + 1;
        ELSIF (check_table(i).level = c_check_level_warning) THEN
          pCheckWarningCount := pCheckWarningCount + 1;
        ELSIF (check_table(i).level = c_check_level_info) THEN
          pCheckInfoCount := pCheckInfoCount + 1;
        -- There can be 'success' status, no count of those is needed.
        END IF;   
      END IF;
    END IF;
  END LOOP;
  return (checks_run);
END run_all_checks;

PROCEDURE run_all_recommend (whatType NUMBER)
IS
BEGIN
  init_package;

  FOR i IN 1..pCheckCount LOOP
    IF check_table(i).type = whatType THEN
      -- Only run the recommend checks
      check_table(i) := run_recommend (check_table(i).name);
    END IF;
  END LOOP;
END run_all_recommend;

FUNCTION run_recommend (check_name VARCHAR2) RETURN check_record_t
IS
  execute_failed BOOLEAN := FALSE;
  idx            NUMBER;
  retval         NUMBER;
  check_stmt     VARCHAR2(100);
  r_text         VARCHAR2(1000);

BEGIN
  init_package;

  IF check_names.EXISTS(check_name) = FALSE 
  THEN
    EXECUTE IMMEDIATE 'BEGIN 
      RAISE_APPLICATION_ERROR (-20000, 
            ''Pre-Upgrade Package Requested Check does not exist''); END;';
      return (NULL);
  END IF;
  idx := check_names(check_name).idx;

  IF check_table(idx).always_fail THEN
    --
    -- We want to fail this check, set the global
    -- so the package checks know to fail
    -- 
    pDBGFailCheck := TRUE;
  END IF;

  --
  -- This executes the check procedure 
  -- An example would be 
  --
  --  BEGIN dictionary_stats_recommend; END;
  --

  check_stmt := 'BEGIN dbms_preup.' 
     || dbms_assert.simple_sql_name(check_table(idx).f_name_prefix)
     ||  '_recommend; END;';

  BEGIN
    EXECUTE IMMEDIATE check_stmt;
    EXCEPTION WHEN OTHERS THEN
      execute_failed := TRUE;
  END;

  --
  -- Save away the results of the check
  --
  check_table(idx).executed := TRUE;

  if execute_failed = TRUE
  THEN
    check_table(idx).execute_failed := TRUE;
  ELSE
    check_table(idx).passed := TRUE;
  END IF;
  --
  -- Always turn this off
  --
  pDBGFailCheck := FALSE;
  return (check_table(idx));
END run_recommend;

-------------------------------  boolval  -------------------------------------
FUNCTION boolval (p boolean, 
                  trueval VARCHAR2, 
                  falseval VARCHAR2) return varchar2
IS
--
-- Return truval if the bool is TRUE otherwise return falseval
-- Usage: boolval(somebool, 'Yes', 'No')
--        boolval(somebool, 'On', 'Off')
--        boolval(somebool, 'True', 'False')
BEGIN
   if p = TRUE THEN
      return trueval;
   ELSE
      return falseval;
   END IF;
END boolval;

PROCEDURE dump_check_rec (p_check_rec check_record_t)
IS 
BEGIN
  DisplayLine ('-------- CHECK RECORD ------');
  DisplayLine ('Name:          ' || p_check_rec.name);
  DisplayLine ('Description:   ' || p_check_rec.descript);
  DisplayLine ('Name Prefix:   ' || p_check_rec.f_name_prefix);
  IF    (p_check_rec.type = c_type_check) THEN
    DisplayLine ('Type:          ' || 'Normal');
  ELSIF (p_check_rec.type = c_type_check_interactive_only) THEN
    DisplayLine ('Type:          ' || 'Manual Only');
  ELSIF (p_check_rec.type = c_type_recommend_pre) THEN
    DisplayLine ('Type:          ' || 'Pre Upgrade Recommend');
  ELSIF (p_check_rec.type = c_type_recommend_post) THEN
    DisplayLine ('Type:          ' || 'Post Upgrade Recommend');
  ELSE
    DisplayLine ('Type:          ' || 'UNKNOWN: ' || p_check_rec.type);
  END IF;
  DisplayLine ('Passed:        ' || boolval(p_check_rec.passed, 'Yes', 'No'));
  DisplayLine ('Skipped:       ' || boolval(p_check_rec.skipped, 'Yes', 'No'));
  DisplayLine ('Fix Type:      ' || p_check_rec.fix_type);
  DisplayLine ('Executed:      ' || boolval(p_check_rec.executed, 'Yes', 'No'));

  if p_check_rec.fixup_executed AND p_check_rec.fixup_failed THEN
    DisplayLine ('Execute Fail:  -- Fixup Attempted --');
  ELSE
    DisplayLine ('Execute Fail:  ' || boolval(p_check_rec.execute_failed, 'Yes', 'No'));
  END IF;
  DisplayLine ('Versions:      ' || p_check_rec.valid_versions);
  DisplayLine ('Fixup Executed:' || boolval(p_check_rec.fixup_executed, 'Yes', 'No'));
  DisplayLine ('Fixup Fail:    ' || boolval(p_check_rec.execute_failed, 'Yes', 'No'));
  DisplayLine ('Text:          ' || p_check_rec.result_text);
  DisplayLine ('SQLCODE:       ' || TO_CHAR(p_check_rec.sqlcode));
  DisplayLine ('----------------------------');

END dump_check_rec;

FUNCTION getHelp (
        name     IN VARCHAR2,
        helpType IN  NUMBER) RETURN VARCHAR2
IS
--
-- Use this to get back the help text (English only)
-- for a specific check.  The helpType is either
-- c_help_overview for an overview of what the check does or
-- c_help_fixup which describes what the fixup would do 
-- 
  idx         NUMBER;
  rhelp       VARCHAR2(2000);
  estatement  VARCHAR2(200);
BEGIN
  IF check_names.EXISTS(name) = FALSE THEN
    return 'WARNING - CHECK ' || name || ' does not exist';
  END IF;
  idx := check_names(name).idx;
  estatement := 'BEGIN :r1 := dbms_preup.' 
           || dbms_assert.simple_sql_name(check_table(idx).f_name_prefix)  
           || '_gethelp (:helpType); END;'; 
  EXECUTE IMMEDIATE estatement
    USING OUT rhelp, IN helpType;
  return rhelp;
END getHelp;

PROCEDURE define_check (
	idx IN OUT NUMBER,
        name VARCHAR2,
        check_level NUMBER,
        descript VARCHAR2)
IS
BEGIN
  --
  -- Setup the check_name array
  --
  check_names(name).idx           := idx;

  check_table(idx).name           := name;
  check_table(idx).descript       := descript;
  -- Default values
  check_table(idx).type           := c_type_check;
  check_table(idx).f_name_prefix  := name;
  check_table(idx).valid_versions := 'ALL';
  check_table(idx).level          := check_level;
  -- Assume all fixable on source side, auto
  check_table(idx).fix_type       := c_fix_source_auto;
  check_table(idx).passed         := FALSE;
  check_table(idx).skipped        := FALSE;
  check_table(idx).executed       := FALSE;
  check_table(idx).execute_failed := FALSE;
  check_table(idx).fixup_executed := FALSE;
  check_table(idx).fixup_failed   := FALSE;
  check_table(idx).always_fail    := FALSE;
  idx := idx + 1;
END define_check;
                        

-- *******************************************************************
--    Init package variables used throughout the package
-- *******************************************************************
PROCEDURE init_package 
IS
  tmp_bool        BOOLEAN;
  c_value         VARCHAR2(80);
  t_db_prev_vers  VARCHAR2(30);
  t_db_dict_vers  VARCHAR2(30);
  tmp_varchar1    VARCHAR2(512);
  tmp_varchar4    VARCHAR2(4000);   -- Max from any query we do
  p_count         INTEGER;

BEGIN

  IF p_package_inited THEN
    RETURN;
  END IF;

  pCheckOnly      := FALSE;
  pDBGFailCheck   := FALSE;
  pDBGFailAll     := FALSE;

  pDBGSizeResources := FALSE;
  pCheckErrorCount   := 0;
  pCheckWarningCount := 0;
  pCheckInfoCount    := 0;
  --
  -- Used all over the place for output
  --
  pStarHeader := CenterLine ('*****************************************');

  -- Check for SYSDBA
  SELECT USER INTO tmp_varchar1 FROM SYS.DUAL;
  IF tmp_varchar1 != 'SYS' THEN
    EXECUTE IMMEDIATE 'BEGIN 
       RAISE_APPLICATION_ERROR (-20000,
          ''These functions must be run AS SYSDBA''); END;';
  END IF;

  EXECUTE IMMEDIATE 'SELECT name    FROM v$database' INTO db_name;
  EXECUTE IMMEDIATE 'SELECT version FROM v$instance' INTO db_version;

  EXECUTE IMMEDIATE 'SELECT value   FROM v$parameter WHERE name = ''compatible'''
     INTO db_compat;

  EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE name = ''db_block_size'''
     INTO db_block_size;  
  EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE name = ''undo_management'''
       INTO db_undo;
  EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE name = ''undo_tablespace'''
       INTO db_undo_tbs;
  --
  -- Flashback on can have several 'on' states, but only one 'off' so check
  -- for NO.
  -- Put inside begin/end to catch execution on pre 10.x DB's where undo_tablespace
  -- is not defined yet.
  --
  p_count := 0;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT count(*) FROM v$database  WHERE flashback_on = ''NO'''
      INTO p_count;
    EXCEPTION WHEN OTHERS THEN NULL;
  END;

  IF p_count <= 0 THEN
    db_flashback_on := TRUE;
  END IF;

  EXECUTE IMMEDIATE 'SELECT LOG_MODE from v$database' 
     INTO db_log_mode;

  IF db_undo != 'AUTO' OR db_undo_tbs IS NULL THEN
    db_undo_tbs := 'NO UNDO TBS';  -- undo tbs is not in use
  END IF;

  EXECUTE IMMEDIATE 'SELECT platform_id, platform_name
           FROM v$database'
  INTO db_platform_id, db_platform;
  IF db_platform_id NOT IN (1,7,10,15,16,17) THEN
    db_64bit := TRUE; 
  END IF;

  db_major_vers := SUBSTR (db_version, 1,6); -- First three digits
  db_patch_vers := SUBSTR (db_version, 1,8); -- Include 4th digit

  db_compat_majorver := TO_NUMBER(SUBSTR(db_compat,1,2));

  IF db_major_vers = '10.2.0'    THEN 
    db_n_version := 102;
  ELSIF db_major_vers = '11.1.0' THEN
    db_n_version := 111;
  ELSIF db_major_vers = '11.2.0' THEN
    db_n_version := 112;
  ELSIF db_major_vers = '12.1.0' THEN
    db_n_version := 121;
  END IF;


  IF ( (instr (c_supported_versions, db_patch_vers) = 0) OR
         (db_major_vers = SUBSTR (c_version, 1,6))) THEN
    --
    -- Didn't find this DB's version in the supported list
    -- However, if the major version matches the c_version 
    -- for this script, this may be a re-run etc so let the tool run.
    -- Note using substr, instead of hard-coding '121' avoids 
    -- errors while versions are updated.
    --
    pUnsupportedUpgrade := TRUE;
  ELSE
    pUnsupportedUpgrade := FALSE;
  END IF;

  EXECUTE IMMEDIATE 'SELECT open_mode FROM sys.v$database' INTO tmp_varchar1;
  IF tmp_varchar1 = 'READ ONLY' THEN
    db_readonly := TRUE;
  END IF;

  EXECUTE IMMEDIATE 'SELECT value FROM sys.v$parameter WHERE name = ''cpu_count'''
        INTO tmp_varchar1;
  db_cpus := to_number (tmp_varchar1);

  EXECUTE IMMEDIATE 
     'SELECT value FROM v$parameter WHERE name = ''parallel_threads_per_cpu'''
  INTO tmp_varchar1;
  db_cpu_threads := pvalue_to_number(tmp_varchar1);

  BEGIN
    EXECUTE IMMEDIATE
       'SELECT edition FROM sys.registry$ WHERE cid=''CATPROC'''
       INTO tmp_varchar1;
      IF tmp_varchar1 = 'XE' THEN 
         db_is_XE := TRUE;
      END IF; -- XE edition
  EXCEPTION
      WHEN OTHERS THEN NULL;  -- no edition column
  END;      

  EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE name = ''use_indirect_data_buffers'''
       INTO tmp_varchar1;
  IF tmp_varchar1 = 'TRUE'
  THEN
    db_VLM_enabled := TRUE;
  END IF;

  --
  -- Make sure we are in OPEN state

  EXECUTE IMMEDIATE 'SELECT status FROM V$INSTANCE' 
  INTO tmp_varchar1;
  IF tmp_varchar1 NOT IN ('OPEN', 'OPEN MIGRATE') THEN
    db_invalid_state := TRUE;
  END IF;

  -- 
  -- Time zone data 
  --
  EXECUTE IMMEDIATE 'SELECT version from v$timezone_file'
    INTO db_tz_version;

  --
  -- Call procedure to fixup timezone info (if needed)
  --

  tz_fixup (FALSE);

  IF db_patch_vers = c_version THEN 
    --
    -- This block will reset db_major_vers to the value 
    -- in prv_version from registry$ - this allows the 
    -- comparision checks to behave correctly.
    --
    BEGIN 
      EXECUTE IMMEDIATE 'SELECT version, prv_version FROM sys.registry$ 
               WHERE cid = ''CATPROC'''
      INTO t_db_dict_vers, t_db_prev_vers;

      IF t_db_dict_vers = db_version THEN
        IF t_db_prev_vers != '' THEN
          --
          -- If prev vers is '', the DB 
          -- was never upgraded, so not really a re-run
          --
          db_major_vers := substr(t_db_prev_vers,1,6);   -- use prev catproc version 
        END IF;
      ELSE
        db_inplace_upgrade := TRUE;
        db_major_vers  := substr(t_db_dict_vers,1,6);   -- use CATPROC version 
        db_version := t_db_dict_vers;
      END IF;

    EXCEPTION
       WHEN NO_DATA_FOUND THEN NULL; -- registry$ exists, but no CATPROC entry  
    END;
  END IF;

  --
  -- Set the newline depending on platform
  --
  IF INSTR(db_platform, 'WINDOWS') != 0 THEN
    crlf := CHR(13) || CHR(10);       -- Windows gets the \r and \n
  ELSE
    crlf := CHR (10);                 -- Just \n for the rest of the world
  END IF;

  init_initparams;
  init_components;

  init_params;  -- Named params, not init params

  -- Process required data

  FOR i IN 1..max_reqp LOOP
    BEGIN
      EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE name = 
              :1 AND isdefault = ''TRUE'''
         INTO c_value
      USING reqp(i).name;
      IF reqp(i).name = 'undo_management' THEN
        --
        -- Starting in 11.1, undo_management default is changed
        -- from MANUAL to AUTO.
        --
        IF db_n_version = 102 THEN
          reqp(i).db_match := TRUE;
        END IF;
      END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN
       reqp(i).db_match := FALSE;
    END;
  END LOOP;

  -- Find values for initialization parameters with minimum values
  -- Convert to numeric values
  store_oldval(minvp_db32);
  store_oldval(minvp_db64);

  -- determine new values for initialization parameters with minimum values
  find_newval(minvp_db32, 32);
  find_newval(minvp_db64, 64);

  init_resources;

  init_preupchecks;

  init_preuprecommend;

  p_package_inited := TRUE;

END init_package;

PROCEDURE init_preupchecks 
IS
  i NUMBER := 1;

BEGIN
  -- ********************************************************
  -- Define the pre-up checks
  -- The order in which they are defined is the order in 
  -- which they will be executed.
  -- ********************************************************

  define_check (i, 'UNSUPPORTED_VERSION', c_check_level_error,
                'Make sure we support a direct upgrade from this version');
  check_table(check_names('UNSUPPORTED_VERSION').idx).fix_type := c_fix_source_manual;
  -- DBUA does their own.
  check_table(check_names('UNSUPPORTED_VERSION').idx).type    := c_type_check_interactive_only;

  define_check (i, 'DEFAULT_PROCESS_COUNT', c_check_level_warning, 
                'Verify min process count is not too low');
  check_table(i-1).fix_type := c_fix_source_manual;
  -- DBUA does their own.
  check_table(i-1).type    := c_type_check_interactive_only;

  define_check (i, 'COMPATIBLE_PARAMETER', c_check_level_error,
                'Verify compatible parameter value is valid');
  check_table(i-1).fix_type := c_fix_source_manual;
  check_table(i-1).type    := c_type_check_interactive_only;

  define_check (i, 'OLS_SYS_MOVE', c_check_level_error,
                'Check if SYSTEM.AUD$ needs to move to SYS.AUD$ before upgrade');
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'OCM_USER_PRESENT', c_check_level_warning,
                'Check for OCM schema');
  define_check (i, 'APPQOSSYS_USER_PRESENT', c_check_level_warning,
                'Check for APPQOSSYS schema');

  define_check (i, 'AUDSYS_USER_PRESENT', c_check_level_error,
                'Verify if a user or role with the name AUDSYS exists');
  check_table(i-1).valid_versions := '102,111,112';
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'AUDIT_ADMIN_ROLE_PRESENT', c_check_level_error,
                'Verify if a user or role with the name AUDIT_ADMIN exists');
  check_table(i-1).f_name_prefix := 'AAR_PRESENT';
  check_table(i-1).valid_versions := '102,111,112';
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'AUDIT_VIEWER', c_check_level_error,
                'Verify if a user or role with the name AUDIT_VIEWER exists');
  check_table(i-1).valid_versions := '102,111,112';
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'AWR_DBIDS_PRESENT', c_check_level_warning,
                'Verify if AWR contains inactive DBIDs');
  check_table(i-1).fix_type := c_fix_target_manual_post;

  define_check (i, 'DV_ENABLED', c_check_level_warning,
                'Check if Database Vault is enabled');
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'EM_PRESENT', c_check_level_warning,
                'Check if Enterprise Manager is present');

  define_check (i, 'FILES_NEED_RECOVERY', c_check_level_error,
                'Check for any pending file recoveries');
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'FILES_BACKUP_MODE', c_check_level_error,
                'Check for files in backup mode');
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, '2PC_TXN_EXIST', c_check_level_error,
                'Check for unresolved distributed transactions'); 
  check_table(i-1).fix_type := c_fix_source_manual;
  check_table(i-1).f_name_prefix := 'pending_2pc_txn';

  define_check (i, 'SYNC_STANDBY_DB', c_check_level_warning,
                'Check for unsynced database');
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'ULTRASEARCH_DATA', c_check_level_warning,
                'Check for any UltraSearch data');
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'REMOTE_REDO', c_check_level_error,
                'Check for invalid values for log_archive_dest_1');
  check_table(i-1).fix_type := c_fix_source_manual;
  check_table(i-1).valid_versions := '102, 111';

  define_check (i, 'SYS_DEFAULT_TABLESPACE', c_check_level_warning,
                'Check that SYS/SYSTEM default tablespace is SYSTEM');    
  check_table(i-1).f_name_prefix := 'SYS_DEF_TABLESPACE';

  define_check (i, 'INVALID_LOG_ARCHIVE_FORMAT', c_check_level_error,
                'Check log_archive_format settings');  
  check_table(i-1).fix_type := c_fix_source_manual;
  check_table(i-1).f_name_prefix := 'INVALID_LAF';

  define_check (i, 'INVALID_USR_TABLEDATA', c_check_level_error,
                'Check for invalid (not converted) user table data');
  check_table(check_names('INVALID_USR_TABLEDATA').idx).fix_type := 
        c_fix_source_manual;

  define_check (i, 'INVALID_SYS_TABLEDATA', c_check_level_error,
                'Check for invalid (not converted) table data');
  check_table(check_names('INVALID_SYS_TABLEDATA').idx).fix_type := 
        c_fix_source_manual;

  define_check (i, 'ENABLED_INDEXES_TBL', c_check_level_warning,
                'Check for existance of sys.enabled$indexes table');
  define_check (i, 'ORDIMAGEINDEX', c_check_level_warning,
                'Check for use of Oracle Multimedia image domain index');
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'DBMS_LDAP_DEPENDENCIES_EXIST', c_check_level_warning,
                'Check for dependency on DBMS_LDAP package');
  check_table(i-1).f_name_prefix := 'DBMS_LDAP_DEP_EXIST';
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'REMOVE_DMSYS', c_check_level_warning,
                'Check for existance of DMSYS schema');
  check_table(i-1).valid_versions := '102,111,112,121';

  define_check (i, 'INVALID_OBJECTS_EXIST', c_check_level_warning,
                'Check for invalid objects');
  check_table(i-1).f_name_prefix := 'INVALID_OBJ_EXIST';
  check_table(i-1).fix_type := c_fix_target_manual_post;

  define_check (i, 'AMD_EXISTS', c_check_level_info,
                'Check to see if AMD is present in the database');
  check_table(i-1).fix_type := c_fix_target_manual_pre; 
  -- DBUA does their own.
  check_table(i-1).type    := c_type_check_interactive_only;

  define_check (i, 'EXF_RUL_EXISTS', c_check_level_info,
                'Check to see if EXF/RUL are present in the database');
  check_table(i-1).fix_type := c_fix_target_manual_pre; 

  define_check (i, 'NEW_TIME_ZONES_EXIST', c_check_level_error,
                'Check for use of newer timezone data file');
  check_table(i-1).fix_type := c_fix_target_manual_pre;

  define_check (i, 'OLD_TIME_ZONES_EXIST', c_check_level_info,
                'Check for use of older timezone data file');
  check_table(i-1).fix_type := c_fix_target_manual_post; 

  define_check (i, 'PURGE_RECYCLEBIN', c_check_level_error,
                'Check that recycle bin is empty prior to upgrade');

  define_check (i, 'NACL_OBJECTS_EXIST', c_check_level_warning,
                'Check for Network ACL Objects in use');
  check_table(i-1).fix_type := c_fix_source_manual;

  define_check (i, 'JOB_QUEUE_PROCESS', c_check_level_warning,
                'Check JOB_QUEUE_PROCESSES value');
  -- This check may get changed to error in the _check routine
  check_table(i-1).fix_type := c_fix_source_manual;

  pCheckCount := i -1;

END init_preupchecks;


PROCEDURE init_preuprecommend
IS
  --
  -- Always start with the existing pCheckCount
  --
  i NUMBER := pCheckCount + 1;

BEGIN

  -- ********************************************************
  -- Define the pre-up recommendations
  -- ********************************************************
  define_check (i, 'DICTIONARY_STATS', c_check_level_recommend,
                'Gather Dictionary Stats prior to upgrade');
  check_table(i-1).type := c_type_recommend_pre;
  define_check (i, 'HIDDEN_PARAMS',  c_check_level_recommend,
                'Check for any hidden params defined');
  check_table(i-1).type := c_type_recommend_pre;
  define_check (i, 'UNDERSCORE_EVENTS',  c_check_level_recommend,
                'Check for any underscore events that are defined');
  check_table(i-1).type := c_type_recommend_pre;
  define_check (i, 'AUDIT_RECORDS',  c_check_level_recommend,
                'Recommend purging audit records');
  check_table(i-1).type := c_type_recommend_pre;
  define_check (i, 'FIXED_OBJECTS',  c_check_level_recommend,
                'Recommend running stats on fixed objects');
  check_table(i-1).type := c_type_recommend_post;
  pCheckCount := i -1;

END init_preuprecommend;


PROCEDURE init_initparams
IS
  t_null          CHAR(1);
  idx             BINARY_INTEGER;
BEGIN

  -- determine if memory_target value is set
  BEGIN
    EXECUTE IMMEDIATE 'SELECT NULL FROM v$parameter WHERE name=''memory_target'''
      INTO t_null;
       db_memory_target := TRUE;
  EXCEPTION               
     WHEN NO_DATA_FOUND THEN NULL;  -- memory_target value not set
   END;

  --
  -- Initialize parameters with minimum values
  --
  -- the loop sets values that differ for a 32-bit db versus a 64-bit db

  FOR i IN 1..2 LOOP

    idx := 0;

    -- 32-bit: up sga_target 336M to 528M. up memory_target 436M to 628M.
    -- 64-bit: up sga_target 672M to 744M. up memory_target 836M to 844M.

    IF i = 1 THEN  
      IF db_memory_target THEN
        store_minval_dbbit(32, idx,'memory_target', 628*c_mb); --  628 MB 
      END IF;
      mt_idx := idx;

      -- sga_target = cs + jv + sp + lp + strp + extra :
      -- (12*4 + 64 + 180 + (12*2*2)*.5 + 0 + 8+32+56) -- 412MB
      -- (32*4 + 64 + 180 + (32*2*2)*.5 + 0 + 8+32+56) -- 532MB
      -- (64*4 + 64 + 180 + (64*2*2)*.5 + 0 + 8+32+56) -- 724MB
      store_minval_dbbit(32, idx,'sga_target',
           (32*4 + 64 + 180 + (32*2*2)*.5 + 0 + 8+32+56) * (c_mb)); -- 532MB
      tg_idx := idx;

      store_minval_dbbit(32, idx,'shared_pool_size',236*c_mb); -- 236 MB
      sp_idx := idx;  

      store_minval_dbbit(32, idx,'java_pool_size',   64*c_mb); -- 64 MB
      jv_idx := idx;

    ELSE  -- Second case...
      --
      -- Now for 64 bit 

      IF db_memory_target THEN
        store_minval_dbbit(64,idx,'memory_target', 844*c_mb); --  844 MB 
      END IF;
      mt_idx := idx;

      -- sga_target = cs + jv + sp + lp + strp + extra :
      -- (12*4 + 100 + 280 + (12*2*2)*.5 + 0 + 8*2+32*2+28+20+16) -- 596M
      -- (32*4 + 100 + 280 + (32*2*2)*.5 + 0 + 8*2+32*2+28+20+16) -- 716M
      -- (64*4 + 100 + 280 + (64*2*2)*.5 + 0 + 8*2+32*2+28+20+16) -- 908M
      store_minval_dbbit(64, idx,'sga_target',
         (32*4 + 100 + 280 + 32*2 + 0 + 16+64+28+20+16) * c_mb); --716MB
      tg_idx := idx;

      store_minval_dbbit(64,idx,'shared_pool_size',472*c_mb); -- 472 MB
      sp_idx := idx;  

      store_minval_dbbit(64,idx,'java_pool_size',  128*c_mb); -- 128 MB
      jv_idx := idx;

      store_minval_dbbit(0,idx,'db_cache_size',    48*c_mb); --  48 MB
      cs_idx := idx;

      store_minval_dbbit(0,idx,'pga_aggregate_target', 24*c_mb); --  24 MB
      pg_idx := idx;

      -- Added large_pool_size and streams_pool_size so that we can include these
      -- user-specified values (if set) for sga_target minimum caculation.
      -- Note that we're not making minimum recommendations for these 2 pools at
      -- at this time.
    END IF;
  END LOOP;

  store_minval_dbbit(0,idx,'large_pool_size', 0);
  lp_idx := idx;
  store_minval_dbbit(0,idx,'streams_pool_size', 0);
  str_idx := idx;
  --
  -- For manual mode, there is a complete preup-check for 
  -- this.
  --
  store_minval_dbbit(0, idx,'processes', c_max_processes);
  max_minvp := idx;

END init_initparams;

PROCEDURE init_params
IS
  i        NUMBER;
  tmp_num2 NUMBER;
  tmp_num3 NUMBER;
  t_null   CHAR(1);
  c_value  VARCHAR2(80);
  idx      BINARY_INTEGER;

BEGIN

/*
   To identify new obsolete and deprecated parameters, use the 
   following queries and diff with the list from the prior release:

   select name from v$obsolete_parameter order by name;

   select name from v$parameter 
   where isdeprecated = 'TRUE' order by name; 
   
*/

  -- Load Obsolete and Deprecated parameters

  -- Obsolete initialization parameters in release 8.0 --
  idx:=0;
  store_removed(idx,'checkpoint_process', '8.0', FALSE);
  store_removed(idx,'fast_cache_flush', '8.0', FALSE);
  store_removed(idx,'gc_db_locks', '8.0', FALSE);
  store_removed(idx,'gc_freelist_groups', '8.0', FALSE);
  store_removed(idx,'gc_rollback_segments', '8.0', FALSE);
  store_removed(idx,'gc_save_rollback_locks', '8.0', FALSE);
  store_removed(idx,'gc_segments', '8.0', FALSE);
  store_removed(idx,'gc_tablespaces', '8.0', FALSE);
  store_removed(idx,'io_timeout', '8.0', FALSE);
  store_removed(idx,'init_sql_files', '8.0', FALSE);
  store_removed(idx,'ipq_address', '8.0', FALSE);
  store_removed(idx,'ipq_net', '8.0', FALSE);
  store_removed(idx,'lm_domains', '8.0', FALSE);
  store_removed(idx,'lm_non_fault_tolerant', '8.0', FALSE);
  store_removed(idx,'mls_label_format', '8.0', FALSE);
  store_removed(idx,'optimizer_parallel_pass', '8.0', FALSE);
  store_removed(idx,'parallel_default_max_scans', '8.0', FALSE);
  store_removed(idx,'parallel_default_scan_size', '8.0', FALSE);
  store_removed(idx,'post_wait_device', '8.0', FALSE);
  store_removed(idx,'sequence_cache_hash_buckets', '8.0', FALSE);
  store_removed(idx,'unlimited_rollback_segments', '8.0', FALSE);
  store_removed(idx,'use_readv', '8.0', FALSE);
  store_removed(idx,'use_sigio', '8.0', FALSE);
  store_removed(idx,'v733_plans_enabled', '8.0', FALSE);

  -- Obsolete in 8.1
  store_removed(idx,'allow_partial_sn_results', '8.1', FALSE);
  store_removed(idx,'arch_io_slaves', '8.1', FALSE);
  store_removed(idx,'b_tree_bitmap_plans', '8.1', FALSE);
  store_removed(idx,'backup_disk_io_slaves', '8.1', FALSE);
  store_removed(idx,'cache_size_threshold', '8.1', FALSE);
  store_removed(idx,'cleanup_rollback_entries', '8.1', FALSE);
  store_removed(idx,'close_cached_open_cursors', '8.1', FALSE);
  store_removed(idx,'complex_view_merging', '8.1', FALSE);
  store_removed(idx,'db_block_checkpoint_batch', '8.1', FALSE);
  store_removed(idx,'db_block_lru_extended_statistics', '8.1', FALSE);
  store_removed(idx,'db_block_lru_statistics', '8.1', FALSE);
  store_removed(idx,'db_file_simultaneous_writes', '8.1', FALSE);
  store_removed(idx,'delayed_logging_block_cleanouts', '8.1', FALSE);
  store_removed(idx,'discrete_transactions_enabled', '8.1', FALSE);
  store_removed(idx,'distributed_recovery_connection_hold_time', '8.1', FALSE);
  store_removed(idx,'ent_domain_name', '8.1', FALSE);
  store_removed(idx,'fast_full_scan_enabled', '8.1', FALSE);
  store_removed(idx,'freeze_DB_for_fast_instance_recovery', '8.1', FALSE);
  store_removed(idx,'gc_latches', '8.1', FALSE);
  store_removed(idx,'gc_lck_procs', '8.1', FALSE);
  store_removed(idx,'job_queue_keep_connections', '8.1', FALSE);
  store_removed(idx,'large_pool_min_alloc', '8.1', FALSE);
  store_removed(idx,'lgwr_io_slaves', '8.1', FALSE);
  store_removed(idx,'lm_locks', '8.1', FALSE);
  store_removed(idx,'lm_procs', '8.1', FALSE);
  store_removed(idx,'lm_ress', '8.1', FALSE);
  store_removed(idx,'lock_sga_areas', '8.1', FALSE);
  store_removed(idx,'log_archive_buffer_size', '8.1', FALSE);
  store_removed(idx,'log_archive_buffers', '8.1', FALSE);
  store_removed(idx,'log_block_checksum', '8.1', FALSE);
  store_removed(idx,'log_files', '8.1', FALSE);
  store_removed(idx,'log_simultaneous_copies', '8.1', FALSE);
  store_removed(idx,'log_small_entry_max_size', '8.1', FALSE);
  store_removed(idx,'mts_rate_log_size', '8.1', FALSE);
  store_removed(idx,'mts_rate_scale', '8.1', FALSE);
  store_removed(idx,'ogms_home', '8.1', FALSE);
  store_removed(idx,'ops_admin_group', '8.1', FALSE);
  store_removed(idx,'optimizer_search_limit', '8.1', FALSE);
  store_removed(idx,'parallel_default_max_instances', '8.1', FALSE);
  store_removed(idx,'parallel_min_message_pool', '8.1', FALSE);
  store_removed(idx,'parallel_server_idle_time', '8.1', FALSE);
  store_removed(idx,'parallel_transaction_resource_timeout', '8.1', FALSE);
  store_removed(idx,'push_join_predicate', '8.1', FALSE);
  store_removed(idx,'reduce_alarm', '8.1', FALSE);
  store_removed(idx,'row_cache_cursors', '8.1', FALSE);
  store_removed(idx,'sequence_cache_entries', '8.1', FALSE);
  store_removed(idx,'sequence_cache_hash_buckets', '8.1', FALSE);
  store_removed(idx,'shared_pool_reserved_min_alloc', '8.1', FALSE);
  store_removed(idx,'snapshot_refresh_interval', '8.1', FALSE);
  store_removed(idx,'snapshot_refresh_keep_connections', '8.1', FALSE);
  store_removed(idx,'snapshot_refresh_processes', '8.1', FALSE);
  store_removed(idx,'sort_direct_writes', '8.1', FALSE);
  store_removed(idx,'sort_read_fac', '8.1', FALSE);
  store_removed(idx,'sort_spacemap_size', '8.1', FALSE);
  store_removed(idx,'sort_write_buffer_size', '8.1', FALSE);
  store_removed(idx,'sort_write_buffers', '8.1', FALSE);
  store_removed(idx,'spin_count', '8.1', FALSE);
  store_removed(idx,'temporary_table_locks', '8.1', FALSE);
  store_removed(idx,'use_ism', '8.1', FALSE);

  -- Obsolete in 9.0.1
  store_removed(idx,'always_anti_join', '9.0.1', FALSE);
  store_removed(idx,'always_semi_join', '9.0.1', FALSE);
  store_removed(idx,'db_block_lru_latches', '9.0.1', FALSE);
  store_removed(idx,'db_block_max_dirty_target', '9.0.1', FALSE);
  store_removed(idx,'gc_defer_time', '9.0.1', FALSE);
  store_removed(idx,'gc_releasable_locks', '9.0.1', FALSE);
  store_removed(idx,'gc_rollback_locks', '9.0.1', FALSE);
  store_removed(idx,'hash_multiblock_io_count', '9.0.1', FALSE);
  store_removed(idx,'instance_nodeset', '9.0.1', FALSE);
  store_removed(idx,'job_queue_interval', '9.0.1', FALSE);
  store_removed(idx,'ops_interconnects', '9.0.1', FALSE);
  store_removed(idx,'optimizer_percent_parallel', '9.0.1', FALSE);
  store_removed(idx,'sort_multiblock_read_count', '9.0.1', FALSE);
  store_removed(idx,'text_enable', '9.0.1', FALSE);

  -- Obsolete in 9.2
  store_removed(idx,'distributed_transactions', '9.2', FALSE);
  store_removed(idx,'max_transaction_branches', '9.2', FALSE);
  store_removed(idx,'parallel_broadcast_enabled', '9.2', FALSE);
  store_removed(idx,'standby_preserves_names', '9.2', FALSE);

  -- Obsolete in 10.1 (mts_ renames commented out)
  store_removed(idx,'dblink_encrypt_login', '10.1', FALSE);
  store_removed(idx,'hash_join_enabled', '10.1', FALSE);
  store_removed(idx,'log_parallelism', '10.1', FALSE);
  store_removed(idx,'max_rollback_segments', '10.1', FALSE);
  store_removed(idx,'mts_listener_address', '10.1', FALSE);
  store_removed(idx,'mts_multiple_listeners', '10.1', FALSE);
  store_removed(idx,'mts_service', '10.1', FALSE);
  store_removed(idx,'optimizer_max_permutations', '10.1', FALSE);
  store_removed(idx,'oracle_trace_collection_name', '10.1', FALSE);
  store_removed(idx,'oracle_trace_collection_path', '10.1', FALSE);
  store_removed(idx,'oracle_trace_collection_size', '10.1', FALSE);
  store_removed(idx,'oracle_trace_enable', '10.1', FALSE);
  store_removed(idx,'oracle_trace_facility_name', '10.1', FALSE);
  store_removed(idx,'oracle_trace_facility_path', '10.1', FALSE);
  store_removed(idx,'partition_view_enabled', '10.1', FALSE);
  store_removed(idx,'plsql_native_c_compiler', '10.1', FALSE);
  store_removed(idx,'plsql_native_linker', '10.1', FALSE);
  store_removed(idx,'plsql_native_make_file_name', '10.1', FALSE);
  store_removed(idx,'plsql_native_make_utility', '10.1', FALSE);
  store_removed(idx,'row_locking', '10.1', FALSE);
  store_removed(idx,'serializable', '10.1', FALSE);
  store_removed(idx,'transaction_auditing', '10.1', FALSE);
  store_removed(idx,'undo_suppress_errors', '10.1', FALSE);

  -- Deprecated in 10.1, no new value
  store_removed(idx,'global_context_pool_size', '10.1', TRUE);
  store_removed(idx,'log_archive_start', '10.1', TRUE);
  store_removed(idx,'max_enabled_roles', '10.1', TRUE);
  store_removed(idx,'parallel_automatic_tuning', '10.1', TRUE);

  store_removed(idx,'_average_dirties_half_life', '10.1', TRUE);
  store_removed(idx,'_compatible_no_recovery', '10.1', TRUE);
  store_removed(idx,'_db_no_mount_lock', '10.1', TRUE);
  store_removed(idx,'_lm_direct_sends', '10.1', TRUE);
  store_removed(idx,'_lm_multiple_receivers', '10.1', TRUE);
  store_removed(idx,'_lm_statistics', '10.1', TRUE);
  store_removed(idx,'_oracle_trace_events', '10.1', TRUE);
  store_removed(idx,'_oracle_trace_facility_version', '10.1', TRUE);
  store_removed(idx,'_seq_process_cache_const', '10.1', TRUE);

  -- Obsolete in 10.2  
  store_removed(idx,'enqueue_resources', '10.2', FALSE);

  -- Deprecated, but not renamed in 10.2
  store_removed(idx,'logmnr_max_persistent_sessions', '10.2', TRUE);
  store_removed(idx,'max_commit_propagation_delay', '10.2', TRUE);
  store_removed(idx,'remote_archive_enable', '10.2', TRUE);
  store_removed(idx,'serial_reuse', '10.2', TRUE);
  store_removed(idx,'sql_trace', '10.2', TRUE);

  -- Deprecated, but not renamed in 11.1
  store_removed(idx,'commit_write', '11.1', TRUE);
  store_removed(idx,'cursor_space_for_time', '11.1', TRUE);
  store_removed(idx,'instance_groups', '11.1', TRUE);
  store_removed(idx,'log_archive_local_first', '11.1', TRUE);
  store_removed(idx,'remote_os_authent', '11.1', TRUE);
  store_removed(idx,'sql_version', '11.1', TRUE);
  store_removed(idx,'standby_archive_dest', '11.1', TRUE);
  store_removed(idx,'plsql_v2_compatibility', '11.1', TRUE);

  -- Instead a new parameter diagnostic_dest is
  -- replace two (core_dump_dest lives)
  store_removed(idx,'background_dump_dest', '11.1', TRUE);
  store_removed(idx,'user_dump_dest', '11.1', TRUE);

  -- Obsolete in 11.1  

  store_removed(idx,'_log_archive_buffer_size', '11.1', FALSE);
  store_removed(idx,'_fast_start_instance_recover_target', '11.1', FALSE);
  store_removed(idx,'_lm_rcv_buffer_size', '11.1', FALSE);
  store_removed(idx,'ddl_wait_for_locks', '11.1', FALSE);
  store_removed(idx,'remote_archive_enable', '11.1', FALSE);

  -- Deprecated in 11.2
  store_removed(idx,'active_instance_count', '11.2', TRUE);
  store_removed(idx,'cursor_space_for_time', '11.2', TRUE);
  store_removed(idx,'fast_start_io_target', '11.2', TRUE);
  store_removed(idx,'global_context_pool_size', '11.2', TRUE);
  store_removed(idx,'instance_groups', '11.2', TRUE);
  store_removed(idx,'lock_name_space', '11.2', TRUE);
  store_removed(idx,'log_archive_local_first', '11.2', TRUE);
  store_removed(idx,'max_commit_propagation_delay', '11.2', TRUE);
  store_removed(idx,'parallel_automatic_tuning', '11.2', TRUE);
  store_removed(idx,'parallel_io_cap_enabled', '11.2', TRUE);
  store_removed(idx,'resource_manager_cpu_allocation', '11.2', TRUE);
  store_removed(idx,'serial_reuse', '11.2', TRUE);

  -- Obsolete in 11.2
  store_removed(idx,'drs_start', '11.2', FALSE);
  store_removed(idx,'gc_files_to_locks', '11.2', FALSE);
  store_removed(idx,'plsql_native_library_dir', '11.2', FALSE);
  store_removed(idx,'plsql_native_library_subdir_count', '11.2', FALSE);
  store_removed(idx,'sql_version', '11.2', FALSE);
  store_removed(idx,'cell_partition_large_extents', '11.2', FALSE);
 
  -- Sessions removed for XE upgrade only
  IF db_is_XE THEN
    store_removed(idx,'sessions', '10.1', FALSE);   
  END IF;

  --
  -- Removed for 12.1
  --
  store_removed(idx,'_lm_validate_resource_type', '12.1', TRUE);
  store_removed(idx,'sec_case_sensitive_logon', '12.1', TRUE);
  max_op := idx; 

  -- Load Renamed parameters

  -- Initialization Parameters Renamed in Release 8.0 --
  idx:=0;
  store_renamed(idx,'async_read','disk_asynch_io');
  store_renamed(idx,'async_write','disk_asynch_io');
  store_renamed(idx,'ccf_io_size','db_file_direct_io_count');
  store_renamed(idx,'db_file_standby_name_convert','db_file_name_convert');
  store_renamed(idx,'db_writers','dbwr_io_slaves');
  store_renamed(idx,'log_file_standby_name_convert',
                    'log_file_name_convert');
  store_renamed(idx,'snapshot_refresh_interval','job_queue_interval');

  -- Initialization Parameters Renamed in Release 8.1.4 --
  store_renamed(idx,'mview_rewrite_enabled','query_rewrite_enabled');
  store_renamed(idx,'rewrite_integrity','query_rewrite_integrity');

  -- Initialization Parameters Renamed in Release 8.1.5 --
  store_renamed(idx,'nls_union_currency','nls_dual_currency');
  store_renamed(idx,'parallel_transaction_recovery',
                    'fast_start_parallel_rollback');

  -- Initialization Parameters Renamed in Release 9.0.1 --
  store_renamed(idx,'fast_start_io_target','fast_start_mttr_target');
  store_renamed(idx,'mts_circuits','circuits');
  store_renamed(idx,'mts_dispatchers','dispatchers');
  store_renamed(idx,'mts_max_dispatchers','max_dispatchers');
  store_renamed(idx,'mts_max_servers','max_shared_servers');
  store_renamed(idx,'mts_servers','shared_servers');
  store_renamed(idx,'mts_sessions','shared_server_sessions');
  store_renamed(idx,'parallel_server','cluster_database');
  store_renamed(idx,'parallel_server_instances',
                    'cluster_database_instances');

  -- Initialization Parameters Renamed in Release 9.2 --
  store_renamed(idx,'drs_start','dg_broker_start');

  -- Initialization Parameters Renamed in Release 10.1 --
  store_renamed(idx,'lock_name_space','db_unique_name');

  -- Initialization Parameters Renamed in Release 10.2 --
  -- none as of 4/1/05

  -- Initialization Parameters Renamed in Release 11.2 --

  store_renamed(idx,'buffer_pool_keep', 'db_keep_cache_size');
  store_renamed(idx,'buffer_pool_recycle', 'db_recycle_cache_size');
  store_renamed(idx,'commit_write', 'commit_logging,commit_wait');

  max_rp := idx; 

  -- Initialize special initialization parameters

  idx := 0;
  store_special(idx,'rdbms_server_dn',NULL,'ldap_directory_access','SSL');
  store_special(idx,'plsql_compiler_flags','INTERPRETED',
                    'plsql_code_type','INTERPRETED');
  store_special(idx,'plsql_compiler_flags','NATIVE',
                    'plsql_code_type','NATIVE');
  store_special(idx,'plsql_debug','TRUE',
                    'plsql_optimize_level','1');
  store_special(idx,'plsql_compiler_flags','DEBUG',
                    'plsql_optimize_level','1');

  --  Only use these special parameters for databases 
  --  in which Very Large Memory is not enabled

  IF db_VLM_enabled = FALSE THEN
    store_special(idx,'db_block_buffers',NULL,
                      'db_cache_size',NULL); 
    store_special(idx,'buffer_pool_recycle',NULL,
                      'db_recycle_cache_size',NULL); 
    store_special(idx,'buffer_pool_keep',NULL,
                      'db_keep_cache_size',NULL);  
  END IF;

  --
  -- for 12.1, AUDIT_TRAIL has depreicated several values
  -- that were allowed for AUDIT_TRAIL, they have new 
  -- mappings.
  -- Use store_special  - bug  2631483 and set the 
  -- dbua_outInUpdate flag so output_xml_initparams
  -- dumps these out
  --
  store_special(idx,'audit_trail','FALSE',
                    'audit_trail','NONE');
  sp(idx).dbua_OutInUpdate := TRUE; 
  store_special(idx,'audit_trail','TRUE',
                    'audit_trail','DB');
  sp(idx).dbua_OutInUpdate := TRUE; 
  store_special(idx,'audit_trail','DB_EXTENDED',
                    'audit_trail','DB,EXTENDED');
  sp(idx).dbua_OutInUpdate := TRUE; 

  max_sp := idx;

  --
  -- Min value for db_block_size
  --
  idx := 0;
  store_required (idx, 'db_block_size', 2048, '', 3);

  IF db_n_version = 102 THEN
    -- If undo_management is not specified in pre-11g database, then
    -- it needs to be specified MANUAL since the default is changing
    -- from MANUAL to AUTO starting in 11.1.
    store_required(idx, 'undo_management', 0, 'MANUAL', 2);
  END IF;
  max_reqp := idx;

  -- 
  -- Now run through them and figure out what is
  -- or isn't in use.
  --
  FOR i IN 1..max_rp LOOP
    BEGIN
      EXECUTE IMMEDIATE 'SELECT NULL FROM v$parameter WHERE name = 
            LOWER(:1) AND isdefault = ''FALSE'''
      INTO t_null
      USING rp(i).oldname;
      rp(i).db_match := TRUE;
    EXCEPTION WHEN NO_DATA_FOUND THEN
       rp(i).db_match := FALSE;
    END;
  END LOOP;
 
  FOR i IN 1..max_op LOOP
    BEGIN
      EXECUTE IMMEDIATE 'SELECT NULL FROM v$parameter WHERE name = 
         LOWER(:1) AND isdefault = ''FALSE'''
      INTO t_null
      USING op(i).name;
      op(i).db_match := TRUE;
    EXCEPTION WHEN NO_DATA_FOUND THEN
      op(i).db_match := FALSE;
    END;
  END LOOP;

  --
  -- The store_special procedure inits the db_match to 
  -- field to FALSE, so only when we match do we need to 
  -- do something.
  --
  FOR i IN 1..max_sp LOOP
    BEGIN
      EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE name = 
               LOWER(:1) AND isdefault = ''FALSE'''  
      INTO c_value
      USING sp(i).oldname;

      IF sp(i).oldvalue IS NULL OR c_value = sp(i).oldvalue THEN

        sp(i).db_match := TRUE;

        --
        -- No old value specified, or oldvalue is what we are 
        -- looking for
        --

        --           db_block_buffers 
        -- Example:  db_block_buffers = 7000

        IF sp(i).oldname = 'db_block_buffers' THEN
          sp(i).newvalue := TO_CHAR(TO_NUMBER(c_value) * db_block_size);

        ELSIF sp(i).oldname = 'buffer_pool_recycle' OR 
              sp(i).oldname = 'buffer_pool_keep' THEN

          --           buffer_pool_...
          -- Examples: buffer_pool_recycle= lru_latches:1, buffers:200
          --  buffer_pool_keep= (buffers:100,lru_latches:1)

          IF INSTR(UPPER(c_value),'BUFFERS:') > 0 THEN -- has keyword
            IF INSTR(SUBSTR(c_value,INSTR(UPPER(c_value),
                    'BUFFERS:')+8),',') > 0  THEN 
              -- has second keyword after BUFFERS
              sp(i).newvalue := TO_CHAR(TO_NUMBER(SUBSTR(c_value,
                     INSTR(UPPER(c_value),'BUFFERS:')+8,
                     INSTR(c_value,',')-INSTR(UPPER(c_value),'BUFFERS:')-8))
                     * db_block_size);
            ELSE -- no second keyword
              sp(i).newvalue := TO_CHAR(TO_NUMBER(SUBSTR(c_value,
                      INSTR(UPPER(c_value),'BUFFERS:')+8)) * db_block_size);
            END IF; -- second keyword
          ELSIF INSTR(UPPER(c_value),',') > 0 THEN   -- has keyword format #,#
            --
            -- In the #,# Format the first number before the comma is
            -- buffers second number is the lru latches. For the calculation
            -- we parse out the the buffer number and multiply
            -- by db_block_size.
            --
            tmp_num2       := INSTR(UPPER(c_value),',');
            sp(i).newvalue := TRIM(SUBSTR(c_value, 1, tmp_num2-1));
            sp(i).newvalue := TO_CHAR(TO_NUMBER(sp(i).newvalue)
                                        * db_block_size);
          ELSE -- no keywords, just number
            sp(i).newvalue := TO_CHAR(TO_NUMBER(c_value) * db_block_size);
          END IF; -- keywords

        END IF; -- params with calculated values

      ELSE
        --
        -- Oldvalue is not null or queried value isn't 
        -- the oldvalue in the sp data.
        --

        --      plsql_compiler_flags may contain two values
        --      in this case we process the list of values

        IF (sp(i).oldname = 'plsql_compiler_flags') AND
             (INSTR(c_value,sp(i).oldvalue) > 0) THEN
          -- If 'DEBUG' value found in list then make sure 
          -- it is not finding NON_DEBUG                
          -- (using premise that DEBUG and NON_DEBUG do not mix)
          IF (sp(i).oldvalue='DEBUG' AND 
               INSTR(c_value,'NON_DEBUG') = 0) OR 
               (sp(i).oldvalue != 'DEBUG') THEN
            sp(i).db_match := TRUE;
          END IF;
      END IF;
    END IF;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;
  END LOOP;

END init_params;

PROCEDURE init_components
IS
  reg_cursor cursor_t;
  c_null     CHAR(1);
  c_cid      VARCHAR2(128);
  c_version  VARCHAR2(128);
  c_schema   VARCHAR2(128);
  n_schema   NUMBER;
  n_status   NUMBER;

BEGIN
  -- Clear all variable component data
  FOR i IN 1..max_comps LOOP
    cmp_info(i).sys_kbytes:=     2*c_kb; 
    cmp_info(i).sysaux_kbytes:=  2*c_kb;
    cmp_info(i).def_ts_kbytes:=  0;
    cmp_info(i).ins_sys_kbytes:= 0;
    cmp_info(i).ins_def_kbytes:= 0;
    cmp_info(i).def_ts     := NULL;
    cmp_info(i).processed  := FALSE;
    cmp_info(i).install    := FALSE;
    cmp_info(i).archivelog_kbytes := 0;
    cmp_info(i).flashbacklog_kbytes := 0;
  END LOOP;

  -- Load component id and name
  cmp_info(catalog).cid := 'CATALOG';
  cmp_info(catalog).cname := 'Oracle Catalog Views';
  cmp_info(catproc).cid := 'CATPROC';
  cmp_info(catproc).cname := 'Oracle Packages and Types';
  cmp_info(javavm).cid := 'JAVAVM';
  cmp_info(javavm).cname := 'JServer JAVA Virtual Machine';
  cmp_info(xml).cid := 'XML';
  cmp_info(xml).cname := 'Oracle XDK for Java';
  cmp_info(catjava).cid := 'CATJAVA';
  cmp_info(catjava).cname := 'Oracle Java Packages';
  cmp_info(xdb).cid := 'XDB';
  cmp_info(xdb).cname := 'Oracle XML Database';
  cmp_info(rac).cid := 'RAC';
  cmp_info(rac).cname := 'Real Application Clusters';
  cmp_info(owm).cid := 'OWM';
  cmp_info(owm).cname := 'Oracle Workspace Manager';
  cmp_info(odm).cid := 'ODM';
  cmp_info(odm).cname := 'Data Mining';
  cmp_info(mgw).cid := 'MGW';
  cmp_info(mgw).cname := 'Messaging Gateway';
  cmp_info(aps).cid := 'APS';
  cmp_info(aps).cname := 'OLAP Analytic Workspace';
  cmp_info(xoq).cid := 'XOQ';
  cmp_info(xoq).cname := 'Oracle OLAP API';
  cmp_info(ordim).cid := 'ORDIM';
  cmp_info(ordim).cname := 'Oracle Multimedia';
  cmp_info(sdo).cid := 'SDO';
  cmp_info(sdo).cname := 'Oracle Spatial';
  cmp_info(context).cid := 'CONTEXT';
  cmp_info(context).cname := 'Oracle Text';
  cmp_info(wk).cid := 'WK';
  cmp_info(wk).cname := 'Oracle Ultra Search';
  cmp_info(ols).cid := 'OLS';
  cmp_info(ols).cname := 'Oracle Label Security';
  cmp_info(exf).cid := 'EXF';
  cmp_info(exf).cname := 'Expression Filter';
  cmp_info(em).cid := 'EM';
  cmp_info(em).cname := 'Oracle Enterprise Manager Repository';
  cmp_info(rul).cid := 'RUL';
  cmp_info(rul).cname := 'Rule Manager';
  cmp_info(apex).cid := 'APEX';
  cmp_info(apex).cname := 'Oracle Application Express';
  cmp_info(dv).cid := 'DV';
  cmp_info(dv).cname := 'Oracle Database Vault'; 
  cmp_info(misc).cid := 'STATS';
  cmp_info(misc).cname := 'Gather Statistics';
   
  -- Initialize comp script names

  IF db_n_version = 112 THEN
    -- 
    -- for 11.2, several components moved into
    -- catalog/catproc so they no longer have their own scripts
    --
    cmp_info(catalog).script := '?/rdbms/admin/catalog.sql';
    cmp_info(catproc).script := '?/rdbms/admin/catproc.sql';
    cmp_info(javavm).script  := '?/javavm/install/jvmpatch.sql'; 
    cmp_info(xml).script     := '?/xdk/admin/xmlpatch.sql';
    cmp_info(xdb).script     := '?/rdbms/admin/xdbpatch.sql';
    cmp_info(rac).script     := '?/rdbms/admin/catclust.sql';
    cmp_info(ols).script     := '?/rdbms/admin/olspatch.sql';
    cmp_info(exf).script     := '?/rdbms/admin/exfpatch.sql';
    cmp_info(rul).script     := '?/rdbms/admin/rulpatch.sql';
    cmp_info(owm).script     := '?/rdbms/admin/owmpatch.sql';
    cmp_info(ordim).script   := '?/ord/im/admin/impatch.sql';
    cmp_info(sdo).script     := '?/md/admin/sdopatch.sql';
    cmp_info(context).script := '?/ctx/admin/ctxpatch.sql';
    cmp_info(mgw).script     := '?/mgw/admin/mgwpatch.sql';
    cmp_info(aps).script     := '?/olap/admin/apspatch.sql';
    cmp_info(xoq).script     := '?/olap/admin/xoqpatch.sql';
    cmp_info(apex).script    := '?/apex/apxpatch.sql';
    cmp_info(dv).script      := '?/rdbms/admin/dvpatch.sql';
  ELSE
    cmp_info(catalog).script := '?/rdbms/admin/catalog.sql';
    cmp_info(catproc).script := '?/rdbms/admin/catproc.sql';
    cmp_info(javavm).script  := '?/javavm/install/jvmdbmig.sql'; 
    cmp_info(xml).script     := '?/xdk/admin/xmldbmig.sql';
    cmp_info(xdb).script     := '?/rdbms/admin/xdbdbmig.sql';
    cmp_info(rac).script     := '?/rdbms/admin/catclust.sql';
    cmp_info(ols).script     := '?/rdbms/admin/olsdbmig.sql';
    cmp_info(exf).script     := '?/rdbms/admin/exfdbmig.sql';
    cmp_info(rul).script     := '?/rdbms/admin/ruldbmig.sql';
    cmp_info(owm).script     := '?/rdbms/admin/owmdbmig.sql';
    cmp_info(odm).script     := '?/rdbms/admin/odmdbmig.sql';
    cmp_info(ordim).script   := '?/ord/im/admin/imdbmig.sql';
    cmp_info(sdo).script     := '?/md/admin/sdodbmig.sql';
    cmp_info(context).script := '?/ctx/admin/ctxdbmig.sql';
    cmp_info(wk).script      := '?/rdbms/admin/wkremov.sql';
    cmp_info(mgw).script     := '?/mgw/admin/mgwdbmig.sql';
    cmp_info(aps).script     := '?/olap/admin/apsdbmig.sql';
    cmp_info(xoq).script     := '?/olap/admin/xoqdbmig.sql';
    cmp_info(apex).script    := '?/apex/apxdbmig.sql';
    cmp_info(dv).script      := '?/rdbms/admin/dvdbmig.sql';
  END IF;

  -- *****************************************************************
  -- Store Release Dependent Data
  -- *****************************************************************

  -- kbytes for component installs (into SYSTEM and DEFAULT tablespaces)
  -- rae: add 10% for 11g .
  -- the '*1.2' below from point (a) to (b) are rae's .
  -- Point (a)
  cmp_info(javavm).ins_sys_kbytes:= 105972*1.2;  -- rae's
  cmp_info(xml).ins_sys_kbytes:=      4818*1.2;  -- rae's
  cmp_info(catjava).ins_sys_kbytes:=  5760*1.2;  -- rae's
  cmp_info(xdb).ins_sys_kbytes :=     10*c_kb * 1.2;
  IF db_block_size = 16384 THEN
    cmp_info(xdb).ins_def_kbytes:=   (88*2)*c_kb * 1.2;
  ELSE
    cmp_info(xdb).ins_def_kbytes:=   88*c_kb * 1.2;
  END IF;
  cmp_info(ordim).ins_sys_kbytes :=   10*c_kb * 1.2;  -- actually saw 1MB
  cmp_info(ordim).ins_def_kbytes :=   60*c_kb * 1.2;
  cmp_info(em).ins_sys_kbytes:= 0; -- was 22528*1.2 (rae's)
  cmp_info(em).ins_def_kbytes:= 0; -- was 51200*1.2 (rae's)
  -- Point (b)

  -- If there's XMLIndex on the XDB Repository during APEX upgrade
  -- from 11107 to 121 (apex v3 to v4), then 316M increase in xdb is seen.
  -- 316M = 85M (increase in lob segments + tables owned by xdb) +
  --        231M (increase in xmlindexes on xdb repository)
  -- (I.e., if no xmlindexes, then 85M of increase in XDB during APEX v3->v4
  -- upgrade.)

  IF db_n_version = 102 THEN
    -- mult by 1.1 for experimental noise
    cmp_info(catalog).sys_kbytes:=   67*c_kb * 1.1;
    cmp_info(catproc).sys_kbytes:=   (99+100)*c_kb * 1.1; -- catproc+catupend
    cmp_info(javavm).sys_kbytes:=   101*c_kb * 1.1;  
    cmp_info(xdb).sys_kbytes:=       12*c_kb * 1.1;  
    cmp_info(ordim).sys_kbytes:=     10*c_kb * 1.1;
    cmp_info(sdo).sys_kbytes:=       12*c_kb * 1.1;
    cmp_info(apex).sys_kbytes:=      81*c_kb * 1.1;

    cmp_info(catalog).sysaux_kbytes:=  14*c_kb * 1.1;
    cmp_info(catproc).sysaux_kbytes:=  31*c_kb * 1.1;  
    cmp_info(aps).sysaux_kbytes:=      36*c_kb * 1.1;

    cmp_info(context).def_ts_kbytes:=  2*c_kb; -- CTXSYS , default
    cmp_info(exf).def_ts_kbytes:=      2*c_kb; -- EXFSYS , default
    cmp_info(apex).def_ts_kbytes:=    320*c_kb * 1.1; -- FLOWS_
    cmp_info(ordim).def_ts_kbytes:=   15*c_kb * 1.1; -- ORDSYS
    cmp_info(sdo).def_ts_kbytes:=     38*c_kb * 1.1; -- MDSYS
    cmp_info(em).def_ts_kbytes:=                  0; -- SYSMAN
    cmp_info(catproc).def_ts_kbytes:= 31*c_kb * 1.1;
    cmp_info(owm).def_ts_kbytes:=      2*c_kb; -- WMSYS
    cmp_info(xdb).def_ts_kbytes:=     85*c_kb; -- XDB
    cmp_info(ols).def_ts_kbytes:=      2*c_kb; -- LBACSYS , default
    cmp_info(dv).def_ts_kbytes:=       2*c_kb; -- DVSYS , default
    cmp_info(aps).def_ts_kbytes :=    37*c_kb * 1.1;
    cmp_info(wk).def_ts_kbytes:=       0;      -- WK removed => 0 increase

  ELSIF db_n_version = 111 THEN 

    -- mult by 1.1 or 1.2 for experimental noise
    cmp_info(catalog).sys_kbytes:=  64*c_kb * 1.1;
    cmp_info(catproc).sys_kbytes:=  (59+123)*c_kb * 1.1; -- catproc+catupend 
    cmp_info(javavm).sys_kbytes:=   49*c_kb * 1.1;
    cmp_info(context).sys_kbytes:=   7*c_kb * 1.1;  
    cmp_info(xdb).sys_kbytes:=       2*c_kb * 1.1;  
    cmp_info(ordim).sys_kbytes:=    50*c_kb * 1.1;
    cmp_info(sdo).sys_kbytes:=      11*c_kb * 1.1;
    cmp_info(apex).sys_kbytes:=     50*c_kb * 1.1;
    cmp_info(em).sys_kbytes:=                   0;

    cmp_info(catalog).sysaux_kbytes:=   12*c_kb * 1.1;
    cmp_info(catproc).sysaux_kbytes:=   21*c_kb * 1.1;  
    cmp_info(aps).sysaux_kbytes:=       13*c_kb * 1.1;

    cmp_info(context).def_ts_kbytes:=  2*c_kb; -- CTXSYS , default
    cmp_info(exf).def_ts_kbytes:=      2*c_kb; -- EXFSYS , default
    cmp_info(apex).def_ts_kbytes :=  320*c_kb * 1.1; -- FLOWS_
    cmp_info(sdo).def_ts_kbytes:=     23*c_kb * 1.1; -- MDSYS
    cmp_info(ordim).def_ts_kbytes:=   15*c_kb * 1.1; -- ORDSYS
    cmp_info(em).def_ts_kbytes:=      0;       -- SYSMAN, removed, 0 increase
    cmp_info(catproc).def_ts_kbytes:= 21*c_kb * 1.1;
    cmp_info(owm).def_ts_kbytes:=      2*c_kb;       -- WMSYS, default
    cmp_info(xdb).def_ts_kbytes:=     85*c_kb; -- XDB
    cmp_info(ols).def_ts_kbytes:=      2*c_kb;       -- LBACSYS , default
    cmp_info(dv).def_ts_kbytes:=       2*c_kb;       -- DVSYS , default
    cmp_info(wk).def_ts_kbytes:=       0;        -- WK removed => 0 increase

  ELSIF db_n_version = 112 THEN

    -- mult by 1.1 or 1.2 for experimental noise
    cmp_info(catalog).sys_kbytes:=  58*c_kb * 1.1;
    cmp_info(catproc).sys_kbytes:=  (31+123)*c_kb * 1.1;  -- catproc+catupend
    cmp_info(javavm).sys_kbytes:=   10*c_kb * 1.1;
    cmp_info(context).sys_kbytes:=   4*c_kb * 1.1;  
    cmp_info(xdb).sys_kbytes:=       2*c_kb * 1.1;  
    cmp_info(sdo).sys_kbytes:=       2*c_kb * 1.1;
    cmp_info(apex).sys_kbytes:=     50*c_kb * 1.1;

    cmp_info(catalog).sysaux_kbytes:=   2*c_kb;  -- default
    cmp_info(catproc).sysaux_kbytes:=  27*c_kb * 1.1;

    -- apex: 269 is the amount of space needed (as seen from experiments) +
    --       50 is the padding because if apex is in its own tablespace
    --       then having a padding would be good
    cmp_info(apex).def_ts_kbytes :=  320*c_kb * 1.1; -- FLOWS_

    cmp_info(sdo).def_ts_kbytes:=     10*c_kb * 1.1; -- MDSYS
    cmp_info(ordim).def_ts_kbytes:=    2*c_kb;       -- ORDSYS , default
    cmp_info(em).def_ts_kbytes:=       0;      -- SYSMAN , 0 increase
    cmp_info(owm).def_ts_kbytes:=      2*c_kb; -- WMSYS , default
    cmp_info(xdb).def_ts_kbytes:=     85*c_kb; -- XDB , default
    cmp_info(aps).def_ts_kbytes :=     2*c_kb; -- default
    cmp_info(ols).def_ts_kbytes:=      2*c_kb; -- LBACSYS , default
    cmp_info(dv).def_ts_kbytes:=       2*c_kb; -- DVSYS , default
    cmp_info(wk).def_ts_kbytes:=       0;      -- WK removed => 0 increase

  ELSIF db_n_version = 121 THEN 
    -- initial estimates of growth in patch release
    -- let's use 112 values for now (copy and paste of 112 values from above)
    -- CML: need to update for 121 patch upgrades

    -- mult by 1.1 or 1.2 for experimental noise
    cmp_info(catalog).sys_kbytes:=  58*c_kb * 1.1;
    cmp_info(catproc).sys_kbytes:=  (31+123)*c_kb * 1.1;  -- catproc+catupend
    cmp_info(javavm).sys_kbytes:=   10*c_kb * 1.1;
    cmp_info(context).sys_kbytes:=   4*c_kb * 1.1;  
    cmp_info(xdb).sys_kbytes:=       2*c_kb * 1.1;  
    cmp_info(sdo).sys_kbytes:=       2*c_kb * 1.1;
    cmp_info(apex).sys_kbytes:=     50*c_kb * 1.1;

    cmp_info(catalog).sysaux_kbytes:=   2*c_kb;  -- default
    cmp_info(catproc).sysaux_kbytes:=  27*c_kb * 1.2;

    cmp_info(apex).def_ts_kbytes :=  320*c_kb * 1.1; -- FLOWS_
    cmp_info(sdo).def_ts_kbytes:=     10*c_kb * 1.1; -- MDSYS
    cmp_info(ordim).def_ts_kbytes:=    2*c_kb;       -- ORDSYS , default
    cmp_info(em).def_ts_kbytes:=       0;      -- SYSMAN , 0 increase
    cmp_info(owm).def_ts_kbytes:=      2*c_kb; -- WMSYS , default
    cmp_info(xdb).def_ts_kbytes:=     85*c_kb; -- XDB , default
    cmp_info(aps).def_ts_kbytes :=     2*c_kb; -- default
    cmp_info(ols).def_ts_kbytes:=      2*c_kb; -- LBACSYS , default
    cmp_info(dv).def_ts_kbytes:=       2*c_kb; -- DVSYS , default
    cmp_info(wk).def_ts_kbytes:=       0;      -- WK removed => 0 increase

  END IF;

  -- Flashback and archivelog for each database component

  cmp_info(catalog).archivelog_kbytes   := 580;
  cmp_info(catalog).flashbacklog_kbytes := 285;

  -- catproc = catproc + utlmmig + utlrp
  cmp_info(catproc).archivelog_kbytes   := 705+410+312;
  cmp_info(catproc).flashbacklog_kbytes := 155+0+210;

  cmp_info(javavm).archivelog_kbytes    := 455;
  cmp_info(javavm).flashbacklog_kbytes  := 160;

  cmp_info(xml).archivelog_kbytes       := 96;
  cmp_info(xml).flashbacklog_kbytes     := 55;

  cmp_info(aps).archivelog_kbytes       := 96;

  cmp_info(dv).archivelog_kbytes        := 47;

  cmp_info(context).archivelog_kbytes   := 92;

  cmp_info(xdb).archivelog_kbytes       := 174;
  cmp_info(xdb).flashbacklog_kbytes     := 55;

  cmp_info(catjava).archivelog_kbytes   := 50;

  cmp_info(owm).archivelog_kbytes       := 49;
  cmp_info(owm).flashbacklog_kbytes     := 60;

  cmp_info(ordim).archivelog_kbytes     := 354;

  cmp_info(sdo).archivelog_kbytes       := 487;
  cmp_info(sdo).flashbacklog_kbytes     := 115;

  cmp_info(apex).archivelog_kbytes      := 822;

  cmp_info(xoq).archivelog_kbytes       := 49;

  cmp_info(em).archivelog_kbytes       := 415;
  cmp_info(em).flashbacklog_kbytes     := 447;

  -- For tablespace sizing
  -- CML: TS: estimate for utlrp later?  utlrp space goes into system and
  --          system right now is not sized for utlrp.
  cmp_info(misc).sys_kbytes:=     100*c_kb;  -- misc: round up to 100M fudge
  cmp_info(misc).sysaux_kbytes:=   50*c_kb;  -- misc: round up to  50M fudge

  --
  -- Grab the Component ID (varchar2) from
  -- registry, and then see if the 
  -- schema exists in USER$ below which means its
  -- in use in this database.
  --
  OPEN reg_cursor FOR 
     'SELECT cid, status, version, schema# 
      FROM sys.registry$ WHERE namespace =''SERVER''';

  LOOP

    FETCH reg_cursor INTO c_cid, n_status, c_version, n_schema;
    EXIT WHEN reg_cursor%NOTFOUND;

    -- If the status is not  REMOVED or REMOVING
    IF n_status NOT IN (99,8) 
    THEN
      EXECUTE IMMEDIATE 'SELECT name FROM sys.user$  WHERE user#=:1'
      INTO c_schema
      USING n_schema;

      FOR i IN 1..max_components LOOP
        IF c_cid = cmp_info(i).cid 
        THEN
          store_comp(i, c_schema, c_version, n_status);
          EXIT; -- from component search loop
        END IF;
      END LOOP;  -- ignore if not in component list
    END IF;
  END LOOP;
  CLOSE reg_cursor;


  -- Ultra Search not in 10.1.0.2 registry so check schema
  IF NOT cmp_info(wk).processed THEN
    BEGIN
      EXECUTE IMMEDIATE 'SELECT NULL FROM sys.user$ WHERE name = ''WKSYS'''
      INTO c_null;
      store_comp(wk, 'WKSYS', db_version, NULL);
    EXCEPTION
         WHEN NO_DATA_FOUND THEN NULL;
    END;
  END IF;

  -- Check for HTML DB in 9.2.0 and 10.1 databases
  -- 121:  Is this needed
  BEGIN
    EXECUTE IMMEDIATE 'SELECT FLOWS_010500.wwv_flows_release from sys.dual'
    INTO c_version;
    store_comp(apex,'FLOWS_010500',c_version, NULL);
  EXCEPTION
       WHEN OTHERS THEN NULL;
  END;

  -- 121:  Is this needed
  BEGIN
    EXECUTE IMMEDIATE 'SELECT FLOWS_010600.wwv_flows_release from sys.dual'
    INTO c_version;
    store_comp(apex,'FLOWS_010600',c_version, NULL);
  EXCEPTION
     WHEN OTHERS THEN NULL;
  END;

  -- Check for APEX in 10.2 databases
  BEGIN
    EXECUTE IMMEDIATE 'SELECT FLOWS_020000.wwv_flows_release from sys.dual'
    INTO c_version;
    store_comp(apex,'FLOWS_020000',c_version, NULL);
  EXCEPTION
     WHEN OTHERS THEN NULL;
  END;

  BEGIN
    EXECUTE IMMEDIATE 'SELECT FLOWS_020100.wwv_flows_release from sys.dual'
    INTO c_version;
    store_comp(apex,'FLOWS_020100',c_version, NULL);
  EXCEPTION
     WHEN OTHERS THEN NULL;
  END; 

  -- Database Vault not in registry so check for dvsys schema
  IF NOT cmp_info(dv).processed THEN
    BEGIN
      EXECUTE IMMEDIATE 'SELECT NULL FROM sys.user$ WHERE name = ''DVSYS'''
      INTO  c_null;
      store_comp(dv, 'DVSYS', '10.2.0', NULL);           
    EXCEPTION
       WHEN NO_DATA_FOUND THEN NULL;
    END;
  END IF;

  -- CML: TS: estimate for utlrp later?
    -- Consider MISC (miscellaneous) in registry because
    -- cmp_info(misc).processed has to be equal to TRUE before the tablespace
    -- sizing algorithm will consider the space needed for MISC.
    -- this call will set 'cmp_info(misc).processed := TRUE;'
  store_comp(misc, 'SYS', NULL, NULL);      


  IF db_n_version != 112 THEN -- install required components on major release only
    -- if SDO, ORDIM, WK, EXF, or ODM components are present, need JAVAVM
    IF NOT cmp_info(javavm).processed THEN
      IF cmp_info(ordim).processed OR cmp_info(wk).processed OR 
           cmp_info(exf).processed OR cmp_info(sdo).processed 
      THEN
        store_comp(javavm, 'SYS', NULL, NULL);           
        cmp_info(javavm).install := TRUE;
        store_comp(catjava, 'SYS', NULL, NULL);           
        cmp_info(catjava).install := TRUE;
      END IF;
    END IF;
 
    -- If there is a JAVAVM component
    -- THEN include the CATJAVA component.
    IF cmp_info(javavm).processed AND NOT cmp_info(catjava).processed 
    THEN
      store_comp(catjava, 'SYS', NULL, NULL);           
      cmp_info(catjava).install := TRUE;
    END IF;

    -- If interMedia or Spatial component, but no XML, Then
    -- install XML
    IF NOT cmp_info(xml).processed AND
         (cmp_info(ordim).processed OR cmp_info(sdo).processed) 
    THEN
      store_comp(xml, 'SYS', NULL, NULL);           
      cmp_info(xml).install := TRUE;
    END IF;
   
    -- If no XDB, Then install XDB
    IF NOT cmp_info(xdb).processed THEN
      store_comp(xdb, 'XDB', NULL, NULL);           
      cmp_info(xdb).install := TRUE;
      cmp_info(xdb).def_ts := 'SYSAUX';
    END IF;
   
    -- If Spatial component, but no ORDIM, Then
    -- install ORDIM
    IF NOT cmp_info(ordim).processed AND
         (cmp_info(sdo).processed)
    THEN
      store_comp(ordim, 'ORDSYS', NULL, NULL);           
      cmp_info(ordim).install := TRUE;
      cmp_info(ordim).def_ts := 'SYSAUX';
    END IF;
 END IF;  -- not for patch release

END init_components;

PROCEDURE init_resources
IS
  idx           BINARY_INTEGER;
  tmp_cursor    cursor_t;
  tmp_num1      NUMBER;
  tmp_num2      NUMBER;
  delta_queues  INTEGER;
  delta_kbytes  NUMBER;
  p_tsname      VARCHAR2(128);
  tmp_varchar1  VARCHAR2(128);
  tmp_varchar2  VARCHAR2(128);
  p_status      VARCHAR2(30);
  sum_bytes     NUMBER;
  p_count       INTEGER;

BEGIN
  --
  -- Misc stand-along values we report about
  --
  pMinFlashbackLogGen  := 0;
  pminArchiveLogGen    := 0;

  idx := 0;
  OPEN tmp_cursor FOR 
      'SELECT tablespace_name, contents, extent_management FROM SYS.dba_tablespaces';
  LOOP
    FETCH tmp_cursor INTO p_tsname, tmp_varchar1, tmp_varchar2;
    EXIT WHEN tmp_cursor%NOTFOUND;
    IF p_tsname IN ('SYSTEM', 'SYSAUX', db_undo_tbs) OR 
        is_comp_tablespace(p_tsname) OR
        ts_has_queues (p_tsname) OR 
        ts_is_SYS_temporary (p_tsname) THEN

      idx := idx + 1;
      ts_info(idx).name  := p_tsname;
      IF tmp_varchar1 = 'TEMPORARY' THEN      
        ts_info(idx).temporary := TRUE;
      ELSE
        ts_info(idx).temporary := FALSE;
      END IF;

      IF tmp_varchar2 = 'LOCAL' THEN
        ts_info(idx).localmanaged := TRUE;
      ELSE
        ts_info(idx).localmanaged := FALSE;
      END IF;

      -- Get number of kbytes used
      EXECUTE IMMEDIATE 
        'SELECT SUM(bytes) FROM sys.dba_segments seg WHERE seg.tablespace_name = :1'
      INTO sum_bytes
      USING p_tsname;
      IF sum_bytes IS NULL THEN 
        ts_info(idx).inuse := 0;
      ELSIF sum_bytes <= c_kb THEN
        ts_info(idx).inuse := 1;
      ELSE
        ts_info(idx).inuse := ROUND(sum_bytes/c_kb);
      END IF;  
      -- TS: calculate space used per tablespace (ts_info(idx).name)

      -- Get number of kbytes allocated
      IF ts_info(idx).temporary AND
        ts_info(idx).localmanaged THEN
        EXECUTE IMMEDIATE 
          'SELECT SUM(bytes) FROM sys.dba_temp_files files WHERE ' ||
               'files.tablespace_name = :1'
        INTO sum_bytes
        USING p_tsname;
      ELSE
        EXECUTE IMMEDIATE 
           'SELECT SUM(bytes) FROM sys.dba_data_files files WHERE ' ||
                  'files.tablespace_name = :1'
        INTO sum_bytes
        USING p_tsname;
      END IF;
 
      IF sum_bytes IS NULL THEN 
        ts_info(idx).alloc:=0;
      ELSIF sum_bytes <= c_kb THEN
        ts_info(idx).alloc:=1;
      ELSE
        ts_info(idx).alloc:=ROUND(sum_bytes/c_kb);
      END IF;  
          
      -- Get number of kbytes of unused autoextend
      IF ts_info(idx).temporary AND 
        ts_info(idx).localmanaged THEN
        EXECUTE IMMEDIATE 
          'SELECT SUM(decode(maxbytes, 0, 0, maxbytes-bytes)) ' ||
          'FROM sys.dba_temp_files WHERE tablespace_name=:1'
        INTO sum_bytes
        USING p_tsname;
      ELSE
        EXECUTE IMMEDIATE 
          'SELECT SUM(decode(maxbytes, 0, 0, maxbytes-bytes)) ' ||
          'FROM sys.dba_data_files WHERE tablespace_name=:1'
        INTO sum_bytes
        USING p_tsname;
      END IF;

      IF sum_bytes IS NULL THEN 
        ts_info(idx).auto:=0;
      ELSIF sum_bytes <= c_kb THEN
        ts_info(idx).auto:=1;
      ELSE
        ts_info(idx).auto:=ROUND(sum_bytes/c_kb);
      END IF;  

      -- total available is allocated plus auto extend
      ts_info(idx).avail := ts_info(idx).alloc + ts_info(idx).auto;
    END IF;
  END LOOP;
  CLOSE tmp_cursor;

  max_ts := idx;   -- max tablespaces of interest

  -- *****************************************************************
  -- Collect Public Rollback Information
  -- *****************************************************************

  idx := 0;
  IF db_undo != 'AUTO' THEN  -- using rollback segments

    OPEN tmp_cursor FOR 
        'SELECT segment_name, next_extent, max_extents, status FROM SYS.dba_rollback_segs 
            WHERE owner=''PUBLIC'' OR (owner=''SYS'' AND segment_name != ''SYSTEM'')';
    LOOP
      FETCH tmp_cursor INTO tmp_varchar1, tmp_num1, tmp_num2, p_status;
      EXIT WHEN tmp_cursor%NOTFOUND;
      BEGIN
        --- get sum of bytes and tablespace name
        EXECUTE IMMEDIATE 
            'SELECT tablespace_name, sum(bytes) FROM sys.dba_segments 
                WHERE segment_name = :1  AND ROWNUM = 1 GROUP BY tablespace_name' 
        INTO p_tsname, sum_bytes
        USING tmp_varchar1;
        IF sum_bytes < c_kb THEN
          sum_bytes := 1;
        ELSE
          sum_bytes := sum_bytes/c_kb;
        END IF;
      EXCEPTION WHEN NO_DATA_FOUND THEN
        sum_bytes := NULL;
      END;

      IF sum_bytes IS NOT NULL THEN
        idx:=idx + 1;
        rs_info(idx).tbs_name := p_tsname;
        rs_info(idx).seg_name := tmp_varchar1;
        rs_info(idx).status   := p_status;
        rs_info(idx).next     := tmp_num1/c_kb;
        rs_info(idx).max_ext  := tmp_num2;
        rs_info(idx).inuse    := sum_bytes;
        EXECUTE IMMEDIATE 
          'SELECT ROUND(SUM(DECODE(maxbytes, 0, 0,maxbytes-bytes)/:1))
              FROM sys.dba_data_files WHERE tablespace_name=:2'
        INTO rs_info(idx).auto
        USING c_kb, p_tsname;

        EXECUTE IMMEDIATE 
          'SELECT ROUND(SUM(DECODE(maxbytes, 0, 0,maxbytes-bytes)/:1))
              FROM sys.dba_data_files WHERE tablespace_name=:2'
        INTO tmp_num1
        USING c_kb, p_tsname;
      END IF;
    END LOOP;
    CLOSE tmp_cursor;
  END IF;  -- using undo tablespace, not rollback

  max_rs := idx;

  -- *****************************************************************
  -- Determine free space needed if
  --   Archiving was on; 
  --   Flashback Database was on
  -- We only report the values if they are actually on.
  -- *****************************************************************

  -- calculate the minimum amount of archive and flashback logs used 
  -- for an upgrade for each component. 
  --
  -- This is only an issue when db_log_mode = 'ARCHIVELOG'
  --
  FOR i in 1..max_comps LOOP
    IF cmp_info(i).processed THEN
      pMinArchiveLogGen := pMinArchiveLogGen
                             + cmp_info(i).archivelog_kbytes;
      pMinFlashbacklogGen := pMinFlashbacklogGen
                             + cmp_info(i).flashbacklog_kbytes;
    END IF;
  END LOOP;

  -- The numbers used were seen from experiments.  Add 10% for experimental
  -- noise.
  pMinArchiveLogGen := pMinArchiveLogGen * 1.1;
  pMinFlashbacklogGen := pMinFlashbacklogGen * 1.1;

  -- Total recovery area needed is:
  --   pMinArchiveLogGen + pMinFlashbacklogGen;

  -- *****************************************************************
  -- Collect Flashback Information
  -- *****************************************************************

  flashback_info.active := FALSE;
  flashback_info.name := '';
  flashback_info.limit := 0;
  flashback_info.used := 0;
  flashback_info.reclaimable := 0;
  flashback_info.files := 0; 
  flashback_info.file_dest := '';
  flashback_info.dsize := 0;

  IF db_flashback_on THEN
    --
    -- Get the rest of the flashback settings
    -- 
    flashback_info.active := TRUE;

    BEGIN
      EXECUTE IMMEDIATE 'SELECT rfd.name, rfd.space_limit, rfd.space_used, 
                  rfd.space_reclaimable, rfd.number_of_files,
                  vp1.value, vp2.value 
        FROM v$recovery_file_dest rfd, v$parameter vp1, v$parameter vp2
        WHERE UPPER(vp1.name) = ''DB_RECOVERY_FILE_DEST'' AND
               UPPER(vp2.name) = ''DB_RECOVERY_FILE_DEST_SIZE'''
       INTO flashback_info.name, flashback_info.limit, flashback_info.used,
              flashback_info.reclaimable, flashback_info.files, 
              flashback_info.file_dest, flashback_info.dsize;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN flashback_info.active := FALSE;
    END;
  END IF;

  -- *****************************************************************
  -- Calculate Tablespace Requirements
  -- *****************************************************************

  -- Look at all relevant tablespaces
  -- TS: loop per tablespace (ts_info(t).name)
  FOR t IN 1..max_ts LOOP
    delta_kbytes:=0;   -- initialize calculated tablespace delta

    IF ts_info(t).name = 'SYSTEM' THEN -- sum the component SYS kbytes
      FOR i IN 1..max_comps LOOP

        IF pDBGSizeResources THEN
          IF cmp_info(i).processed THEN
            DisplayDiagLine (cmp_info(i).cid || ' Processed. ' || ' Default Tblspace ' || cmp_info(i).def_ts || '.');
          ELSE
            DisplayDiagLine (cmp_info(i).cid || ' NOT Processed.');
          END IF;
        END IF;

        IF cmp_info(i).processed THEN
          IF cmp_info(i).install THEN  -- if component will be installed
            delta_kbytes := delta_kbytes + cmp_info(i).ins_sys_kbytes;
            IF pDBGSizeResources THEN
              DisplayDiagLine ('SYSTEM ' || 
                  LPAD(cmp_info(i).cid, 10) || ' ToBeInstalled ' ||
                  LPAD(cmp_info(i).ins_sys_kbytes/c_kb,10) || 'Mb'); 
            END IF;
          ELSE  -- if component is already in the registry
            delta_kbytes := delta_kbytes + cmp_info(i).sys_kbytes;
            IF pDBGSizeResources THEN
              DisplayDiagLine ('SYSTEM ' || 
                     LPAD(cmp_info(i).cid, 10) || ' IsInRegistry ' ||
                     LPAD(cmp_info(i).sys_kbytes/c_kb,10) || 'Mb');
            END IF;
          END IF;
        END IF;  -- nothing to add if component is or will not be in
                 -- the registry
      END LOOP;
    END IF;  -- end of special SYSTEM tablespace processing
    -- TS: delta after looping through components in SYSTEM

    IF ts_info(t).name = 'SYSAUX' THEN -- sum the component SYSAUX kbytes
      FOR i IN 1..max_comps LOOP
        IF cmp_info(i).processed AND
              (cmp_info(i).def_ts = 'SYSAUX' OR
               cmp_info(i).def_ts = 'SYSTEM') THEN
          IF cmp_info(i).sysaux_kbytes >= cmp_info(i).def_ts_kbytes THEN
            delta_kbytes := delta_kbytes + cmp_info(i).sysaux_kbytes;
          ELSE
            delta_kbytes := delta_kbytes + cmp_info(i).def_ts_kbytes;
          END IF;
          IF pDBGSizeResources THEN
            DisplayDiagLine('SYSAUX ' || 
                   LPAD(cmp_info(i).cid, 10) || ' ' ||
                   LPAD(cmp_info(i).sysaux_kbytes/c_kb,10) || 'Mb');
          END IF;
          -- bug 13060071 :  apex , xdb
          -- if xdb and apex are both in db, then add 316M-85M (or 231M
          -- more) to sysaux if xdb resides here
          IF (cmp_info(i).cid = 'XDB'
              AND cmp_info(apex).processed = TRUE) THEN
            delta_kbytes :=  delta_kbytes + (231*c_kb);
            IF pDBGSizeResources THEN
              DisplayDiagLine('SYSAUX ' || 
                  LPAD(cmp_info(i).cid, 10) || ' ' || '(due to APEX) ' ||
                  LPAD(231, 10) || 'Mb');
            END IF;
          END IF;
        END IF;
      END LOOP;
    END IF;  -- end of special SYSAUX tablespace processing
    -- TS: sum delta for components in SYSAUX

    -- For tablespaces that are not SYSTEM:
    -- For tablespaces that are not SYSAUX:
    -- For tablespaces that are not UNDO:
    -- Now add in component default tablespace deltas
    -- def_tablespace_name is NULL for unprocessed comps

    IF (ts_info(t).name != 'SYSTEM' AND
        ts_info(t).name != 'SYSAUX' AND
        ts_info(t).name != db_undo_tbs) THEN
      FOR i IN 1..max_comps LOOP 
        IF (ts_info(t).name = cmp_info(i).def_ts AND
           cmp_info(i).processed) THEN
          IF cmp_info(i).install THEN  -- use install amount
            delta_kbytes := delta_kbytes + cmp_info(i).ins_def_kbytes;
            IF pDBGSizeResources THEN
              DisplayDiagLine( RPAD(ts_info(t).name, 10) ||
                           LPAD(cmp_info(i).cid, 10) || ' ' ||
                           LPAD(cmp_info(i).ins_def_kbytes,10));   
            END IF;

          ELSE  -- use default tablespace amount
            -- bug 9664514
            -- if apex version in the source db is older than the version
            -- in target db, then apex upgrade include apex install;
            -- estimate 180M for typical apex install.
            -- note: this section is for space calculations for
            -- tablespaces that are non-system and non-sysaux
            delta_kbytes :=  delta_kbytes + cmp_info(i).def_ts_kbytes;

            IF pDBGSizeResources THEN
              DisplayDiagLine(RPAD(ts_info(t).name, 10) ||
                      LPAD(cmp_info(i).cid, 10) || ' ' ||
                      LPAD(cmp_info(i).def_ts_kbytes/c_kb, 10) || 'Mb');
              --update_puiu_data('SCHEMA', 
              --   ts_info(t).name || '-' || cmp_info(i).schema,
              --   cmp_info(i).def_ts_kbytes);
            END IF;
          END IF;

          -- bug 13060071 :  apex , xdb
          -- if xdb and apex are both in db, then add 316M-85M (or 231M
          -- more) to xdb default tablespace
          IF (cmp_info(i).cid = 'XDB' AND
              cmp_info(apex).processed = TRUE) THEN
            delta_kbytes :=  delta_kbytes + (231*c_kb);
            IF pDBGSizeResources THEN
              DisplayDiagLine(RPAD(ts_info(t).name, 10) || ' ' ||
                        LPAD(cmp_info(i).cid, 10) || ' ' ||
                        '(due to APEX) ' || LPAD(231, 10) || 'Mb');
            END IF;
          END IF;
        END IF;
      END LOOP; -- end of default tablespace calculations 
    END IF; -- end of if tblspace is not undo and not sysaux and not system
            -- then add in component default tablespace deltas

    -- TS: sum delta for install in default tablespaces other than
    --          SYSAUX

    -- For tablespaces that are not undo:
    -- Now look for queues in user schemas
    IF ts_info(t).name != db_undo_tbs THEN
      EXECUTE IMMEDIATE 'SELECT count(*) FROM sys.dba_tables tb, sys.dba_queues q
          WHERE q.queue_table = tb.table_name AND
               tb.tablespace_name = '' || ts_info(t).name || '' AND tb.owner NOT IN
                (''SYS'',''SYSTEM'',''MDSYS'',''ORDSYS'',''OLAPSYS'',''XDB'',
                ''LBACSYS'',''CTXSYS'',''ODM'',''DMSYS'', ''WKSYS'',''WMSYS'',
                 ''SYSMAN'',''EXFSYS'') '
      INTO delta_queues;

      IF delta_queues > 0 THEN
        delta_kbytes := delta_kbytes + delta_queues*48; 
        IF pDBGSizeResources THEN
          DisplayDiagLine(RPAD(ts_info(t).name, 10) ||
                  ' QUEUE count = ' || delta_queues);
        END IF;
      END IF;
    END IF;  -- end of if tablespace is not undo
             -- then look for queues in user schemas

    -- See if this is the temporary tablespace for SYS
    IF ts_is_SYS_temporary(ts_info(t).name) THEN
      delta_kbytes := delta_kbytes + 50*c_kb;  -- Add 50M for TEMP
    END IF;

    -- See if this is the UNDO tablespace - be sure at least
    -- 400M (or c_undo_minsz_kb) is available
    IF ts_info(t).name = db_undo_tbs THEN
      ts_info(t).min := c_undo_minsz_kb;
      IF ts_info(t).alloc < ts_info(t).min THEN
        delta_kbytes := ts_info(t).min - ts_info(t).inuse;
      ELSE
        delta_kbytes := 0;
      END IF;
    END IF;  -- end of if this is the undo tablespace

    -- If DBUA output, then add in EM install if not in database
    IF pOutputType = c_output_xml THEN
      IF NOT cmp_info(em).processed THEN
        IF ts_info(t).name = 'SYSTEM' THEN 
          delta_kbytes := delta_kbytes + cmp_info(em).ins_sys_kbytes;
        ELSIF ts_info(t).name = 'SYSAUX' THEN
          delta_kbytes := delta_kbytes + cmp_info(em).ins_def_kbytes;
        END IF;
      END IF;
    END IF;

    -- Put a 20% safety factor on DELTA and round it off
    delta_kbytes := ROUND(delta_kbytes*1.20);            

    -- Finally, save DELTA value
    ts_info(t).delta := delta_kbytes;

    -- Calculate here the recommendation for minimum tablespace size - it is
    -- the "delta" plus existing in use amount IF tablespace is not undo.
    -- Else if tablespace is undo, then minimum was already set above
    -- to 400M (or c_undo_minsz_kb); therefore no need to calculate here.

    -- calculate ts_info(t).min
    IF ts_info(t).name != db_undo_tbs THEN
      -- calculate minimum tablespace size IF tablespace is NOT undo
      ts_info(t).min := ts_info(t).inuse + ts_info(t).delta;

      -- See if this is the SYSAUX tablespace - be sure at least 500M allocated
      IF ts_info(t).name = 'SYSAUX' THEN
        IF ts_info(t).min < c_sysaux_minsz_kb THEN
          ts_info(t).min := c_sysaux_minsz_kb;
        END IF;
      END IF;  -- end of checking that the minimum required space for SYSAUX
               -- is at least 500Mb (or c_sysaux_minsz_kb)

    END IF;  -- end of calculate ts_info(t).min 

    -- convert to MB and round up(min required)/down (alloc,avail,inuse)
    ts_info(t).min :=   CEIL(ts_info(t).min/c_kb);
    ts_info(t).alloc := ROUND((ts_info(t).alloc-512)/c_kb);
    ts_info(t).avail := ROUND((ts_info(t).avail-512)/c_kb);
    ts_info(t).inuse := ROUND((ts_info(t).inuse)/c_kb);

    -- Determine amount of additional space needed
    -- independent of autoextend on/off
    --

    IF ts_info(t).min > ts_info(t).alloc THEN
      ts_info(t).addl  := ts_info(t).min - ts_info(t).alloc;
    ELSE
      ts_info(t).addl := 0;
    END IF;

    -- Do we have enough space in the existing tablespace?
    IF ts_info(t).min < ts_info(t).avail  THEN
      ts_info(t).inc_by := 0;
    ELSE
       -- need to add space
       ts_info(t).inc_by := ts_info(t).min - ts_info(t).avail; 

       -- sorta silly to ask user to increase tablespace by, for example, 3M.
       -- so how about : if there are any increases of less than 50M, we'll
       -- just round up the increase to 50M (or c_incby_minsz_mb).
       IF ts_info(t).inc_by < c_incby_minsz_mb THEN
         -- round up 'min' size such that the inc_by size would equal to 50M
         ts_info(t).min := ts_info(t).min +
                             (c_incby_minsz_mb - ts_info(t).inc_by);
         -- round up the 'inc_by' size to 50M
         ts_info(t).inc_by := c_incby_minsz_mb;
       END IF;  -- if inc_by is < 50M
    END IF;

    -- Find at least one file in the tablespace with autoextend on.
    -- If found, then that tablespace has autoextend on; else not on.
    -- DBUA will use this information to add to autoextend
    -- or to check for total space on disk
    --
    IF ts_info(t).addl > 0 OR ts_info(t).inc_by > 0 THEN
      ts_info(t).fauto := FALSE;
      IF ts_info(t).temporary AND  ts_info(t).localmanaged THEN
        OPEN tmp_cursor FOR 
             'SELECT file_name, autoextensible from sys.dba_temp_files ' ||
             'where tablespace_name = :1' using ts_info(t).name;
      ELSE
        OPEN tmp_cursor FOR
             'SELECT file_name, autoextensible from sys.dba_data_files ' ||
             'where tablespace_name = :1' using ts_info(t).name;
      END IF;
      LOOP
        FETCH tmp_cursor INTO tmp_varchar1, tmp_varchar2;
        EXIT WHEN tmp_cursor%NOTFOUND;
        IF tmp_varchar2 = 'YES' THEN
          ts_info(t).fname := tmp_varchar1;
          ts_info(t).fauto := TRUE;
          EXIT;
        END IF;
      END LOOP;
      CLOSE tmp_cursor;
    END IF;
  END LOOP;  -- end of tablespace loop
END init_resources;

procedure time_zone_check
IS
  --
  -- This is decared as a public function for the package.
  --
  -- Allow dbms_preup.timezone_check to be called which 
  -- tells the real procedure to call the init routine.
  --
BEGIN
  tz_fixup(TRUE);
END time_zone_check;

procedure tz_fixup (call_init BOOLEAN)
IS
  --
  -- This is the timzeone procedure that does the work
  --
  tmp_bool BOOLEAN;
BEGIN
  -- If called with call_init = TRUE, call the init
  -- package, otherwise don't.  We need this because
  -- the init package will call this procedure
  -- and we'll end up in a loop.
  --
  IF call_init THEN
    init_package;
  ELSE
    -- Need db_tz_version below - fetch it the same way the init routine
    -- does.
    EXECUTE IMMEDIATE 'SELECT version from v$timezone_file'
      INTO db_tz_version;
  END IF;
  --
  -- Update registry$database with tz version (create it if necessary)
  --
  tmp_bool := FALSE;
  IF NOT db_readonly and NOT db_invalid_state THEN
    BEGIN
      EXECUTE IMMEDIATE 
          'UPDATE registry$database set tz_version = :1'
      USING db_tz_version;
      COMMIT;
    EXCEPTION WHEN OTHERS THEN 
      IF sqlcode = -904 THEN  -- registry$database exists but no tz_version
        tmp_bool := TRUE;
      END IF;
    END;

    IF tmp_bool = TRUE 
    THEN
      --
      -- registry$database does not have tz_version, 
      -- add it here.
      --
      EXECUTE IMMEDIATE
             'ALTER TABLE registry$database ADD (tz_version NUMBER)';
      EXECUTE IMMEDIATE
             'UPDATE registry$database set tz_version = :1'
      USING db_tz_version;
      COMMIT;
    END IF;

    -- populate sys.props$ with Day Light Saving Time (DST) props
    -- Only needed for releases before 11.2
    IF db_n_version IN (102, 111) THEN
      -- only if the database time zone file versions match.
      BEGIN
        -- remove all DST entries that we will then populate
        EXECUTE IMMEDIATE '
           DELETE sys.props$ WHERE name IN (''DST_UPGRADE_STATE'', 
                                          ''DST_PRIMARY_TT_VERSION'',
                                          ''DST_SECONDARY_TT_VERSION'')';
        EXECUTE IMMEDIATE 'INSERT INTO sys.props$ (name, value$, comment$)
             VALUES (''DST_UPGRADE_STATE'', ''NONE'', 
                   ''State of Day Light Saving Time Upgrade'')';
        EXECUTE IMMEDIATE 'INSERT INTO sys.props$ (name, value$, comment$)
             VALUES (''DST_PRIMARY_TT_VERSION'', TO_CHAR( :1, ''FM999''),
                   ''Version of primary timezone data file'')'
        USING db_tz_version;
        EXECUTE IMMEDIATE 'INSERT INTO sys.props$ (name, value$, comment$)
              VALUES (''DST_SECONDARY_TT_VERSION'', ''0'', 
                    ''Version of secondary timezone data file'')';
        COMMIT;
      END;
    END IF;
  END IF;  -- DB read only and db_invalid state
END tz_fixup;

--
-- Put a line out to the output file (or screen)
-- 
PROCEDURE DisplayLine (line VARCHAR2)
IS
BEGIN
  --
  -- If the package isn't inited yet (output from init routines)
  -- use dbms_output (output files would not be opened)
  --
  IF p_package_inited = FALSE OR pOutputDest = c_output_terminal THEN
    dbms_output.put_line (line);
  ELSE
    UTL_FILE.PUT_LINE (pOutputUFT,line);
  END IF;
END DisplayLine;

--
-- Put a line of text directly to a file
-- 
PROCEDURE DisplayLine (uft UTL_FILE.FILE_TYPE, line IN VARCHAR2)
IS
BEGIN
  BEGIN
    UTL_FILE.PUT_LINE (uft,line);
  EXCEPTION 
    WHEN OTHERS THEN NULL; -- utl_file.invalid_filehandle
  END;
END DisplayLine;

PROCEDURE DisplayDiagLine (line IN VARCHAR2)
IS
BEGIN
  IF pOutputType = c_output_xml THEN
    DisplayLine ('<!-- DBG: ' || line || ' -->');
  ELSE
    DisplayLine ('DBG: ' || line);
  END IF;
END DisplayDiagLine;

--
-- Put a line out using put_line (no matter what)
-- 
PROCEDURE DisplayLinePL (line VARCHAR2)
IS
BEGIN
  dbms_output.put_line (line);
END DisplayLinePL;

FUNCTION CenterLine (line IN VARCHAR2) RETURN VARCHAR2
IS
BEGIN
  RETURN (LPAD(line,35+(length(line)/2)+1));
END CenterLine;

--
-- Put a line of text to output AND to passed file but 
-- its wrapped around dbms_output.put_line (so text only)
-- intended to be dumped out while the pre/post fixup scripts
-- are being run.
-- 
PROCEDURE DisplayLineBoth (uft UTL_FILE.FILE_TYPE, line IN VARCHAR2)
IS
BEGIN
  DisplayLine(line);
  IF pOutputtingScripts THEN
    DisplayLine (uft, 'dbms_output.put_line (''' || line || ''');');
  END IF;
END DisplayLineBoth;


PROCEDURE DisplayBanner
IS
BEGIN
  DisplayLine('**********************************************************************');
END DisplayBanner;

--
-- Overloaded version go to script file if we are creating one.
--
PROCEDURE DisplayBanner (uft UTL_FILE.FILE_TYPE)
IS 
BEGIN
  DisplayLine('**********************************************************************');
  IF pOutputtingScripts THEN
    DisplayLine (uft, 'dbms_output.put_line (''' 
      || '**********************************************************************'
      || ''');');
  END IF;
END DisplayBanner;

--
-- Put the passed line out, centering it in a field of 70 char (the length of the banner)
--
PROCEDURE DisplayCenter (line IN VARCHAR2)
IS
BEGIN
  DisplayLine(LPAD(line,35+(length(line)/2)+1));
END DisplayCenter;

--
-- Overloaded, including dumping to script file (only TEXT to be 
-- displayed when the script file is executed)
--
PROCEDURE DisplayCenter (uft UTL_FILE.FILE_TYPE, line IN VARCHAR2)
IS
BEGIN
  DisplayLine(LPAD(line,35+(length(line)/2)+1));
  IF pOutputtingScripts THEN
    DisplayLine (uft, 'dbms_output.put_line (''' 
      || LPAD(line,35+(length(line)/2)+1)
      || ''');');
  END IF;
END DisplayCenter;

--
-- Same as above, only use dbms_output.put_line only
-- Intended to be used by fixup routine to better control
-- format.
--
PROCEDURE DisplayCenterPL (line IN VARCHAR2)
IS
BEGIN
  dbms_output.put_line(LPAD(line,35+(length(line)/2)+1));
END DisplayCenterPL;

PROCEDURE DisplayWarning (text varchar2)
IS
BEGIN
  DisplayLine ('WARNING: --> ' || text);
END DisplayWarning;

PROCEDURE DisplayError (text varchar2)
IS
BEGIN
  pCheckErrorCount := pCheckErrorCount + 1;   
  DisplayLine ('ERROR: --> ' || text);
END DisplayError;

--
--  Define what the output from this is going to be
--  Text/XML are the only valid options.
--  Defaulting to text
-- If XML, call the procedure to output the header
-- .
PROCEDURE set_output_type (p_type VARCHAR2)
IS
BEGIN
  IF p_type = 'XML' THEN
    pOutputType := c_output_xml;
  ELSE
    -- Default to text
    pOutputType := c_output_text;
  END IF;
END set_output_type;

PROCEDURE set_output_file (p_on_off BOOLEAN) 
IS
BEGIN
  IF p_on_off THEN
    IF pOutputDest = c_output_file THEN
      -- Already done.
      RETURN;
    END IF;
    set_output_file (c_output_fn);
  ELSE
    close_file;
  END IF;  -- on/off
END set_output_file;

--
-- Overloaded version of set_output_file to include
-- location.
-- Note that p_location is assumed to be verified
-- by the caller.
-- 
PROCEDURE set_output_file (p_location VARCHAR2, p_fn VARCHAR2) 
IS
BEGIN
  -- Set local dirobject name then call set output
  pOutputLocation := p_location;
  pOutputVerified := TRUE;
  set_output_file(p_fn);
END set_output_file;

PROCEDURE set_output_file (p_fn VARCHAR2)
IS
  openFailure BOOLEAN;
BEGIN
  pOutputFName := p_fn;

  IF (pOutputLocation IS NULL ) THEN
    verifyDefaultDirObj;
  END IF;
  openFailure := FALSE;
  IF pOutputVerified THEN
    BEGIN
      pOutputUFT := UTL_FILE.FOPEN(pOutputLocation, pOutputFName, 'W', 15000);
      EXCEPTION WHEN OTHERS THEN openFailure := TRUE;
    END;
    IF openFailure THEN
      DisplayLine ('WARNING: Failed to open ' || pOutputFName || ' for write access');
      DisplayLine('    script will generate terminal output only');
      pOutputVerified := FALSE;
      pOutputLocation := NULL;
      pOutputDest       := c_output_terminal;
    ELSE
      pOutputDest := c_output_file;
    END IF;
  ELSE
    --
    -- Failed to verify the outputdir, default to 
    -- terminal (verify routine will issue error)
    --
    pOutputDest := c_output_terminal;
  END IF;
END set_output_file;

PROCEDURE close_file 
IS
BEGIN
  IF pOutputDest = c_output_file THEN
    UTL_FILE.FCLOSE(pOutputUFT);
    pOutputDest := c_output_terminal;

    IF pOutputtingScripts = FALSE AND pCreatedDirObj THEN 
      --
      -- Cleanup the directory if we created it, however the
      -- DBUA process deals with this so just ignore any 
      -- drop error.
      --
      BEGIN
        EXECUTE IMMEDIATE 'DROP DIRECTORY :1' USING pOutputLocation;
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
    END IF;
    -- We no longer have a pOutputFName and reset pOutputLocation
    pOutputFName := NULL;
    pOutputLocation := NULL;
  END IF;
END close_file;

--
-- For manual mode, we need to output the path were the logs/scripts
-- If we are not outputting files, return ''
--
FUNCTION get_output_path RETURN VARCHAR2 
IS
  path    VARCHAR2(4000);
BEGIN
  IF pOutputtingScripts = FALSE THEN
    RETURN '*** Scripts/Logs are not being Generated ***';
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 'SELECT directory_path from DBA_DIRECTORIES where directory_name=:1'
    INTO path
    USING c_dir_obj;
    EXCEPTION WHEN NO_DATA_FOUND THEN path := '*** PATH NOT DEFINED ***';
  END;
  RETURN path;
END get_output_path;

PROCEDURE set_scripts (p_on_off BOOLEAN) 
IS
  openFailure BOOLEAN;
  timeinfo    VARCHAR2(60);
  genline     VARCHAR2(200);
BEGIN
  IF p_on_off THEN
    IF pOutputtingScripts THEN
      -- Already done.
      RETURN;
    END IF;
    --
    -- Make sure a directory object exists
    --
    verifyDefaultDirObj;

    IF pOutputVerified = FALSE THEN
      --
      -- We couldn't verify the directory object
      -- 
      pOutputtingScripts := FALSE;
      RETURN;
    END IF;

    --
    -- Open both files and put some info out.
    -- Also dump out a begin/end output line - if there 
    -- is no errors, these lines will stop the script from 
    -- generating an error because the begin/end block would be
    -- empty.
    --
    openFailure := FALSE;
    BEGIN
      pPreScriptUFT  := UTL_FILE.FOPEN(pOutputLocation, pPreScriptFname, 'W', 15000);  
      EXCEPTION WHEN OTHERS THEN openFailure := TRUE;
    END;
    IF openFailure THEN
      DisplayLine ('WARNING: Failed to open ' || pPreScriptFname || ' for write access');
    ELSE
      BEGIN
        pPostScriptUFT := UTL_FILE.FOPEN(pOutputLocation, pPostScriptFname, 'W', 15000);
        EXCEPTION WHEN OTHERS THEN openFailure := TRUE;
      END;
      IF openFailure THEN
        DisplayLine ('WARNING: Failed to open ' || pPostScriptFname || ' for write access');
      END IF;
    END IF;

    IF openFailure THEN
      DisplayLine('     script will not generate fixup scripts.');
      pOutputVerified := FALSE;
      pOutputLocation := NULL;
      pOutputtingScripts := FALSE;
      RETURN;
    END IF;

    EXECUTE IMMEDIATE 'SELECT TO_CHAR(SYSTIMESTAMP,''YYYY-MM-DD HH24:MI:SS '') FROM SYS.DUAL'
    INTO timeinfo;

    --
    -- The linesize at 750 allows the buffering of some of the help text
    -- which can get long.  No data will be lost, the line will just be 
    -- unnaturally wrapped.
    --
    DisplayLine (pPreScriptUFT, 'REM Pre-Upgrade Script Generated on: ' || timeinfo);
    DisplayLine (pPreScriptUFT, 'REM Generated by Version: ' || c_version || ' Build: ' 
                                        || c_build);
    DisplayLine (pPreScriptUFT, 'SET ECHO OFF SERVEROUTPUT ON FORMAT WRAPPED TAB OFF LINESIZE 750;' || crlf);
    -- In its own begin/end so the output gets out before 
    -- the real work gets started.
    genline := 'Pre-Upgrade Fixup Script Generated on ' || timeinfo || ' Version: ' || c_version 
 	|| ' Build: ' || c_build;
    DisplayLine (pPreScriptUFT, 'BEGIN');
    DisplayLine (pPreScriptUFT, '  dbms_output.put_line (''' || genline || ''');');
    DisplayLine (pPreScriptUFT, '  dbms_output.put_line (''Beginning Pre-Upgrade Fixups...'');');
    DisplayLine (pPreScriptUFT, 'END;');
    DisplayLine (pPreScriptUFT, '/');
    DisplayLine (pPreScriptUFT, 'BEGIN');
    DisplayLine (pPreScriptUFT, 'dbms_preup.clear_run_flag(TRUE);'); 
    DisplayLine (pPreScriptUFT, 'END;');
    DisplayLine (pPreScriptUFT, '/');
   --
    -- Now post...
    --
    DisplayLine (pPostScriptUFT, 'REM Post Upgrade Script Generated on: ' || timeinfo);
    DisplayLine (pPostScriptUFT, 'REM Generated by Version: ' || c_version || ' Build: '
                                        || c_build);
    DisplayLine (pPostScriptUFT, 'SET ECHO OFF SERVEROUTPUT ON FORMAT WRAPPED TAB OFF LINESIZE 750;' || crlf);

    genline := 'Post Upgrade Fixup Script Generated on ' || timeinfo || ' Version: ' || c_version 
 	|| ' Build: ' || c_build;
    -- In its own begin/end so the output gets out before 
    -- the real work gets started.
    DisplayLine (pPostScriptUFT, 'BEGIN');
    DisplayLine (pPostScriptUFT, '  dbms_output.put_line (''' || genline || ''');');
    DisplayLine (pPostScriptUFT, '  dbms_output.put_line (''Beginning Post-Upgrade Fixups...'');');
    DisplayLine (pPostScriptUFT, 'END;');
    DisplayLine (pPostScriptUFT, '/');
    DisplayLine (pPostScriptUFT, 'BEGIN');
    DisplayLine (pPostScriptUFT, 'dbms_preup.clear_run_flag(FALSE);');
    DisplayLine (pPostScriptUFT, 'END;');
    DisplayLine (pPostScriptUFT, '/');
    pOutputtingScripts := TRUE;
  ELSE
    IF pOutputtingScripts THEN
      --
      -- Dump out a call to the routine to run through all the checks and report
      -- a summary of success/failures/user actions
      --
      DisplayLine (pPreScriptUFT, 'BEGIN dbms_preup.fixup_summary(TRUE); END;');
      DisplayLine (pPreScriptUFT,'/');

      DisplayLine (pPostScriptUFT, 'BEGIN dbms_preup.fixup_summary(FALSE); END;');
      DisplayLine (pPostScriptUFT,'/');


      EXECUTE IMMEDIATE 'SELECT TO_CHAR(SYSTIMESTAMP,''YYYY-MM-DD HH24:MI:SS '') FROM SYS.DUAL'
      INTO timeinfo;

      DisplayLine (pPreScriptUFT, 'BEGIN');
      DisplayLine (pPreScriptUFT,
          'dbms_output.put_line (''**************** Pre-Upgrade Fixup Script Complete *********************'');');
      DisplayLine (pPreScriptUFT, 'END;' || crlf || '/' || crlf);
      DisplayLine (pPreScriptUFT, 'REM Pre-Upgrade Script Closed At: ' || timeinfo);

      DisplayLine (pPostScriptUFT, 'BEGIN');
      DisplayLine (pPostScriptUFT,
          'dbms_output.put_line (''*************** Post Upgrade Fixup Script Complete ********************'');');
      DisplayLine (pPostScriptUFT,'END;' || crlf || '/' );
      DisplayLine (pPostScriptUFT,'REM Post Upgrade Script Closed At: ' || timeinfo);

      UTL_FILE.FCLOSE(pPreScriptUFT);
      UTL_FILE.FCLOSE(pPostScriptUFT);
      --
      pOutputtingScripts := FALSE;
    END IF;
    IF pOutputDest = c_output_terminal AND pCreatedDirObj THEN 
      --
      -- If we created the directory object, (and we are not outputting
      -- to a log file) drop the directory object (usually done in close_file
      -- but that will not be called if we are not outputting a log file)
      --
      BEGIN
        EXECUTE IMMEDIATE 'DROP DIRECTORY :1' USING pOutputLocation;
      EXCEPTION WHEN OTHERS THEN NULL;
      END;
    END IF;
    pOutputLocation := NULL;

  END IF;  -- on/off
END set_scripts;

PROCEDURE verifyDefaultDirObj
--
-- Bulk of this code started with a version in catbundle.sql
-- The code creates a java package to create an actual 
-- directory on the server under cfgtoollogs/<dbid>/preupgrade
-- and then also creates a directory object to point there.
-- Note: If the directory object already exists, it will 
-- be used and no directory will be created.
--
-- The global value:
--   pOutputVerified 
-- is set to TRUE if the directory object could be verified, 
-- otherwise FALSE.
--
-- Notes:
--   This routine will dump out a warning should the directory object
--   fail to be verified.
--
IS
  dummy       VARCHAR2(2500);
  tmp_varchar VARCHAR2(200);
  platform    v$database.platform_name%TYPE;
  uniqueName  VARCHAR2(100);  
  logDir      VARCHAR2(4000);  -- the physical directory
  dirObjName  VARCHAR2(128);   -- the object name
  rdbmsLogDir VARCHAR2(500);
  homeDir     VARCHAR2(500);
  baseDir     VARCHAR2(500);
  useDir      VARCHAR2(500);
  tmp_dirpath VARCHAR2(4000);
  usingExistingDef BOOLEAN := FALSE;
  clearJava   BOOLEAN;
  status      NUMBER;
  javaOK      NUMBER;
  javaCreate  VARCHAR2(500) :=
    'CREATE OR REPLACE FUNCTION PreupCreateDir(path VARCHAR2)
       RETURN NUMBER AS
       LANGUAGE JAVA
       NAME ''PreupCreateDir.create (java.lang.String) return java.lang.int'';';
  dummyCreate   VARCHAR2(500) :=
    'CREATE OR REPLACE FUNCTION PreupCreateDir(path VARCHAR2)
       RETURN NUMBER AS
     BEGIN
       RETURN 0;
     END PreupCreateDir;';
  createString  VARCHAR2(500);

  nameAlreadyExists  EXCEPTION;
  PRAGMA exception_init(nameAlreadyExists, -955);

  classInUse         EXCEPTION;
  PRAGMA EXCEPTION_INIT(classInUse, -29553);

BEGIN

  --
  -- See if the directory object already exists
  --
  BEGIN
    EXECUTE IMMEDIATE 'SELECT directory_name,directory_path from DBA_DIRECTORIES where directory_name=:1'
    INTO tmp_varchar, tmp_dirpath
    USING c_dir_obj;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
  END;

  IF tmp_varchar = c_dir_obj THEN
    --
    -- The directory object exists and is using our name
    --
    pOutputLocation := c_dir_obj;
    pCreatedDirObj := FALSE;
    --
    -- Define logDir (javascript will veirfy it exists)
    --
    logDir := dbms_assert.enquote_literal(tmp_dirpath);
    usingExistingDef := TRUE;
  END IF;

  IF usingExistingDef = FALSE THEN
    --
    -- If we didn't grab the existing directory path from the query above
    -- construct one here.
    --
    -- This is the default case (assuming we will create the directory object)
    -- so figure out the path we want so we can actually create the target
    -- directory.
    --
    -- Determine where we are going to put the log/scripts
    --
    -- Determine ORACLE_HOME value 
    EXECUTE IMMEDIATE 'SELECT NLS_UPPER(platform_name) FROM v$database'
       INTO platform;

    EXECUTE IMMEDIATE 'SELECT value FROM v$parameter where '
       || 'name=''db_unique_name'''
      INTO uniqueName;

    -- Default to $ORACLE_BASE/cfgtoollogs/<db-unique-name>/preupgrade
    --  if $ORACLE_BASE is not defined then use 
    -- $ORACLE_HOME/cfgtoollogs/<db-unique-name>/preupgrade 
    -- if $ORACLE_HOME is not defined then error

    DBMS_SYSTEM.GET_ENV('ORACLE_BASE', baseDir);
    DBMS_SYSTEM.GET_ENV('ORACLE_HOME', homeDir);

    IF homeDir IS NULL THEN
      pOutputLocation := NULL;
      pOutputVerified := FALSE;
      DisplayLine('Warning:  ORACLE_HOME is not defined');
      DisplayLine('          Terminal output only');
      RETURN;
    END IF;

    IF baseDir IS NOT NULL THEN
      useDir := baseDir;
    ELSE
      useDir := homeDir;
    END IF;

    --
    -- Setup logDir and rdbmsLogDir, starting with useDir as the 
    -- default.
    --
    IF INSTR(platform, 'WINDOWS') != 0 THEN
      -- Windows, use '\'
      useDir := RTRIM(useDir, '\');  -- Remove any trailing slashes
      logDir := dbms_assert.enquote_literal(
              useDir
           || '\cfgtoollogs\'  
           || uniqueName
           || '\preupgrade\');
      rdbmsLogDir := homeDir || '\rdbms\log\';
    ELSIF INSTR(platform, 'VMS') != 0 THEN
      -- VMS, use [] and .
      logDir := dbms_assert.enquote_literal (REPLACE (
            useDir
         || '[cfgtoollogs.' 
         ||  uniqueName
         || '.preupgrade]', '][', '.'));
      rdbmsLogDir := REPLACE(homeDir || '[rdbms.log]', '][', '.');
    ELSE 
      -- Unix and z/OS, '/'
      useDir := RTRIM(useDir, '/');  -- Remove any trailing slashes
      logDir := dbms_assert.enquote_literal(
              useDir
           || '/cfgtoollogs/' 
           || uniqueName
           || '/preupgrade/');
      rdbmsLogDir := homeDir || '/rdbms/log/';
    END IF;
  END IF;

  --
  -- Load in the Java piece
  --
  status := 1;
  javaOK := 0;

  IF dbms_registry.is_valid('JAVAVM',dbms_registry.release_version) = 1 THEN
    BEGIN
      -- Because of the dbms_assert checks we know we are getting a string with 
      -- leading and trailing single quotes as the path.  We need to remove those 
      -- single quotes before using the passed path variable.
      EXECUTE IMMEDIATE '
        CREATE OR REPLACE AND COMPILE JAVA SOURCE NAMED "PreupCreateDir" AS
          import java.lang.*;
          import java.util.*;
          import java.io.*;

          public class PreupCreateDir
          {
            public static int create (String path)
            {
              path = path.substring(1,path.length()-1); /* Take off leading/trailing quotes */
              File myFile = new File(path);
              if (myFile.exists())
              {
                if (myFile.canWrite())
                  return 1;  /* Directory exists and is writable, OK */
                else
                  return 2;  /* Directory exists and is not writable, NOT OK */
              }
              else
              {
                if (myFile.mkdirs())
                  return 1;  /* Directory created, OK */
                else
                  return 4;  /* Directory could not be created, NOT OK */
              }
            }
          }';
        javaOK := 1;
        EXCEPTION
          WHEN classInUse THEN javaOK := 1;  -- already created
          WHEN OTHERS THEN     javaOK := 0;
    END;
    
    IF javaOK = 1 THEN
      createString := javaCreate;
    ELSE
      --  Create dummy version if the java create failed
      createString := dummyCreate;      
    END IF;
  ELSE
    -- JavaVM is not present or in an invalid state
    --
    -- Create dummy version of PreupCreateDir so subsequent
    -- blocks will compile
    createString := dummyCreate;
  END IF;
  EXECUTE IMMEDIATE createString;

  IF javaOK = 1 THEN
    DECLARE
      --
      -- This exception is command and is handled by ending 
      -- the session inside the loop.
      --
      JavaSessionCleared EXCEPTION;
      PRAGMA EXCEPTION_INIT(JavaSessionCleared, -29549);
    BEGIN
      clearJava := FALSE;
      status := 0;
      FOR tries IN 1..2 LOOP
        BEGIN
          EXECUTE IMMEDIATE 'CALL PreupCreateDir(:1) into :2'
          USING IN logDir, OUT status;
        EXCEPTION
          WHEN JavaSessionCleared THEN  clearJava := TRUE;
          WHEN OTHERS THEN 
           IF usingExistingDef = FALSE THEN
             logDir := dbms_assert.enquote_literal(rdbmsLogDir);
           ELSE
             -- Can't do anything, exit the loop
             EXIT;
           END IF;
        END;

        IF clearJava THEN 
          -- Clear state and try again
          -- Use dynamic SQL since dbms_java may not be installed
          BEGIN
            EXECUTE IMMEDIATE 'BEGIN :1 := dbms_java.endsession; END;'
            USING OUT dummy;
          EXCEPTION WHEN OTHERS THEN NULL;
          END;
        ELSIF status = 1 THEN
          -- Success, exit loop
          EXIT;
        ELSIF status = 2 THEN
          --
          -- Directory exists, not writeable
          --
          IF usingExistingDef = FALSE THEN
            -- 
            -- We said where to create the dir, and it failed, 
            -- try the rdbmdLogDir area
            --
            logDir := dbms_assert.enquote_literal(rdbmsLogDir);    
          ELSE
            --
            -- They specified an area, and we can't write to it.
            --
            EXIT;
          END IF;
        ELSE
          -- 
          -- status = 4 = could not create the directory
          --
          EXIT;
        END IF;
      END LOOP;
    END;
    --
    -- done with the java, clean it up
    --
    BEGIN
      EXECUTE IMMEDIATE 'DROP JAVA SOURCE "PreupCreateDir"';
    EXCEPTION WHEN OTHERS THEN NULL;
    END;

    --
    -- end the session
    --
    BEGIN
      EXECUTE IMMEDIATE 'BEGIN :1 := dbms_java.endsession; END;'
      USING OUT dummy;
    EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END IF; 

  --
  -- Even if we failed to verify things, try to create the 
  -- default directory.
  --
  IF usingExistingDef = FALSE THEN
    --
    -- Try to create the directory object for the actual directory 
    -- the javascript created or verified existed
    --
    BEGIN
      EXECUTE IMMEDIATE 
        'CREATE DIRECTORY ' || c_dir_obj || ' AS ' || logDir ;
      EXCEPTION 
        WHEN nameAlreadyExists THEN pCreatedDirObj := FALSE;
        WHEN OTHERS THEN status := 0;
    END;

    IF status = 0 THEN
      pOutputLocation := NULL;    
      pOutputVerified := FALSE;
      DisplayLine('WARNING: Unable to create required directory object');
      DisplayLine('         Terminal output only');
      RETURN;
    END IF;
    BEGIN
      -- 10.n gives an error on granting to sys, just ignore it.
      EXECUTE IMMEDIATE
       'GRANT READ,WRITE ON DIRECTORY ' || c_dir_obj || ' TO SYS';
      EXCEPTION WHEN OTHERS THEN NULL;
    END;
  END IF;  -- Using Existing Def = false

  IF status != 1 THEN
    --
    -- something went wrong with the java (or it was not even executed)
    --
    pOutputLocation := NULL;
    pOutputVerified := FALSE;

    IF status = 2 THEN
      -- A two means we can't write to the area.
      tmp_varchar := 'Unable to write to  directory ';
    ELSIF status = 4 THEN
      -- Only other is a 4 which means we couldn't create the dir
      tmp_varchar := 'Unable to create directory ';
    ELSE
      -- 0 ?  Could not verify/create because of JAVA
      tmp_varchar := 'Unable to verify or create directory ';
    END IF;

    IF usingExistingDef = TRUE THEN
      --
      -- Tell them we tried to use their existing dir object and it failed
      --
      DisplayLine('WARNING: ' || tmp_varchar || logDir 
              || ' for existing Directory Object: ' || c_dir_obj);
    ELSE
      --
      -- We failed to create the directory that we want 
      --
      DisplayLine('WARNING: ' || tmp_varchar || logDir 
              || ' for Directory Object: ' || c_dir_obj);
    END IF;
    --
    -- Finish it off and get out.
    --
    DisplayLine('     script will generate terminal output only');
    RETURN;
  END IF;

  --
  -- Set the package variable (will be used for utl_file)
  --
  pOutputLocation := c_dir_obj;
  pOutputVerified := TRUE;

END verifyDefaultDirObj;

PROCEDURE start_xml_document
IS
BEGIN
  init_package;
  DisplayLine ('<RDBMSUP xmlns="http://www.oracle.com/Upgrade" version="' 
          || c_version || '">');
END start_xml_document;

PROCEDURE end_xml_document 
IS 
BEGIN
   DisplayLine ('</RDBMSUP>');
END end_xml_document;

-- ****************************************************************************
-- Run a specific check, but don't generate any fixup script or output
-- Do that by setting the 'pCheckOnly' package level variable then execute 
-- the check
-- ****************************************************************************
FUNCTION run_check_simple (check_name VARCHAR2) RETURN check_record_t
IS
  t_check_rec    check_record_t;
  execute_failed BOOLEAN := FALSE;
  idx            NUMBER;
  retval         NUMBER;
  check_stmt     VARCHAR2(100);
  r_text         VARCHAR2(1000);

BEGIN
  init_package;

  IF check_names.EXISTS(check_name) = FALSE 
  THEN
    EXECUTE IMMEDIATE 'BEGIN 
      RAISE_APPLICATION_ERROR (-20000, 
            ''Pre-Upgrade Package Requested Check does not exist''); END;';
      RETURN (NULL);
  END IF;
  idx := check_names(check_name).idx;

  pCheckOnly := TRUE;

  IF check_table(idx).always_fail THEN
    --
    -- We want to fail this check, set the global
    -- so the package checks know to fail
    --
    pDBGFailCheck := TRUE;
  END IF;

  -- Clear out the info about the check before 
  -- executing it (only an issue during re-run)
  --
  check_table(idx).passed         := FALSE;
  check_table(idx).skipped        := FALSE;
  check_table(idx).executed       := FALSE;
  check_table(idx).execute_failed := FALSE;
  check_table(idx).fixup_executed := FALSE;
  check_table(idx).fixup_failed   := FALSE;
  check_table(idx).always_fail    := FALSE;

  check_stmt := 'BEGIN :r1 := dbms_preup.' 
     || dbms_assert.simple_sql_name(check_table(idx).f_name_prefix)
     ||  '_check (:rtxt); END;';

  BEGIN
    EXECUTE IMMEDIATE check_stmt 
       USING OUT retval, IN OUT r_text;
    EXCEPTION WHEN OTHERS THEN
      execute_failed := TRUE;
  END;

  --
  -- Save away the results of the check
  --
  t_check_rec.executed := TRUE;

  IF execute_failed = TRUE
  THEN
    -- Passed is already FALSE
    t_check_rec.execute_failed := TRUE;
  ELSE
    IF retval = c_status_success THEN
      t_check_rec.passed := TRUE;
    ELSIF retval = c_status_not_for_this_version THEN
      t_check_rec.passed := TRUE;
      t_check_rec.skipped := TRUE;
    ELSE
      -- Passed is already FALSE
      t_check_rec.result_text := r_text;
    END IF;
  END IF;

  --
  -- Always turn these off
  --
  pDBGFailCheck := FALSE;
  pCheckOnly := FALSE;

  return t_check_rec;
END run_check_simple; 

-- ****************************************************************************
-- Same as run_check_simple only return true/false 
-- ****************************************************************************
FUNCTION condition_exists (check_name VARCHAR2) RETURN BOOLEAN
IS
  t_check_rec    check_record_t := NULL;
  execute_failed BOOLEAN := FALSE;
  idx            NUMBER;
  retval         NUMBER;
  check_stmt     VARCHAR2(100);
  r_text         VARCHAR2(1000);

BEGIN
  init_package;
  
  t_check_rec := dbms_preup.run_check_simple(check_name);

  IF t_check_rec.passed THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END condition_exists;


FUNCTION run_check (check_name VARCHAR2) RETURN check_record_t
IS
  execute_failed    BOOLEAN := FALSE;
  idx               NUMBER;
  retval            NUMBER;
  check_stmt        VARCHAR2(100);
  r_text            VARCHAR2(1000);

BEGIN

  init_package;

  IF check_names.EXISTS(check_name) = FALSE 
  THEN
    EXECUTE IMMEDIATE 'BEGIN 
      RAISE_APPLICATION_ERROR (-20000, 
            ''Pre-Upgrade Package Requested Check does not exist''); END;';
      return (NULL);
  END IF;
  idx := check_names(check_name).idx;

  IF check_table(idx).always_fail THEN
    --
    -- We want to fail this check, set the global
    -- so the package checks know to fail
    -- 
    pDBGFailCheck := TRUE;
  END IF;

  -- Clear out the info about the check before 
  -- executing it (only an issue during re-run)
  --
  check_table(idx).passed         := FALSE;
  check_table(idx).skipped        := FALSE;
  check_table(idx).executed       := FALSE;
  check_table(idx).execute_failed := FALSE;
  check_table(idx).fixup_executed := FALSE;
  check_table(idx).fixup_failed   := FALSE;
  check_table(idx).always_fail    := FALSE;

  --
  -- This executes the check procedure 
  -- An example would be 
  --
  --  BEGIN :r1 := purge_recyclebin_check(r_text); END;
  --

  check_stmt := 'BEGIN :r1 := dbms_preup.' 
      || dbms_assert.simple_sql_name(check_table(idx).f_name_prefix)
      ||  '_check (:rtxt); END;';

  BEGIN
    EXECUTE IMMEDIATE check_stmt 
       USING OUT retval, IN OUT r_text;
    EXCEPTION WHEN OTHERS THEN
      execute_failed := TRUE;
  END;

  --
  -- Save away the results of the check
  --
  check_table(idx).executed := TRUE;

  if execute_failed = TRUE
  THEN
    check_table(idx).execute_failed := TRUE;
    check_table(idx).passed := FALSE;
  ELSE
    IF retval = c_status_success THEN
      check_table(idx).passed := TRUE;
    ELSIF retval = c_status_not_for_this_version THEN
      check_table(idx).passed := TRUE;
      check_table(idx).skipped := TRUE;
    ELSE
      check_table(idx).passed := FALSE;
      check_table(idx).result_text := r_text;
    END IF;
  END IF;
  --
  -- Always turn this off
  --
  pDBGFailCheck := FALSE;
  return (check_table(idx));
END run_check;

--
-- Run a check, dump out the results, no script created
--
PROCEDURE run_check (check_name VARCHAR2) 
IS
  t_check_rec     check_record_t;
  execute_failed  BOOLEAN := FALSE;
  checkonly       BOOLEAN;
  idx             NUMBER;
  retval          NUMBER;
  check_stmt      VARCHAR2(100);
  r_text          VARCHAR2(1000);

BEGIN

  init_package;

  IF check_names.EXISTS(check_name) = FALSE 
  THEN
    EXECUTE IMMEDIATE 'BEGIN 
      RAISE_APPLICATION_ERROR (-20000, 
            ''Pre-Upgrade Package Requested Check does not exist''); END;';
      return;
  END IF;

  checkonly := pCheckOnly;
  pCheckOnly := TRUE;

  idx := check_names(check_name).idx;

  --
  -- Because the info is not recorded in our check_table,
  -- the run status fields do not need to be cleared)
  --

  --
  -- This executes the check procedure 
  -- An example would be 
  --
  --  BEGIN :r1 := purge_recyclebin_check(r_text); END;
  --
  check_stmt := 'BEGIN :r1 := dbms_preup.' 
    || dbms_assert.simple_sql_name(check_table(idx).f_name_prefix)
    ||  '_check (:rtxt); END;';

  BEGIN
    EXECUTE IMMEDIATE check_stmt 
       USING OUT retval, IN OUT r_text;
    EXCEPTION WHEN OTHERS THEN
      execute_failed := TRUE;
  END;

  DisplayLinePL('');
  DisplayLinePL('**********************************************************************');
  DisplayLinePL('Check Tag:       ' || check_table(idx).name);
  DisplayLinePL('Check Summary:   ' || check_table(idx).descript);
  DisplayLinePL('Check Help Text: ');
  DisplayLinePL('  ' || getHelp(check_table(idx).name,c_help_overview));
  DisplayLinePL('Fixup Summary: ');
  DisplayLinePL('  ' || getHelp(check_table(idx).name,c_help_fixup));
  DisplayLinePL('');


  IF execute_failed = TRUE THEN 
    DisplayLinePL(CenterLine('**** Check Failed to Execute ****'));
  ELSE
    IF retval = c_status_success THEN
      DisplayLinePL('++++ Check Passed');
    ELSIF retval = c_status_not_for_this_version THEN
      DisplayLinePL('++++ Check Not Valid from your current release.');
    ELSE
      DisplayLinePL('++++ Check Failed:');
      DisplayLinePL('   ' || r_text);
    END IF;
  END IF;
  --
  -- Restore setting
  --
  pCheckOnly := checkonly;
END run_check;

PROCEDURE run_fixup_and_report (check_name VARCHAR2)
IS
  --
  -- Run a check and dump any errors out to stdout.
  -- This procedure is used by the fixup scripts.
  -- "set server output on" must be executed before and 
  -- must be connected as SYS
  --
  -- NOTE:
  --   This function is intended to be run OUTSIDE of the preupgrade
  --   checks, therefore, its output is displayed to the terminal or 
  --   redirected location specified (spool) and not to the preupgrade
  --   log file.
  --
  idx          NUMBER;
  retval       NUMBER;
  r_sqlcode    NUMBER := 0;
  check_stmt   VARCHAR2(100);
  r_text       VARCHAR2(1500);

BEGIN
  init_package;

  IF check_names.EXISTS(check_name) = FALSE 
  THEN
    RAISE_APPLICATION_ERROR (-20000, 
            'Pre-Upgrade Package Requested Fixup: ' ||
            check_name || ' does not exist');
    RETURN;
  END IF;
  idx := check_names(check_name).idx;

  --
  -- This executes the fixup procedure, 
  -- An example would be 
  --
  --  BEGIN :r1 := purge_recyclebin_fixup(r_text, r_sqlcode); END;
  --

  check_stmt := 'BEGIN :r1 := dbms_preup.' 
     || dbms_assert.simple_sql_name(check_table(idx).f_name_prefix)
     || '_fixup (:rtxt, :rsqlcode); END;'; 

  --
  -- No exception catching here, let the lower levels catch
  -- and return the problems.
  --
  DisplayLinePL('');
  DisplayLinePL('**********************************************************************');
  DisplayLinePL('Check Tag:     ' || check_table(idx).name);
  DisplayLinePL('Check Summary: ' || check_table(idx).descript);
  DisplayLinePL('Fix Summary:   ' || getHelp(check_table(idx).name,c_help_fixup));
  DisplayLinePL('**********************************************************************');

  -- 
  -- Clear out the existing values
  --
  check_table(idx).fixup_executed := FALSE;
  check_table(idx).result_text    := '';
  check_table(idx).sqlcode        := 0;

  EXECUTE IMMEDIATE check_stmt
     USING OUT retval, IN OUT r_text, IN OUT r_sqlcode;

  --
  -- Save away the results of the fixup
  --
  check_table(idx).fixup_executed := TRUE;
  check_table(idx).result_text    := r_text;
  check_table(idx).sqlcode        := r_sqlcode;
  check_table(idx).fixup_status   := retval;

  IF retval = c_fixup_status_success THEN
    check_table(idx).fixup_failed := FALSE;
    DisplayLinePL('Fixup Succeeded');
  ELSIF retval = c_fixup_status_info THEN
    -- The fixup wants to return some text, display it here
    check_table(idx).fixup_failed := FALSE;
    DisplayLinePL('Fixup Returned Information:');
    DisplayLinePL(check_table(idx).result_text);
  ELSE
    check_table(idx).fixup_failed := TRUE;
    DisplayLinePL('Fixup Failed:');
    DisplayLinePL  (check_table(idx).result_text);
    DisplayLinePL  ('SQL Code: ' || check_table(idx).sqlcode); 
  END IF;
  DisplayLinePL('**********************************************************************');
  DisplayLinePL('');
  return;
END run_fixup_and_report;


PROCEDURE run_fixup_info (check_name VARCHAR2)
IS
  --
  -- Run a check, and instead of returning a record with the info
  -- on the run (which is what run_check does), This grabs the return
  -- text from the fixup routine and displays it.
  -- This is only used for those fixup functions that can not do 
  -- anything for the existing issue, but we need to display some 
  -- text.
  --
  -- NOTE:
  --   This function is intended to be run OUTSIDE of the preupgrade
  --   checks, therefore, its output is displayed to the terminal or 
  --   redirected location specified and not to the preupgrade
  --   log file.
  --
  idx          NUMBER;
  retval       NUMBER;
  r_sqlcode    NUMBER := 0;
  check_stmt   VARCHAR2(100);
  r_text       VARCHAR2(1000);

BEGIN
  init_package;

  IF check_names.EXISTS(check_name) = FALSE 
  THEN
    RAISE_APPLICATION_ERROR (-20000, 
            'Pre-Upgrade Package Requested Fixup: ' ||
            check_name || ' does not exist');
    RETURN;
  END IF;
  idx := check_names(check_name).idx;

  --
  -- This executes the fixup procedure, 
  -- An example would be 
  --
  --  BEGIN :r1 := purge_recyclebin_fixup(r_text, r_sqlcode); END;
  --

  check_stmt := 'BEGIN :r1 := dbms_preup.' 
     || dbms_assert.simple_sql_name(check_table(idx).f_name_prefix)
     || '_fixup (:rtxt, :rsqlcode); END;'; 

  --
  -- No exception catching here, let the lower levels catch
  -- and return the problems.
  --

  dbms_output.put_line ('------- ---------- Executing Fixup  ------------ ----------');
  dbms_output.put_line ('------- ' || RPAD (check_table(idx).name, 40) || ' ----------');

  EXECUTE IMMEDIATE check_stmt
     USING OUT retval, IN OUT r_text, IN OUT r_sqlcode;

  --
  -- Save away the results of the fixup
  --
  check_table(idx).fixup_executed := TRUE;
  check_table(idx).result_text    := r_text;
  check_table(idx).sqlcode        := r_sqlcode;
  --
  -- don't care about the return status
  --
  check_table(idx).fixup_failed := FALSE;
  dbms_output.put_line ('------- ------------ Fixup Succeeded ----------- ----------');
  dbms_output.put_line ('------- ------- Informational Text Returned ---- ----------');
  dbms_output.put_line (check_table(idx).result_text);
  dbms_output.put_line ('------- ---------------------------------------- ----------');
END run_fixup_info;


FUNCTION run_fixup (check_name VARCHAR2) RETURN check_record_t
IS
  idx          NUMBER;
  retval       NUMBER;
  r_sqlcode    NUMBER := 0;
  check_stmt   VARCHAR2(100);
  r_text       VARCHAR2(1000);

BEGIN
  init_package;

  IF check_names.EXISTS(check_name) = FALSE 
  THEN
    EXECUTE IMMEDIATE 'BEGIN 
      RAISE_APPLICATION_ERROR (-20000, 
            ''Pre-Upgrade Package Requested Fixup: '' ||
            check_name || '' does not exist''); END;';
      return (NULL);
  END IF;
  idx := check_names(check_name).idx;

  -- This executes the fixup procedure 
  -- An example would be 
  --
  --  BEGIN :r1 := purge_recyclebin_fixup(r_text, r_sqlcode); END;
  --

  check_stmt := 'BEGIN :r1 := dbms_preup.' 
    || dbms_assert.simple_sql_name(check_table(idx).f_name_prefix)
    || '_fixup (:rtxt, :rsqlcode); END;'; 

  --
  -- No exception catching here, let the lower levels catch
  -- and return the problems.
  --
  EXECUTE IMMEDIATE check_stmt
     USING OUT retval, IN OUT r_text, IN OUT r_sqlcode;

  --
  -- Save away the results of the fixup
  --
  check_table(idx).fixup_executed := TRUE;
  check_table(idx).result_text    := r_text;
  check_table(idx).sqlcode        := r_sqlcode;

  IF retval = 1
  THEN
    check_table(idx).fixup_failed := FALSE;
  ELSE
    check_table(idx).fixup_failed := TRUE;
  END IF;

  return (check_table(idx));
END run_fixup;

-- ****************************************************************************
--    Debug Functions/Procedures
-- ****************************************************************************

--
-- Set always_fail for a specific check, causing the check to not 
-- actually execute the specific check, but cause it to 'fail'
--
PROCEDURE dbg_check (check_name VARCHAR2)
IS
  execute_failed    BOOLEAN := FALSE;
  idx               NUMBER;
  retval            NUMBER;
  check_stmt        VARCHAR2(100);

BEGIN
  init_package;

  IF check_names.EXISTS(check_name) = FALSE 
  THEN
    EXECUTE IMMEDIATE 'BEGIN 
      RAISE_APPLICATION_ERROR (-20000, 
            ''Pre-Upgrade Package Requested Check does not exist''); END;';
  END IF;
  idx := check_names(check_name).idx;
  check_table(idx).always_fail := TRUE;
END dbg_check;

--
-- Set All the checks always_fail to TRUE
--
PROCEDURE dbg_all_checks 
IS
BEGIN
  init_package;

  FOR i IN 1..pCheckCount LOOP
    check_table(i).always_fail := TRUE;
  END LOOP;
  pDBGFailAll := TRUE;
END dbg_all_checks;

--
-- Turn on or off the output of space information into 
-- the log 
--
PROCEDURE dbg_space_resources (onoff BOOLEAN)
IS
BEGIN
  init_package;
  pDBGSizeResources := onoff;
END dbg_space_resources;

--
-- Turn on or off the output of resource information
-- (as if there is an issue with each resource)
--
PROCEDURE dbg_all_resources (onoff BOOLEAN)
IS
BEGIN
  init_package;
  pDBGAllResources := onoff;
END dbg_all_resources;

--
-- Output the result text of a check
--
PROCEDURE  display_check_text (check_record check_record_t )
IS
BEGIN
   DisplayLine (check_record.result_text);
END display_check_text;

-- ****************************************************************************
--    General utility functions 
-- ****************************************************************************

--------------------------- pvalue_to_number --------------------------------
-- This function converts a parameter string to a number. The function takes
-- into account that the parameter string may have a 'K' or 'M' multiplier
-- character.
FUNCTION pvalue_to_number (value_string VARCHAR2) RETURN NUMBER
IS
  ilen NUMBER;
  pvalue_number NUMBER;

BEGIN
    -- How long is the input string?
    ilen := LENGTH ( value_string );

    -- Is there a 'K' or 'M' in last position?
    IF SUBSTR(UPPER(value_string), ilen, 1) = 'K' THEN
         RETURN (c_kb * TO_NUMBER (SUBSTR (value_string, 1, ilen-1)));

    ELSIF SUBSTR(UPPER(value_string), ilen, 1) = 'M' THEN
         RETURN (c_mb * TO_NUMBER (SUBSTR (value_string, 1, ilen-1)));
    END IF;

    -- A multiplier wasn't found. Simply convert this string to a number.
    RETURN (TO_NUMBER (value_string));
END pvalue_to_number;

PROCEDURE store_oldval (minvp  IN OUT MINVALUE_TABLE_T)
IS
  c_value   VARCHAR2(80);
  i         INTEGER;
BEGIN
  FOR i IN 1..max_minvp LOOP
    BEGIN
      EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE name = 
         LOWER(:1)'
      INTO c_value
      USING minvp(i).name;
      minvp(i).oldvalue := pvalue_to_number(c_value);
    EXCEPTION WHEN NO_DATA_FOUND THEN
         minvp(i).oldvalue := NULL;
    END;
  END LOOP;

  -- After getting init ora values:
  -- Parameter streams_pool_size is not available in 92. Set old value to 0.
  IF (db_n_version = 920) THEN
    minvp(str_idx).oldvalue := 0;
  END IF;
END store_oldval;

PROCEDURE store_renamed (i   IN OUT BINARY_INTEGER,
                         old VARCHAR2,
                         new VARCHAR2)
IS
BEGIN
  i:= i+1;
  rp(i).oldname:=old;
  rp(i).newname:=new;
END store_renamed;

PROCEDURE store_removed (i IN OUT BINARY_INTEGER,
                         name       VARCHAR2,
                         version    VARCHAR2,
                         deprecated BOOLEAN)
IS
BEGIN
  i:=i+1;
  op(i).name:=name;
  op(i).version:=version;
  op(i).deprecated:=deprecated;
END store_removed;

PROCEDURE store_special (i    IN OUT BINARY_INTEGER,
                         old  VARCHAR2,
                         oldv VARCHAR2,
                         new  VARCHAR2,
                         newv VARCHAR2)
IS
BEGIN
  i:= i+1;
  sp(i).oldname      := old;
  sp(i).oldvalue     := oldv;
  sp(i).newname      := new;
  sp(i).newvalue     := newv;
  sp(i).db_match     := FALSE; 
  sp(i).dbua_OutInUpdate := FALSE; 
END store_special;

PROCEDURE store_required (i    IN OUT BINARY_INTEGER,
                         name  VARCHAR2,
                         newvn NUMBER,
                         newvs VARCHAR2,
                         dtype NUMBER)
--
-- Pass a 0, or '', for the newvn (new value numeric) or 
-- that you are not setting.
--    store_required(idx, 'foo', 0, 'bar', 2); 
-- would mean a string value of 'bar' is expected
-- 
IS
BEGIN
  i:= i+1;
  reqp(i).name:=name;
  reqp(i).newnumbervalue:=newvn;
  reqp(i).newstringvalue:=newvs;
  reqp(i).type:= dtype;
  reqp(i).db_match:=FALSE;   
END store_required;

PROCEDURE find_newval (minvp  IN OUT MINVALUE_TABLE_T,
                       dbbit  NUMBER)
IS
  extra    NUMBER;
BEGIN

  IF minvp(tg_idx).oldvalue != 0 THEN  -- SGA_TARGET in use
    find_sga_mem_values(minvp, dbbit);

    IF minvp(tg_idx).newvalue > minvp(tg_idx).oldvalue THEN
      minvp(tg_idx).display := TRUE;
    END IF;

    -- do not set display to TRUE for these params: sga_target,
    -- memory_target, db_cache_size, java_pool_size,
    -- shared_pool_size, large_pool_size, and streams_pool_size
    FOR i IN 1..max_minvp LOOP
      IF i NOT IN (tg_idx,mt_idx,cs_idx,jv_idx,sp_idx,lp_idx,str_idx) AND 
          (minvp(i).oldvalue IS NULL OR
          minvp(i).oldvalue < minvp(i).minvalue) THEN  
        minvp(i).display := TRUE;
        minvp(i).newvalue := minvp(i).minvalue;
      END IF;
    END LOOP;
  ELSE -- pool sizes included 
    FOR i IN 1..max_minvp LOOP
      -- don't print recommendations for sga_target, memory_target,
      -- large_pool_size, and streams_pool_size
      IF i NOT IN (tg_idx,mt_idx,lp_idx,str_idx) AND 
          (minvp(i).oldvalue IS NULL OR
           minvp(i).oldvalue < minvp(i).minvalue) THEN  
        minvp(i).display := TRUE;
        minvp(i).newvalue := minvp(i).minvalue;
      END IF;
    END LOOP;
  END IF;

  -- For 11.1 and 11.2 check if MEMORY_TARGET is set and NON-ZERO 
  -- then check that MEMORY_TARGET is at least 12M greater than 
  -- sga_target + pga_target (for cases where SGA_TARGET is in use)
  IF db_n_version IN (111,112) AND 
       db_memory_target AND (minvp(mt_idx).oldvalue != 0) THEN 
    find_sga_mem_values(minvp, dbbit);

    -- If the newvalue is greater than the old value set the display TRUE
    IF minvp(mt_idx).newvalue > minvp(mt_idx).oldvalue THEN
      minvp(mt_idx).display := TRUE;
      -- Loop through other pool sizes to ignore warnings
      -- If displaying MEMORY_TARGET warning then the other 
      -- pool sizes do not need warnings
    END IF;

    -- If a minimum value is required for MEMORY_TARGET then
    -- do not output a minimum value for sga_target or pga_aggregate
    -- or shared_pool_size or java_pool_size or db_cache_size or
    -- large_pool_size or streams_pool_size as these values
    -- are no longer considered once MEMORY_TARGET value is set.
    -- i.e., for params listed above, set display to FALSE if memory_target
    -- is set.
    FOR i IN 1..max_minvp LOOP
      IF i IN (tg_idx,pg_idx,sp_idx,jv_idx,cs_idx,lp_idx,str_idx) AND minvp(i).display THEN
        minvp(i).display := FALSE;
      END IF;
    END LOOP;     
  END IF; -- 11.1/11.2 db and memory_target in use
END find_newval;

--------------------------- find_sga_mem_values -------------------------------
-- This is called when sga_target or memory_target is used.

PROCEDURE find_sga_mem_values (minvp  IN OUT MINVALUE_TABLE_T,
                               dbbit  NUMBER)
IS
  cpucalc   NUMBER;
  extra     NUMBER;
  mtgval    NUMBER;
BEGIN

  -- We're here because sga_target/memory_target is used.
  -- Need to find new values for sga_target.

  -- First, reset min values for pools related to sga_target.

  -- If db_cpus is < 12, then calculate sga_target using 12 cpus.
  -- If db_cpus is >= 12, then calculate sga_target using cpu_count.
  -- If db_cpus is >= 64, then calculate sga_target using 64 cpus.
  -- At this point, we don't have enough data to size for greater than 64 cpus.
  IF (db_cpus >= 64) THEN
    cpucalc := 64;
  ELSIF (db_cpus >= 12) THEN
    cpucalc := db_cpus;
  ELSIF (db_cpus < 12) THEN
    cpucalc := 12;
  END IF;

  minvp(cs_idx).minvalue := cpucalc*4 * c_mb;
  minvp(str_idx).minvalue := 0;  -- 0M

  IF dbbit = 32 THEN
    minvp(jv_idx).minvalue := 64 * c_mb;
    minvp(sp_idx).minvalue := 180 * c_mb;
    minvp(lp_idx).minvalue := (cpucalc*2*2 * .5) * c_mb;
    extra := (8 + 32 + 56) * c_mb;  -- 96M
  ELSE
    minvp(jv_idx).minvalue := 100 * c_mb;
    minvp(sp_idx).minvalue := 280 * c_mb;
    minvp(lp_idx).minvalue := (cpucalc*2*2 * .5) * c_mb;
    extra := (8*2+32*2+28+20+16) * c_mb;  -- 144M
  END IF;

  minvp(tg_idx).minvalue :=
    minvp(cs_idx).minvalue + minvp(jv_idx).minvalue +
    minvp(sp_idx).minvalue + minvp(lp_idx).minvalue +
    minvp(str_idx).minvalue + extra;

  minvp(mt_idx).minvalue :=
    minvp(cs_idx).minvalue + minvp(jv_idx).minvalue +
    minvp(sp_idx).minvalue + minvp(lp_idx).minvalue +
    minvp(str_idx).minvalue + minvp(pg_idx).minvalue + extra;

  -- buffer cache (cs)
  IF minvp(cs_idx).oldvalue > minvp(cs_idx).minvalue THEN
    minvp(cs_idx).diff := minvp(cs_idx).oldvalue - minvp(cs_idx).minvalue;
  END IF;

  -- java pool (jv)
  IF minvp(jv_idx).oldvalue > minvp(jv_idx).minvalue THEN
    minvp(jv_idx).diff := minvp(jv_idx).oldvalue - minvp(jv_idx).minvalue;
  END IF;

  -- shared pool (sp)
  IF minvp(sp_idx).oldvalue > minvp(sp_idx).minvalue THEN
    minvp(sp_idx).diff := minvp(sp_idx).oldvalue - minvp(sp_idx).minvalue;
  END IF;

  -- large pool (lp)
  IF minvp(lp_idx).oldvalue > minvp(lp_idx).minvalue THEN
    minvp(lp_idx).diff := minvp(lp_idx).oldvalue - minvp(lp_idx).minvalue;
  END IF;

  -- streams pool (str)
  IF minvp(str_idx).oldvalue > minvp(str_idx).minvalue THEN
    minvp(str_idx).diff :=
      minvp(str_idx).oldvalue - minvp(str_idx).minvalue;
  END IF;

  -- pga_aggregate_target (pg)
  IF minvp(pg_idx).oldvalue > minvp(pg_idx).minvalue THEN
    minvp(pg_idx).diff :=
      minvp(pg_idx).oldvalue - minvp(pg_idx).minvalue;
  END IF;

  -- calculate sga_target 'newvalue' (new derived minimum) based on
  -- tg_idx.minvalue and user-specified pool sizes
  minvp(tg_idx).newvalue := 
      minvp(tg_idx).minvalue + minvp(cs_idx).diff
      + minvp(jv_idx).diff + minvp(sp_idx).diff
      + minvp(lp_idx).diff + minvp(str_idx).diff;

  -- calculate memory_target 'newvalue' (new derived minimum) based on
  -- mt_idx.minvalue and user-specified pool sizes
  minvp(mt_idx).newvalue :=
    minvp(mt_idx).minvalue + minvp(cs_idx).diff
    + minvp(jv_idx).diff + minvp(sp_idx).diff
    + minvp(lp_idx).diff + minvp(str_idx).diff + minvp(pg_idx).diff;
  IF (minvp(tg_idx).oldvalue != 0) THEN -- SGA_TARGET in use
    -- calculate 'newvalue' (new derived minimum) based on user-set sga_target
    -- and user-set pga_aggregate_target.  also add 12M to this calculation
    -- for memory_target if sga_target is also set.
    mtgval := minvp(tg_idx).oldvalue + minvp(pg_idx).oldvalue + 12*c_mb;
    -- set 'newvalue' to the larger of the two new derived minimums (see above)
    IF (mtgval > minvp(mt_idx).newvalue) THEN
      minvp(mt_idx).newvalue := mtgval;
    END IF;
  END IF;

  -- Note: Although sga_target and memory_target values are found here, we
  -- don't set DISPLAY in minvp in this procedure.  This setting is done
  -- in find_newval.

END find_sga_mem_values;

--------------------------- store_minvalue --------------------------------
PROCEDURE store_minvalue (i     BINARY_INTEGER,
                          name  VARCHAR2,
                          minv  NUMBER,
                          minvp IN OUT MINVALUE_TABLE_T)
IS
BEGIN
   minvp(i).name := name;
   minvp(i).minvalue := minv;
   minvp(i).display := FALSE;
   minvp(i).diff := 0;
END store_minvalue;

--------------------------- store_minval_dbbit -----------------------------
PROCEDURE store_minval_dbbit  (dbbit  NUMBER,
                               i      IN OUT BINARY_INTEGER,
                               name   VARCHAR2,
                               minv   NUMBER)
IS
BEGIN
   i:= i+1;
   IF dbbit = 32 THEN  -- set values for 32-bit
     store_minvalue(i, name, minv, minvp_db32);
   ELSIF dbbit = 64 THEN  -- set values for 64-bit
     store_minvalue(i, name, minv, minvp_db64);
   ELSE -- if 0 (or anything but 32 and 64), then set values for both db bits
     store_minvalue(i, name, minv, minvp_db32);
     store_minvalue(i, name, minv, minvp_db64);
   END IF;

END store_minval_dbbit;

--------------------------- store_comp -----------------------------------
PROCEDURE store_comp (i       BINARY_INTEGER,
                      schema  VARCHAR2,
                      version VARCHAR2,
                      status  NUMBER)
IS
BEGIN
   cmp_info(i).processed := TRUE;
   IF status = 0 THEN
      cmp_info(i).status := 'INVALID';
   ELSIF status = 1 THEN
      cmp_info(i).status := 'VALID';
   ELSIF status = 2 THEN
      cmp_info(i).status := 'LOADING';
   ELSIF status = 3 THEN
      cmp_info(i).status := 'LOADED';
   ELSIF status = 4 THEN
      cmp_info(i).status := 'UPGRADING';
   ELSIF status = 5 THEN
      cmp_info(i).status := 'UPGRADED';
   ELSIF status = 6 THEN
      cmp_info(i).status := 'DOWNGRADING';
   ELSIF status = 7 THEN
      cmp_info(i).status := 'DOWNGRADED';
   ELSIF status = 8 THEN
      cmp_info(i).status := 'REMOVING';
   ELSIF status = 9 THEN
      cmp_info(i).status := 'OPTION OFF';
   ELSIF status = 10 THEN
      cmp_info(i).status := 'NO SCRIPT';
   ELSIF status = 99 THEN
      cmp_info(i).status := 'REMOVED';
   ELSE
      cmp_info(i).status := NULL;
   END IF;
   cmp_info(i).version   := version;
   cmp_info(i).schema    := schema;
   EXECUTE IMMEDIATE 
      'SELECT default_tablespace FROM sys.dba_users WHERE username =:1'
   INTO cmp_info(i).def_ts
   USING schema;
EXCEPTION
   WHEN NO_DATA_FOUND THEN NULL;
END store_comp;

-------------------------- is_comp_tablespace ------------------------------------
-- returns TRUE if some existing component has the tablespace as a default

FUNCTION is_comp_tablespace (tsname VARCHAR2) RETURN BOOLEAN
IS
BEGIN
  FOR i IN 1..max_components LOOP
    IF cmp_info(i).processed AND
       tsname = cmp_info(i).def_ts THEN
      RETURN TRUE;
    END IF;
  END LOOP;
  RETURN FALSE;
END is_comp_tablespace;

-------------------------- ts_has_queues ---------------------------------
-- returns TRUE if there is at least one queue in the tablespace
FUNCTION ts_has_queues (tsname VARCHAR2) RETURN BOOLEAN
IS
  t_null CHAR(1);
BEGIN
  EXECUTE IMMEDIATE 'SELECT NULL FROM sys.dba_tables t
      WHERE EXISTS 
      (SELECT 1 FROM sys.dba_queues q 
         WHERE q.queue_table = t.table_name AND q.owner = t.owner)
      AND t.tablespace_name = :1 AND rownum <= 1'
      INTO t_null
      USING tsname;
    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN RETURN FALSE;
END ts_has_queues;

-------------------------- ts_is_SYS_temporary ---------------------------------
-- returns TRUE if there is at least one queue in the tablespace

FUNCTION ts_is_SYS_temporary (tsname VARCHAR2) RETURN BOOLEAN
IS
  t_null CHAR(1);
BEGIN
  EXECUTE IMMEDIATE 'SELECT NULL FROM sys.dba_users 
        WHERE username = ''SYS'' AND temporary_tablespace = :1' 
    INTO t_null
    USING tsname;
  RETURN TRUE;
EXCEPTION
  WHEN NO_DATA_FOUND THEN RETURN FALSE;
END ts_is_SYS_temporary;

--
-- Note:  There could be a verify function on 
-- the params passed in, but for now, we assume the
-- caller is passing something DBUA knows how to handle
--
FUNCTION genDBUAXMLCheck (
     name       VARCHAR2, 
     eseverity  NUMBER,
     etext      VARCHAR2,
     ecause     VARCHAR2, 
     action     VARCHAR2,
     detailtype VARCHAR2,
     detailinfo VARCHAR2, 
     fixuptype  VARCHAR2,
     fixupstage VARCHAR2 ) RETURN VARCHAR2 
IS
  t_severity   VARCHAR2(10);

--  name 
--    Text name that MUST BE KNOWN BY DBUA.  They use it to key off of.
--
--  eseverity
--    c_check_level_warning, _error, _info - tells the DBUA how to handle 
--    the condition.
--
--  etext
--    Text of the error (if DBUA has a translated message, they will
--      use that, otherwise, this will be displayed)
--
--  ecause
--    Details of what causes this issue.
--    
--  action
--    Action to be taken to resolve the issue.
--
--                         detailtype/info 
--    Detail is the details for the issue being reported.  What check
--    was run that caused this issue to be reported.
--
--  detailtype
--    c_dbua_detail_type_text or _sql.  If _text, the DBUA will display
--    it when displaying information about this issue.  If _sql, the
--    DBUA will execute it, grab the output and display it.  Make 
--    sure the SQL generates approporate output.
--
--  detailinfo 
--   If _text, a description of what the issue is, if _sql, then 
--   its the SQL command to execute to generate output that will be 
--   displayed by the DBUA.
--
--  fixuptype
--    c_dbua_fixup_type_auto _manual
--    _auto =  there is a fixup function to solve the issue which 
--      can be executed to resolve the issue.
--    _manual = There may still be a fixup function, but it must 
--      either confirmed, or executed manually (complex issue, or
--      possible data manupulation).
--
--  fixupstage
--    c_dbua_fixup_stage_pre, _post, _now
--     _pre = Should be fixed before the upgrade is executed, usually
--       right before the upgrade is started. 
--     _post = Should be fixed after the upgrade is executed
--     _now = Can be solved right now, no need to wait until right 
--       before upgrade is executed.
--
BEGIN
  IF (eseverity = c_check_level_warning) THEN
    t_severity := c_check_level_warning_txt;
  ELSIF (eseverity = c_check_level_error) THEN
    t_severity := c_check_level_error_txt;
  ELSIF (eseverity = c_check_level_info) THEN
    t_severity := c_check_level_info_txt;
  ELSE 
    t_severity := c_check_level_success_txt;
  END IF;
  return ('<PreUpgradeCheck ID="' || name || 
   '" Status="'  || t_severity  || '">' ||
   '<Message><Text>'         || etext      || '</Text>'   ||
            '<Cause>'        || ecause     || '</Cause>'  ||
            '<Action>'       || action     || '</Action>' ||
            '<Detail Type="' || detailtype || '">'  ||
               detailinfo || '</Detail>' ||
   '</Message>' ||
   '<FixUp Type="' || fixuptype  || '" FixAtStage="' || fixupstage || '"/>' ||
   '</PreUpgradeCheck>');
END genDBUAXMLCheck;


FUNCTION htmlentities (intxt varchar2) RETURN VARCHAR2
  --
  -- Replace chars which DBUA/XML will parse into 
  -- their HTML equivilants
  --
IS
  rstr VARCHAR2(4000);
BEGIN
  --
  -- Because we can't depend on the env turing DEFINE off,
  -- use chr(38) for the ampersand character.
  --
  rstr := replace(intxt, chr(38), chr(38) || 'amp;');
  rstr := replace(rstr, '<',      chr(38) || 'lt;');
  return replace(rstr, '>',      chr(38) || 'gt;');
  -- dbua testing showed that the ' and " did not need
  -- replacing
END htmlentities;

--
-- Output a 'fixup' to the passed file.  
-- This is a call to the dbms_preup.run_fixup_and_report 
-- routine.  That routine will run the fixup and report 
-- the problem.
-- 
PROCEDURE genFixup (name VARCHAR2 )
IS
  idx     NUMBER;
  rstr    VARCHAR2(400);
  tlevel  VARCHAR2(30);
  taction VARCHAR2(50);
  tfile   UTL_FILE.FILE_TYPE;
 
BEGIN
  IF pCheckOnly THEN
    return;
  END IF;

  idx := check_names(name).idx;

  rstr := 'dbms_preup.run_fixup_and_report(''' || name || ''');';

  IF check_table(idx).fix_type IN (c_fix_source_manual,
                                   c_fix_source_auto,
                                   c_fix_target_manual_pre,
                                   c_fix_target_auto_pre) THEN
    tfile := pPreScriptUFT;
  ELSE
    tfile := pPostScriptUFT;
  END IF;

  If check_table(idx).fix_type IN (c_fix_source_manual, 
                                   c_fix_target_manual_pre,
                                   c_fix_target_manual_post) THEN
    taction := pActionRequired;
  ELSE
    taction := 'Fixup routine';
  END IF;

  IF check_table(idx).level = c_check_level_info THEN
    tlevel := 'Informational';
  ELSIF check_table(idx).level = c_check_level_warning THEN
    tlevel := 'Warning';
  ELSIF check_table(idx).level = c_check_level_error THEN
    tlevel := 'Error';
  ELSIF check_table(idx).level = c_check_level_recommend THEN
    tlevel := 'Recommendation';
  END IF;

  DisplayLine (tfile, 'BEGIN');
  DisplayLine (tfile, '-- *****************  Fixup Details ***********************************');
  DisplayLine (tfile, '-- Name:        ' || name);
  DisplayLine (tfile, '-- Description: ' || check_table(idx).descript);
  DisplayLine (tfile, '-- Severity:    ' || tlevel);
  DisplayLine (tfile, '-- Action:      ' || taction);
  DisplayLine (tfile, '-- Fix Summary: ');
  DisplayLine (tfile, '--     ' || GetHelp(name, c_help_fixup));
  DisplayLine (tfile, '');
  DisplayLine (tfile, rstr);
  DisplayLine (tfile, 'END;');
  DisplayLine (tfile, '/');

END genFixup;

-- **********************************************************************************
--   Output routines for each phase of the preupgrade checks
-- **********************************************************************************
PROCEDURE output_summary 
IS
  t_varchar   VARCHAR2(40);
BEGIN
  init_package;
  if pOutputType = c_output_xml
  THEN
    -- TODO:  DBUA may need to know if this is a 
    -- restart.
    DisplayLine ('<SupportedOracleVersions value="' || c_supported_versions || '"/>');
    DisplayLine ('<OracleVersion value="'           || db_version || '"/>');
    DisplayLine ('<Database Name="'  || db_name || '" Version=" '
             || db_version || '" Compatibility="'
             || db_compat  || '"/>');
    IF pDBGFailAll THEN
      DisplayDiagLine (' ***** DEBUG MODE *****');
    END IF;
  ELSE
    IF pDBGFailAll THEN
      t_varchar := ' ***** DEBUG MODE *****';
    ELSE
      t_varchar := '';
    END IF;
    DisplayLine('Oracle Database Pre-Upgrade Information Tool ' || TO_CHAR(SYSDATE, 'MM-DD-YYYY HH24:MI:SS'));
    DisplayLine('Script Version: ' || c_version || c_patchset ||
                            ' Build: ' || c_build || t_varchar);
    DisplayBanner;
    DisplayLine ('   Database Name:  ' || db_name );
    DisplayLine ('         Version:  ' || db_version );
    DisplayLine ('      Compatible:  ' || db_compat );
    DisplayLine ('       Blocksize:  ' || db_block_size );
    DisplayLine ('        Platform:  ' || db_platform );
    DisplayLine ('   Timezone file:  V' || db_tz_version );
    IF db_readonly THEN
      DisplayLine ('        ReadOnly:   TRUE');
    END IF;
    IF db_is_XE THEN
      DisplayLine ('         Edition:  ' || 'XE' );
    END IF;
  END IF;
END output_summary;

PROCEDURE output_xml_initparams (minvp MINVALUE_TABLE_T)
IS
  i       NUMBER;
BEGIN
  DisplayLine ('<Update>');
  FOR i IN 1..max_minvp LOOP
    IF minvp(i).display THEN
      IF NOT (i = jv_idx and NOT cmp_info(javavm).processed) THEN
        IF NOT (i = mt_idx and minvp(i).oldvalue IS NULL) THEN
           DisplayLine('<Parameter name="' ||
              minvp(i).name ||
            '" atleast="' || TO_CHAR(ROUND(minvp(i).newvalue)) ||
            '" atleast_32="' || TO_CHAR(ROUND(minvp_db32(i).newvalue)) ||
            '" atleast_64="' || TO_CHAR(ROUND(minvp_db64(i).newvalue)) ||
            '" type="NUMBER"/>');
        END IF;
      END IF;
    END IF;
  END LOOP;

  IF db_compat_majorver < c_compat_min_num THEN
    -- 
    -- Display the minimum compatibility (manual mode has
    -- actual check)
    --
    DisplayLine (
      '<Parameter name="compatible" atleast="' || c_compat_min || '" type="VERSION"/>');
  END IF;

  -- 
  -- Check the special list for any values that 
  -- need to be updated and dumped out inside the <update> tags for the DBUA
  --
  FOR i IN 1..max_sp LOOP
    IF sp(i).dbua_OutInUpdate THEN
      IF sp(i).db_match = TRUE AND
        sp(i).newvalue IS NOT NULL THEN
        -- <parameter name="Audit_Trail" newValue="NONE"/>
        DisplayLine('<Parameter name="' || sp(i).oldname ||
            '" newValue="' || sp(i).newvalue || '" type="STRING"/>');
      ELSIF pDBGAllResources THEN
        DisplayLine('<Parameter name="' || sp(i).oldname ||
            '" newValue="' || sp(i).newvalue || '" type="STRING"/>');
      END IF;
    END IF;
  END LOOP;
  DisplayLine ('</Update>');
END output_xml_initparams;

PROCEDURE output_initparams 
IS 
  changes_req BOOLEAN;
  def_or_obs  VARCHAR2(15);
  result_txt  VARCHAR2(200);
  tmp_str     VARCHAR2(80);
BEGIN
  init_package;

  IF db_invalid_state = TRUE THEN
    IF pOutputType = c_output_xml THEN
      --
      -- Although the DBUA will ensure the db is
      -- opended correctly, leave this error output
      --
      result_txt:= genDBUAXMLCheck('DATABASE_NOT_OPEN', 
        c_check_level_error,
	'Database must be in "OPEN" state.',
	'Database is not in OPEN state',
        'SELECT status from V$INSTANCE',
	 c_dbua_detail_type_text,
        'Close the database and reopen it using OPEN as the state',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      DisplayLine ('Database not in OPEN state.');
      DisplayLine ('   Database must be in OPEN state for script to execute correctly.');
    END IF;
    return;
  END IF;

  IF (pOutputType = c_output_xml)
  THEN
    DisplayLine ('<InitParams>');

    IF db_64bit THEN
      output_xml_initparams(minvp_db64);
    ELSE
      output_xml_initparams(minvp_db32);
    END IF;
  
    -- Migration tag was here

    DisplayLine ('<NonHandled>');
    --  DisplayLine ('<Parameter name="remote_listener"/>');
    DisplayLine ('</NonHandled>');

    DisplayLine ('<Rename>');
    FOR i IN 1..max_rp LOOP
      IF rp(i).db_match = TRUE THEN
        DisplayLine(
        '<Parameter name="' || rp(i).oldname || 
                  '" newName="' || rp(i).newname || '"/>');
      ELSIF pDBGAllResources THEN
        DisplayLine(
        '<Parameter name="' || rp(i).oldname || 
                  '" newName="' || rp(i).newname || '"/>');
      END IF;
    END LOOP;

    -- Display parameters that have a new name and a new value
    FOR i IN 1..max_sp LOOP
      IF sp(i).db_match = TRUE AND
        sp(i).newvalue IS NOT NULL AND 
        sp(i).dbua_OutInUpdate = FALSE THEN  
        DisplayLine('<Parameter name="' || sp(i).oldname ||
            '" newName="' || sp(i).newname ||
            '" newValue="' || sp(i).newvalue || '"/>');
      ELSIF pDBGAllResources THEN
        IF sp(i).dbua_OutInUpdate = FALSE THEN
          DisplayLine('<Parameter name="' || sp(i).oldname ||
              '" newName="' || sp(i).newname ||
              '" newValue="' || sp(i).newvalue || '"/>');
        END IF;
      END IF;
    END LOOP;
    DisplayLine ('</Rename>');

    DisplayLine('<Remove>');
    FOR i IN 1..max_op LOOP
      IF op(i).db_match = TRUE THEN
         DisplayLine('<Parameter name="' ||
           op(i).name || '"/>');
      ELSIF pDBGAllResources THEN
         DisplayLine('<Parameter name="' ||
           op(i).name || '"/>');
      END IF;
    END LOOP;  
    DisplayLine('</Remove>');
    DisplayLine ('</InitParams>'); 
  ELSE
    --
    -- Text output
    --
    --
    -- compat check is done as an actual check 
    -- since it can stop the DB from starting up
    --
    DisplayBanner;
    DisplayCenter('[Renamed Parameters]');
    changes_req := FALSE;

    FOR i IN 1..max_rp LOOP
      IF rp(i).db_match = TRUE THEN
        changes_req := TRUE;
        DisplayWarning('"' || rp(i).oldname ||
            '" new name is "' || rp(i).newname || '"');
      ELSIF pDBGAllResources THEN
        DisplayWarning('"' || rp(i).oldname ||
            '" new name is "' || rp(i).newname || '"');
      END IF;
    END LOOP; 

    -- Display parameters that have a new name and a new value

    FOR i IN 1..max_sp LOOP
      IF sp(i).db_match = TRUE AND
          sp(i).newvalue IS NOT NULL
      THEN
        changes_req := TRUE;
        IF sp(i).oldvalue IS NULL
        THEN
          DisplayWarning('"' || sp(i).oldname ||
              '" new name is "' || sp(i).newname ||
              '" new value is "' || sp(i).newvalue || '"');
        ELSE
          DisplayLine('"' || sp(i).oldname ||
             '" old value was "' || sp(i).oldvalue || '";');
          DisplayLine('         --> new name is "' || 
              sp(i).newname || '", new value is "' || sp(i).newvalue || '"');
        END IF;
      ELSIF pDBGAllResources THEN
        IF sp(i).newvalue IS NULL THEN
          tmp_str := 'NULL';
        ELSE
          tmp_str := sp(i).newvalue;
        END IF;
        IF sp(i).oldvalue IS NULL  THEN
          DisplayWarning('"' || sp(i).oldname ||
              '" new name is "' || sp(i).newname ||
              '" new value is "' || tmp_str || '"');
        ELSE
          DisplayLine('"' || sp(i).oldname ||
             '" old value was "' || sp(i).oldvalue || '";');
          DisplayLine('         --> new name is "' || 
              sp(i).newname || '", new value is "' || tmp_str || '"');
        END IF;
      END IF;
    END LOOP;

    IF changes_req THEN
      DisplayLine('');
      DisplayCenter ('[Changes required in Oracle Database init.ora or spfile]');
      DisplayLine('');
    ELSE
      DisplayCenter('[No Renamed Parameters in use]');
    END IF;
    DisplayBanner;

    changes_req := FALSE;
    DisplayBanner;
    DisplayCenter ('[Obsolete/Deprecated Parameters]');

    FOR i IN 1..max_op LOOP
      IF op(i).deprecated = TRUE 
      THEN
        def_or_obs := 'DESUPPORTED';
      ELSE
        def_or_obs := 'OBSOLETE';
      END IF;

      IF op(i).db_match = TRUE THEN
        changes_req := TRUE;

        IF op(i).name NOT IN ('background_dump_dest','user_dump_dest') 
        THEN
          DisplayLine(
            '--> ' || rpad(op(i).name, 28) || ' ' ||
                     rpad(op(i).version, 10) || ' ' ||
                     rpad(def_or_obs, 12));
        ELSE
          -- bdump, udump deprecated by diagnostic_dest
          -- If core_dump_dest gets back onto this list, it goes here (and above)
          DisplayLine (
            '--> ' || rpad(op(i).name, 28) || ' ' ||
                     rpad(op(i).version, 10) || ' ' ||
                     rpad(def_or_obs, 12) || 
                     ' replaced by  "diagnostic_dest"');
        END IF;
      ELSIF pDBGAllResources THEN
        DisplayLine(
            '--> ' || rpad(op(i).name, 28) || ' ' ||
                     rpad(op(i).version, 10) || ' ' ||
                     rpad(def_or_obs, 12));
      END IF;
    END LOOP;

    IF changes_req THEN
      DisplayLine('');
      DisplayCenter('[Changes required in Oracle Database init.ora or spfile]');
      DisplayLine('');
    ELSE
      DisplayCenter ('[No Obsolete or Desupported Parameters in use]');
    END IF;
  END IF;  -- check for terminal output
END output_initparams;

PROCEDURE output_components
IS 
  post_list_info VARCHAR2(300) := '';
  tmp_varchar    VARCHAR2(30);
  ui             VARCHAR2(10);

BEGIN
  init_package;

  IF db_invalid_state = TRUE THEN
    return;
  END IF;

  IF  pOutputType = c_output_xml
  THEN
    IF (cmp_info(catalog).status = 'VALID' AND cmp_info(catproc).status = 'VALID') THEN
      tmp_varchar := cmp_info(catalog).status;
    ELSE
      tmp_varchar := 'INVALID';
    END IF;
    DisplayLine ('<Components>');
      --
      -- For Server status, use Catalog status (catalog and catproc are 
      -- skipped in the below loop)
      --
      DisplayLine ('<Component id ="Oracle Server" type="SERVER" cid="RDBMS" version="' 
                || db_version || '" status="' || tmp_varchar || '"/>');
      --
      -- Note:
      --      1,2 are catalog and catproc which are skipped 
      --
      FOR i IN 3 .. max_components LOOP
        IF cmp_info(i).processed and NOT (cmp_info(i).cid = 'WK') THEN
          IF (cmp_info(i).status = NULL) THEN
            -- If we get a NULL value, don't dump out the status
            tmp_varchar := '';
          ELSE
            -- Create the status= entry 
            tmp_varchar := ' status="' || cmp_info(i).status || '"';
          END IF;
          DisplayLine ('<Component id="'   || cmp_info(i).cname   ||
                            '" cid="'     || cmp_info(i).cid     || 
                            '" script="'  || cmp_info(i).script  || 
                            '" version="' || cmp_info(i).version || 
                            '"' || tmp_varchar || '/>');
        END IF;
      END LOOP;
   DisplayLine('</Components>');
  ELSE
    DisplayBanner;
    DisplayCenter ('[Component List]');
    DisplayBanner;

    FOR i IN 1..max_components LOOP
      IF cmp_info(i).processed THEN
        IF cmp_info(i).install THEN ui := '[install]';
        ELSE                        ui := '[upgrade]';
        END IF;
        DisplayLine(
           '--> ' || rpad(cmp_info(i).cname, 38) || ' ' ||
                     rpad(ui, 10) || ' ' ||
                     rpad(cmp_info(i).status, 10));
        IF ((cmp_info(i).cid  = 'OLS') AND 
                NOT cmp_info(dv).processed) THEN
          post_list_info := post_list_info  || crlf 
              || 'To successfully upgrade Oracle Label Security, choose ' || crlf 
              || '''Select Options'' in Oracle installer and then select ' || crlf
              || 'Oracle Label Security.';
        END IF;
      END IF;
    END LOOP;
    IF (length(post_list_info) != 0) THEN
      DisplayLine (post_list_info);
    END IF;
  END IF;
END output_components;

PROCEDURE output_resources 
--
-- This calls all the resource routines 
--
IS
BEGIN
  init_package;

  --
  -- Make sure resources are set before so 
  -- everything is re-calculated.
  --
  init_resources;

  IF db_invalid_state = TRUE THEN
    RETURN;
  END IF;
  output_tablespaces;
  output_rollback_segs;
  output_flashback;
END output_resources;

PROCEDURE output_tablespaces
IS
  resourcenum    NUMBER (38);
  changes_req BOOLEAN := FALSE;
BEGIN
  IF pOutputType = c_output_xml
  THEN
    DisplayLine('<SystemResource>');

    FOR i IN 1..max_ts LOOP
      DisplayLine (
         '<Tablespace name="' || ts_info(i).name ||
         '" additional_size="' ||
             TO_CHAR(ROUND(ts_info(i).addl)) || '"/>');

      IF pDBGSizeResources THEN
        DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' used =                    ' || LPAD(ts_info(i).inuse,10));
        DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                         ' delta=                    ' || LPAD(ts_info(i).delta,10));
        DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                         ' total req=                ' || LPAD(ts_info(i).min,10));
        DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' alloc=                    ' || LPAD(ts_info(i).alloc,10));
        DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' auto_avail=               ' || LPAD(ts_info(i).auto,10));
        DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' total avail=              ' ||  LPAD(ts_info(i).avail,10));
        DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' additional space needed = ' || LPAD(ts_info(i).addl,10));
        DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' increment by =            ' || LPAD(ts_info(i).inc_by,10));
        DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' total avail=              ' ||  LPAD(ts_info(i).avail,10));
      END IF;
    END LOOP;
    --
    -- ArchiveLogs and Flashback info 
    --
    IF db_log_mode = 'ARCHIVELOG' OR pDBGSizeResources THEN
      resourcenum := pMinArchiveLogGen;
    ELSE
      resourcenum := 0;
    END IF;
    DisplayLine (
      '<ArchiveLogs name="ArchiveLogs" additional_size="' ||
         resourcenum || '" />');

    IF db_flashback_on OR pDBGSizeResources THEN
      resourcenum := pMinFlashbackLogGen;
    ELSE
      resourcenum := 0;
    END IF;
    DisplayLine (
      '<FlashbackLogs name="FlasbackLogs" additional_size="' ||
        resourcenum || '" />');

    DisplayLine('</SystemResource>');
  ELSE
    DisplayBanner;
    IF pUnsupportedUpgrade THEN
      DisplayCenter('[ Unsupported Upgrade: Tablespace Data Supressed ]');
    ELSE 
      DisplayCenter('[Tablespaces]');
    END IF;
    DisplayBanner;

    IF max_ts > 0 and pUnsupportedUpgrade = FALSE THEN
      FOR i IN 1..max_ts LOOP
        --
        -- For debugging, dump out the allocated and used info
        --
        IF pDBGSizeResources THEN
          DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' used =                    ' || LPAD(ts_info(i).inuse,10));
          DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' delta=                    ' || LPAD(ts_info(i).delta,10));
          DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                         ' total req=                ' || LPAD(ts_info(i).min,10));
          DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' alloc=                    ' || LPAD(ts_info(i).alloc,10));
          DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' auto_avail=               ' || LPAD(ts_info(i).auto,10));
          DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' total avail=              ' ||  LPAD(ts_info(i).avail,10));
          DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' additional space needed = ' || LPAD(ts_info(i).addl,10));
          DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' increment by =            ' || LPAD(ts_info(i).inc_by,10));
          DisplayDiagLine(RPAD(ts_info(i).name,10) || 
                          ' total avail=              ' ||  LPAD(ts_info(i).avail,10));
        END IF;

        IF ts_info(i).inc_by = 0 THEN
          DisplayLine(
            '--> ' || ts_info(i).name || 
                 ' tablespace is adequate for the upgrade.');
          DisplayLine(
            '     minimum required size: ' ||
            TO_CHAR(ROUND(ts_info(i).min)) || ' MB');
        ELSE
          --  
          -- need more space in tablespace
          --
          changes_req := TRUE;
          DisplayError(ts_info(i).name || 
                      ' tablespace is not large enough for the upgrade.');
          DisplayLine(
             '     currently allocated size: ' ||
              TO_CHAR(ROUND(ts_info(i).alloc)) || ' MB');
          DisplayLine(
             '     minimum required size: ' ||
              TO_CHAR(ROUND(ts_info(i).min)) || ' MB');
          DisplayLine(
             '     increase current size by: ' ||
              TO_CHAR(ROUND(ts_info(i).inc_by)) || ' MB');

          IF ts_info(i).fauto THEN
             DisplayLine(
               '     tablespace is AUTOEXTEND ENABLED.');
          ELSE 
             DisplayLine(
              '     tablespace is NOT AUTOEXTEND ENABLED.');
          END IF;    
        END IF; 
      END LOOP;
    END IF;

    IF pUnsupportedUpgrade = FALSE THEN
        DisplayLine('');
      IF changes_req THEN
        DisplayCenter('[make adjustments in the current environment]');
      ELSE
        DisplayCenter('[No adjustments recommended]');
      END IF;
      DisplayLine('');
      DisplayBanner;
    END IF;
  END IF;   -- output type text
END output_tablespaces;

PROCEDURE output_rollback_segs 
IS
  auto VARCHAR2(3);
BEGIN
  IF pOutputType = c_output_xml THEN
    RETURN;
  END IF;

  IF max_rs > 0 THEN
    DisplayBanner;
    DisplayLine('Rollback Segments: [make adjustments ' ||
                      'immediately prior to upgrading]');
    DisplayBanner;
    -- Loop through the rs_info table
    FOR i IN 1..max_rs LOOP
      IF rs_info(i).auto > 0 THEN 
        auto:='ON'; 
      ELSE
        auto:='OFF'; 
      END IF;
      DisplayLine(
            '--> ' || rs_info(i).seg_name || ' in tablespace ' || 
                      rs_info(i).tbs_name || ' is ' || 
                      rs_info(i).status ||
                      '; AUTOEXTEND is ' || auto);
      DisplayLine(
            '     currently allocated: ' || rs_info(i).inuse 
                  || 'K');
      DisplayLine(
            '     next extent size: ' || rs_info(i).next 
                  || 'K; max extents: ' || rs_info(i).max_ext);
    END LOOP;
    DisplayWarning('For the upgrade, use a large (minimum 70M) ' ||
                         'public rollback segment');
    IF max_rs > 1 THEN
      DisplayWarning('Take smaller public rollback segments OFFLINE');
    END IF;
    DisplayLine ('');
  END IF;
END output_rollback_segs;

PROCEDURE output_flashback
IS
BEGIN

  IF pDBGSizeResources THEN
    FOR i in 1..max_comps LOOP
      IF cmp_info(i).processed THEN
        DisplayDiagLine ('Archivelog:   ' || rpad(cmp_info(i).cid,10) || ' ' ||
                         lpad(cmp_info(i).archivelog_kbytes,10));
        DisplayDiagLine ('Flashbacklog: ' || rpad(cmp_info(i).cid,10) || ' ' ||
                lpad(cmp_info(i).flashbacklog_kbytes,10));
      END IF;
    END LOOP;
  END IF;

  IF pOutputType = c_output_xml THEN
    RETURN;
  END IF;

  IF flashback_info.active OR pDBGAllResources THEN
    DisplayBanner;
    IF pUnsupportedUpgrade THEN
      DisplayCenter('[ Unsupported Upgrade: Flashback Data Supressed ]');
    ELSE 
      DisplayCenter('[Flashback Information]');
    END IF;
    DisplayBanner;
    DisplayLine ('--> name:          ' || flashback_info.name );
    DisplayLine ('--> limit:         ' || TO_CHAR( (flashback_info.limit / c_mb))          || ' MB');
    DisplayLine ('--> used:          ' || TO_CHAR( round((flashback_info.used / c_mb ),0))  || ' MB');
    DisplayLine ('--> size:          ' || TO_CHAR( (flashback_info.dsize / c_mb ))       || ' MB');
    DisplayLine ('--> reclaim:       ' || TO_CHAR( (flashback_info.reclaimable / c_mb)) || ' MB');
    DisplayLine ('--> files:         ' || TO_CHAR(flashback_info.files));
    DisplayLine ('');
    pCheckWarningCount := pCheckWarningCount + 1;
    DisplayWarning ('Flashback Database is enabled.');
    DisplayLine ('     Ensure adequate disk space exists in the flash recovery area');
    DisplayLine ('     before performing the upgrade.  Your recovery area');
    DisplayLine ('     will require at least ' 
                || TO_CHAR(ROUND((pMinArchiveLogGen + pMinFlashbacklogGen)/c_mb)) 
                || ' MB - or greater - of free space.');
    DisplayBanner;
  END IF;
END output_flashback;

PROCEDURE output_recommendations
--
-- Output both the pre and post recommendations
--
IS
BEGIN
  init_package;

  IF db_invalid_state = TRUE OR pOutputType = c_output_xml THEN
    RETURN;
  END IF;
  DisplayLine(pPreScriptUFT, 'BEGIN');
  DisplayLineBoth(pPreScriptUFT, '');
  DisplayBanner(pPreScriptUFT);
  DisplayCenter(pPreScriptUFT, '[Pre-Upgrade Recommendations]');
  DisplayBanner(pPreScriptUFT);
  DisplayLineBoth(pPreScriptUFT, '');
  DisplayLine(pPreScriptUFT, 'END;');
  DisplayLine(pPreScriptUFT, '/');

  --
  -- Dump the pre recommendations
  --
  run_all_recommend (c_type_recommend_pre);
 
  DisplayLine(pPostScriptUFT, 'BEGIN');
  DisplayBanner(pPostScriptUFT);
  DisplayCenter(pPostScriptUFT, '[Post-Upgrade Recommendations]');
  DisplayBanner(pPostScriptUFT);
  DisplayLineBoth(pPostScriptUFT, '');
  DisplayLine(pPostScriptUFT, 'END;');
  DisplayLine(pPostScriptUFT, '/');

  --
  -- Dump the post recommendations
  --
  run_all_recommend (c_type_recommend_post);
  DisplayBanner;
END output_recommendations;

--
-- A quick summary of the checks - this is the last thing
-- seen in the log file.
--  
-- The thought is, this may be the last thing seen so 
-- if there are things we REALLY need them to know, it should
-- be output here.
-- 
-- This is ONLY for TEXT output.
-- 
PROCEDURE output_prolog 
IS
  toutput VARCHAR2(1000);
  tstr    VARCHAR2(30);
BEGIN
  init_package;

  IF pOutputType = c_output_text THEN
    --
    -- Only output for non XML display
    --
    DisplayLine (CenterLine('************  Summary  ************'));
    DisplayLine (''); 

    tstr := ' ERRORS';
    toutput := ' exist that must be addressed prior to performing your upgrade.';
    IF (pCheckErrorCount = 1) THEN
      tstr := ' ERROR';
    ELSIF pCheckErrorCount = 0 THEN
      toutput := ' exist in your database.';
    END IF;
    DisplayLine (LPAD(pCheckErrorCount,2) || tstr  || toutput);

    tstr := ' WARNINGS';
    toutput := ' that Oracle suggests are addressed to improve database performance.';
    IF (pCheckWarningCount = 1) THEN
      tstr := ' WARNING';
    ELSIF pCheckWarningCount = 0 THEN
      toutput := ' exist in your database.';
    END IF;
    DisplayLine (LPAD(pCheckWarningCount,2) || tstr  || toutput);

    tstr := ' INFORMATIONAL messages';
    toutput := ' that should be reviewed prior to your upgrade.';
    If pCheckInfoCount = 1 THEN
      tstr := ' INFORMATIONAL message';
    ELSIF (pCheckInfoCount = 0) THEN
      toutput := ' messages have been reported.';
    END IF;
    DisplayLine (LPAD(pCheckInfoCount,2) || tstr || toutput);

    toutput := 
         crlf || ' After your database is upgraded and open in normal mode you must run '
      || crlf || ' rdbms/admin/catuppst.sql which executes several required tasks and completes'
      || crlf || ' the upgrade process.'
      || crlf || crlf ||   
                 ' You should follow that with the execution of rdbms/admin/utlrp.sql, and a'
      || crlf || ' comparison of invalid objects before and after the upgrade using'
      || crlf || ' rdbms/admin/utluiobj.sql'
      || crlf || crlf ||   
                 ' If needed you may want to upgrade your timezone data using the process'
      || crlf || ' described in My Oracle Support note 977512.1'
      || crlf || CenterLine('***********************************');
    DisplayLine(toutput);
  END IF;
END output_prolog;

PROCEDURE output_preup_checks
IS
BEGIN
  IF db_invalid_state = TRUE THEN
    return;
  END IF;

  IF pOutputType = c_output_xml THEN
    DisplayLine ('<PreUpgradeChecks>');
  ELSE
    DisplayBanner;
    DisplayCenter('[Pre-Upgrade Checks]');
    DisplayBanner;
  END IF;

  FOR i IN 1..pCheckCount LOOP
    --
    -- Dump out the results of the Normal checks only
    -- if they failed (and if there is something to display)
    --
    IF (check_table(i).passed = FALSE AND
        ( check_table(i).type = c_type_check OR 
          check_table(i).type = c_type_check_interactive_only)) THEN 
      DisplayLine (check_table(i).result_text);
      DisplayLine ('');
    END IF;
  END LOOP;

  IF pOutputType = c_output_xml THEN
    DisplayLine ('</PreUpgradeChecks>');
    IF pOutputtingScripts THEN
      DisplayLinePL (CenterLine('[Pre and Post Upgrade Fixup Script Have been Generated]'));
      DisplayLinePL (CenterLine('[Location: ' || get_output_path || ' ]'));
    END IF;
  END IF;
END output_preup_checks;

--
-- Dump out a summary of the checks that were run
-- and also if there are any errors that require user
-- action.
--
-- This output to TO THE TEMRINAL no matter what.
--
PROCEDURE output_check_summary
IS
  path     VARCHAR2(500);
  tsuccess NUMBER  := 0;
  tfailed  NUMBER  := 0;
  terrors  NUMBER  := 0;
  ttotal   NUMBER  := 0;
  
BEGIN
  IF db_invalid_state = TRUE THEN
    RETURN;
  END IF;

  init_package;
  IF pOutputType = c_output_text THEN
    FOR i IN 1..pCheckCount LOOP
      IF (check_table(i).executed) THEN
        IF check_table(i).passed THEN
          tsuccess := tsuccess +1;
        ELSE
          tfailed := tfailed +1;
        END IF;
        IF check_table(i).level = c_check_level_error THEN
          terrors := terrors + 1;
        END IF; 
      END IF;
    END LOOP;

    path := get_output_path;

    DisplayLinePL(CenterLine('************************************************************'));
    DisplayLinePL('');
    DisplayLinePL('Results of the checks are located at:');
    DisplayLinePL(' ' || path || 'preupgrade.log');
    DisplayLinePL('');

    If pOutputtingScripts THEN
      DisplayLinePL('Pre-Upgrade Fixup Script (run in source database environment):');
      DisplayLinePL(' ' || path || 'preupgrade_fixups.sql');
      DisplayLinePL('');

      DisplayLinePL('Post-Upgrade Fixup Script (run shortly after upgrade):');
      DisplayLinePL(' ' || path || 'postupgrade_fixups.sql');
      DisplayLinePL('');
      DisplayLinePL(CenterLine('************************************************************'));
      DisplayLinePL('');
      DisplayLinePL(CenterLine('Fixup scripts must be reviewed prior to being executed.'));
      DisplayLinePL('');
      DisplayLinePL(CenterLine('************************************************************'));
    END IF;

    IF terrors != 0 THEN
      DisplayLinePL('');
      DisplayLinePL(CenterLine('************************************************************'));
      DisplayLinePL(CenterLine('====>> USER ACTION REQUIRED  <<===='));
      DisplayLinePL(CenterLine('************************************************************'));
      DisplayLinePL('');
      --
      -- Centerline cuts off long lines so if you are changing this line, 
      -- be careful of its lenght.
      --
      DisplayLinePL(CenterLine('The following are *** ERROR LEVEL CONDITIONS *** that must be addressed'));
      DisplayLinePl(CenterLine('prior to attempting your upgrade.'));
      DisplayLinePL(CenterLine('Failure to do so will result in a failed upgrade.'));
      DisplayLinePL('');

      FOR i IN 1..pCheckCount LOOP
        IF (check_table(i).executed         AND
            check_table(i).passed  = FALSE  AND
            check_table(i).level = c_check_level_error) THEN
          ttotal := ttotal + 1;
          DisplayLinePL('');
          DisplayLinePL(LPAD(ttotal,2) || ') Check Tag:    ' || check_table(i).name);
          DisplayLinePL('    Check Summary: ' || check_table(i).descript);
          DisplayLinePL('    Fixup Summary: ');
          DisplayLinePL('     "' || getHelp(check_table(i).name,c_help_fixup) || '"');
          --
          -- Then let them know when the manual action is required.
          --
          IF (check_table(i).fix_type = c_fix_source_manual) THEN
            DisplayLinePL('    +++ Source Database Manual Action Required +++');
          ELSIF (check_table(i).fix_type = c_fix_target_manual_pre) THEN
            DisplayLinePL('   +++ Post Upgraded Database Manual Action Required +++');
          END IF;
          DisplayLinePL ('');
        END IF;
      END LOOP;

      IF ttotal = 1 THEN
        DisplayLinePL(CenterLine('You MUST resolve the above error prior to upgrade'));
      ELSE
        DisplayLinePL(CenterLine('You MUST resolve the above errors prior to upgrade'));
      END IF;
      DisplayLinePL('');
      DisplayLinePL(CenterLine('************************************************************'));
      DisplayLinePL('');
    END IF;
  END IF;  -- output type
END output_check_summary;

--
-- This is called from the pre and post fixup routines to clear out
-- the 'fixup_run' flag (in case the fixups are run multiple times).
--
-- If preup is TRUE, this is the summary for the 
-- preupgrade script.
--
PROCEDURE clear_run_flag (preup BOOLEAN) 
IS
BEGIN
  init_package;
  FOR i IN 1..pCheckCount LOOP
    check_table(i).fixup_executed := FALSE;
  END LOOP;
END clear_run_flag;

--
-- Walk through all the checks and provide a summary of how 
-- the fixup routines did.
--
-- This is intended to be run AFTER the fixup (pre or post) 
-- scripts have been executed (and is called from those 
-- scripts).
--
-- If preup is TRUE, this is the summary for the 
-- preupgrade script.
--
PROCEDURE fixup_summary (preup BOOLEAN)
IS
  tinfo    NUMBER  := 0;
  tsuccess NUMBER  := 0;
  tfailed  NUMBER  := 0;
  terrors   NUMBER := 0;
  ttotal   NUMBER  := 0;
  tinfoerrors NUMBER := 0;

BEGIN
  IF p_package_inited = FALSE THEN
    EXECUTE IMMEDIATE 'BEGIN 
      RAISE_APPLICATION_ERROR (-20000, 
            ''Pre-Upgrade Package Fixup Summary called prior to fixups being executed''); END;';
      RETURN;
  END IF;

  FOR i IN 1..pCheckCount LOOP
    --
    IF (check_table(i).fixup_executed) THEN
      ttotal := ttotal+ 1;
      IF check_table(i).fixup_status = c_fixup_status_success THEN
        tsuccess := tsuccess +1;
      ELSIF check_table(i).fixup_status = c_fixup_status_info THEN
        IF check_table(i).level = c_check_level_error  THEN
          --
          -- Fixup returned some info, but its an error level
          --
          tinfoerrors := tinfoerrors+1;
        ELSE
          tinfo := tinfo + 1;
        END IF;
      ELSIF check_table(i).fixup_status = c_fixup_status_failure THEN
        tfailed := tfailed + 1;
      END IF;
      IF (check_table(i).level = c_check_level_error AND
          check_table(i).fixup_status != c_fixup_status_success) THEN
        --
        -- This is an error level (must be fixed), that did not 
        -- succeed, 
        -- at the end of this routine, dump out a list of 
        -- these so they know they need to resolve these prior to upgrade
        --
        terrors := terrors+1;
      END IF;
    END IF;
  END LOOP;
  --
  -- Output counts.
  -- 
  DisplayLinePL('');
  DisplayLinePL(CenterLine('**************************************************'));
  DisplayLinePL(CenterLine('************* Fixup Summary ************'));
  DisplayLinePL('');
  IF ttotal = 0 THEN
    DisplayLinePL('No fixup routines were executed.');
    DisplayLinePL('');
    DisplayLinePL(CenterLine('**************************************************'));
    RETURN;
  END IF;

  IF tsuccess = 1 THEN

    DisplayLinePL(' 1 fixup routine was successful.');

  ELSIF tsuccess = 0 THEN
    -- 
    -- If all we had was 'info' routines, then displaying
    -- that none were successful doesn't sound correct
    -- so take that into account here by seeing if infocount
    -- is the same as total.
    --
    IF ttotal = tinfo THEN

      IF tinfo = 1 THEN
        DisplayLinePL(' 1 fixup routine generated an INFORMATIONAL message that should be reviewed.');
      ELSE
        -- we know its not zero.
        DisplayLinePL(LPAD(tinfo,2) || ' fixup routines generated INFORMATIONAL messages that should be reviewed.');
      END IF;
    END IF;

  ELSE
    DisplayLinePL(LPAD(tsuccess,2) || ' fixup routines were successful.');
  END IF;

  IF tinfo != ttotal THEN
    --
    -- If they are equal, the message is taken care of
    -- in the tsuccess block above (all that ran returned info messages.
    --
    IF tinfo = 1 THEN
      DisplayLinePL(' 1 fixup routine returned INFORMATIONAL text that should be reviewed.');
    ELSE
      DisplayLinePL(LPAD(tinfo,2) || ' fixup routines returned INFORMATIONAL text that should be reviewed.');
    END IF;
  END IF;

  IF tinfoerrors != 0 THEN
    IF tinfoerrors = 1 THEN 
      DisplayLinePL(' 1 ERROR LEVEL check returned INFORMATION that must be acted on prior to upgrade.');
    ELSE 
      DisplayLinePL(LPAD(tinfoerrors,2) || ' ERROR LEVEL checks returned INFORMATION that must be acted on prior to upgrade.');
    END IF;
  END IF;

  IF tfailed = 1 THEN 
    DisplayLinePL(' 1 fixup routine failed to execute. The output must be reviewed.');
  ELSIF tfailed != 0 THEN
    DisplayLinePL(LPAD(tfailed,2) || ' fixup routines failed to execute. The output must be reviewed.');
  END IF;

  --
  -- If there is an error level check that was run and did not succeed,
  -- make sure we report that they MUST RESOLVE this.
  --
  IF terrors != 0 THEN
    DisplayLinePL('');
    DisplayLinePL(CenterLine('************************************************************'));
    DisplayLinePL(CenterLine('====>> USER ACTION REQUIRED  <<===='));
    DisplayLinePL(CenterLine('************************************************************'));

    ttotal := 0;  -- reuse this variable.
    FOR i IN 1..pCheckCount LOOP
      --
      IF (check_table(i).level = c_check_level_error AND
          check_table(i).fixup_status != c_fixup_status_success) THEN
        --
        -- Report this as a MUST FIX
        --
        ttotal := ttotal + 1;
        DisplayLinePL('');
        DisplayLinePL(LPAD(ttotal,2) || ') Check Tag:    ' || check_table(i).name || ' failed.');
        DisplayLinePL('    Check Summary: ' || check_table(i).descript);
        DisplayLinePL('    Fixup Summary: ');
        DisplayLinePL('     "' || getHelp(check_table(i).name,c_help_fixup) || '"');
        IF check_table(i).fix_type IN (c_fix_source_manual, 
                                       c_fix_target_manual_pre, 
                                       c_fix_target_manual_post) THEN
          --
          -- If this is a manual situation, let them know they have
          -- something to do (may be redundant given the block we are in but...)
          --
          DisplayLinePL('    ' || pActionRequired);
        END IF;
      END IF;
    END LOOP;

    DisplayLinePL('');
    DisplayLinePL(CenterLine('**************************************************'));
    IF ttotal = 1 THEN
      DisplayLinePL(CenterLine('You MUST resolve the above error prior to upgrade'));
    ELSE
      DisplayLinePL(CenterLine('You MUST resolve the above errors prior to upgrade'));
    END IF;
    DisplayLinePL(CenterLine('**************************************************'));
    DisplayLinePL('');
  END IF;
  DisplayLinePL('');
END fixup_summary;

-- ***************************************************************************
--                             Specific Check Area 
-- ***************************************************************************


-- *****************************************************************
--     AMD_EXISTS Section 
-- *****************************************************************
FUNCTION amd_exists_check (result_txt OUT VARCHAR2) RETURN number
IS
  n_status NUMBER := -1;
BEGIN
  --
  -- Is AMD around?
  -- 
  BEGIN
    EXECUTE IMMEDIATE
       'SELECT  status FROM sys.registry$ WHERE cid=''AMD'' 
          AND namespace=''SERVER'''
       INTO n_status;
  EXCEPTION
      WHEN OTHERS THEN NULL; -- AMD not in registry
  END;      

  IF n_status = -1 AND pDBGFailCheck = FALSE OR pOutputType = c_output_xml THEN
    -- AMD not in registry
    -- or output is XML, return success
    RETURN c_status_success;
  END IF;

  --
  -- This is a manual only check
  --
  result_txt := amd_exists_gethelp(c_help_overview);

  IF pOutputtingScripts THEN
      genFixup ('AMD_EXISTS');
  END IF;
  RETURN c_status_failure;

END amd_exists_check ;

FUNCTION amd_exists_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'INFORMATION: --> OLAP Catalog(AMD) exists in database' || crlf 
     || crlf || '     Starting with Oracle Database 12c, OLAP is desupported.'
     || crlf || '     If you are not using the OLAP Catalog component and want' 
     || crlf || '     to remove it, then execute the '
     || crlf || '     ORACLE_HOME/oraolap/admin/catnoamd.sql script before or '
     || crlf || '     after the upgrade.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Manually execute ORACLE_HOME/oraolap/admin/catnoamd.sql script to remove OLAP.';
  END IF;
END amd_exists_gethelp;
--
PROCEDURE amd_exists_fixup 
IS
  result   VARCHAR2(1000);
  status   NUMBER;
  tSqlcode  NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := amd_exists_fixup (result, tSqlcode);
END amd_exists_fixup;

FUNCTION amd_exists_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := amd_exists_gethelp(c_help_overview);
   pSqlcode := 0;
   return c_fixup_status_info;
END amd_exists_fixup;


-- *****************************************************************
--     AUDIT_ADMIN_ROLE_PRESENT Section
-- *****************************************************************
FUNCTION AAR_PRESENT_check (result_txt OUT VARCHAR2) RETURN number
IS
  roll_exists NUMBER := 1;
  t_null      CHAR(1);
  status      NUMBER;
BEGIN
  IF (db_n_version NOT IN (102,111,112) AND pDBGFailCheck = FALSE) THEN
    return c_status_not_for_this_version;
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 
     'SELECT NULL FROM sys.user$ WHERE name=''AUDIT_ADMIN'''
      INTO t_null;
    EXCEPTION 
      WHEN NO_DATA_FOUND then roll_exists := 0;
  END;

  IF (roll_exists = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('AUDIT_ADMIN_ROLE_PRESENT', 
        c_check_level_error,
	'A user or role named "AUDIT_ADMIN" found in the database.',
	'A user or role named "AUDIT_ADMIN" found in the database.',
        '"AUDIT_ADMIN" role or user must be dropped prior to upgrading.',
	 c_dbua_detail_type_text,
        'To drop the role "AUDIT_ADMIN", use the command: '||
        ' DROP ROLE AUDIT_ADMIN,' || ' and To drop user "AUDIT_ADMIN"'||
        ' use the command: DROP USER AUDIT_ADMIN CASCADE',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := AAR_PRESENT_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('AUDIT_ADMIN_ROLE_PRESENT');
    END IF;
    RETURN c_status_failure;
   END IF;
END AAR_PRESENT_check;

FUNCTION AAR_PRESENT_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> A user or role with the name "AUDIT_ADMIN" found in the database.' || crlf 
      || crlf || '     This is an Oracle defined role.'
      || crlf || '     You must drop this role or user prior to upgrading.';
  ELSIF HelpType = c_help_fixup THEN
    return 'The AUDIT_ADMIN roll must be dropped prior to upgrading.';
  END IF;
END AAR_PRESENT_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE AAR_PRESENT_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := AAR_PRESENT_fixup (result, tSqlcode);
END AAR_PRESENT_fixup;

FUNCTION AAR_PRESENT_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  result_txt :=  AAR_PRESENT_gethelp(c_help_overview);
  pSqlcode := 0;
  return c_fixup_status_info;
END AAR_PRESENT_fixup;
-- *****************************************************************
--     APPQOSSYS_USER_PRESENT Section
-- *****************************************************************
FUNCTION APPQOSSYS_USER_PRESENT_check (result_txt OUT VARCHAR2) RETURN number
IS
  user_exists BOOLEAN;
  tmp_num1    NUMBER;
  t_null      CHAR(1);
  status      NUMBER;

BEGIN
  user_exists := TRUE;  -- Assume its around

  IF (db_n_version NOT IN (102) AND pDBGFailCheck = FALSE) THEN
    return c_status_not_for_this_version;
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 'SELECT user# FROM sys.user$ WHERE name=''APPQOSSYS'''
      INTO tmp_num1;
    EXCEPTION 
      WHEN NO_DATA_FOUND then user_exists := FALSE;
  END;

  IF user_exists THEN
    BEGIN
      EXECUTE IMMEDIATE 
       'SELECT NULL FROM sys.obj$ WHERE owner# = (SELECT user# from SYS.USER$ 
         WHERE name=''APPQOSSYS'') AND 
           name =''WLM_METRICS_STREAM'' AND  type# = 2'
      INTO t_null;
    EXCEPTION 
      WHEN NO_DATA_FOUND then user_exists := TRUE;
    END;
  END IF;

  IF user_exists = FALSE AND pDBGFailCheck = FALSE
  THEN
   RETURN c_status_success; -- No issue
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('APPQOSSYS_USER_PRESENT', 
        c_check_level_warning,
	'User APPQOSSYS present in database',
	'User APPQOSSYS present in database',
        'Remove APPQOSYS user from database.',
	 c_dbua_detail_type_text,
        'The APPQOSSYS user exists in the database.'
          || ' This is an internal account and should be '
          || ' removed prior to upgrading your database',
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre);
    ELSE
      result_txt := appqossys_user_present_gethelp (c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('APPQOSSYS_USER_PRESENT');
    END IF;
    RETURN c_status_failure;
   END IF;
END APPQOSSYS_USER_PRESENT_check;

FUNCTION APPQOSSYS_USER_PRESENT_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> "APPQOSSYS" user found in database.' || crlf 
      || crlf || '     This is an internal account used by '
      || crlf || '     Oracle Application Quality of Service Management. '
      || crlf || '     Please drop this user prior to upgrading.';
  ELSIF HelpType = c_help_fixup THEN
    return 'The APPQOSSYS user will will be dropped.';
  END IF;
END APPQOSSYS_USER_PRESENT_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE APPQOSSYS_USER_PRESENT_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := APPQOSSYS_USER_PRESENT_fixup (result, tSqlcode);
END APPQOSSYS_USER_PRESENT_fixup;

FUNCTION APPQOSSYS_USER_PRESENT_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   return execute_sql_statement ('DROP USER APPQOSSYS CASCADE', result_txt, pSqlcode);
END APPQOSSYS_USER_PRESENT_fixup;
-- *****************************************************************
--     AUDSYS_USER_PRESENT Section
-- *****************************************************************
FUNCTION AUDSYS_USER_PRESENT_check (result_txt OUT VARCHAR2) RETURN number
IS
  user_exists NUMBER := 1;
  t_null      CHAR(1);
  status      NUMBER;
BEGIN
  IF (db_n_version NOT IN (102,111,112) AND pDBGFailCheck = FALSE) THEN
    return c_status_not_for_this_version;
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 
     'SELECT NULL FROM sys.user$ WHERE name = ''AUDSYS'''
      INTO t_null;
    EXCEPTION 
      WHEN NO_DATA_FOUND then user_exists := 0;
  END;
  IF (user_exists = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('AUDSYS_USER_PRESENT', 
        c_check_level_error,
	'A user or role named "AUDSYS" found in the database.',
	'A user or role named "AUDSYS" found in the database.',
        '"AUDSYS" user or role must be dropped prior to upgrading.',
	 c_dbua_detail_type_text,
        'To drop the user "AUDSYS", use the command: '||
        'DROP USER AUDSYS CASCADE'||', and To drop the role "AUDSYS", use the'||
        'command: DROP ROLE AUDSYS',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := AUDSYS_USER_PRESENT_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('AUDSYS_USER_PRESENT');
    END IF;
    RETURN c_status_failure;
   END IF;
END AUDSYS_USER_PRESENT_check;

FUNCTION AUDSYS_USER_PRESENT_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> A user or role with the name "AUDSYS" found in the database.' || crlf
      || crlf || '     This is an internal account used by Oracle Database Auditing.'
      || crlf || '     You must drop this user or role prior to upgrading.';
  ELSIF HelpType = c_help_fixup THEN
    return 'The AUDSYS user or roll must be dropped prior to upgrading.';
  END IF;
END AUDSYS_USER_PRESENT_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE AUDSYS_USER_PRESENT_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := AUDSYS_USER_PRESENT_fixup (result, tSqlcode);
END AUDSYS_USER_PRESENT_fixup;

FUNCTION AUDSYS_USER_PRESENT_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  result_txt  := AUDSYS_USER_PRESENT_gethelp(c_help_overview);
  pSqlcode := 0;
  return c_fixup_status_info;
END AUDSYS_USER_PRESENT_fixup;

-- *****************************************************************
--     AUDIT_VIEWER Section
-- *****************************************************************
FUNCTION AUDIT_VIEWER_check (result_txt OUT VARCHAR2) RETURN number
IS
  roll_exists NUMBER := 1;
  t_null      CHAR(1);
  status      NUMBER;
BEGIN

  IF (db_n_version NOT IN (102,111,112) AND pDBGFailCheck = FALSE) THEN
    return c_status_not_for_this_version;
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 
     'SELECT NULL FROM sys.user$ WHERE NAME = ''AUDIT_VIEWER'''
      INTO t_null;
    EXCEPTION 
      WHEN NO_DATA_FOUND then roll_exists := 0;
  END;

  IF (roll_exists = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('AUDIT_VIEWER', 
        c_check_level_error,
	'A user or role named "AUDIT_VIEWER" found in the database.',
	'A user or role named "AUDIT_VIEWER" found in the database.',
        '"AUDIT_VIEWER" role or user must be dropped prior to upgrading.',
	 c_dbua_detail_type_text,
        'To drop the role "AUDIT_VIEWER", use the command:'
        || ' DROP ROLE AUDIT_VIEWER' || ', and To drop the user "AUDIT_VIEWER"'
        || ' use the command: DROP USER AUDIT_VIEWER CASCADE',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := AUDIT_VIEWER_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('AUDIT_VIEWER');
    END IF;
    RETURN c_status_failure;
   END IF;
END AUDIT_VIEWER_check;

FUNCTION AUDIT_VIEWER_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> A user or role with the name "AUDIT_VIEWER" found in the database.' || crlf
      || crlf || '     This is an Oracle defined role.'
      || crlf || '     You must drop this role or user prior to upgrading.';
  ELSIF HelpType = c_help_fixup THEN
    return 'The AUDIT_VIEWER roll or user must be dropped prior to upgrading.';
  END IF;
END AUDIT_VIEWER_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE AUDIT_VIEWER_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := AUDIT_VIEWER_fixup (result, tSqlcode);
END AUDIT_VIEWER_fixup;

FUNCTION AUDIT_VIEWER_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  result_txt := AUDIT_VIEWER_gethelp(c_help_overview);
  pSqlcode := 0;
  return c_fixup_status_info;
END AUDIT_VIEWER_fixup;
-- *****************************************************************
--     AWR_DBIDS_PRESENT Section
-- *****************************************************************
FUNCTION AWR_DBIDS_PRESENT_check (result_txt OUT VARCHAR2) RETURN number
IS
  roll_exists NUMBER := 1;
  t_null      CHAR(1);
  status      NUMBER;
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 
     'SELECT NULL FROM sys.wrm$_wr_control WHERE dbid != (SELECT dbid FROM v$database)'
      INTO t_null;
    EXCEPTION 
      WHEN NO_DATA_FOUND then roll_exists := 0;
  END;

  IF (roll_exists = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('AWR_DBIDS_PRESENT', 
        c_check_level_warning,
	'Inactive DBIDs found in AWR',
	'Inactive DBIDs found in AWR.',
        'The inactive DBIDs in AWR may need additional updating after ' ||
        'upgrading.',
	 c_dbua_detail_type_text,
        'To update the inactive DBIDs in AWR, run the script awrupd12.sql as SYSDBA',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_post );
    ELSE
      result_txt := AWR_DBIDS_PRESENT_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('AWR_DBIDS_PRESENT');
    END IF;
    RETURN c_status_failure;
   END IF;
END AWR_DBIDS_PRESENT_check;

FUNCTION AWR_DBIDS_PRESENT_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> Inactive DBIDs found in AWR' || crlf 
      || crlf || '     AWR contains inactive DBIDs which may need additional updating after' || crlf || '     upgrading.';
  ELSIF HelpType = c_help_fixup THEN
    return 'The inactive DBIDs in AWR may need additional updating after upgrading.';
  END IF;
END AWR_DBIDS_PRESENT_gethelp;

--
-- Fixup (Procedure and function)
--
PROCEDURE AWR_DBIDS_PRESENT_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := AWR_DBIDS_PRESENT_fixup (result, tSqlcode);
END AWR_DBIDS_PRESENT_fixup;

FUNCTION AWR_DBIDS_PRESENT_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  result_txt := AWR_DBIDS_PRESENT_gethelp(c_help_overview);
  pSqlcode := 0;
  return c_fixup_status_info;
END AWR_DBIDS_PRESENT_fixup;

-- *****************************************************************
--     compatible_parameter Section
-- *****************************************************************
FUNCTION compatible_parameter_check (result_txt OUT VARCHAR2) RETURN number
IS
  status      NUMBER;
BEGIN
  --
  -- If we have the correct min compat and not debug and not XML
  -- return success.
  --
  IF ((db_compat_majorver >= c_compat_min_num AND pDBGFailCheck = FALSE)  OR
      pOutputType = c_output_xml)  THEN
    RETURN c_status_success;
  END IF;

  result_txt := compatible_parameter_gethelp(c_help_overview);
  IF pOutputtingScripts THEN
    genFixup ('COMPATIBLE_PARAMETER');
  END IF;
  RETURN c_status_failure;
END compatible_parameter_check;

FUNCTION compatible_parameter_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS
  result_txt VARCHAR2(1500);
BEGIN
  IF HelpType = c_help_overview THEN
    result_txt := 'ERROR: --> Compatible set too low' || crlf 
      || crlf || '     "compatible" currently set at ' || db_compat ||    ' and must'
      || crlf || '     be set to at least '           || c_compat_min || ' prior to upgrading the database.';

    IF db_n_version = 102 THEN
      result_txt := result_txt 
          || crlf || '     Do not make this change until you are ready to upgrade' 
          || crlf || '     because a downgrade back to 10.2 is not possible once compatible'
          || crlf || '     has been raised.';
    END IF;
    result_txt := result_txt 
       || crlf || crlf || '     Update your init.ora or spfile to make this change.';
  ELSIF HelpType = c_help_fixup THEN
    result_txt := '"compatible" parameter must be increased manually prior to upgrade.';
  END IF;
  RETURN result_txt;
END compatible_parameter_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE compatible_parameter_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := compatible_parameter_fixup (result, tSqlcode);
END compatible_parameter_fixup;

FUNCTION compatible_parameter_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := compatible_parameter_gethelp(c_help_overview);
   pSqlcode := 0;
   return c_fixup_status_info;
END compatible_parameter_fixup;

-- *****************************************************************
--     DBMS_LDAP_DEPENDENCIES_EXIST Section
-- *****************************************************************
FUNCTION DBMS_LDAP_DEP_EXIST_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_null      CHAR(1);
  status      NUMBER := 0;
BEGIN

  BEGIN
    EXECUTE IMMEDIATE 'SELECT NULL FROM dba_dependencies
        WHERE referenced_name IN (''DBMS_LDAP'')
        AND owner NOT IN (''SYS'',''PUBLIC'',''ORD_PLUGINS'')
        AND rownum <= 1'
    INTO t_null;
      status := 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN NULL;
  END;

  IF (status = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('DBMS_LDAP_DEPENDENCIES_EXIST', 
        c_check_level_warning,
	'Database contains schemas with objects dependent on DBMS_LDAP package.'
          || ' Refer to the Upgrade Guide for instructions to configure Network ACLs.',
	'Database contains schemas with objects dependent on DBMS_LDAP package.',
        'Refer to the Upgrade Guide for instructions to configure Network ACLs.',
	 c_dbua_detail_type_sql,
        htmlentities('SELECT name FROM dba_dependencies WHERE'
           || ' referenced_name IN (''DBMS_LDAP'') '
           || ' AND owner NOT IN (''SYS'',''PUBLIC'',''ORD_PLUGINS'')'
           || ' AND rownum <= 1'),
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := DBMS_LDAP_DEP_EXIST_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('DBMS_LDAP_DEPENDENCIES_EXIST');
    END IF;
    RETURN c_status_failure;
   END IF;
END DBMS_LDAP_DEP_EXIST_check;

FUNCTION DBMS_LDAP_DEP_EXIST_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS
  tmp_cursor   cursor_t;
  tmp_varchar1 VARCHAR2(512);
  tstr         VARCHAR2(1000);
  result_txt   VARCHAR2(1500);
BEGIN
  IF HelpType = c_help_overview THEN
    result_txt := 'WARNING: --> Existing DBMS_LDAP dependent objects' || crlf 
      || crlf || '     Database contains schemas with objects dependent on DBMS_LDAP package.'
      || crlf || '     Refer to the Upgrade Guide for instructions to configure Network ACLs.';
    tstr := '';
    OPEN tmp_cursor FOR 
      'SELECT DISTINCT owner FROM DBA_DEPENDENCIES
         WHERE referenced_name IN (''DBMS_LDAP'')
             AND owner NOT IN (''SYS'',''PUBLIC'',''ORDPLUGINS'')';
    LOOP
      FETCH tmp_cursor INTO tmp_varchar1;
      EXIT WHEN tmp_cursor%NOTFOUND;
      tstr := tstr || crlf || '     USER ' || tmp_varchar1 || ' has dependent objects.';
    END LOOP;
    IF (tstr IS NOT NULL OR tstr != '' ) THEN
      result_txt := result_txt || tstr;
    END IF;
    CLOSE tmp_cursor;
  ELSIF HelpType = c_help_fixup THEN
    result_txt := 'Network Objects must be reviewed manually.';
  END IF;
  RETURN result_txt;
END DBMS_LDAP_DEP_EXIST_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE DBMS_LDAP_DEP_EXIST_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := DBMS_LDAP_DEP_EXIST_fixup (result, tSqlcode);
END DBMS_LDAP_DEP_EXIST_fixup;

FUNCTION DBMS_LDAP_DEP_EXIST_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := DBMS_LDAP_DEP_EXIST_gethelp(c_help_overview);
   return c_fixup_status_info;
END DBMS_LDAP_DEP_EXIST_fixup;

-- *****************************************************************
--     default_process_count Section
-- *****************************************************************
FUNCTION default_process_count_check (result_txt OUT VARCHAR2) RETURN number
IS
  processes NUMBER;
  status    NUMBER;
BEGIN
  EXECUTE IMMEDIATE 'SELECT value FROM V$PARAMETER WHERE NAME=''processes'''
    INTO processes;
  --
  -- Right number of processes (and not debug) or XML
  -- output, return success
  --
  IF ( (processes >= c_max_processes AND  pDBGFailCheck = FALSE) OR
      pOutputType = c_output_xml ) THEN
    RETURN c_status_success;
  END IF;

  result_txt := default_process_count_gethelp(c_help_overview);

  IF pOutputtingScripts THEN
    genFixup ('DEFAULT_PROCESS_COUNT');
  END IF;
  RETURN c_status_failure;
END default_process_count_check;

FUNCTION default_process_count_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
  processes NUMBER;
BEGIN
  IF HelpType = c_help_overview THEN
    EXECUTE IMMEDIATE 'SELECT value FROM V$PARAMETER WHERE NAME=''processes'''
      INTO processes;
    return 'WARNING: --> Process Count may be too low' || crlf 
     || crlf || '     Database has a maximum process count of '
                    || processes || ' which is lower than the'
     || crlf || '     default value of ' || c_max_processes || ' for this release.'
     || crlf || '     You should update your processes value prior to the upgrade'
     || crlf || '     to a value of at least ' || c_max_processes || '.'
     || crlf || '     For example:'
     || crlf || '        ALTER SYSTEM SET PROCESSES=' || c_max_processes || ' SCOPE=SPFILE'
     || crlf || '     or update your init.ora file.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Review and increase if needed, your PROCESSES value.';
  END IF;
END default_process_count_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE default_process_count_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := default_process_count_fixup (result, tSqlcode);
END default_process_count_fixup;

FUNCTION default_process_count_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := default_process_count_gethelp(c_help_overview);
   return c_fixup_status_info;
END default_process_count_fixup;

-- *****************************************************************
--     DV_ENABLED Section
-- *****************************************************************
FUNCTION DV_ENABLED_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_null      CHAR(1);
  status      NUMBER;
BEGIN

  IF (db_n_version IN (102,111,112) and pDBGFailCheck = FALSE) THEN
    -- 12.1 and above...
    return c_status_not_for_this_version;
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 'SELECT NULL FROM sys.registry$ r, v$option o
         WHERE r.cid = ''DV'' and r.cname = o.parameter and 
          o.value = ''TRUE'''
    INTO t_null;
    status := 1;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
        status := 0;
  END;

  IF (status = 0 and pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('DV_ENABLED', 
        c_check_level_info,
	'Database Vault option is enabled. Database Vault is disabled during upgrade'
         || ' and re-enabled after the upgrade.',
	'Database Vault option is enabled.',
        'Disable the Database Vault option prior to Upgrade',
	 c_dbua_detail_type_sql,
         htmlentities ('SELECT r.cid FROM sys.registry$ r, v$option o '
            || 'WHERE r.cid = ''DV'' and r.cname = o.parameter and ' 
            || 'o.value = ''TRUE'''),
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := DV_ENABLED_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('DV_ENABLED');
    END IF;
    RETURN c_status_failure;
  END IF;
END;

FUNCTION DV_ENABLED_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> Oracle Database Vault is enabled in this database' || crlf 
      || crlf || '     Starting with release 12.1, it is REQUIRED that Database Vault be'
      || crlf || '     disabled prior to database upgrade. To disable Database Vault, log'
      || crlf || '     in as Database Vault administrator and run this operation:'
      || crlf || '     DVSYS.DBMS_MACAMD.DISABLE_DV()';
  ELSIF HelpType = c_help_fixup THEN
    return 'Database Vault must be disabled prior to upgrading.';
  END IF;
END DV_ENABLED_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE DV_ENABLED_fixup 
IS
  result  VARCHAR2(1500);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := DV_ENABLED_fixup (result, tSqlcode);
END DV_ENABLED_fixup;

FUNCTION DV_ENABLED_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := DV_ENABLED_gethelp(c_help_overview);
  return c_fixup_status_info;
END DV_ENABLED_fixup;

-- *****************************************************************
--     EM_PRESENT Section
-- *****************************************************************
FUNCTION EM_PRESENT_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_null      CHAR(1);
  status      NUMBER;
BEGIN

  BEGIN
    EXECUTE IMMEDIATE  'SELECT NULL FROM sys.registry$ WHERE cid=''EM'' 
      AND status NOT IN (99,8)'
    INTO  t_null;
      status := 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
      status := 0;
  END;

  IF (status = 0 and pDBGFailCheck = FALSE)
  THEN
    -- EM not here.
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('EM_PRESENT', 
        c_check_level_info,
	'Enterprise Manager Database Control repository exists in the database.'
         || ' In 12c, the database is managed by MiniGC.'
         || ' The Enterprise Manager database Control Repository is removed during the upgrade',
	'Enterprise Manager Database Control repository is removed',
        'Enterprise Manager data can be migrated.',
	 c_dbua_detail_type_text,
        'The EM Database data can be migrated/removed prior to upgrade.',
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := EM_PRESENT_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('EM_PRESENT');
    END IF; 
   RETURN c_status_failure;
   END IF;
END;

FUNCTION EM_PRESENT_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> Enterprise Manager Database Control repository found in the database' || crlf 
           || crlf || '     In Oracle Database 12c, Database Control is removed during'
           || crlf || '     the upgrade. To save time during the Upgrade, this action'
           || crlf || '     can be done prior to upgrading using the following steps after'
           || crlf || '     copying rdbms/admin/emremove.sql from the new Oracle home'
           || crlf || '   - Stop EM Database Control:'
           || crlf || '    $> emctl stop dbconsole'
           || crlf  
           || crlf || '   - Connect to the Database using the SYS account AS SYSDBA:' 
           || crlf  
           || crlf || '   SET ECHO ON;'
           || crlf || '   SET SERVEROUTPUT ON;'
           || crlf || '   @emremove.sql'
           || crlf || '     Without the set echo and serveroutput commands you will not '
           || crlf || '     be able to follow the progress of the script.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Execute emremove.sql prior to upgrade.';
  END IF;
END;
--
-- Fixup (Procedure and function)
--
PROCEDURE EM_PRESENT_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := EM_PRESENT_fixup (result, tSqlcode);
END;
FUNCTION EM_PRESENT_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- The removal is done during the upgrade.
  -- Dump out the same thing we give for help
  result_txt := EM_PRESENT_gethelp(c_help_overview);
  return c_fixup_status_info;
END;

-- *****************************************************************
--     ENABLED_INDEXES_TBL Section
-- *****************************************************************
FUNCTION ENABLED_INDEXES_TBL_check (result_txt OUT VARCHAR2) RETURN number
IS
  status  NUMBER := 0;
  t_count   INTEGER;
BEGIN
  --
  -- Check for pre-existing temporary table sys.enabled$indexes.
  -- If it exists, then warn the user to DROP SYS.ENABLED$INDEXES.
  --
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM sys.enabled$indexes'
    INTO t_count;
    IF (t_count >= 0) THEN
      status := 1;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;

  IF (status = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('ENABLED_INDEXES_TBL', 
        c_check_level_warning,
	'Table sys.enabled$indexes exists in the database',
	'Table sys.enabled$indexes exists in the database',
        'Drop table prior to upgrade.',
	 c_dbua_detail_type_text,
        'To view if enabled indexes execute, execute the following'
          || ' query: SELECT COUNT(1) FROM SYS.ENABLED$INDEXES',
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre);
    ELSE
      result_txt := ENABLED_INDEXES_TBL_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('ENABLED_INDEXES_TBL');
    END IF;
    RETURN c_status_failure;
   END IF;
END ENABLED_INDEXES_TBL_check;

FUNCTION ENABLED_INDEXES_TBL_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> Table sys.enabled$indexes exists in the database' || crlf
     || crlf || '     DROP TABLE sys.enabled$indexes prior to upgrading the database.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Drop table sys.enabled$indexes.';
  END IF;
END ENABLED_INDEXES_TBL_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE ENABLED_INDEXES_TBL_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := ENABLED_INDEXES_TBL_fixup (result, tSqlcode);
END ENABLED_INDEXES_TBL_fixup;

FUNCTION ENABLED_INDEXES_TBL_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   return execute_sql_statement ('DROP TABLE sys.enabled$indexes', result_txt, pSqlcode);
END ENABLED_INDEXES_TBL_fixup;

-- *****************************************************************
--     EXF_RUL_EXISTS Section 
-- *****************************************************************
FUNCTION exf_rul_exists_check (result_txt OUT VARCHAR2) RETURN number
IS
  n_status NUMBER := -1;
BEGIN
  --
  -- See if EXF and/or RUL components exist, they will be 
  -- removed during the upgrade so let them know they can remove them 
  -- before the upgrade.
  -- 
  BEGIN
    EXECUTE IMMEDIATE
       'SELECT  status FROM sys.registry$ WHERE (cid=''RUL'' OR cid=''EXF'')
          WHERE namespace=''SERVER'''
       INTO n_status;
  EXCEPTION
      WHEN OTHERS THEN NULL; -- EXF or RUL not in registry
  END;      

  IF n_status = -1 AND pDBGFailCheck = FALSE THEN 
    --
    -- does not exist
    --
    return c_status_success;
  END IF;

  IF pOutputType = c_output_xml THEN
    result_txt:= genDBUAXMLCheck('EXF_RUL_EXIST', 
        c_check_level_info,
	'Expression Filter (EXF) or Rules Manager (RUL) exist in database.',
	'Expression Filter (EXF) and Rules Manager (RUL) are desupported in 12.1.',
        'Expression Filter (EXF) and Rules Manager (RUL) will be removed during the upgrade.',
	 c_dbua_detail_type_text,
        htmlentities('To drop EXF and RUL prior to upgrade'||
        ' execute @?/rdbms/admin/catnoexf.sql script'),
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre );
    ELSE
    result_txt := exf_rul_exists_gethelp(c_help_overview);
  END IF;

  IF pOutputtingScripts THEN
      genFixup ('EXF_RUL_EXISTS');
  END IF;
  RETURN c_status_failure;
END exf_rul_exists_check ;

FUNCTION exf_rul_exists_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'INFORMATION: --> Expression Filter (EXF) or Rules Manager (RUL) exist in database and will be removed during the upgrade.' || crlf
     || crlf || '     Starting with Oracle Database release 12.1, the Expression Filter (EXF) and Database Rules Manager (RUL)' 
     || crlf || '     features are desupported and will be removed during the upgrade process.  To save time during'
     || crlf || '     the upgrade, this action can be done prior to upgrading by executing the ORACLE_HOME/rdbms/admin/catnoexf.sql script.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Manually execute ORACLE_HOME/rdbms/admin/catnoexf.sql script to remove EXF and RUL.';
  END IF;
END exf_rul_exists_gethelp;
--
PROCEDURE exf_rul_exists_fixup 
IS
  result   VARCHAR2(1000);
  status   NUMBER;
  tSqlcode  NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := exf_rul_exists_fixup (result, tSqlcode);
END exf_rul_exists_fixup;

FUNCTION exf_rul_exists_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := exf_rul_exists_gethelp(c_help_overview);
   pSqlcode := 0;
   return c_fixup_status_info;
END exf_rul_exists_fixup;

-- *****************************************************************
--     FILES_NEED_RECOVERY Section
-- *****************************************************************
FUNCTION FILES_NEED_RECOVERY_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_null      CHAR(1);
  status      NUMBER;
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'SELECT NULL FROM v$recover_file WHERE rownum <=1'
    INTO t_null;
    status := 1;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN status := 0;
   END;

  IF (status = 0 and pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('FILES_NEED_RECOVERY', 
        c_check_level_warning,
	'There are files that need media recovery. Ensure no files need media recovery prior to upgrade.',
	'There are files that need media recovery.',
        'Ensure no files need recovery.',
	 c_dbua_detail_type_sql,
        htmlentities ('SELECT count(*) FROM v$recover_file WHERE rownum <=1'),
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := FILES_NEED_RECOVERY_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('FILES_NEED_RECOVERY');
    END IF;
    RETURN c_status_failure;
   END IF;
END;

FUNCTION FILES_NEED_RECOVERY_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> There are files which need media recovery' || crlf
      || crlf || '     Ensure no files need media recovery prior to upgrade.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Recover or repair these files prior to upgrade.';
  END IF;
END FILES_NEED_RECOVERY_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE FILES_NEED_RECOVERY_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := FILES_NEED_RECOVERY_fixup (result, tSqlcode);
END FILES_NEED_RECOVERY_fixup;

FUNCTION FILES_NEED_RECOVERY_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- The removal is done during the upgrade.
  -- Dump out the same thing we give for help
  result_txt := FILES_NEED_RECOVERY_gethelp(c_help_overview);
  return c_fixup_status_info;
END FILES_NEED_RECOVERY_fixup;

-- *****************************************************************
--     FILES_BACKUP_MODE Section
-- *****************************************************************
FUNCTION FILES_BACKUP_MODE_check (result_txt OUT VARCHAR2) RETURN number
IS
  roll_exists NUMBER := 1;
  t_null      CHAR(1);
  status      NUMBER;
BEGIN

  IF (db_n_version NOT IN (102,111,112) and pDBGFailCheck = FALSE) THEN
    return c_status_not_for_this_version;
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 
     'SELECT NULL FROM sys.user$ WHERE (name=''FILES_BACKUP_MODE'' and type#=0)'
      INTO t_null;
    EXCEPTION 
      WHEN NO_DATA_FOUND then roll_exists := 0;
  END;

  IF (roll_exists = 0 and pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('FILES_BACKUP_MODE', 
        c_check_level_warning,
	'There are files in backup mode. Ensure no files are in backup mode prior to upgrade.',
	'Ensure no files are in backup mode prior to upgrade.',
        'Ensure no files are in backup mode prior to upgrade.',
	 c_dbua_detail_type_sql,
        'SELECT name FROM sys.user$ WHERE (name=''FILES_BACKUP_MODE'' and type#=0)',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre);
    ELSE
      result_txt := FILES_BACKUP_MODE_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('FILES_BACKUP_MODE');
    END IF;
    RETURN c_status_failure;
   END IF;
END FILES_BACKUP_MODE_check;

FUNCTION FILES_BACKUP_MODE_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> There are files in backup mode' || crlf 
      || crlf || '     Ensure no files are in backup mode prior to upgrade.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Verify that no files are in backup mode prior to upgrade.';
  END IF;
END FILES_BACKUP_MODE_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE FILES_BACKUP_MODE_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := FILES_BACKUP_MODE_fixup (result, tSqlcode);
END FILES_BACKUP_MODE_fixup;

FUNCTION FILES_BACKUP_MODE_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := FILES_BACKUP_MODE_gethelp(c_help_overview);
  return c_fixup_status_info;
END FILES_BACKUP_MODE_fixup;

-- *****************************************************************
--     INVALID_LOG_ARCHIVE_FORMAT Section
-- *****************************************************************
FUNCTION INVALID_LAF_check (result_txt OUT VARCHAR2) RETURN number
IS
  laf_format   VARCHAR2(4000);
  tmp_varchar1 VARCHAR2(512);
  t_null       CHAR(1);
  status       NUMBER := 0;
BEGIN

   --
   -- invalid log_archive_format check
   -- 
   -- for 9.x, RDBMS set a default value which did not include %r, 
   -- which is required by 11.2.
   -- Grab the format string, and if its defaulted or not, 
   -- Only report an error if its NOT defaulted (user set) and it is 
   -- missing the %r.
   --
   BEGIN 
     EXECUTE IMMEDIATE 
        'SELECT value, isdefault FROM v$parameter WHERE name = ''log_archive_format'''
     INTO laf_format, tmp_varchar1;
   EXCEPTION WHEN OTHERS THEN NULL;
   END;

   IF (tmp_varchar1 = 'FALSE') AND 
      (instr (LOWER(laf_format), '%r') = 0) THEN
     -- 
     -- no %[r|R] and we are not defaulted by the system - we have to report something...
     --
     status := 1;
   END IF;

  IF (status = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      --
      -- DBUA will fix this up by changing the param
      -- so its an INFO
      --
      result_txt:= genDBUAXMLCheck('INVALID_LOG_ARCHIVE_FORMAT', 
        c_check_level_info,
        'Initialization parameter log_archive_format must contain %s, %t and %r.'
          || ' Database Upgrade Assistant will update this parameter to database'
          || ' default value. This value can be customized after the upgrade.',
	'log_archive_format is invalid',
        'Update your initialization parameter to a valid value.',
	 c_dbua_detail_type_sql,
        htmlentities('select value from v$parameter where name = ''log_archive_format'''),
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt  := INVALID_LAF_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('INVALID_LOG_ARCHIVE_FORMAT');
    END IF;
    RETURN c_status_failure;
   END IF;
END INVALID_LAF_check;

FUNCTION INVALID_LAF_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
  format    VARCHAR2(4000);
  log_mode  VARCHAR2(30);
  result_txt VARCHAR2(4000);
BEGIN
  IF HelpType = c_help_overview THEN
    EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE name = ''log_archive_format'''
     INTO format;
    EXECUTE IMMEDIATE 'SELECT LOG_MODE from v$database' 
       INTO log_mode;
    result_txt := 'ERROR: --> log_archive_format must be updated' || crlf 
      || crlf || '     As of 10.1, log_archive_format requires a %r format qualifier'
      || crlf || '     be present in its format string.  Your current setting is:'
      || crlf || '     log_archive_format=''' || format || '''.';
    IF log_mode = 'NOARCHIVELOG' THEN
      result_txt := result_txt 
        || crlf || '     Archive Logging is currently OFF, but failure to add the %r to the'
        || crlf || '     format string will still prevent the upgraded database from starting up.';
    ELSE
      result_txt := result_txt 
        || crlf || '     Archive Logging is currently ON, and failure to add the %r to the'
        || crlf || '     format string will prevent the upgraded database from starting up.'; 
    END IF;
  ELSIF HelpType = c_help_fixup THEN
    result_txt := 'Update log_archive_format prior to upgrade.';
  END IF;
  RETURN result_txt;
END INVALID_LAF_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE INVALID_LAF_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := INVALID_LAF_fixup (result, tSqlcode);
END INVALID_LAF_fixup;

FUNCTION INVALID_LAF_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := INVALID_LAF_gethelp(c_help_overview);
  return c_fixup_status_info;
END INVALID_LAF_fixup;

-- *****************************************************************
--     INVALID_OBJECTS_EXIST Section
-- *****************************************************************
FUNCTION INVALID_OBJ_EXIST_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_null              CHAR(1);
  invalid_objs        BOOLEAN := FALSE;
  status              NUMBER;
  tbl_exists          NUMBER;
  nonsys_invalid_objs NUMBER;
BEGIN
  --
  -- Check for INVALID objects
  -- For "inplace" upgrades check for invalid objects that can be excluded
  -- as they may have changed between releases and don't need to be reported.
  --
  -- For all other types of upgrades, use the simple query below to 
  -- eliminate running the intricate queries except when they are needed.
  --
  BEGIN
    IF NOT db_inplace_upgrade  THEN
      EXECUTE IMMEDIATE 'SELECT NULL FROM sys.dba_objects
          WHERE status = ''INVALID'' AND object_name NOT LIKE ''BIN$%'' AND 
             rownum <=1'
      INTO t_null;
      -- For patch release - update the objects in the query below
    ELSE
      -- V_$ROLLNAME special cased because of references  to x$ tables
      EXECUTE IMMEDIATE 'SELECT NULL FROM SYS.DBA_OBJECTS
           WHERE status = ''INVALID'' AND object_name NOT LIKE ''BIN$%'' AND 
              rownum <=1 AND
              object_name NOT IN 
                 (SELECT name FROM SYS.dba_dependencies
                    START WITH referenced_name IN ( 
                         ''V$LOGMNR_SESSION'', ''V$ACTIVE_SESSION_HISTORY'',
                         ''V$BUFFERED_SUBSCRIBERS'',  ''GV$FLASH_RECOVERY_AREA_USAGE'',
                         ''GV$ACTIVE_SESSION_HISTORY'', ''GV$BUFFERED_SUBSCRIBERS'',
                         ''V$RSRC_PLAN'', ''V$SUBSCR_REGISTRATION_STATS'',
                         ''GV$STREAMS_APPLY_READER'',''GV$ARCHIVE_DEST'',
                         ''GV$LOCK'',''DBMS_STATS_INTERNAL'',''V$STREAMS_MESSAGE_TRACKING'',
                         ''GV$SQL_SHARED_CURSOR'',''V$RMAN_COMPRESSION_ALGORITHM'',
                         ''V$RSRC_CONS_GROUP_HISTORY'',''V$PERSISTENT_SUBSCRIBERS'',''V$RMAN_STATUS'',
                         ''GV$RSRC_CONSUMER_GROUP'',''V$ARCHIVE_DEST'',''GV$RSRCMGRMETRIC'',
                         ''GV$RSRCMGRMETRIC_HISTORY'',''V$PERSISTENT_QUEUES'',''GV$CPOOL_CONN_INFO'',
                         ''GV$RMAN_COMPRESSION_ALGORITHM'',''DBA_BLOCKERS'',''V$STREAMS_TRANSACTION'',
                         ''V$STREAMS_APPLY_READER'',''GV$SGA_DYNAMIC_FREE_MEMORY'',''GV$BUFFERED_QUEUES'',
                         ''GV$RSRC_PLAN_HISTORY'',''GV$ENCRYPTED_TABLESPACES'',''V$ENCRYPTED_TABLESPACES'',
                         ''GV$RSRC_CONS_GROUP_HISTORY'',''GV$RSRC_PLAN'',
                         ''GV$RSRC_SESSION_INFO'',''V$RSRCMGRMETRIC'',''V$STREAMS_CAPTURE'',
                         ''V$RSRCMGRMETRIC_HISTORY'',''GV$STREAMS_TRANSACTION'',''DBMS_LOGREP_UTIL'',
                         ''V$RSRC_SESSION_INFO'',''GV$STREAMS_CAPTURE'',''V$RSRC_PLAN_HISTORY'',
                         ''GV$FLASHBACK_DATABASE_LOGFILE'',''V$BUFFERED_QUEUES'',
                         ''GV$PERSISTENT_SUBSCRIBERS'',''GV$FILESTAT'',''GV$STREAMS_MESSAGE_TRACKING'',
                         ''V$RSRC_CONSUMER_GROUP'',''V$CPOOL_CONN_INFO'',''DBA_DML_LOCKS'',
                         ''V$FLASHBACK_DATABASE_LOGFILE'',''GV$HM_RECOMMENDATION'',
                         ''V$SQL_SHARED_CURSOR'',''GV$PERSISTENT_QUEUES'',''GV$FILE_HISTOGRAM'',
                         ''DBA_WAITERS'',''GV$SUBSCR_REGISTRATION_STATS'')
                                AND referenced_type in (''VIEW'',''PACKAGE'') OR
                          name = ''V_$ROLLNAME''
                             CONNECT BY
                               PRIOR name = referenced_name and
                               PRIOR type = referenced_type)'
      INTO t_null;
    END IF;
    invalid_objs := TRUE;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN NULL;
  END;

  -- create a table to store invalid objects (create it if necessary)
  IF NOT db_readonly THEN
    tbl_exists := 0;
    EXECUTE IMMEDIATE
      'SELECT count(*) FROM dba_tables
         WHERE table_name = ''REGISTRY$SYS_INV_OBJS'''
    INTO tbl_exists;

    IF tbl_exists != 0 -- if registry$sys_inv_objs table exists
    THEN
      -- Truncate table first
      EXECUTE IMMEDIATE 'TRUNCATE TABLE registry$sys_inv_objs';

      -- Insert into table 
      EXECUTE IMMEDIATE
        'INSERT INTO registry$sys_inv_objs
         SELECT owner,object_name,object_type
           FROM sys.dba_objects
           WHERE status !=''VALID'' AND owner in (''SYS'',''SYSTEM'')
           ORDER BY owner';
    ELSE
      -- Create invalid objects table and populate with all SYS and SYSTEM
      -- invalid objects
      EXECUTE IMMEDIATE
        'CREATE TABLE registry$sys_inv_objs AS
          SELECT owner,object_name,object_type
            FROM sys.dba_objects 
            WHERE status !=''VALID'' AND owner in (''SYS'',''SYSTEM'')
            ORDER BY owner';
    END IF;  -- IF/ELSE registry$sys_inv_objs exists

    -- If there are less than 5000 non-sys invalid objects then create 
    -- another table with non-SYS/SYSTEM owned objects.
    -- If there are more than 5000 total then that is too many
    -- for utluiobj.sql to handle so output a message.
    EXECUTE IMMEDIATE 'SELECT count(*) FROM sys.dba_objects 
            WHERE status !=''VALID'' AND owner NOT in (''SYS'',''SYSTEM'')'
    INTO nonsys_invalid_objs;

    IF nonsys_invalid_objs < 5000 THEN
      tbl_exists := 0;
      EXECUTE IMMEDIATE
        'SELECT count(*) FROM dba_tables
           WHERE table_name = ''REGISTRY$NONSYS_INV_OBJS'''
      INTO tbl_exists;

      IF tbl_exists != 0 -- if registry$nonsys_inv_objs table exists
      THEN
        -- Truncate table first
        EXECUTE IMMEDIATE 'TRUNCATE TABLE registry$nonsys_inv_objs';

        -- Insert into table next
        EXECUTE IMMEDIATE
          'INSERT INTO registry$nonsys_inv_objs
           SELECT owner,object_name,object_type
             FROM sys.dba_objects
             WHERE status !=''VALID'' AND owner NOT in (''SYS'',''SYSTEM'')
             ORDER BY owner';
      ELSE  -- if table does not exist
        -- Create invalid objects table and populate with non-SYS and
        -- non-SYSTEM invalid objects
        EXECUTE IMMEDIATE
           'CREATE TABLE registry$nonsys_inv_objs
              AS
            SELECT owner,object_name,object_type
              FROM sys.dba_objects
              WHERE status !=''VALID'' AND owner NOT in (''SYS'',''SYSTEM'')
              ORDER BY owner';
      END IF;  -- IF/ELSE registry$nonsys_inv_objs exists
    END IF;  -- IF/ELSE nonsys_invalid_objs > 5000
    COMMIT;
  END IF; -- db NOT readonly

  --
  -- Now get back to reporting the issue if we need to.
  --
  IF invalid_objs = FALSE AND pDBGFailCheck = FALSE THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('INVALID_OBJECTS_EXIST', 
        c_check_level_warning,
          'There are INVALID objects in the database.  Invalid SYS/SYSTEM objects'
          || ' was written to REGISTRY$SYS_INV_OBJS.  Invalid non-SYS/SYSTEM objects'
          || ' was written to REGISTRY$NONSYS_INV_OBJS.  Use utluiobj.sql after the'
          || ' upgrade to identify any new invalid objects due to the upgrade.',
	'Invalid object found in the database.',
        'It is recommended that utlprp.sql be run to attempt to validate objects',
	 c_dbua_detail_type_sql,
         'SELECT owner,object_name,object_type from registry$sys_inv_objs',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre);
    ELSE
      result_txt := INVALID_OBJ_EXIST_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('INVALID_OBJECTS_EXIST');
    END IF;
    RETURN c_status_failure;
  END IF;
END INVALID_OBJ_EXIST_check;

FUNCTION INVALID_OBJ_EXIST_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> Database contains INVALID objects prior to upgrade' || crlf 
      || crlf || '     The list of invalid SYS/SYSTEM objects was written to'
      || crlf || '     registry$sys_inv_objs.'
      || crlf || '     The list of non-SYS/SYSTEM objects was written to'
      || crlf || '     registry$nonsys_inv_objs unless there were over 5000.'
      || crlf || '     Use utluiobj.sql after the upgrade to identify any new invalid'
      || crlf || '     objects due to the upgrade.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Invalid objects are displayed and must be reviewed.';
  END IF;
END INVALID_OBJ_EXIST_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE INVALID_OBJ_EXIST_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := INVALID_OBJ_EXIST_fixup (result, tSqlcode);
END INVALID_OBJ_EXIST_fixup;

FUNCTION INVALID_OBJ_EXIST_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  result_txt := INVALID_OBJ_EXIST_gethelp(c_help_overview);
  pSqlcode := 0;
  return c_fixup_status_info;
  --
  -- This could be executed by post-fixup 
   --   return execute_sql_statement ('@?/rdbms/admin/utlprp.sql', result_txt, pSqlcode);
END INVALID_OBJ_EXIST_fixup;

FUNCTION invalid_obj_exclude RETURN VARCHAR2
--
-- The list of invalid objects to 'accept' as invalid
-- 
IS
BEGIN
  return '''V$LOGMNR_SESSION'', ''V$ACTIVE_SESSION_HISTORY'', ''V$BUFFERED_SUBSCRIBERS'','
     || '''GV$FLASH_RECOVERY_AREA_USAGE'', ''GV$ACTIVE_SESSION_HISTORY'','
     || '''GV$BUFFERED_SUBSCRIBERS'', ''V$RSRC_PLAN'', ''V$SUBSCR_REGISTRATION_STATS'','
     || '''GV$STREAMS_APPLY_READER'',''GV$ARCHIVE_DEST'', ''GV$LOCK'',''DBMS_STATS_INTERNAL'','
     || '''V$STREAMS_MESSAGE_TRACKING'', ''GV$SQL_SHARED_CURSOR'',''V$RMAN_COMPRESSION_ALGORITHM'','
     || '''V$RSRC_CONS_GROUP_HISTORY'',''V$PERSISTENT_SUBSCRIBERS'',''V$RMAN_STATUS'','
     || '''GV$RSRC_CONSUMER_GROUP'',''V$ARCHIVE_DEST'',''GV$RSRCMGRMETRIC'','
     || '''GV$RSRCMGRMETRIC_HISTORY'',''V$PERSISTENT_QUEUES'',''GV$CPOOL_CONN_INFO'','
     || '''GV$RMAN_COMPRESSION_ALGORITHM'',''DBA_BLOCKERS'',''V$STREAMS_TRANSACTION'','
     || '''V$STREAMS_APPLY_READER'',''GV$SGA_DYNAMIC_FREE_MEMORY'',''GV$BUFFERED_QUEUES'','
     || '''GV$RSRC_PLAN_HISTORY'',''GV$ENCRYPTED_TABLESPACES'',''V$ENCRYPTED_TABLESPACES'','
     || '''GV$RSRC_CONS_GROUP_HISTORY'',''GV$RSRC_PLAN'',''GV$RSRC_SESSION_INFO'','
     || '''V$RSRCMGRMETRIC'',''V$STREAMS_CAPTURE'',''V$RSRCMGRMETRIC_HISTORY'','
     || '''GV$STREAMS_TRANSACTION'',''DBMS_LOGREP_UTIL'',''V$RSRC_SESSION_INFO'','
     || '''GV$STREAMS_CAPTURE'',''V$RSRC_PLAN_HISTORY'',''GV$FLASHBACK_DATABASE_LOGFILE'','
     || '''V$BUFFERED_QUEUES'',''GV$PERSISTENT_SUBSCRIBERS'',''GV$FILESTAT'','
     || '''GV$STREAMS_MESSAGE_TRACKING'',''V$RSRC_CONSUMER_GROUP'',''V$CPOOL_CONN_INFO'','
     || '''DBA_DML_LOCKS'', ''V$FLASHBACK_DATABASE_LOGFILE'',''GV$HM_RECOMMENDATION'','
     || '''V$SQL_SHARED_CURSOR'',''GV$PERSISTENT_QUEUES'',''GV$FILE_HISTOGRAM'','
     || '''DBA_WAITERS'',''GV$SUBSCR_REGISTRATION_STATS'', ''DBA_KGLLOCK''';
END invalid_obj_exclude;

-- *****************************************************************
--     INVALID_SYS_TABLEDATA Section
-- *****************************************************************
FUNCTION INVALID_SYS_TABLEDATA_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_count  NUMBER;
  status   NUMBER;
BEGIN
  --
  BEGIN
    EXECUTE IMMEDIATE  'SELECT COUNT(*) '                         ||
      'FROM SYS.OBJ$ o, SYS.COL$ c, SYS.COLTYPE$ t, SYS.USER$ u ' ||
      'WHERE o.OBJ# = t.OBJ# AND c.OBJ# = t.OBJ# '                ||
        'AND c.COL# = t.COL# AND t.INTCOL# = c.INTCOL# '          ||
        'AND BITAND(t.FLAGS, 256) = 256 AND o.OWNER# = u.USER# '  ||
        'AND o.OWNER# in '                                        ||
         '(SELECT r.schema# FROM SYS.REGISTRY$ r '                ||
           'WHERE r.NAMESPACE = ''SERVER'')'
     INTO t_count;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN t_count := 0;
  END;

  IF (t_count <= 0 and pDBGFailCheck = FALSE)
  THEN
    -- Nothing to do.
    RETURN c_status_success;

  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('INVALID_SYS_TABLEDATA', 
        c_check_level_error,
	'Database contains table data which has not been upgraded. Proceeding'
         || ' with an Upgrade before upgrading the table data can lead to'
         || ' data loss. ',
	'Invalid table data found in database.',
        'Use "ALTER TABLE ... UPGRADE INCLUDING DATA" prior to upgrade.',
	 c_dbua_detail_type_text,
        'Use "ALTER TABLE ... UPGRADE INCLUDING DATA" prior to upgrade.',
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_validation );
    ELSE
      result_txt := INVALID_SYS_TABLEDATA_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('INVALID_SYS_TABLEDATA');
    END IF; 
   RETURN c_status_failure;
   END IF;
END;

FUNCTION INVALID_SYS_TABLEDATA_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> Invalid Oracle supplied table data found in your database.' || crlf 
           || crlf || '     Invalid data can be seen prior to the database upgrade'
           || crlf || '     or during PDB plug in.  This table data must be made'
           || crlf || '     valid BEFORE upgrade or plug in.'
           || crlf
           || crlf || '   - To fix the data, load the Preupgrade package and execute'
           || crlf || '     the fixup routine.'
           || crlf || '     For plug in, execute the fix up routine in the PDB.'
           || crlf
           || crlf || '    @?/rdbms/admin/utluppkg.sql'
           || crlf || '    SET SERVEROUTPUT ON;'
           || crlf || '    exec dbms_preup.run_fixup_and_report(''INVALID_SYS_TABLEDATA'')'
           || crlf || '    SET SERVEROUTPUT OFF;';
  ELSIF HelpType = c_help_fixup THEN
    return 'UPGRADE Oracle supplied table data prior to the database upgrade.';
  END IF;
END;
--
-- Fixup (Procedure and function)
--
PROCEDURE INVALID_SYS_TABLEDATA_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := INVALID_SYS_TABLEDATA_fixup (result, tSqlcode);
END;
FUNCTION INVALID_SYS_TABLEDATA_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
  t_cursor     cursor_t;
  t_tabname    sys.obj$.name%TYPE;
  t_schema     sys.user$.name%TYPE;
  t_full_name  VARCHAR2(261); -- extra for quotes and . 
  t_sqltxt     VARCHAR2(4000);
  t_new_err    VARCHAR2(500);
  t_error      BOOLEAN := FALSE;
  t_took_error BOOLEAN := FALSE;
  t_sqlcode    NUMBER;  -- The last sql error we took
  t_len        NUMBER;

BEGIN
  result_txt := '';

  OPEN t_cursor FOR 'SELECT DISTINCT (o.NAME), u.NAME '          ||
    'FROM SYS.OBJ$ o, SYS.COL$ c, SYS.COLTYPE$ t, SYS.USER$ u '  ||
    'WHERE o.OBJ# = t.OBJ# AND c.OBJ# = t.OBJ# '                 ||
       'AND c.COL# = t.COL# AND t.INTCOL# = c.INTCOL# '          ||
       'AND BITAND(t.FLAGS, 256) = 256 AND o.OWNER# = u.USER# '  ||
       'AND o.OWNER# in (SELECT r.schema# FROM SYS.REGISTRY$ r ' ||
              'WHERE r.NAMESPACE = ''SERVER'')';
  LOOP
    FETCH t_cursor INTO t_tabname,t_schema;
    EXIT WHEN t_cursor%NOTFOUND;
    --
    -- Put quotes around the schema and table name
    --
    t_full_name :=  dbms_assert.enquote_name(t_schema, FALSE) || '.' || 
                    dbms_assert.enquote_name(t_tabname,FALSE);
   BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || t_full_name 
                || ' UPGRADE INCLUDING DATA';
      EXCEPTION WHEN OTHERS THEN
        t_error  := TRUE;
        t_sqltxt := SQLERRM;
        t_sqlcode  := SQLCODE;
        t_took_error := TRUE;
    END;

    IF t_error THEN
      IF result_txt != '' THEN
        -- If not the first, add a crlf
        result_txt := result_txt || crlf;
      END IF;

      t_new_err := 
            '  Error upgrading: ' || t_full_name || crlf ||
            '  Error Text:      ' || t_sqltxt || crlf;

      --
      --  length returns NULL (and not zero) for null varchar2's 
      --
      t_len := NVL(length(result_txt), 0);

      IF (t_len + length (t_new_err) <= c_str_max) THEN
        --
        -- will fit into our buffer
        --
        result_txt := result_txt || t_new_err;
      ELSE
        t_new_err := crlf || 
           '  *** Too Many Tables ***' || crlf ||
           '  *** Cleanup and re-execute to see more tables *** ';
        --
        -- see if this will fit on the end (should be 
        -- shorter than the actual error)
        --
        IF (t_len + length (t_new_err) < c_str_max) THEN
          -- Fits
          result_txt := result_txt || t_new_err;  
        ELSE 
          -- 
          -- Won't fit, cut some off and add the above error
          --
          result_txt := substr (result_txt, 1, t_len - 
                              length(t_new_err) - 1);
          result_txt := result_txt || t_new_err;
        END IF;
        -- We are done.
        EXIT;   -- Out of the loop
      END IF;
      t_error := FALSE;  -- Reset error
    END IF;
  END LOOP;

  IF t_took_error THEN
    pSqlcode := t_sqlcode;  -- Return the last failure code
    return c_fixup_status_failure;
  ELSE
    return c_fixup_status_success;
  END IF;
END;

-- *****************************************************************
--     INVALID_USR_TABLEDATA Section
-- *****************************************************************
FUNCTION INVALID_USR_TABLEDATA_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_count  NUMBER;
  status   NUMBER;
BEGIN
  --
  -- Exclude tables returned in the _sys_tabledata version
  -- by using NOT IN clause
  --
  BEGIN
    EXECUTE IMMEDIATE  'SELECT COUNT(*) '                         ||
      'FROM SYS.OBJ$ o, SYS.COL$ c, SYS.COLTYPE$ t, SYS.USER$ u ' ||
      'WHERE o.OBJ# = t.OBJ# AND c.OBJ# = t.OBJ# '                ||
        'AND c.COL# = t.COL# AND t.INTCOL# = c.INTCOL# '          ||
        'AND BITAND(t.FLAGS, 256) = 256 AND o.OWNER# = u.USER# '  ||
        'AND o.OWNER# NOT IN '                                    ||
           '(SELECT UNIQUE (d.USER_ID) FROM SYS.DBA_USERS d, '    || 
             'SYS.REGISTRY$ r WHERE d.USER_ID = r.SCHEMA# '       || 
             'AND r.NAMESPACE=''SERVER'')'
     INTO t_count;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN t_count := 0;
  END;

  IF (t_count <= 0 and pDBGFailCheck = FALSE)
  THEN
    -- Nothing to do.
    RETURN c_status_success;

  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('INVALID_USR_TABLEDATA', 
        c_check_level_error,
	'Database contains user table data which has not been upgraded. Proceeding'
         || ' with an Upgrade of the database before upgrading the table data can lead to'
         || ' data loss.',
	'Invalid user table data found in database.',
        'Use "ALTER TABLE ... UPGRADE INCLUDING DATA prior to upgrade.',
	 c_dbua_detail_type_text,
        'Use "ALTER TABLE ... UPGRADE INCLUDING DATA" prior to upgrade.',
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_validation );
    ELSE
      result_txt := INVALID_USR_TABLEDATA_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('INVALID_USR_TABLEDATA');
    END IF; 
   RETURN c_status_failure;
   END IF;
END;

FUNCTION INVALID_USR_TABLEDATA_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> Invalid user table data found in your database.' || crlf 
           || crlf || '     Invalid data can be seen prior to the database upgrade'
           || crlf || '     or during PDB plug in.  This table data must be made'
           || crlf || '     valid BEFORE upgrade or plug in.'
           || crlf
           || crlf || '   - To fix the data, load the Preupgrade package and execute'
           || crlf || '     the fixup routine.'
           || crlf || '     For plug in, execute the fix up routine in the PDB.'
           || crlf
           || crlf || '    @?/rdbms/admin/utluppkg.sql'
           || crlf || '    SET SERVEROUTPUT ON;'
           || crlf || '    exec dbms_preup.run_fixup_and_report(''INVALID_USR_TABLEDATA'');'
           || crlf || '    SET SERVEROUTPUT OFF;';
  ELSIF HelpType = c_help_fixup THEN
    return 'UPGRADE user table data prior to the database upgrade.';
  END IF;
END;
--
-- Fixup (Procedure and function)
--
PROCEDURE INVALID_USR_TABLEDATA_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := INVALID_USR_TABLEDATA_fixup (result, tSqlcode);
END;
FUNCTION INVALID_USR_TABLEDATA_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
  t_cursor     cursor_t;
  t_tabname    sys.obj$.name%TYPE;
  t_schema     sys.user$.name%TYPE;
  t_full_name  VARCHAR2(256);
  t_sqltxt     VARCHAR2(4000);
  t_new_err    VARCHAR2(500);
  t_error      BOOLEAN := FALSE;
  t_took_error BOOLEAN := FALSE;
  t_sqlcode    NUMBER;  -- The last sql error we took
  t_len        NUMBER;

BEGIN
  result_txt := '';

  OPEN t_cursor FOR 'SELECT DISTINCT (o.NAME), u.NAME '          ||
    'FROM SYS.OBJ$ o, SYS.COL$ c, SYS.COLTYPE$ t, SYS.USER$ u '  ||
    'WHERE o.OBJ# = t.OBJ# AND c.OBJ# = t.OBJ# '                 ||
       'AND c.COL# = t.COL# AND t.INTCOL# = c.INTCOL# '          ||
       'AND BITAND(t.FLAGS, 256) = 256 AND o.OWNER# = u.USER# '  ||
       'AND o.OWNER# NOT IN (SELECT UNIQUE (d.USER_ID) FROM '    ||
         'SYS.DBA_USERS d, SYS.REGISTRY$ r WHERE '                || 
           'd.USER_ID = r.SCHEMA# AND r.NAMESPACE=''SERVER'')';
  LOOP
    FETCH t_cursor INTO t_tabname,t_schema;
    EXIT WHEN t_cursor%NOTFOUND;
    --
    -- Put quotes around the schema and table name
    --
    t_full_name :=  dbms_assert.enquote_name(t_schema, FALSE) || '.' || 
                    dbms_assert.enquote_name(t_tabname,FALSE);
    BEGIN
      EXECUTE IMMEDIATE 'ALTER TABLE ' || t_full_name 
                || ' UPGRADE INCLUDING DATA';
      EXCEPTION WHEN OTHERS THEN
        t_error  := TRUE;
        t_sqltxt := SQLERRM;
        t_sqlcode  := SQLCODE;
        t_took_error := TRUE;
    END;

    IF t_error THEN
      IF result_txt != '' THEN
        -- If not the first, add a crlf
        result_txt := result_txt || crlf;
      END IF;

      t_new_err := 
            '  Error upgrading: ' || t_full_name || crlf ||
            '  Error Text:      ' || t_sqltxt || crlf;

      --
      --  length returns NULL (and not zero) for null varchar2's 
      --
      t_len := NVL(length(result_txt), 0);

      IF (t_len + length (t_new_err) <= c_str_max) THEN
        --
        -- will fit into our buffer
        --
        result_txt := result_txt || t_new_err;
      ELSE
        t_new_err := crlf || 
           '  *** Too Many Tables ***' || crlf ||
           '  *** Cleanup and re-execute to see more tables *** ';
        --
        -- see if this will fit on the end (should be 
        -- shorter than the actual error)
        --
        IF (t_len + length (t_new_err) < c_str_max) THEN
          -- Fits
          result_txt := result_txt || t_new_err;  
        ELSE 
          -- 
          -- Won't fit, cut some off and add the above error
          --
          result_txt := substr (result_txt, 1, t_len - 
                                    length(t_new_err));
          result_txt := result_txt || t_new_err;
        END IF;
        -- We are done.
        EXIT;   -- Out of the loop
      END IF;
      t_error := FALSE;  -- Reset error
    END IF;
  END LOOP;

  IF t_took_error THEN
    pSqlcode := t_sqlcode;  -- Return the last failure code
    return c_fixup_status_failure;
  ELSE
    return c_fixup_status_success;
  END IF;
END;


-- *****************************************************************
--     job_queue_process Section
-- *****************************************************************
FUNCTION job_queue_process_check (result_txt OUT VARCHAR2) RETURN number
IS
  p_count  NUMBER := -1;
  status   NUMBER;
  idx      NUMBER;
  p_lowest NUMBER;
  edetails VARCHAR2(500);

BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE 
          name=''job_queue_processes'''
    INTO p_count;
  EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
  END;

  p_lowest := db_cpus * db_cpu_threads;

  --
  -- If we failed to grab the count (not set), 
  -- or the count is > the number of cpu*threads then 
  -- there is no error 
  --
  IF ( (p_count = -1) OR (p_count > p_lowest) 
    AND pDBGFailCheck = FALSE) THEN
    RETURN c_status_success;
  END IF;
  --
  -- Find the index of this routine in the check_array
  --
  idx := check_names('JOB_QUEUE_PROCESS').idx;

  IF (p_count = 0) THEN
    check_table(idx).level := c_check_level_error;
    edetails := 'JOB_QUEUE_PROCESSES is set at zero which will cause both ' 
        || 'DBMS_SCHEDULER and DBMS_JOB jobs to not run.';
  ELSE
    --
    -- We know at this point the count is under db_cpus * db_cpu_threads
    -- (or debug is on)
    --
    check_table(idx).level := c_check_level_warning;
    edetails := 'JOB_QUEUE_PROCESSES is set at ' || p_count || ' which may cause ' 
        || 'the upgrade to take significantly longer to complete.';
  END IF;

  IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('JOB_QUEUE_PROCESS', 
        check_table(idx).level,
        'JOB_QUEUE_PROCESSES value must be updated.',
        edetails,
        'Either remove setting of JOB_QUEUE_PROCESSES value ' ||
        'or set it to a value greater than ' || to_char(p_lowest) ||
        '.',
        c_dbua_detail_type_text,
        'Either remove setting of JOB_QUEUE_PROCESSES value ' ||
        'or set it to a value greater than ' || to_char(p_lowest) ||
        '.',
        c_dbua_fixup_type_manual,
        c_dbua_fixup_stage_pre );
  ELSE
    result_txt := JOB_QUEUE_PROCESS_gethelp(c_help_overview);
  END IF;
  IF pOutputtingScripts THEN
    genFixup ('JOB_QUEUE_PROCESS');
  END IF;
  RETURN c_status_failure;
END job_queue_process_check;

FUNCTION job_queue_process_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS
  p_count     NUMBER := -1;
  error_level NUMBER;
  status      NUMBER;
  result_txt  VARCHAR2(1500);

BEGIN
  IF HelpType = c_help_overview THEN
    BEGIN
      EXECUTE IMMEDIATE 'SELECT value FROM v$parameter WHERE 
            name=''job_queue_processes'''
      INTO p_count;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;
    --
    -- Note:  We are going to assume the caller knows there is
    -- an issue, so if the count is non-zero, its going to be below
    -- cpu*threads which is a warning.
    --
    IF p_count = 0 THEN
      result_txt := 'ERROR: --> job_queue_processes set to zero' || crlf
        || crlf || '     Starting with Oracle Database 11g Release 2 (11.2), setting'
        || crlf || '     JOB_QUEUE_PROCESSES to 0 causes both DBMS_SCHEDULER and'
        || crlf || '     DBMS_JOB jobs to not run. Previously, setting JOB_QUEUE_PROCESSES'
        || crlf || '     to 0 caused DBMS_JOB jobs to not run, but DBMS_SCHEDULER jobs were'
        || crlf || '     unaffected and would still run.';
    ELSE 
      result_txt := 'WARNING: --> job_queue_processes set too low' || crlf;
    END IF;
    -- Now add the rest
    result_txt := result_txt 
      || crlf || '     This parameter must be removed or updated to a value greater'
      || crlf || '     than ' || to_char(db_cpus*db_cpu_threads)
              || ' (default value if not defined is 1000) prior to upgrade.'
      || crlf || '     Not doing so will affect the running of utlrp.sql after the upgrade'
      || crlf || crlf || '     Update your init.ora or spfile to make this change.';
  ELSIF HelpType = c_help_fixup THEN
    result_txt := 'Review and increase or remove the setting of job_queue_processes';
  END IF;
  RETURN result_txt;
END job_queue_process_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE job_queue_process_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := job_queue_process_fixup (result, tSqlcode);
END job_queue_process_fixup;

FUNCTION job_queue_process_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := job_queue_process_gethelp(c_help_overview);
   return c_fixup_status_info;
END job_queue_process_fixup;

-- *****************************************************************
--     NACL_OBJECTS_EXIST Section
-- *****************************************************************
FUNCTION nacl_objects_exist_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_null      CHAR(1);
  status      NUMBER := 0;
BEGIN

  IF (db_n_version NOT IN (102) AND pDBGFailCheck = FALSE) THEN
    -- Only valid for 10.2 upgrades
    return c_status_not_for_this_version;
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 'SELECT NULL FROM sys.user$ WHERE name=''DMSYS'''
      INTO t_null;
    status := 1;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN NULL;
  END;

  IF (status = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_passed;
  END IF;

  IF pOutputType = c_output_xml THEN
    result_txt:= genDBUAXMLCheck('NACL_OBJECTS_EXIST', 
      c_check_level_warning,
      'Database contains schemas with objects dependent on network packages.',
      'Database contains schemas with objects dependent on network packages.',
      'Refer to the 11g Upgrade Guide for instructions to configure Network ACLs',
      c_dbua_detail_type_text,
      'Refer to the 11g Upgrade Guide for instructions on how to re-configure Network ACLs.',
       c_dbua_fixup_type_manual,
       c_dbua_fixup_stage_pre );
  ELSE
    result_txt := nacl_objects_exist_gethelp(c_help_overview);
  END IF;
  IF pOutputtingScripts THEN
    genFixup ('NACL_OBJECTS_EXIST');
  END IF;
  RETURN c_status_failure;
END nacl_objects_exist_check;

FUNCTION nacl_objects_exist_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
  owner       VARCHAR2(128);
  tstr        VARCHAR2(1000); -- Because of loop issues, use temp str 
  tmp_cursor  cursor_t;
  result_txt  VARCHAR2(1500);
BEGIN
  IF HelpType = c_help_overview THEN
    result_txt := 'WARNING: --> Existing schemas with network ACLs exist' || crlf 
       || crlf || '     Database contains schemas with objects dependent on network packages.'
       || crlf || '     Refer to the Upgrade Guide for instructions to configure Network ACLs.';

    tstr := '';
    OPEN tmp_cursor FOR
      'SELECT DISTINCT owner FROM DBA_DEPENDENCIES'
          || ' WHERE referenced_name IN'
          || ' (''UTL_TCP'',''UTL_SMTP'',''UTL_MAIL'',''UTL_HTTP'',''UTL_INADDR'')'
          || ' AND owner NOT IN (''SYS'',''PUBLIC'',''ORDPLUGINS'')';
    LOOP
      FETCH tmp_cursor INTO owner;
      EXIT WHEN tmp_cursor%NOTFOUND;
      tstr := tstr 
        || crlf || '     USER ' || owner || ' has dependent objects.';
    END LOOP;
    CLOSE tmp_cursor;
    IF (tstr IS NOT NULL OR tstr != '' ) THEN
      result_txt := result_txt || tstr;
    END IF;

    tstr := '';
    OPEN tmp_cursor FOR 
       'SELECT DISTINCT owner FROM all_tab_columns'
          || ' WHERE data_type IN'
          || ' (''ORDIMAGE'', ''ORDAUDIO'', ''ORDVIDEO'', ''ORDDOC'','
          || '  ''ORDSOURCE'', ''ORDDICOM'') AND'
          || '    (data_type_owner = ''ORDSYS'' OR'
          || '       data_type_owner = owner) AND'
          || '         (owner != ''PM'')';
    LOOP
      FETCH tmp_cursor INTO owner;
      EXIT WHEN tmp_cursor%NOTFOUND;
      tstr := tstr 
         || crlf || '     USER ' || owner || ' uses interMedia and may have dependent objects.';
    END LOOP;
    CLOSE tmp_cursor;
    IF (tstr IS NOT NULL OR tstr != '' ) THEN
      result_txt := result_txt || tstr;
    END IF;
  ELSIF HelpType = c_help_fixup THEN
    result_txt := 'Objects with network acls are displayed and need to be reviewed.';
  END IF;
  RETURN result_txt;
END nacl_objects_exist_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE nacl_objects_exist_fixup 
IS
  result  VARCHAR2(1500);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := nacl_objects_exist_fixup (result, tSqlcode);
END nacl_objects_exist_fixup;

FUNCTION nacl_objects_exist_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := nacl_objects_exist_gethelp(c_help_overview);
  return c_fixup_status_info;
END nacl_objects_exist_fixup;

-- *****************************************************************
--     NEW_TIME_ZONES_EXIST Section
-- *****************************************************************
FUNCTION NEW_TIME_ZONES_EXIST_check (result_txt OUT VARCHAR2) RETURN number
IS
  status NUMBER;
BEGIN
  IF db_tz_version <= c_tz_version AND pDBGFailCheck = FALSE
  THEN
    RETURN c_status_success; -- success
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('NEW_TIME_ZONES_EXIST', 
        c_check_level_error,
	'Your database contains a time zone file newer than that of the new Oracle software.',
	'Your database contains a time zone file newer than that of the new Oracle software.',
        'Patch new oracle home with time zone file equivilant to existing Oracle database.',
	 c_dbua_detail_type_text,
        'SELECT version from v$timezone_file',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := NEW_TIME_ZONES_EXIST_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('NEW_TIME_ZONES_EXIST');
    END IF;
    RETURN c_status_failure;
   END IF;
END NEW_TIME_ZONES_EXIST_check;

FUNCTION NEW_TIME_ZONES_EXIST_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> New Timezone File in use' || crlf 
       || crlf || '     Database is using a time zone file newer than version ' 
                       || c_tz_version  || '.'
       || crlf || '     BEFORE upgrading the database, patch the new '
       || crlf || '     ORACLE_HOME/oracore/zoneinfo/ with a time zone data file of the'
       || crlf || '     same version as the one used in the ' || db_version 
       || ' release database.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Time zone data file must be updated in the new ORACLE_HOME.';
  END IF;
END NEW_TIME_ZONES_EXIST_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE NEW_TIME_ZONES_EXIST_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := NEW_TIME_ZONES_EXIST_fixup (result, tSqlcode);
END NEW_TIME_ZONES_EXIST_fixup;

FUNCTION NEW_TIME_ZONES_EXIST_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := NEW_TIME_ZONES_EXIST_gethelp(c_help_overview);
  return c_fixup_status_info;
END NEW_TIME_ZONES_EXIST_fixup;
-- *****************************************************************
--     OCM_USER_PRESENT Section
-- *****************************************************************
FUNCTION OCM_USER_PRESENT_check (result_txt OUT VARCHAR2) RETURN number
IS
  user_exists BOOLEAN;
  tmp_num1    NUMBER;
  status      NUMBER;
  t_null      CHAR(1);
BEGIN

  IF (db_n_version NOT IN (102) AND pDBGFailCheck = FALSE) THEN
    return c_status_not_for_this_version;
  END IF;

  user_exists := TRUE;
  BEGIN
    EXECUTE IMMEDIATE 
     'SELECT user# from SYS.USER$ WHERE name=''ORACLE_OCM'''
     INTO tmp_num1;
    EXCEPTION WHEN NO_DATA_FOUND then user_exists := FALSE;
  END;

  IF user_exists THEN
    BEGIN
      EXECUTE IMMEDIATE 
       'SELECT NULL FROM sys.obj$ WHERE owner# = (SELECT user# from SYS.USER$ 
           WHERE name=''ORACLE_OCM'') AND 
             name =''MGMT_DB_LL_METRICS'' AND  type# = 9'
        INTO t_null;
      EXCEPTION 
        WHEN NO_DATA_FOUND then user_exists := TRUE;
    END;
  END IF;

  IF user_exists = FALSE AND pDBGFailCheck = FALSE
  THEN
    RETURN c_status_success;   -- No user, not debug
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('OCM_USER_PRESENT', 
        c_check_level_warning,
	'User OCM present in database',
	'User OCM present in database',
        'Remove OCM user from the database prior to Upgrade',
	 c_dbua_detail_type_text,
        'The OCM internal account is present in your database' 
          || ' and should be dropped prior to upgrading',
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre);
    ELSE
      result_txt := ocm_user_present_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('OCM_USER_PRESENT');
    END IF;
    RETURN c_status_failure;
   END IF;
END OCM_USER_PRESENT_check;

FUNCTION OCM_USER_PRESENT_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> "ORACLE_OCM" user found in database' || crlf 
     || crlf || '     This is an internal account used by Oracle Configuration Manager. '
     || crlf || '     Please drop this user prior to upgrading.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Drop the ORACLE_OCM user.';
  END IF;
END OCM_USER_PRESENT_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE OCM_USER_PRESENT_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := OCM_USER_PRESENT_fixup (result, tSqlcode);
END OCM_USER_PRESENT_fixup;

FUNCTION OCM_USER_PRESENT_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   return execute_sql_statement ('DROP USER ORACLE_OCM CASCADE', result_txt, pSqlcode);
END OCM_USER_PRESENT_fixup;

-- *****************************************************************
--     OLD_TIME_ZONES_EXISTS Section 
-- *****************************************************************
FUNCTION old_time_zones_exist_check (result_txt OUT VARCHAR2) RETURN number
IS
  status  NUMBER;
BEGIN
  -- 
  -- Do we have a valid time zone for an upgrade
  -- 
  IF db_tz_version < c_tz_version OR pDBGFailCheck THEN
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('OLD_TIME_ZONES_EXIST',
	c_check_level_warning,
	'Database is using a time zone file older than shipped with the new Oracle Software',
	'Your time zone file must be updated, this can be done after the Upgrade is executed.',
	'Execute the dbms_dst package after your database is upgraded.',
	c_dbua_detail_type_text,
	'Execute the dbms_dst package after your database is upgraded.',
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre);
    ELSE
      result_txt := old_time_zones_exist_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('OLD_TIME_ZONES_EXIST');
    END IF;
    RETURN c_status_failure;
  END IF;
  RETURN c_status_success;
END old_time_zones_exist_check ;

FUNCTION old_time_zones_exist_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'INFORMATION: --> Older Timezone in use' || crlf 
      || crlf || '     Database is using a time zone file older than version ' 
                       || c_tz_version || '.'
      || crlf || '     After the upgrade, it is recommended that DBMS_DST package'
      || crlf || '     be used to upgrade the ' || db_version || ' database time zone version'
      || crlf || '     to the latest version which comes with the new release.'
      || crlf || '     Please refer to My Oracle Support note number 977512.1 for details.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Update the timezone using the DBMS_DST package after upgrade is complete.';
  END IF;
END old_time_zones_exist_gethelp;
--
PROCEDURE old_time_zones_exist_fixup 
IS
  result   VARCHAR2(1000);
  status   NUMBER;
  tSqlcode  NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := old_time_zones_exist_fixup (result, tSqlcode);
END old_time_zones_exist_fixup;

FUNCTION old_time_zones_exist_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := old_time_zones_exist_gethelp(c_help_overview);
   pSqlcode := 0;
   return c_fixup_status_info;
END old_time_zones_exist_fixup;
-- *****************************************************************
--     ols_sys_move Section
-- *****************************************************************
FUNCTION ols_sys_move_check (result_txt OUT VARCHAR2) RETURN number
IS
  usernum          INTEGER := 0;
  preaud_cnt       INTEGER := 0;
  status           NUMBER;
  condition_exists BOOLEAN := FALSE;
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'SELECT user# FROM sys.user$ WHERE name=''LBACSYS''' 
       INTO usernum;
    EXCEPTION WHEN OTHERS THEN NULL;
  END;

  IF (usernum != 0) THEN
    BEGIN
      --
      -- This check means the ols script has not been executed
      --
      EXECUTE IMMEDIATE 'SELECT count(*) FROM dba_tables where OWNER=''SYS'' AND table_name=''PREUPG_AUD$'''
        into preaud_cnt;
      IF preaud_cnt = 0 THEN
        condition_exists := TRUE;
      END IF;
    END;
  END IF;

  IF (condition_exists = FALSE AND
      pDBGFailCheck = FALSE) THEN
    RETURN c_status_success;
  END IF;

  IF pOutputType = c_output_xml THEN
    result_txt:= genDBUAXMLCheck('OLS_SYS_MOVE',
      c_check_level_error,
      'olspreupgrade.sql has not been executed on this database',
      'Oracle requires that olspreupgrade.sql be executed to move audit records into the correct table.',
      'The script rdbms/admin/olspreupgrade.sql must be executed to move records over prior to the upgrade.',
      c_dbua_detail_type_text,
      'To view the number of records that will be moved use the command: SELECT count(*) from system.aud$',
      c_dbua_fixup_type_manual,
      c_dbua_fixup_stage_pre);
  ELSE
    result_txt := ols_sys_move_gethelp (c_help_overview);
  END IF;
  IF pOutputtingScripts THEN
    genFixup ('OLS_SYS_MOVE');
  END IF;
  RETURN c_status_failure;
END ols_sys_move_check;

FUNCTION ols_sys_move_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS
  aud_rowcnt  INTEGER := -1;
  result_txt  VARCHAR2(1500);
BEGIN
  IF HelpType = c_help_overview THEN
    BEGIN
      EXECUTE IMMEDIATE 'SELECT count(*) FROM SYSTEM.aud$'
        INTO aud_rowcnt;
      EXCEPTION
        WHEN OTHERS THEN NULL;
    END;

    --
    -- In debug mode we want both messages to come out.
    --
    IF aud_rowcnt = -1 OR pDBGFailCheck = TRUE THEN
      result_txt := 'ERROR: --> SYSTEM.AUD$ (audit records) Move'
        || crlf || crlf || '    An error occured retrieving a count from SYSTEM.AUD$'
        || crlf ||         '    This can happen when the table has already been cleaned up.'
        || crlf ||         '    The olspreupgrade.sql script should be re-executed.';
    END IF;

    IF aud_rowcnt != -1 OR pDBGFailCheck = TRUE THEN
      result_txt := 'ERROR: --> SYSTEM.AUD$ (audit records) Move'
        || crlf || crlf || '     Oracle requires that records in the audit table SYSTEM.AUD$ be moved'
        || crlf ||         '     to SYS.AUD$ prior to upgrading..'
        || crlf || crlf || '     The Database has ' || aud_rowcnt || ' rows in SYSTEM.AUD$ which'
        || crlf ||         '     will be moved during the upgrade.'
        || crlf || crlf || '     The downtime during the upgrade will be affected if there are a'
        || crlf ||         '     large number of rows to be moved.'
        || crlf || crlf || '     The audit data can be moved manually prior to the upgrade by using'
        || crlf ||         '     the script: rdbms/admin/olspreupgrade.sql which is part of the'
        || crlf ||         '     Oracle Database 12c software.'
        || crlf ||         '     Please refer to the Label Security Administrator guide or'
        || crlf ||         '     the Database Upgrade guide.';
    END IF;
  ELSIF HelpType = c_help_fixup THEN
    result_txt := 'Execute olspreupgrade.sql script prior to upgrade.';
  END IF;
  RETURN result_txt;
END ols_sys_move_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE ols_sys_move_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := ols_sys_move_fixup (result, tSqlcode);
END ols_sys_move_fixup;

FUNCTION ols_sys_move_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := ols_sys_move_gethelp(c_help_overview);
   return c_fixup_status_info;
END ols_sys_move_fixup;

-- *****************************************************************
--     ORDIMAGEINDEX Section
-- *****************************************************************
FUNCTION ORDIMAGEINDEX_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_count NUMBER := 0;
  status  NUMBER;
BEGIN
  -- 
  -- The upgrade will remove them, so the misc warning section will
  -- let them know.
  --
  BEGIN
    EXECUTE IMMEDIATE
     'SELECT COUNT(*) FROM sys.dba_indexes WHERE index_type = ''DOMAIN''
         and ityp_name = ''ORDIMAGEINDEX'''
   INTO t_count;
  EXCEPTION 
     WHEN OTHERS THEN NULL;
  END;

  IF (t_count = 0 AND pDBGFailCheck = FALSE) THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('ORDIMAGEINDEX', 
        c_check_level_info,
	'Ordsys.OrdImageIndex is in use.  These images are dropped as part of the upgrade',
	'Ordsys.OrdImageIndex is in use',
        'Images are cleaned up as part of the upgrade process.',
	c_dbua_detail_type_sql,
        htmlentities('SELECT COUNT(*) FROM sys.dba_indexes WHERE index_type'
          || ' = ''DOMAIN'' and ityp_name = ''ORDIMAGEINDEX'''),
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := ORDIMAGEINDEX_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('ORDIMAGEINDEX');
    END IF;
    RETURN c_status_failure;
   END IF;
END ORDIMAGEINDEX_check;

FUNCTION ORDIMAGEINDEX_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
  tmp_cursor   cursor_t;
  tmp_varchar1 VARCHAR2(512);
  tmp_varchar2 VARCHAR2(512);
  tstr         VARCHAR2(1000);
  result_txt   VARCHAR2(1500);
BEGIN
  IF HelpType = c_help_overview THEN
    result_txt := 'INFORMATION: --> ORDSYS.OrdImageIndex in use' || crlf 
      || crlf || '     The previously desupported Oracle Multimedia image domain index,'
      || crlf || '     ORDSYS.OrdImageIndex, is no longer supported and has been removed in '
      || crlf || '     Oracle Database 11g Release 2 (11.2). '
      || crlf || '     Following is the list of affected indexes that are dropped'
      || crlf || '     during the upgrade.';
    OPEN tmp_cursor FOR 
       'SELECT dbai.index_name, dbai.owner FROM SYS.DBA_INDEXES dbai
          WHERE dbai.index_type = ''DOMAIN'' AND 
            dbai.ityp_name  = ''ORDIMAGEINDEX'' 
         ORDER BY dbai.owner';
    tstr := '';
    LOOP 
      FETCH tmp_cursor INTO tmp_varchar1, tmp_varchar2;
      EXIT WHEN tmp_cursor%NOTFOUND;
      tstr := tstr || crlf || '     USER: ' || RPAD(tmp_varchar2, 32) || 
                     ' Index: ' || RPAD(tmp_varchar1,32);
    END LOOP;
    CLOSE tmp_cursor;
    IF (tstr IS NOT NULL OR tstr != '' ) THEN
      result_txt := result_txt || tstr;
    END IF;
  ELSIF HelpType = c_help_fixup THEN
    result_txt := 'Cleanup of ordimageIndexes is performed during the upgrade';
  END IF;
  RETURN result_txt;
END ORDIMAGEINDEX_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE ORDIMAGEINDEX_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := ORDIMAGEINDEX_fixup (result, tSqlcode);
END ORDIMAGEINDEX_fixup;

FUNCTION ORDIMAGEINDEX_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := 
     'OrdimageIndexes are cleaned up as part of the upgrade';
   pSqlcode := 1;
   return c_fixup_status_info;
END ORDIMAGEINDEX_fixup;
-- *****************************************************************
--     2PC_TXN_EXIST Section
-- *****************************************************************
FUNCTION PENDING_2PC_TXN_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_null      CHAR(1);
  status      NUMBER;
BEGIN

  BEGIN
    EXECUTE IMMEDIATE 'SELECT NULL FROM sys.dba_2pc_pending WHERE rownum <=1'
    INTO t_null;
      status := 1;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN status := 0;
  END;

  IF (status = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('2PC_TXN_EXIST', 
        c_check_level_warning,
	'There are outstanding unresolved distributed transactions. Resolve outstanding distributed transactions prior to upgrade.',
	'Resolve outstanding distributed transactions prior to upgrade.',
        'Resolve outstanding distributed transactions prior to upgrade.',
	 c_dbua_detail_type_sql,
        htmlentities('SELECT count(*) FROM sys.dba_2pc_pending WHERE rownum <=1'),
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre);
    ELSE
      result_txt := PENDING_2PC_TXN_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('2PC_TXN_EXIST');
    END IF;
    RETURN c_status_failure;
   END IF;
END PENDING_2PC_TXN_check;

FUNCTION PENDING_2PC_TXN_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> Unresolved distributed transactions' || crlf 
      || crlf || '     There are outstanding unresolved distributed transactions.'
      || crlf || '     Resolve all outstanding distributed transactions prior to upgrade.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Distributed transactions must be resolved prior to upgrade.';
  END IF;
END PENDING_2PC_TXN_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE PENDING_2PC_TXN_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := PENDING_2PC_TXN_fixup (result, tSqlcode);
END PENDING_2PC_TXN_fixup;

FUNCTION PENDING_2PC_TXN_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := PENDING_2PC_TXN_gethelp(c_help_overview);
  return c_fixup_status_info;
END PENDING_2PC_TXN_fixup;

-- *****************************************************************
--     Recycle Bin Section 
-- *****************************************************************
FUNCTION purge_recyclebin_check (result_txt OUT VARCHAR2) RETURN number
IS
  obj_count NUMBER;
BEGIN
   EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM sys.recyclebin$' 
     INTO obj_count;
  IF (obj_count > 0 OR pDBGFailCheck)
  THEN

    IF (pDBGFailCheck AND obj_count = 0) THEN
      obj_count := 10;  -- Give it some non-zero number
    END IF;

    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('PURGE_RECYCLEBIN', c_check_level_error,
        'Recycle Bin is not empty',
        'Recycle bin is not empty',
        'BEGIN dbms_preup.purge_recyclebin_fixup; END;',
        c_dbua_detail_type_sql,
        'select count(*) from sys.recyclebin$',
        c_dbua_fixup_type_auto,
        c_dbua_fixup_stage_validation);
    ELSE
      result_txt :=  'ERROR: --> RECYCLE_BIN not empty.'
           || crlf || '     Your recycle bin contains ' || TO_CHAR(obj_count) || ' object(s). '
           || crlf || '     It is REQUIRED that the recycle bin is empty prior to upgrading.'
           || crlf || '     Immediately before performing the upgrade, execute the following'
           || crlf || '     command:'
           || crlf || '       EXECUTE dbms_preup.purge_recyclebin_fixup;';
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('PURGE_RECYCLEBIN');
    END IF;
    RETURN c_status_failure;
  ELSE
    RETURN c_status_success; -- success
  END IF;
END purge_recyclebin_check;

FUNCTION purge_recyclebin_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
  obj_count  NUMBER;
  result_txt VARCHAR2(1500);
BEGIN
  IF HelpType = c_help_overview THEN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM sys.recyclebin$' 
      INTO obj_count;
    IF (pDBGFailCheck AND obj_count = 0) THEN
      obj_count := 10;  -- Give it some non-zero number
    END IF;

    result_txt :=  'ERROR: --> Recycle Bin not empty' || crlf 
        || crlf || '     Your recycle bin contains ' || TO_CHAR(obj_count) || ' object(s).'
        || crlf || '     It is REQUIRED that the recycle bin is empty prior to upgrading'
        || crlf || '     your database.  The command:'
        || crlf || '         execute dbms_preup.purge_recyclebin_fixup;'
        || crlf || '     must be executed immediately prior to executing your upgrade.';
  ELSIF HelpType = c_help_fixup THEN
    result_txt := 'The recycle bin will be purged.';
  END IF;
  RETURN result_txt;
END purge_recyclebin_gethelp;
--
-- Fixup
--
PROCEDURE purge_recyclebin_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := purge_recyclebin_fixup (result, tSqlcode);
END purge_recyclebin_fixup;

FUNCTION purge_recyclebin_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   return execute_sql_statement ('PURGE DBA_RECYCLEBIN',
	result_txt, pSqlcode);
END purge_recyclebin_fixup;

-- *****************************************************************
--     REMOVE_DMSYS Section
-- *****************************************************************
FUNCTION REMOVE_DMSYS_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_null      CHAR(1);
  status      NUMBER := 0;
BEGIN

  IF (db_n_version NOT IN (102,111,112,121) AND pDBGFailCheck = FALSE) THEN
    RETURN c_status_success;
  END IF;

  BEGIN
    EXECUTE IMMEDIATE 'SELECT NULL FROM sys.user$ WHERE name=''DMSYS'''
      INTO t_null;
    status := 1;
    EXCEPTION
       WHEN NO_DATA_FOUND THEN NULL;
  END;

  IF (status = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('REMOVE_DMSYS', 
        c_check_level_info,
	'The DMSYS schema exists in the database and will be '
          || 'removed during the upgrade. '
          || 'Refer to the Oracle Data Mining User''s Guide for '
          || 'instructions on how to perform this task.',
	'The DMSYS schema exists in the database.',
        'Refer to the Oracle Data Mining User''s Guide for '
          || 'instructions on how to perform this task.',
	 c_dbua_detail_type_sql,
        'select name from sys.user$ where name=''DMSYS''',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := REMOVE_DMSYS_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('REMOVE_DMSYS');
    END IF;
    RETURN c_status_failure;
   END IF;
END REMOVE_DMSYS_check;

FUNCTION REMOVE_DMSYS_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> "DMSYS" schema exists in the database' || crlf
      || crlf || '     The DMSYS schema (Oracle Data Mining) will be removed'
      || crlf || '     from the database during the database upgrade.'
      || crlf || '     All data in DMSYS will be preserved under the SYS schema.'
      || crlf || '     Refer to the Oracle Data Mining User''s Guide for details.';
  ELSIF HelpType = c_help_fixup THEN
    return 'The DMSYS schema is removed as part of the upgrade.';
  END IF;
END REMOVE_DMSYS_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE REMOVE_DMSYS_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := REMOVE_DMSYS_fixup (result, tSqlcode);
END REMOVE_DMSYS_fixup;

FUNCTION REMOVE_DMSYS_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := REMOVE_DMSYS_gethelp(c_help_overview);
  return c_fixup_status_info;
END REMOVE_DMSYS_fixup;

-- *****************************************************************
--     REMOTE_REDO Section
-- *****************************************************************
FUNCTION REMOTE_REDO_check (result_txt OUT VARCHAR2) RETURN number
IS
  tmp_varchar1 VARCHAR2(100);
  t_count      INTEGER;
  status       NUMBER := 0;
BEGIN

  IF (db_n_version NOT IN (102,111) AND pDBGFailCheck = FALSE) THEN
    return c_status_not_for_this_version;
  END IF;
  --
  -- Check to detect if REDO configuration is supported with beyond
  -- 11.2
  --
  --  For 11.2, REDO has changed its maximum number of remote redo transport 
  --  destinations from 9 to 30, we need to see if 10 is being used, and what 
  --  its default is, if its local, there is an error.
  --
  -- Condition 1) Archiving of log files is enabled
  --
  -- Condition 2) DB_RECOVERY_FILE_DEST is defined
  -- 
  -- Condition 3) No local destinations are defined
  -- 
  -- Condition 4) LOG_ARCHIVE_DEST_1 is in use, and is a remote destition
  -- 
  --
  -- Only continue if archive logging is on
  --

  BEGIN
    EXECUTE IMMEDIATE
      'SELECT LOG_MODE FROM v$database'
      INTO tmp_varchar1;
    EXCEPTION 
       WHEN NO_DATA_FOUND THEN tmp_varchar1 := 'NOARCHIVELOG';
  END;

  IF tmp_varchar1 != 'ARCHIVELOG' AND pDBGFailCheck = FALSE THEN
    RETURN c_status_success;
  END IF;

  --
  -- Check for db_recovery_file_dest
  --
  tmp_varchar1 := NULL;
  BEGIN
    EXECUTE IMMEDIATE 'SELECT vp.value FROM v$parameter vp WHERE  
               UPPER(vp.NAME) = ''DB_RECOVERY_FILE_DEST''' 
    INTO tmp_varchar1; 

    EXCEPTION
      WHEN NO_DATA_FOUND THEN NULL;
  END;

  IF tmp_varchar1 IS NOT NULL OR tmp_varchar1 != '' THEN
    --
    -- See if there are any local destinations defined
    -- Note the regexp_like 
    --
    EXECUTE IMMEDIATE '
      SELECT count(*) FROM v$parameter v 
        WHERE v.NAME  LIKE ''log_archive_dest_%'' AND 
        REGEXP_LIKE(v.VALUE,''*[ ^]?location([ ])?=([ ])?*'')'
    INTO t_count;

    IF t_count > 0 THEN
      --
      -- Next is _1 in use, and remote
      --
      EXECUTE IMMEDIATE '
        SELECT count(*) FROM v$archive_dest ad 
        WHERE ad.status=''VALID'' AND ad.dest_id=1 AND
                 ad.target=''STANDBY'''
      INTO t_count; 

      IF t_count = 1 THEN
        --
        -- There is an issue to report.
        --
        status := 1;
      END IF;
    END IF; -- t_count = 1
  END IF;  -- having local dest values set

  IF (status = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('REMOTE_REDO', 
        c_check_level_warning,
	'Starting with 11.2, only LOG_ARCHIVE_DEST_1 is used for defaulting local'
          || 'archival of redo data.'
          || ' You must specify a destination for local archiving since '
          || 'LOG_ARCHIVE_DEST_1 is not available.',
	'You must specify a destination for local archiving since '
          || 'LOG_ARCHIVE_DEST_1 is not available.',
        'BEGIN dbms_preup.REMOTE_REDO_fixup; END',
	c_dbua_detail_type_text,
        'You must specify a destination for local archiving since '
          || 'LOG_ARCHIVE_DEST_1 is not available.',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := REMOTE_REDO_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('REMOTE_REDO');
    END IF;
    RETURN c_status_failure;
   END IF;
END REMOTE_REDO_check;

FUNCTION REMOTE_REDO_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> REDO Configuration not supported in 11.2' || crlf
        || crlf || '     Your REDO configuration is defaulting the use of'
        || crlf || '     LOG_ARCHIVE_DEST_10 for local archiving of redo data to'
        || crlf || '     the recovery area and has also defined'
        || crlf || '     LOG_ARCHIVE_DEST_1 for remote use.'
        || crlf || '     Starting with 11.2, only LOG_ARCHIVE_DEST_1 is used for defaulting local'
        || crlf || '     archival of redo data.'
        || crlf || '     You must specify a destination for local archiving since'
        || crlf || '     LOG_ARCHIVE_DEST_1 is not available.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Manually specify a destination for local archiving.';
  END IF;
END REMOTE_REDO_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE REMOTE_REDO_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := REMOTE_REDO_fixup (result, tSqlcode);
END REMOTE_REDO_fixup;

FUNCTION REMOTE_REDO_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := REMOTE_REDO_gethelp(c_help_overview);
  return c_fixup_status_info;
END REMOTE_REDO_fixup;

-- *****************************************************************
--     SYNC_STANDBY_DB Section
-- *****************************************************************
FUNCTION SYNC_STANDBY_DB_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_null      CHAR(1);
  status      NUMBER;
BEGIN
  BEGIN
    EXECUTE IMMEDIATE 'SELECT NULL FROM v$parameter WHERE 
       name LIKE ''log_archive_dest%'' AND upper(value) LIKE ''SERVICE%''
       AND rownum <=1'
    INTO t_null;
       status := 1;
  EXCEPTION
      WHEN NO_DATA_FOUND THEN status := 0;
  END;

  IF (status = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('SYNC_STANDBY_DB', 
        c_check_level_warning,
        'Sync standby database prior to upgrade.',
        'Sync standby database prior to upgrade.',
        'Sync standby database prior to upgrade.',
        c_dbua_detail_type_sql,
        htmlentities('SELECT name FROM v$parameter WHERE' 
           || ' name LIKE ''log_archive_dest%'' AND'
           || ' upper(value) LIKE ''SERVICE%'' AND rownum <=1'),
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := SYNC_STANDBY_DB_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('SYNC_STANDBY_DB');
    END IF;
    RETURN c_status_failure;
   END IF;
END SYNC_STANDBY_DB_check;

FUNCTION SYNC_STANDBY_DB_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> Standby database not synced' || crlf
      || crlf || '     Sync standby database prior to upgrade.'
      || crlf || '     Your standby databases should be synched prior to upgrading.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Standby databases should be synced prior to upgrade.';
  END IF;
END SYNC_STANDBY_DB_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE SYNC_STANDBY_DB_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := SYNC_STANDBY_DB_fixup (result, tSqlcode);
END SYNC_STANDBY_DB_fixup;

FUNCTION SYNC_STANDBY_DB_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := SYNC_STANDBY_DB_gethelp(c_help_overview);
  return c_fixup_status_info;
END SYNC_STANDBY_DB_fixup;
-- *****************************************************************
--     SYS_DEFAULT_TABLESPACE Section
-- *****************************************************************
FUNCTION SYS_DEF_TABLESPACE_check (result_txt OUT VARCHAR2) RETURN number
IS
  t_ts1       VARCHAR2(30);
  t_ts2       VARCHAR2(30);
  status      NUMBER;
BEGIN

  EXECUTE IMMEDIATE 'SELECT default_tablespace FROM sys.dba_users WHERE username = ''SYS'''  
  INTO t_ts1;
  EXECUTE IMMEDIATE 'SELECT default_tablespace FROM sys.dba_users WHERE username = ''SYSTEM'''
  INTO t_ts2;

  IF (t_ts1 = 'SYSTEM') AND (t_ts2 = 'SYSTEM') AND (pDBGFailCheck = FALSE) THEN
    -- Everything is fine.
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('SYS_DEFAULT_TABLESPACE', 
        c_check_level_warning,
	'The SYSTEM or SYS schemas have been altered so their default tablespace'
           || ' is no longer SYSTEM.  Prior to upgrading, the schema default'
           || ' tablespace must be reset to the SYSTEM tablespace',
        'The SYSTEM or SYS schemas have been altered so their default tablespace',
        'BEGIN dbms_preup.SYS_DEF_TABLESPACE_fixup; END;',
	 c_dbua_detail_type_sql,
        htmlentities('select username,default_tablespace from sys.dba_users'
          || ' where username IN (''SYS'',''SYSTEM'')'),
	c_dbua_fixup_type_auto,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := SYS_DEF_TABLESPACE_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('SYS_DEFAULT_TABLESPACE');
    END IF;
    RETURN c_status_failure;
   END IF;
END SYS_DEF_TABLESPACE_check;

FUNCTION SYS_DEF_TABLESPACE_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> SYS and SYSTEM schema default tablespace has been altered' || crlf
     || crlf || '     Prior to upgrading your database, please ensure both'
     || crlf || '     the SYS and SYSTEM schema default their tablespace to SYSTEM.'
     || crlf || '       Execute: execute dbms_preup.SYS_DEF_TABLESPACE_fixup; ';
  ELSIF HelpType = c_help_fixup THEN
    return 'SYSTEM account default tablespace is altered to be SYSTEM.';
  END IF;
END SYS_DEF_TABLESPACE_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE SYS_DEF_TABLESPACE_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := SYS_DEF_TABLESPACE_fixup (result, tSqlcode);
END SYS_DEF_TABLESPACE_fixup;

FUNCTION SYS_DEF_TABLESPACE_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
  t_result_txt VARCHAR2(1000);
  t_ts1        VARCHAR2(128);
  rval         NUMBER := 1;
BEGIN
  --
  --  Check both SYS and SYSTEM and reset if needed
  --
  result_txt := '';
  pSqlcode := 1;
  EXECUTE IMMEDIATE 'SELECT default_tablespace FROM sys.dba_users WHERE username = ''SYS'''  
  INTO t_ts1;
  IF (t_ts1 != 'SYSTEM') THEN
    result_txt := 'Altering SYS schema default tablespace.  Result: ';
    rval := execute_sql_statement ('ALTER USER SYS DEFAULT TABLESPACE SYSTEM', t_result_txt, pSqlcode);
    result_txt := result_txt || TO_CHAR(pSqlcode);
  END IF;

  EXECUTE IMMEDIATE 'SELECT default_tablespace FROM sys.dba_users WHERE username = ''SYSTEM'''  
  INTO t_ts1;
  IF (t_ts1 != 'SYSTEM') THEN
    result_txt := result_txt || crlf || 'Altering SYSTEM schema default tablespace Result: ';
    rval := execute_sql_statement ('ALTER USER SYSTEM DEFAULT TABLESPACE SYSTEM', t_result_txt, pSqlcode);
    result_txt := result_txt || TO_CHAR(pSqlcode);
  END IF;
  --
  -- If both were executed, only the last status is returned.
  --
  RETURN rval;
END SYS_DEF_TABLESPACE_fixup;

-- *****************************************************************
--     ULTRASEARCH_DATA Section
-- *****************************************************************
FUNCTION ULTRASEARCH_DATA_check (result_txt OUT VARCHAR2) RETURN number
IS
  status  NUMBER := 0;
  i_count INTEGER;
BEGIN
  -- Once Ultra Search instance is created, wk$instance table is populated.
  -- The logic determines if Ultra Search has data or not by looking up
  -- wk$instance table. WKSYS.WK$INSTANCE table exists when Ultra Search is
  -- installed. If it's not installed, WKSYS.WK$INSTANCE doesn't exist and the
  -- pl/sql block raises exception. 
  --
  BEGIN
    EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM wksys.wk$instance'
      INTO i_count;
    -- count will be 0 when there are no rows in wksys.wk$instance
    -- Otherwise there is at least one row in 
    -- and an ultra search warning should be displayed
    IF (i_count != 0) THEN
       status := 1;
    END IF;
    EXCEPTION WHEN OTHERS THEN NULL;
  END;

  IF (status = 0 AND pDBGFailCheck = FALSE)
  THEN
    RETURN c_status_success;
  ELSE
    IF pOutputType = c_output_xml THEN
      result_txt:= genDBUAXMLCheck('ULTRASEARCH_DATA', 
        c_check_level_warning,
	'Ultra Search is not supported beyond 11.2 and is removed automatically during upgrade.'
         || ' If you need to preserve Ultra Search data please perform a manual cold backup prior to upgrade.',
	'Ultra Search data is present in the Database',
        'Optionally backup Ultra Search',
	 c_dbua_detail_type_text,
        'To verify that Ultrasearch data exists, execute' 
          || ' the following query: SELECT COUNT(*) FROM wksys.wk$instance',
	c_dbua_fixup_type_manual,
	c_dbua_fixup_stage_pre );
    ELSE
      result_txt := ULTRASEARCH_DATA_gethelp(c_help_overview);
    END IF;
    IF pOutputtingScripts THEN
      genFixup ('ULTRASEARCH_DATA');
    END IF;
    RETURN c_status_failure;
   END IF;
END ULTRASEARCH_DATA_check;

FUNCTION ULTRASEARCH_DATA_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'WARNING: --> Ultra Search not supported' || crlf
      || crlf || '     Ultra Search is not supported as of 11.2 and is removed during the upgrade.'
      || crlf || '     You may perform this task prior to the upgrade by  using wkremov.sql '
      || crlf || '     located in the rdbms/admin directory of the new software installation.'
      || crlf || '     If you wish to preserve the Ultra Search data please perform a manual'
      || crlf || '     cold backup prior to upgrade.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Ultra Search data may be backed up prior upgrade as it will be removed during the upgrade.';
  END IF;
END ULTRASEARCH_DATA_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE ULTRASEARCH_DATA_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := ULTRASEARCH_DATA_fixup (result, tSqlcode);
END ULTRASEARCH_DATA_fixup;

FUNCTION ULTRASEARCH_DATA_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
  -- Dump out the same thing we give for help
  result_txt := ULTRASEARCH_DATA_gethelp(c_help_overview);
  return c_fixup_status_info;
END ULTRASEARCH_DATA_fixup;

-- *****************************************************************
--     unsupported_version Section
-- *****************************************************************
FUNCTION unsupported_version_check (result_txt OUT VARCHAR2) RETURN number
IS
  status      NUMBER;
BEGIN
  --
  -- If the major (does not include fifth digit) is in the supported list
  -- we're good (if we are not failing all the checks)
  -- Also return SUCCESS if we are in XML because this is a manual
  -- only test.
  --
  -- Same check is done in init routine to set pUnsupportedUpgrade
  -- Using substr of c_version instead of hard-coding, for example 
  -- '121' avoids errors while versions are updated.
  --

  IF ( ( ( (instr (c_supported_versions, db_patch_vers) > 0) -- Supported ver found
          OR (db_major_vers = SUBSTR(c_version, 1,6))  -- DB is same version
         )  AND pDBGFailCheck = FALSE                  -- We want to fail all checks
       ) OR pOutputType = c_output_xml ) THEN       -- Output XML
    RETURN c_status_success;
  END IF;

  --
  -- The DBUA has its own check, this is for text version only
  --
  result_txt := unsupported_version_gethelp(c_help_overview);

  IF pOutputtingScripts THEN
    genFixup ('UNSUPPORTED_VERSION');
  END IF;
  RETURN c_status_failure;
END unsupported_version_check;

FUNCTION unsupported_version_gethelp (HelpType IN NUMBER) RETURN VARCHAR2
IS 
BEGIN
  IF HelpType = c_help_overview THEN
    return 'ERROR: --> Unsupported Version Upgrade' || crlf 
      || crlf || pStarHeader
      || crlf || CenterLine('**** YOU CANNOT UPGRADE THIS DATABASE TO THIS RELEASE ****')
      || crlf || pStarHeader
      || crlf || '     Direct upgrade from ' || db_patch_vers || ' is not supported.'
      || crlf || '     Please refer to Chapter 2 of the Oracle Database Upgrade Guide for'
      || crlf || '     the matrix of releases supported for direct upgrade.';
  ELSIF HelpType = c_help_fixup THEN
    return 'Database must be first upgraded to a supported release prior to upgrading to this release.';
  END IF;
END unsupported_version_gethelp;
--
-- Fixup (Procedure and function)
--
PROCEDURE unsupported_version_fixup 
IS
  result  VARCHAR2(1000);
  status  NUMBER;
  tSqlcode NUMBER;
BEGIN
  -- Call fixup and throw away the result
  status := unsupported_version_fixup (result, tSqlcode);
END unsupported_version_fixup;

FUNCTION unsupported_version_fixup (
         result_txt IN OUT VARCHAR2,
         pSqlcode    IN OUT NUMBER) RETURN number
IS
BEGIN
   result_txt := unsupported_version_gethelp(c_help_overview);
   return c_fixup_status_info;
END unsupported_version_fixup;

-- ****************************************************************************
--                             Specific Recommendation Area 
-- ****************************************************************************
--
-- "check-name"_recommend() 
--   These checks are usually just dumping out text either to the log or to 
--   the scripts
--
PROCEDURE dictionary_stats_recommend
IS
BEGIN
  IF pOutputType = c_output_text THEN
    --
    -- Stale Stats
    --
    DisplayLine(pPreScriptUFT,'BEGIN');
    DisplayCenter(pPreScriptUFT,pStarHeader);
    DisplayCenter(pPreScriptUFT,CenterLine('********* Dictionary Statistics *********'));
    DisplayCenter(pPreScriptUFT,pStarHeader);
    DisplayLineBoth(pPreScriptUFT, '');
    DisplayLineBoth(pPreScriptUFT, 'Please gather dictionary statistics 24 hours prior to');
    DisplayLineBoth(pPreScriptUFT, 'upgrading the database.');
    DisplayLineBoth(pPreScriptUFT, 'To gather dictionary statistics execute the following command');
    DisplayLineBoth(pPreScriptUFT, 'while connected as SYSDBA:');
    DisplayLineBoth(pPreScriptUFT, '    EXECUTE dbms_stats.gather_dictionary_stats;');
    DisplayLineBoth(pPreScriptUFT, '');
    DisplayLineBoth(pPreScriptUFT, pActionSuggested);
    DisplayLineBoth(pPreScriptUFT, '');
    DisplayLine(pPreScriptUFT,'END;');
    DisplayLine(pPreScriptUFT,'/');
  END IF;
END dictionary_stats_recommend;

PROCEDURE hidden_params_recommend
IS
  t_boolean BOOLEAN;
  t_status  NUMBER;
BEGIN
  IF pOutputType = c_output_text THEN
    --
    -- If there are no hidden params set, no need to recommend review.
    --
    t_boolean := FALSE;
    BEGIN
       EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM sys.v$parameter WHERE name LIKE ''\_%'' ESCAPE ''\'''
       INTO t_status;
       IF (t_status >= 1) THEN
         t_boolean := TRUE;
       END IF;
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    IF t_boolean THEN
      DisplayLine(pPreScriptUFT,'BEGIN');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayCenter(pPreScriptUFT,pStarHeader);
      DisplayCenter(pPreScriptUFT,CenterLine('*********** Hidden Parameters ***********'));
      DisplayCenter(pPreScriptUFT,pStarHeader);
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT, 'Please remove all hidden parameters prior to upgrading.');
      DisplayLineBoth(pPreScriptUFT, 'To view existing hidden parameters execute the following command');
      DisplayLineBoth(pPreScriptUFT, 'while connected AS SYSDBA:');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT, '    SELECT name,description from SYS.V$PARAMETER WHERE name');
      DisplayLineBoth(pPreScriptUFT, q'!        LIKE ''\_%'' ESCAPE ''\''!');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT, 'Changes will need to be made in the init.ora or spfile.');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT, pActionSuggested);
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLine(pPreScriptUFT,'END;');
      DisplayLine(pPreScriptUFT,'/');
      --
      -- These are only if we are dumping out a script - output the command listed above.
      --
      IF pOutputtingScripts THEN
        DisplayLine('');
        DisplayLine(' The Pre-Upgrade Fixup Script will display the Hidden Parameters');
        DisplayLine(' currently defined');
        DisplayLine(''); 
        DisplayLine(pPreScriptUFT,'BEGIN');

        DisplayLine(pPreScriptUFT, q'!dbms_output.put_line ('           ********    Existing Hidden Parameters   ********');!');
        DisplayLine(pPreScriptUFT, 'END;');
        DisplayLine(pPreScriptUFT, '/');
        DisplayLine(pPreScriptUFT, q'!SELECT name,description from SYS.V$PARAMETER WHERE name LIKE '\_%' ESCAPE '\';!');
      END IF;
    END IF; -- end of hidden_params_in_use
  END IF;
END hidden_params_recommend;


PROCEDURE underscore_events_recommend
IS
  t_boolean BOOLEAN;
  t_status  NUMBER;
BEGIN

  IF pOutputType = c_output_text THEN
    --
    -- underscore events that are set.
    --
    t_boolean := FALSE;
    BEGIN
      EXECUTE IMMEDIATE 'SELECT COUNT(1) FROM sys.v$parameter2 WHERE (UPPER(name) = ''EVENT'' 
           OR UPPER(name)=''_TRACE_EVENTS'') AND isdefault=''FALSE'''
      INTO t_status;
      IF (t_status >= 1) THEN
        t_boolean := TRUE;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

    IF t_boolean THEN
      DisplayLine(pPreScriptUFT, 'BEGIN');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayCenter(pPreScriptUFT,pStarHeader);
      DisplayCenter(pPreScriptUFT,CenterLine('************ Existing Events ************'));
      DisplayCenter(pPreScriptUFT,pStarHeader);
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT,'Please review any defined events prior to upgrading.');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT,'To view existing nondefault events execute the following commands');
      DisplayLineBoth(pPreScriptUFT,'while connected AS SYSDBA:');
      DisplayLineBoth(pPreScriptUFT,'  Events:');
      DisplayLineBoth(pPreScriptUFT,q'!    SELECT (translate(value,chr(13)||chr(10),'' '')) FROM sys.v$parameter2!');
      DisplayLineBoth(pPreScriptUFT,q'!      WHERE  UPPER(name) =''EVENT'' AND  isdefault=''FALSE'';!');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT,'  Trace Events:');
      DisplayLineBoth(pPreScriptUFT,q'!    SELECT (translate(value,chr(13)||chr(10),'' '')) from sys.v$parameter2!');
      DisplayLineBoth(pPreScriptUFT,q'!      WHERE (UPPER(name) = ''_TRACE_EVENTS'') AND isdefault=''FALSE'';!');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT,'Changes will need to be made in the init.ora or spfile.');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT, pActionSuggested);
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLine(pPreScriptUFT, 'END;');
      DisplayLine(pPreScriptUFT, '/');
      --
      -- These are only if we are dumping out a script - output the command listed above.
      --
      IF pOutputtingScripts THEN
        DisplayLine('');
        DisplayLine(' The Pre-Upgrade Fixup Script will display the Existing Events');
        DisplayLine(' currently defined');
        DisplayLine(''); 

        DisplayLine(pPreScriptUFT, 'BEGIN');
        DisplayLine(pPreScriptUFT, '');
        DisplayLine(pPreScriptUFT,q'!dbms_output.put_line  ('            ********           Existing Events       ********');!');
        DisplayLine(pPreScriptUFT,q'!dbms_output.put_line  ('            ********  Query may return no Rows Selected *****');!');
        DisplayLine(pPreScriptUFT, 'END;');
        DisplayLine(pPreScriptUFT, '/');

        DisplayLine(pPreScriptUFT,q'! SELECT (translate(value,chr(13)||chr(10),' ')) FROM sys.v$parameter2!');
        DisplayLine(pPreScriptUFT,q'!   WHERE  UPPER(name) ='EVENT' AND  isdefault='FALSE';!');

        DisplayLine(pPreScriptUFT, 'BEGIN');
        DisplayLine(pPreScriptUFT, q'!dbms_output.put_line ('            ********      Existing Trace Events      ********');!');
        DisplayLine(pPreScriptUFT,q'!dbms_output.put_line  ('            ********  Query may return no Rows Selected *****');!');
        DisplayLine(pPreScriptUFT, 'END;');
        DisplayLine(pPreScriptUFT, '/');

        DisplayLine(pPreScriptUFT,q'! SELECT (translate(value,chr(13)||chr(10),' ')) from sys.v$parameter2!');
        DisplayLine(pPreScriptUFT,q'!   WHERE (UPPER(name) = '_TRACE_EVENTS') AND isdefault='FALSE';!');

      END IF;
    END IF; -- end of non_default_events
  END IF;
END underscore_events_recommend;

PROCEDURE audit_records_recommend
IS
  t_boolean BOOLEAN;
  t_status  NUMBER;
BEGIN
  IF pOutputType = c_output_text THEN
    t_boolean := FALSE;
    t_status := 0;
    -- There are three checks here - for various options of audit records.
    BEGIN
      EXECUTE IMMEDIATE 'SELECT count(*) FROM sys.aud$ WHERE dbid is null'
      INTO t_status;
      IF t_status > 250000 THEN 
        t_boolean := TRUE;
      END IF;
    EXCEPTION 
      WHEN OTHERS THEN NULL;
    END;
    BEGIN
      -- Standard Auditing, only when Oracle Label Security (OLS) 
      -- and/or Database Vault (DV) is installed
      EXECUTE IMMEDIATE 'SELECT count(*) FROM system.aud$ WHERE dbid is null'
      INTO t_status;
      IF t_status > 250000 THEN 
        t_boolean := TRUE;
    END IF;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;
    BEGIN
      -- Fine Grained Auditing
      EXECUTE IMMEDIATE 'SELECT count(*) FROM sys.fga_log$ WHERE dbid is null'
      INTO t_status;
      IF t_status > 250000 THEN 
        t_boolean := TRUE;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END;

    IF t_boolean THEN
      DisplayLine(pPreScriptUFT, 'BEGIN');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayCenter(pPreScriptUFT,pStarHeader);
      DisplayCenter(pPreScriptUFT,CenterLine('******** Audit Record Pre-Processing ********'));
      DisplayCenter(pPreScriptUFT,pStarHeader);
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT, 'The database contains a large number of Audit records which can slow down');
      DisplayLineBoth(pPreScriptUFT, 'an upgrade.  Please review My Oracle Support note number 1329590.1 ');
      DisplayLineBoth(pPreScriptUFT, 'for options on processing these records prior to the upgrade to save');
      DisplayLineBoth(pPreScriptUFT, 'upgrade down time');
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLineBoth(pPreScriptUFT, pActionSuggested);
      DisplayLineBoth(pPreScriptUFT, '');
      DisplayLine(pPreScriptUFT, 'END;');
      DisplayLine(pPreScriptUFT, '/');
    END IF;
  END IF;
END audit_records_recommend;

PROCEDURE fixed_objects_recommend
IS
BEGIN
  IF pOutputType = c_output_text THEN
    DisplayLine(pPostScriptUFT, 'BEGIN');
    DisplayCenter(pPostScriptUFT,pStarHeader);
    DisplayCenter(pPostScriptUFT,CenterLine('******** Fixed Object Statistics ********'));
    DisplayCenter(pPostScriptUFT,pStarHeader);

    DisplayLineBoth(pPostScriptUFT,'');
    DisplayLineBoth(pPostScriptUFT,'Please create stats on fixed objects two weeks');
    DisplayLineBoth(pPostScriptUFT,'after the upgrade using the command:');
    DisplayLineBoth(pPostScriptUFT,'   EXECUTE DBMS_STATS.GATHER_FIXED_OBJECTS_STATS;');
    DisplayLineBoth(pPostScriptUFT,'');
    DisplayLineBoth(pPostScriptUFT, pActionSuggested);
    DisplayLineBoth(pPostScriptUFT, '');
    DisplayLine(pPostScriptUFT, 'END;');
    DisplayLine(pPostScriptUFT, '/');
  END IF;
END fixed_objects_recommend;

END dbms_preup;
/

