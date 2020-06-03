#!/bin/sh
#
# $Header: oss/image/SupportTools/exachk/checkDiskFGMapping.sh gadiga_exachk_2_2_2/2 2013/04/15 03:27:09 cnagur Exp $
#
# checkDiskFGMapping.sh
#
# Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      checkDiskFGMapping.sh - ASM disk group check
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    cnagur      04/15/13 - Fix for Bug: 16448891
#    gadiga      04/08/13 - ASM grid disk checker
#    gadiga      04/08/13 - Creation
#

pname="checkDiskFGMapping.sh"

exachk=0
silent=0
checkonly=0

# Process args
for arg in $*
do
  case $arg in
    "-silent")
      silent=1
      ;;
    "-checkonly")
      checkonly=1
      ;;
    "-exachk")
      exachk=1
      silent=1
      checkonly=1
      ;;
    "-report")
      exachk=1
      checkonly=0
      ;;
    *)
      echo "Unknown command line arg: $arg. Exiting."
      echo ""
      echo "Usage: $pname [-silent] [-checkonly]"
      echo "         -silent    : Don't prompt user for input."
      echo "         -checkonly : Don't take corrective action. Just check"
      echo "                      for disks in wrong failgroup and report."
      echo ""

      exit -1
  esac
done


oh=$ORACLE_HOME
workdir=/tmp/checkDiskFGMapping/
reportfile=${workdir}/checkDiskFGMapping_REPORT.txt
logfile=${workdir}/checkDiskFGMapping.log
exachk_hosts_file=/tmp/.exachk/cells.out

if [ ! -d "$workdir" ]
then
  mkdir $workdir
fi

if [ ! -d "$workdir" ]
then
  echo "Failed to create ${workdir}. Exiting"
  exit -1
fi

if [ $exachk -eq 1 ]
then
  if [ ! -f "$exachk_hosts_file" ]
  then
    echo "$exachk_hosts_file is not present"
    exit -1
  fi
fi

rndm=$RANDOM
tfile=${workdir}/tfile_${rndm}
touch $tfile
if [ ! -f "$tfile" ]
then
  echo "Unable to write to ${workdir}. Exiting"
  exit -1
fi
rm $tfile

my_maj_version=1
my_min_verion=1
dcli_user=celladmin


if [ $exachk -ne 1 ]
then
  echo ""
  echo "$pname : ${my_maj_version}.${my_min_verion=1}"
  echo ""
  echo "This script will check for ASM disks that have been"
  echo "incorrectly added to the wrong failgroup by"
  echo "Exadata Auto-Management. If found, it will attempt"
  echo "drop those disks and add them back to their rightful"
  echo "failgroup".
  echo ""
  echo "This problem in Exadata Auto-Management was reported"
  echo "as bug 12433293."
  echo ""
  echo "While a fix for this bug is available which will"
  echo "prevent such occurrences in the future, it cannot"
  echo "revert the wrong actions taken prior to this fix"
  echo "being applied."
  echo ""
  echo "This script will automatically detect and repair"
  echo "only if the grid disk naming convention in"
  echo "Best Practices are followed."
  echo ""
  echo "NOTE:"
  echo "1).  This script should be run by the ASM admin user."
  echo "2).  Ensure that ASM instance is running and all the"
  echo "     requisite diskgroups are mounted."
  echo "3).  Ensure all the cells are up and running."
  echo "4).  It should be possible to run dcli using celladmin"
  echo "     login credentials. The necessary user equivalence"
  echo "     should be in place."
  echo "        Please refer 787205.1"
  echo ""
  echo "WARNING: ONLY One copy of this script should be"
  echo "         running in a given ASM cluster"
  echo ""
  echo "If this script completed successfully, check"
  echo "   $reportfile"
  echo "and verify that all disks in the Exadata storage tier"
  echo "have been processed."
  echo "If not this typically means that one or more cells"
  echo "are down (or) disks on those cells are inaccessible."
  echo "Ensure all disks are accessible and re-run this script"
  echo ""
  echo "Do you want to continue (press 'y' or 'Y'): "
fi

proceed=""
if [ $silent -eq 0 ]
then
  read proceed
else
  if [ $exachk -eq 0 ]
  then
    echo "Running in silent mode"
  fi
  proceed="y"
fi

