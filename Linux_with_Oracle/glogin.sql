--
-- Copyright (c) 1988, 2011, Oracle and/or its affiliates. 
-- All rights reserved. 
--
-- NAME
--   glogin.sql
--
-- DESCRIPTION
--   SQL*Plus global login "site profile" file
--
--   Add any SQL*Plus commands here that are to be executed when a
--   user starts SQL*Plus, or uses the SQL*Plus CONNECT command.
--
-- USAGE
--   This script is automatically run
--
set sqlprompt "_user'@'_connect_identifier> "
set linesize 200