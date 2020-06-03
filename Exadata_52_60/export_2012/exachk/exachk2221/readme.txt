exachk readme.txt - Exadata configuration audit tool
----------------------------------------------------------------------------------

Please refer to the ExachkUserGuide.pdf file included with the bundle downloaded from MOS Note 1070954.1 for additional detail and up to date information. 

PURPOSE
=========
the tool is designed to audit various important configuration settings within an Exadata System - Database Servers, Storage Servers and Infiniband Switches..  The  tool audits configuration settings within the following categories

PLATFORMS SUPPORTED
======================
Please refer to MOS Note 1070954.1 for details
 

DATABASE VERSIONS SUPPORTED
============================
Please refer to MOS Note 1070954.1 for details
 

USAGE
======
Stage and run the tool only on database servers (ie., database servers) as the Oracle RDBMS software owner (eg., oracle) if Oracle software installed.

the tool can be run with following  arguments

  1   -a – default, performs all checks, best practice and database/clusterware patch/os recommendations.
  2.  -o - for invoking optional functionality
                v|verbose to display PASSing audit checks as well as non-PASSing
                eg., exachk -a -o v
                or exachk -a -o verbose

  3.  -v - returns the version of the tool
  4.  -s (silent, non-interactive mode, see exachk User Guide Automation section below)
  5.  -S (silent, non-interactive mode, see exachk User Guide Automation section below)
  6.  -m – suppresses the Maximum Availability Architecture Scorecard which is 
           enabled by default in exachk (See exachk User Guide Appendix L for more details)

WHEN TO RUN THE TOOL
=====================

1.  When the Grid Infrastructure and at least one database are all up and running
2.  During times of least load on the system
3.  After initial deployment
4.  Before system maintenance
5.  After system maintenance
6.  Approximately every two months


HOW TO OBTAIN SUPPORT
======================

If problems are encountered either at runtime or if there are questions about the content of the findings of the tool, 

Refer to the Exachk Tool How To downloadable from Note  1070954.1
Refer to the ExachkUserGuide.pdf downloaded with the Exachk bundle available from MOS Note  1070954.1
Finally if the problem is still not resolved then please log an SR with Oracle Support.

NOTE:  For more information about Password Handling, Multiple database support scenarios, Troubleshooting, etc  please refer to the exachk User Guide.