if [ "$proceed" != "y" -a "$proceed" != "Y" ]
then
  echo "Exiting"
  exit 0
fi

echo ""


if [ $exachk -eq 0 ]
then
  startTime=`date`
  echo "" | tee -a $logfile
  echo "" | tee -a $logfile
  echo "======================================================================" | tee -a $logfile
  echo " $pname : started at $startTime" | tee -a $logfile
  echo " =====================================================================" | tee -a $logfile

  echo "A record of this session will be available in $logfile"
  echo ""
  sleep 3
fi


if [ ! -d "$oh" ]
then
  echo "ORACLE_HOME: $oh is not valid" | tee -a $logfile
  exit -1
fi

if [ $exachk -eq 0 ]
then
  osid=$ORACLE_SID
  if [ "$osid" = "" ]
  then
    echo "ORACLE_SID needs to be set" | tee -a $logfile
    exit -1
  fi
fi


PATH=${PATH}:${oh}/bin
export PATH
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${oh}/lib
export LD_LIBRARY_PATH

same=0
toupper_name=""
tolower_name=""

initVars()
{
  totalDisks=0
  numDisksInWrongFG=0
  disksChecked=""
  disks2DropAndAdd=""
  disks2Add=""
  blankDisks=""
  disksInBadState=""
  diskList=""
  requiresManualSteps=0
  disks_file=""
}

cmp_case_insensitive()
{
  same=`awk -vs1="$1" -vs2="$2" 'BEGIN {
          if ( tolower(s1) != tolower(s2) ){
            print 0
          }
          else {
            print 1
          }
        }'`
}

toupper_wrapper()
{
  toupper_name=`awk -vs1="$1" 'BEGIN {
                  print toupper(s1)
                }'`
}


tolower_wrapper()
{
  tolower_name=`awk -vs1="$1" 'BEGIN {
                  print tolower(s1)
                }'`
}


manualSteps()
{
  echo "One or more grid disk names didn't follow the naming convention" | tee -a $logfile
  echo "of '<diskgroup_name>_CD_nn_<cellname>' and/or is NOT using " | tee -a $logfile
  echo "'<cellname>' as the failgroup name" | tee -a $logfile
  echo "" | tee -a $logfile
  echo "Manual instructions to fix the situation would be as follows" | tee -a $logfile
  echo "=====================================================================" | tee -a $logfile


  echo "For each griddisk in an Exadata DBM" | tee -a $logfile

  echo "- make sure the corresponding disk group is mounted" | tee -a $logfile

  echo "- check if its failgroup reflects to the failgroup it" | tee -a $logfile
  echo "  intends to belong (i.e., we recommend all griddisks" | tee -a $logfile
  echo "  from the same cell belong to the same failgroup and" | tee -a $logfile
  echo "  each cell is configured as an independent failgroup)" | tee -a $logfile
  echo "  using the following SQL:" | tee -a $logfile
   
  echo "   > select failgroup from v$asm_disk_stat where name = <ASM disk name>;" | tee -a $logfile

  echo "   - if the failgroup is correct, nothing needs to be done" | tee -a $logfile
  echo "   - if the failgroup is not correct (i.e., griddisk from" | tee -a $logfile
  echo "     one cell belongs to the failgroup of a different cell)," | tee -a $logfile
  echo "     issue the following SQLs to correct the failgroup association:" | tee -a $logfile

  echo "      > alter diskgroup <ASM diskgroup name> drop disk <ASM disk name>;" | tee -a $logfile
  echo "      [wait for drop rebalance to complete]" | tee -a $logfile
  echo "      > alter diskgroup <ASM diskgroup name> add failgroup <correct ASM failgroup name> disk <ASM disk name>;" | tee -a $logfile
}


findDisksInWrongFG()
{
  rndm=$RANDOM
  disks_file=${workdir}/disks_checkDiskFGMapping${rndm}.txt
  disk_header_file=${workdir}/diskHdr_checkDiskFGMapping${rndm}.txt

  ${oh}/bin/kfod disks=all a='o/*/*' | grep "o/" | awk '{print $4}' > $disks_file

  for path in `cat $disks_file`
  do
    if [ -f "$disk_header_file" ]
    then
      rm $disk_header_file
    fi

    disksChecked=`echo "$disksChecked $path"`
    diskInFormerStatus=0

    totalDisks=`expr $totalDisks + 1`

    cellip=`echo $path | awk -F/ '{print $2}'`
    gname=`echo $path | awk -F/ '{print $3}'`
    gname_suffix=`echo $gname | awk -F_ '{print $NF}'`

    if [ $exachk -eq 0 ]
    then
      cellname=`/usr/local/bin/dcli -l ${dcli_user} -c $cellip hostname -s | awk -F' ' '{ print $2 }'`
    else
      cellname=`grep $cellip $exachk_hosts_file | awk '{print $3}'`
      if [ $? -ne 0 ]
      then
        cellname=""
      fi
    fi

    # Check if disk name has a cell name suffix
    #if [ "$gname_suffix" != "$cellname" ]
   
    #Fix for Bug: 16448891
    if [ "`echo $gname_suffix | awk '{ print tolower($0) }'`" != "`echo $cellname | awk '{ print tolower($0) }'`" ] 
    then
      if [ $exachk -eq 0 -o $checkonly -eq 0 ]
      then
        echo "NOTE:" | tee -a $logfile
        echo "------------------------------------------------------------------" | tee -a $logfile
        echo "  Grid Disk name $gname does not have cell name ($cellname) suffix" | tee -a $logfile
        echo "  Naming convention not used. Cannot proceed further with" | tee -a $logfile
        echo "  automating checks and repair for bug 12433293" | tee -a $logfile
        echo "" | tee -a $logfile
      fi

      requiresManualSteps=1

      continue
    fi

    # Dump the disk header
    ${oh}/bin/kfed dev=$path op=read cnt=1 blknum=0 blksz=512 > $disk_header_file

    # Make sure this is an ORCLDISK
    grep ORCLDISK $disk_header_file > /dev/null
    if [ $? -ne 0 ]
    then
      if [ $exachk -eq 0 -o $checkonly -eq 0 ]
      then
        echo "NOTE:" | tee -a $logfile
        echo "------------------------------------------------------------------" | tee -a $logfile
        echo "  Grid Disk $path is not ASM managed" | tee -a $logfile
        echo "" | tee -a $logfile
      fi

      blankDisks=`echo "$blankDisks $path"`

      continue;
    fi


    # Check if this is a FORMER disk
    grep KFDHDR_FORMER $disk_header_file > /dev/null
    if [ $? -eq 0 ]
    then
      diskInFormerStatus=1

      if [ $exachk -eq 0 -o $checkonly -eq 0 ]
      then
        echo "NOTE:" | tee -a $logfile
        echo "------------------------------------------------------------------" | tee -a $logfile
        echo "  Grid Disk $path has been dropped cleanly from ASM diskgroup" | tee -a $logfile
        echo "" | tee -a $logfile
      fi

    else
      # Make sure this is a member disk
      grep KFDHDR_MEMBER $disk_header_file > /dev/null
      if [ $? -ne 0 ]
      then
        if [ $exachk -eq 0 -o $checkonly -eq 0 ]
        then
          echo "NOTE:" | tee -a $logfile
          echo "----------------------------------------------------------------" | tee -a $logfile
          echo "  Grid Disk $path is not in MEMBER status. Skipping this disk" | tee -a $logfile
          echo "" | tee -a $logfile
        fi

        disksInBadState=`echo "$disksInBadState $path"`
        continue;
      fi
    fi

    # Get failgroup name
    fgname=`grep kfdhdb.fgname $disk_header_file | awk '{print $2}'`

    # failgroup must be a cellname
    if [ $exachk -eq 0 ]
    then
      hname=`/usr/local/bin/dcli -l ${dcli_user} -c $fgname hostname -s | awk -F' ' '{ print $2 }'`
    else
      tolower_wrapper $fgname
      fgname_lower=$tolower_name

      hname=`grep $fgname_lower $exachk_hosts_file | awk '{print $3}'`
      if [ $? -ne 0 ]
      then
        hname=""
      fi
    fi

    cmp_case_insensitive $fgname $hname
    if [ $same -ne 1 ]
    then
      if [ $exachk -eq 0 -o $checkonly -eq 0 ]
      then
        echo "NOTE:" | tee -a $logfile
        echo "------------------------------------------------------------------" | tee -a $logfile
        echo "  failgroup name ($fgname) for grid disk $gname is not cell name" | tee -a $logfile
        echo "  Naming convention not used. Cannot proceed further with" | tee -a $logfile
        echo "  automating checks and repair for bug 12433293" | tee -a $logfile
        echo "" | tee -a $logfile
      fi

      requiresManualSteps=1
      continue
    fi

    # Get DG name from the block
    dgname=`grep kfdhdb.grpname $disk_header_file | awk '{print $2}'`

    # Get DG name from gname
    dgname_from_gname=`echo $gname | awk -F_CD '{print $1}'`

    # Check DG name is prefixed in the grid disk name
    if [ "$dgname" != "$dgname_from_gname" ]
    then
      if [ $exachk -eq 0 -o $checkonly -eq 0 ]
      then
        echo "NOTE:" | tee -a $logfile
        echo "------------------------------------------------------------------" | tee -a $logfile
        echo "  Grid Disk name $gname does not have Diskgroup name $dgname prefix" | tee -a $logfile
        echo "  Naming convention not used. Cannot proceed further with" | tee -a $logfile
        echo "  automating checks and repair for bug 12433293" | tee -a $logfile
        echo "" | tee -a $logfile
      fi

      requiresManualSteps=1
      continue
    fi

    # Check if grid disk name is same as ASM disk name
    gname_from_kfed=`grep kfdhdb.dskname $disk_header_file | awk -F: '{print $2}' | awk '{print $1}'`

    # grid disk name to upper
    toupper_wrapper $gname
    gname_upper=$toupper_name

    if [ "$gname_from_kfed" != "$gname_upper" ]
    then
      if [ $exachk -eq 0 -o $checkonly -eq 0 ]
      then
        echo "NOTE:" | tee -a $logfile
        echo "------------------------------------------------------------------" | tee -a $logfile
        echo "  Grid Disk name (upper case) is not the same as ASM diskname" | tee -a $logfile
        echo "    ASM Disk name : $gname_from_kfed" | tee -a $logfile
        echo "    Grid Disk name: $gname_upper (in uppercase)" | tee -a $logfile
        echo "  Naming convention not used. Cannot proceed further with" | tee -a $logfile
        echo "  automating checks and repair for bug 12433293" | tee -a $logfile
        echo "" | tee -a $logfile
      fi

      requiresManualSteps=1
      continue
    fi


    # Check to see if the Grid Disk name suffix is the same as the
    # Failgroup name
    cmp_case_insensitive $fgname $cellname
    if [ $same -ne 1 ]
    then
      if [ $exachk -eq 0 -o $checkonly -eq 0 ]
      then

        state="MEMBER"
        if [ $diskInFormerStatus -eq 1 ]
        then
          state="FORMER"
        fi

        toupper_wrapper $cellname
        cellname_upper=$toupper_name

        echo "WARNING:" | tee -a $logfile
        echo "------------------------------------------------------------------" | tee -a $logfile
        echo "  Grid Disk $path in $state state found in wrong failgroup" | tee -a $logfile
        echo "  Expected to be in $cellname_upper but found in $fgname" | tee -a $logfile
      fi

      if [ $diskInFormerStatus -eq 1 ]
      then
        disks2Add=`echo "$disks2Add $path"`
      else
        disks2DropAndAdd=`echo "$disks2DropAndAdd $path"`
      fi

      numDisksInWrongFG=`expr $numDisksInWrongFG + 1`
    fi
  done

  if [ -f "$disk_header_file" ]
  then
    rm $disk_header_file
  fi

  rm $disks_file
}


dropOrAddDisks()
{
  dropDisk=$1

  for path in $diskList
  do
    echo "Proceeding to fix $path ..." | tee -a $logfile
    gname=`echo $path | awk -F/ '{print $3}'`
    gname_suffix=`echo $gname | awk -F_ '{print $NF}'`

    fgname=$gname_suffix
    toupper_wrapper $fgname
    fgname=$toupper_name

    dgname=`echo $gname | awk -F_CD '{print $1}'`

    toupper_wrapper $gname
    gname_upper=$toupper_name

    rndm=$RANDOM
    tmpsql=${workdir}/checkDiskFGMapping${rndm}.sql
    tmpspool=${workdir}/checkDiskFGMapping${rndm}

    # Generate sql
    echo "Generating $tmpsql to check if diskgroup ($dgname) is mounted and " | tee -a $logfile
    echo "no disk reconfiguration operation is in progress" | tee -a $logfile

    echo "spool $tmpspool" > $tmpsql
    echo "set echo on" >> $tmpsql
    echo "" >> $tmpsql
    echo "VARIABLE rebal_inprogress NUMBER;" >> $tmpsql
    echo "VARIABLE dg_not_mounted NUMBER;" >> $tmpsql
    echo "" >> $tmpsql
    echo "DECLARE" >> $tmpsql
    echo "  c NUMBER := 1;" >> $tmpsql
    echo "  d NUMBER := 1;" >> $tmpsql
    echo "BEGIN" >> $tmpsql
    echo "" >> $tmpsql
    echo ":rebal_inprogress := 1;" >> $tmpsql
    echo ":dg_not_mounted := 1;" >> $tmpsql
    echo "" >> $tmpsql
    echo "select count(*) into c from x\$kfdpartner" >> $tmpsql
    echo "      where" >> $tmpsql
    echo "        active_kfdpartner=0" >> $tmpsql
    echo "          and" >> $tmpsql
    echo "        grp in" >> $tmpsql
    echo "          (" >> $tmpsql
    echo "           select group_number from v\$asm_diskgroup_stat" >> $tmpsql
    echo "             where" >> $tmpsql
    echo "               name='$dgname'" >> $tmpsql
    echo "                 and" >> $tmpsql
    echo "               state='MOUNTED'" >> $tmpsql
    echo "          );" >> $tmpsql
    echo "" >> $tmpsql
    echo "if (c = 0)" >> $tmpsql
    echo "then" >> $tmpsql
    echo "  :rebal_inprogress := 0;" >> $tmpsql
    echo "" >> $tmpsql
    echo "  select count(*) into d from v\$asm_diskgroup_stat" >> $tmpsql
    echo "        where" >> $tmpsql
    echo "          name='$dgname'" >> $tmpsql
    echo "            and" >> $tmpsql
    echo "          state='MOUNTED';" >> $tmpsql
    echo "" >> $tmpsql
    echo "  if (d = 1)" >> $tmpsql
    echo "  then" >> $tmpsql
    echo "    :dg_not_mounted := 0;" >> $tmpsql
    echo "  end if;" >> $tmpsql
    echo "end if;" >> $tmpsql
    echo "" >> $tmpsql
    echo "" >> $tmpsql
    echo "END;" >> $tmpsql
    echo "/" >> $tmpsql
    echo "" >> $tmpsql
    echo "print rebal_inprogress;" >> $tmpsql
    echo "print dg_not_mounted;" >> $tmpsql
    echo "" >> $tmpsql

    # Run sql
    echo "Running $tmpsql with output spooled to $tmpspool" | tee -a $logfile
    num_zeroes=`sqlplus / as sysasm < $tmpsql | egrep -A 2 -i "rebal_inprogress|dg_not_mounted"  | egrep "0" | wc -l`

#    rm -rf $tmpsql
#    rm -rf $tmpspool

    if [ $num_zeroes -eq 2 ]
    then
      tmpsql=${workdir}/checkDiskFGMapping${rndm}_alter.sql
      tmpspool=${workdir}/checkDiskFGMapping${rndm}_alter


      echo "Generating $tmpsql to" | tee -a $logfile
      if [ $dropDisk -eq 1 ]
      then
        echo "  Drop disk $path dg: $dgname name: $gname_upper fg: $fgname" | tee -a $logfile
      else
        echo "  Add disk $path dg: $dgname name: $gname_upper fg: $fgname" | tee -a $logfile
      fi

      # Generate sql
      echo "spool $tmpspool" > $tmpsql
      echo "set echo on" >> $tmpsql
 
      if [ $dropDisk -eq 1 ]
      then
        echo "alter diskgroup $dgname drop disk $gname_upper rebalance nowait;" >> $tmpsql
        echo "" | tee -a $logfile
      else
        echo "alter diskgroup $dgname add failgroup $fgname disk '$path' name $gname_upper rebalance nowait;" >> $tmpsql
        echo "" | tee -a $logfile
      fi

      echo "Running $tmpsql with output spooled to $tmpspool" | tee -a $logfile
      sqlplus / as sysasm < $tmpsql >& /dev/null
#      rm -rf $tmpsql
#      rm -rf $tmpspool
    fi

    echo "" | tee -a $logfile
  done
}


iter=0
while [ 1 ]
do
  iter=`expr $iter + 1`
  success=0

  initVars

  if [ $exachk -eq 0 -o $checkonly -eq 0 ]
  then
    echo "Iteration ${iter} : Checking for disks in wrong failgroup" | tee -a $logfile
    echo "" | tee -a $logfile
  fi

  findDisksInWrongFG

  if [ $totalDisks -eq 0 -a $exachk -eq 1 ]
  then
    if [ $checkonly -eq 0 ]
    then
      echo "Failed to find any disks"  | tee -a $logfile
    fi

    exit -1
  fi

  if [ $exachk -eq 0 -o $checkonly -eq 0 ]
  then
    echo "  Total Number of disks processed in this iteration: $totalDisks" | tee -a $logfile
    echo "  Num disks on wrong failgroup in this iteration   : $numDisksInWrongFG" | tee -a $logfile
  fi


  if [ $requiresManualSteps -eq 1 ]
  then
    if [ $exachk -eq 0 -o $checkonly -eq 0 ]
    then
      manualSteps
      echo "" | tee -a $logfile
      echo "" | tee -a $logfile
      echo "===================================================================" | tee -a $logfile
    fi

    exit -1
  fi

  if [ "$disksInBadState" != "" ]
  then
    success=1
    echo "Disks with bad header status" | tee -a $logfile
    for path in $disksInBadState
    do
      echo "  $path" | tee -a $logfile
    done
  fi

  if [ "$blankDisks" != "" ]
  then
    success=1
    echo "Blank Disks" | tee -a $logfile
    for path in $blankDisks
    do
      echo "  $path" | tee -a $logfile
    done
  fi

  if [ $exachk -eq 1 -o $checkonly -eq 1 ]
  then
    exit $success
  fi


  if [ $numDisksInWrongFG -eq 0 ]
  then
    echo "======================================================================" >> $reportfile
    echo " $pname : Report for session started at $startTime" >> $reportfile
    echo " ======================================" >> $reportfile
    echo "" >> $reportfile

    echo "Total Number of disks processed: $totalDisks" >> $reportfile
    echo "Num disks on wrong failgroup   : $numDisksInWrongFG" >> $reportfile

    echo "  Following disks were checked:" >> $reportfile

    for path in $disksChecked
    do
      echo "    $path" >> $reportfile
    done

    echo "" >> $reportfile
    echo "" >> $reportfile
    echo "===================================================================" >> $reportfile

    echo "" | tee -a $logfile
    echo "" | tee -a $logfile
    echo "Report written to $reportfile" | tee -a $logfile
    echo "Done" | tee -a $logfile
    echo "===================================================================" | tee -a $logfile


    exit 0
  fi

  if [ "$disks2Add" != "" ]
  then
    echo "Disks in wrong failgroup that have been dropped from their diskgroup" | tee -a $logfile
    echo "These disks need to be added back to diskgroup" | tee -a $logfile
    for path in $disks2Add
    do
      echo "  $path" | tee -a $logfile
    done

    if [ $checkonly -eq 0 ]
    then
      diskList=$disks2Add
      dropOrAddDisks 0
    fi
  fi

  if [ "$disks2DropAndAdd" != "" ]
  then
    echo "Disks in wrong failgroup that need to be dropped normal from their diskgroup" | tee -a $logfile
    echo "Once the disks have been dropped, add the disks back to diskgroup" | tee -a $logfile
    for path in $disks2DropAndAdd
    do
      echo "  $path" | tee -a $logfile
    done

    if [ $checkonly -eq 0 ]
    then
      diskList=$disks2DropAndAdd
      dropOrAddDisks 1
    fi
  fi

  if [ $checkonly -eq 1 ]
  then
    echo "Running in checkonly mode. Done with checks. Exiting" | tee -a $logfile

    exit $numDisksInWrongFG
  fi

  sleep_time=900
  echo "NOTE:" | tee -a $logfile
  echo "-------------------------------------------------------------------" | tee -a $logfile
  echo "  Sleeping for $sleep_time (sec) before checking again" | tee -a $logfile
  echo "" | tee -a $logfile
  sleep $sleep_time
done


