#!/usr/local/bin/perl
# 
# $Header: oss/image/SupportTools/exachk/diff_collections.pl gadiga_exachk_2_2_1_ci/8 2013/02/07 10:13:49 cgirdhar Exp $
#
# diff_collections.pl
# 
# Copyright (c) 2013, Oracle and/or its affiliates. All rights reserved. 
#
#    NAME
#      diff_collections.pl - <one-line expansion of the name>
#
#    DESCRIPTION
#      <short description of component this file declares/defines>
#
#    NOTES
#      <other useful comments, qualifications, etc.>
#
#    MODIFIED   (MM/DD/YY)
#    gadiga      02/04/13 - diff two exachk reports
#    gadiga      02/04/13 - Creation
# 
# Author: Andrego Halim
# Purpose: This script compares the result of two exachk run to analyze the changes between them
# use strict;
# use warnings;

my $version="1.0";

# Initializing variables to be used

# $ref and $new are the arguments supplied by the user
my $ref = $ARGV[0];
my $new = $ARGV[1];
#my $machinetype = $ARGV[2];
my $output_file = $ARGV[2];

my $machinetype = "";

my $same_cluster = 1;

# $refhtml and $newhtml are formed from the user-supplied arguments(if they aren't in html format yet)
my ($refhtml, $newhtml);

###### Sanity checking on the parameters given into the perl script ######
if ( ! $ref || ! $new )
{
  print "Usage : diffc.pl <exachk_output_folder_1> <exachk_output_folder_2>\n";
  exit;
}

if ( $ref =~ /\.html/ )
{
  $refhtml = "$ref";
}
else
{
  $refhtml = "$ref/$ref.html";
}

if ( $new =~ /\.html/ )
{
  $newhtml = "$new";
}
else
{
  $newhtml = "$new/$new.html";
}

if ( ! -r $refhtml || ! -r $newhtml )
{
  print "Can't read files. Please check $refhtml & $newhtml exist and are readable\n";
  exit;
}

my ($refhtml_color, $newhtml_color);
my ($ref_basename, $new_basename);
if ( $refhtml =~ /([^\/]+)\.html/ ) {
  #$refhtml_color = "<span style=\"color:green\">$1</span>";
  $refhtml_color = "$1";
  $ref_basename = $1;
}
if ( $newhtml =~ /([^\/]+)\.html/ ) {
  $newhtml_color = "$1";
  $new_basename = $1;
}
my @d = split(/_/, $ref_basename);
my @dn= split(/_/, $new_basename);
my $program_name = $d[0];
my $program_name_initcap = ucfirst($program_name);

if ( ! $output_file )
{
  $output_file = "${program_name}_$d[-2]$d[-1]_$dn[-2]$dn[-1]_diff.html";
}

###### End of sanity checking ######

# Declare %dh to be a hash table containing data from the first html
my %dh = ();

# list of check_id of all known checks
my %checkid_list = ();

# Summary table details

my %summary = ();

#### Process the first html file that will be compared to and extract the data from it into a hash table %dh
open(RF, $refhtml);
while(<RF>)
{
  my $temp_key;
  chomp;
  $line = $_;

  # Check if the line has info about the details of the pass/error message and its location. If it does, then parse the info
  if ( $line =~  /deletebutton.*deleteRow.*summary......(\w+)/)
  {
    %dh=parse_line("1",%dh);
  }
  # Check if the line has info about the name of the check
  if ( $line =~ /^<a href="#([\w\d]+)_summary.*/ )
  {
    $temp_key = $1;
    chomp;
    $line = <RF>;
    if ($line =~ /^<h3>(.*)<\/h3>/)
    {
      $checkid_list{$temp_key}->{NAME}=$1;
    }
  }
   elsif ( ! $machinetype && $line =~ /<title>Oracle (.*) Report<\/title>/ )
  {
    my $words = $1;
    $words =~ s/Upgrade Readiness//;
    $words =~ s/Assessment//;
    $machinetype = $words;
    $machinetype .= " Rack" if ( $machinetype =~ /Exalogic/ );

  }
   elsif ( ! $summary{"OLD-CDATE"} && $line =~ /Collection Date<\/td><td>(.*)<\/td>/ )
  {
    $summary{"OLD-CDATE"} = $1;
  }
   elsif ( ! $summary{"OLD-VERSION"} && $line =~ /k Version<\/td><td>(.*)<\/td>/ )
  {
    $summary{"OLD-VERSION"} = $1;
  }
   elsif ( ! $summary{"OLD-CLUSTER"} && $line =~ /Cluster Name<\/td><td>([^<]+)</ )
  {
    $summary{"OLD-CLUSTER"} = lc($1);
  }
}
close(RF);

# Declare %new_dh to be hash table containing new checks within second html that didn't exist in first html
my %new_dh = ();

### Process the second html file that will be compared to and compare it to the data from the first html as it progresses
open(RF, $newhtml);
while(<RF>)
{
  chomp;
  $line = $_;
  if ( $line =~ /deletebutton.*deleteRow.*summary......(\w+)/) 
  {
    %new_dh=parse_line("2",%new_dh);
  }
  # Check if the line has info about the name of the check
  if ( $line =~ /^<a href="#([\w\d]+)_summary.*/ )
  {
    $temp_key = $1;
    chomp;
    $line = <RF>;
    if ($line =~ /^<h3>(.*)<\/h3>/)
    {
      $checkid_list{$temp_key}->{NAME}=$1;
    }
  }
   elsif ( ! $summary{"NEW-CDATE"} && $line =~ /Collection Date<\/td><td>(.*)<\/td>/ )
  {
    $summary{"NEW-CDATE"} = $1;
  }
   elsif ( ! $summary{"NEW-VERSION"} && $line =~ /k Version<\/td><td>(.*)<\/td>/ )
  {
    $summary{"NEW-VERSION"} = $1;
  }
   elsif ( ! $summary{"NEW-CLUSTER"} && $line =~ /Cluster Name<\/td><td>([^<]+)</ )
  {
    $summary{"NEW-CLUSTER"} = lc($1);
    $summary{"NEW-CLUSTER"} =~ s/^ *//g;
    $summary{"NEW-CLUSTER"} =~ s/ *$//g;
    $summary{"OLD-CLUSTER"} =~ s/^ *//g;
    $summary{"OLD-CLUSTER"} =~ s/ *$//g;
    if ( $summary{"NEW-CLUSTER"} ne $summary{"OLD-CLUSTER"} )
    {
      $same_cluster = 0;
    }
  }

}
close(RF);

# Perform the data comparison from the two reports
foreach $check (keys %checkid_list)
{ 
  $checkid_list{$check}->{STATUS} = compare($check);
}

dump_html();

#-- end of main

# Auxiliary function called to parse each line within the html report containing a check. The parsed results are stored in $status, $type, $msg, $on, $key
# $status : WARNING, FAIL, INFO, PASS
# $type : OS Check, Switch Check, etc
# $msg : Success Message if it's a PASS, Failure Message otherwise
# $on : The nodes where the check pass/fail
# $key : <$check_id>_<$status> (Status is needed as a key since a check may show up in both PASS and non-PASS if the check doesn't pass in all intended nodes)
sub parse_line()
{
  my $key;
  my ($iter, %hash)=@_;
  if ( $line =~ /this,\W(\w+)_contents\'.*/)
  {
    $key = $1;
  }
  $checkid_list{$key}->{NAME}="";
  $pline = $line;
  $pline =~ s/.*_summary......//;

  if ( $pline =~ /(\w+)\<\/td..td\>([\w\s]+)\<\/td..td scope=\"row\"\>(.*)\<\/td..td\>[\<a.*\>]*([^\<]+)[\<\/a\>]*\<\/td..td\>.*\<\/td.\<\/tr/ )
  {
    $status = $1;
    $type = $2;
    
    if ( $status eq "PASS" ) 
    {
      $pass_msg = $3;
      $pass_on = $4;
      if ( $pass_on =~ /.*title\=\"(.*)\".*/ )
      {
         $pass_on = $1;
      }
    }
    else 
    {
      $error_label = $status;
      $error_msg = $3;
      $error_on = $4;
      if ( $error_on =~ /.*title\=\"(.*)\".*/ )
      {
         $error_on = $1;
      }
    }
  }
  $hash{$key}->{TYPE} = "$type";
  if ( $status eq "PASS" )
  {
    $hash{$key}->{PASS_MSG} = "$pass_msg";
    $hash{$key}->{PASS_ON} = "$pass_on";
    $hash{$key}->{PASS_LINE} = "$line";
  }
  else
  {
    $hash{$key}->{ERROR_LABEL} = "$error_label";
    $hash{$key}->{ERROR_MSG} = "$error_msg";
    $hash{$key}->{ERROR_ON} = "$error_on";
    $hash{$key}->{ERROR_LINE} = "$line";
  }
  $pass_msg = "";
  $pass_on = "";
  $error_label = "";
  $error_msg = "";
  $error_on = "";
  
  return %hash;
}

# Auxiliary function called by the parser of the second html report that will perform the comparison
sub compare
{
  my $check_id = shift;
  my $ret;
  # First, verify if the check id exists in the first html report
  if ( exists $dh{$check_id} )
  {
    # Check if the check id also exists in the second html report
    if ( exists $new_dh{$check_id} )
    {
      # If the check exists in both report, check if it pass and/or fail at the same nodes
      if ( ("$dh{$check_id}->{PASS_ON}" eq "$new_dh{$check_id}->{PASS_ON}" ) && ("$dh{$check_id}->{ERROR_ON}" eq "$new_dh{$check_id}->{ERROR_ON}" ) && ("$dh{$check_id}->{ERROR_LABEL}" eq "$new_dh{$check_id}->{ERROR_LABEL}" ) )
      { # Everything is same
        $ret = "same";
      }
       elsif ( $same_cluster == 0 && ("$dh{$check_id}->{ERROR_LABEL}" eq "$new_dh{$check_id}->{ERROR_LABEL}" ) )
      { # If results are from different clusters, ignore the host names
        if ( ( $dh{$check_id}->{PASS_ON} && ! $new_dh{$check_id}->{PASS_ON} ) ||
             ( ! $dh{$check_id}->{PASS_ON} && $new_dh{$check_id}->{PASS_ON} ) ||
             ( $dh{$check_id}->{ERROR_ON} && ! $new_dh{$check_id}->{ERROR_ON} ) ||
             ( ! $dh{$check_id}->{ERROR_ON} && $new_dh{$check_id}->{ERROR_ON} )
           )
        {
          $ret = "diff";
        }
         else
        {
          $ret = "same";
        }
      }
      else
      {
        $ret = "diff";
      }
    }
    else 
    {
      # if the check id doesn't exist in the second html report, tag it as "missing"
      $ret = "missing";
    }
  }
  else
  {
    # If key doesn't exist (meaning that it's a new check showing up in the 2nd html that didn't exist in the 1st html)
    $ret = "new";
  }
}

# Prints the comparison report from the processed data
sub dump_html
{
  $total = scalar(keys(%checkid_list));
  $missing = 0;
  $changed = 0;
  $new = 0;
  $same = 0;
  open(WF, ">$output_file") || die "Can't open $output_file\n";

  # Initialize the header for the comparison html report
  print WF <<EOF
<html lang="en"><head>
<style type="text/css">
body {font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 13px;
    background:white;
}
h1 {color:blue; text-align: center}
h2 {color:blue; background:white; font-family: Arial; font-size: 24px}
h3 {color:blue; background:white}
a {color: #000000;}
p {font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 13px;
}
.a_bgw {
  color: #000000;
  background:white;
}

table {
    color: #000000;
    font-weight: bold;
    border-spacing: 0;
    outline: medium none;
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 12px;
}

th {
 background: #D7EBF9;
    border: 1px solid #AED0EA;
    font-size: 13px;
    font-weight: bold;
}

th.checktype {
    width: 5%;
}
th.checkname {
    width: 15%;
}
th.status_halved {
    width: 40%;
}
th.status_halved_status{
    width: 5%;
}
td {
 background: #F2F5F7;
    border: 1px solid #AED0EA;
    font-weight: normal;
    padding: 5;
}

.status_FAIL
{
    font-weight: bold;
    color: #c70303;
}
.status_WARNING
{
    font-weight: bold;
    color: #b05c1c;
}
.status_INFO
{
    font-weight: bold;
    color: blue;
}
.status_PASS
{
    font-weight: bold;
    color: #006600;
}

.td_output {
    color: #000000;
    background: #E0E0E0;
    border: 1px solid #AED0EA;
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 13px;
    font-weight: normal;
    padding: 1;
}

.td_column {
 background: #D7EBF9;
    border: 1px solid #AED0EA;
    font-size: 13px;
    font-weight: bold;
}

.td_column_second {
 background: #D7EBF9;
    border: 1px solid #AED0EA;
    font-size: 11px;
    font-weight: bold;
}

td_report {
 background: #F2F5F7;
    border: 1px solid #AED0EA;
    font-weight: normal;
    padding: 5;
}

.td_report2 {
 background: #F2EDEF;
    border: 1px solid #AED0EA;
    font-size: 13px;
}

.td_report1 {
 background: #F2F5EE;
    border: 1px solid #AED0EA;
    font-size: 13px;
}   

.td_title {

 background: #F2F5F7;
    border: 0px solid #AED0EA;
    font-weight: normal;
    padding: 5;
}

.h3_class {
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 15px;
    font-weight: bold;
    color: blue;
    padding: 15;
}

.tips {
    display: none;
    position: absolute;
    border: 3px solid #AED0EA;;
    padding:5;
    background-color: #D7EBF9;
    width: 200px;
    font-family: Lucida Grande,Lucida Sans,Arial,sans-serif;
    font-size: 13px;
    font-weight: normal;
}

pre {
 overflow-x: auto; /* Use horizontal scroller if needed; for Firefox 2, not needed in Firefox 3 */
 white-space: pre-wrap; /* css-3 */
 white-space: -moz-pre-wrap !important; /* Mozilla, since 1999 */
 white-space: -pre-wrap; /* Opera 4-6 */
 white-space: -o-pre-wrap; /* Opera 7 */
 /* width: 99%; */
 word-wrap: break-word; /* Internet Explorer 5.5+ */
}

.shs_bar {
width: 500px ;
height: 20px ;
float: left ;
border: 1px solid #444444;
background-color: #656565 ;
}

.shs_barfill {
height: 20px ;
float: left ;
background-color: #FF9933 ;
width: 94% ;
}

</style>

<script type = "text/javascript">
function show_help(tipdiv, e ) 
{
  var x = 0;
  var y = 0;
  if ( document.all ) 
  {
    x = event.clientX;
    y = event.clientY;
  } 
   else 
  {
    x = e.pageX;
    y = e.pageY;
  }

  var element = document.getElementById(tipdiv);
  element.style.display = "block";
  element.style.left = x + 12;
  element.style.top = y + 10;
}

function hide_help(tipdiv) 
{
  document.getElementById(tipdiv).style.display = "none";
}
</script>

<title>${program_name_initcap} Baseline Comparison Report</title>
</head><body>

<center><table summary="Comparison Report" border=0 width=100%><tr><td class="td_title" align="center"><h1>${machinetype} Health Check Baseline Comparison Report<br><br></td></tr></table></center>
<h2>Table of Contents</h2>
<ul>
  <li><a class="a_bgw" href="#changed">Differences between Report 1 and Report 2</a></li>
  <li><a class="a_bgw" href="#missing">Unique findings in Report 1</a></li>
  <li><a class="a_bgw" href="#new">Unique findings in Report 2</a></li>
  <li><a class="a_bgw" href="#same">Common Findings in Both Reports</a></li>
</ul>
<hr><br/>
EOF
;
###################################################################################
  # Create a section for checks changed from the 1st to 2nd html report
  print WF <<EOF
<a name="changed"></a>
<table summary="Differences between Report 1 and Report 2" border=1 id="changedtbl">
  <tr>
    <td colspan="6" align="center" scope="row"><span class="h3_class">Differences between Report 1 ($refhtml_color) and Report 2 ($newhtml_color)</span><br/><br/></td>
  </tr>
  <tr>         
      <th scope="col" class="checktype" rowspan="2">Type</th>
      <th scope="col" class="checkname" rowspan="2">Check Name</th>
      <th scope="col" class="status_halved" colspan="2">Status On Report 1</th>
      <th scope="col" class="status_halved" colspan="2" border-left-style="solid" border-left-width="20">Status On Report 2</th>
  </tr>
  <tr>
     <th scope="col" class="status_halved_status">Status</th>
     <th scope="col">Status On</th>
     <th scope="col" class="status_halved_status">Status</th>
     <th scope="col">Status On</th>
  </tr>
EOF
;
  foreach $key (keys %checkid_list)
  {
    if ( $checkid_list{$key}->{STATUS} eq "diff" )
    {
      $changed++;
      if ( (! ($dh{$key}->{PASS_ON} ) || (! $dh{$key}->{ERROR_ON} )) && ((!$new_dh{$key}->{PASS_ON}) || (! $new_dh{$key}->{ERROR_ON})))
      {
        $rowspan1 = 1;
      } 
      else 
      {
        $rowspan1 = 2;
      }
      if ( $dh{$key}->{PASS_ON} && $dh{$key}->{ERROR_ON} ) 
      {
        $rowspan2=1;
      }
      else {
        $rowspan2=2;
      }
      if ( $new_dh{$key}->{PASS_ON} && $new_dh{$key}->{ERROR_ON} ) 
      {
        $rowspan3=1;
      }
      else {
        $rowspan3=2;
      }
      if ( ($rowspan2 eq 2) && ($rowspan3 eq 2) ){
        $rowspan2 = 1;
        $rowspan3 = 1;
      }
      print WF "<tr rowspan=$rowspan1>\n";
      print WF "<td rowspan=$rowspan1>$dh{$key}->{TYPE}</td>\n";
      print WF "<td scope=\"row\" rowspan=$rowspan1>$checkid_list{$key}->{NAME}</td>\n";
      $ret_extra_row1=print_node_status("td_report1", "WF", \%dh, $key, $rowspan2);
      $ret_extra_row2=print_node_status("td_report2", "WF", \%new_dh, $key, $rowspan3);
      if ( $ret_extra_row1 || $ret_extra_row2 ) 
      {
        print WF "<tr>\n$ret_extra_row1\n$ret_extra_row2</tr>\n";
      }
      print WF "</tr>\n";
    }
  }
  print WF "</table>\n";
  print WF "<a class=\"a_bgw\" href=\"#\">Top</a>\n";
  print WF "<hr><br/>\n";

  ###################################################################################
  # Create a section for checks that are missing in the 2nd html report
  print WF <<EOF
<a name="missing"></a>
<table summary="Unique findings in Report 1" border=1 id="missingtbl">
  <tr>
    <td colspan="4" align="center" scope="row"><span class="h3_class">Unique findings in Report 1 ($refhtml_color)<br/><br/></span></td>
  </tr>
  <tr>         
      <th scope="col" rowspan="2">Type</th>
      <th scope="col" rowspan="2">Check Name</th>
      <th scope="col" colspan="2">Status On Report 1</th>
  </tr>
  <tr>
     <th scope="col">Status</th>
     <th scope="col">Status On</th>
  </tr>
EOF
;
  foreach $key (keys %checkid_list)
  {
    if ( $checkid_list{$key}->{STATUS} eq "missing" )
    {
      $missing++;
      print WF "<tr>\n";
      print WF "<td>$dh{$key}->{TYPE}</td>\n";
      print WF "<td scope=\"row\">$checkid_list{$key}->{NAME}</td>\n";
      print_node_status("td_report", "WF", \%dh, $key);
      print WF "</tr>\n";
    }
  }
  print WF "</table>\n";
  print WF "<a class=\"a_bgw\" href=\"#\">Top</a>\n";
  print WF "<hr><br/>\n";

  ####################################################################################
  # Create a section for checks that are new in the 2nd html report, and doesn't show up in the 1st one
  ####################################################################################
  print WF <<EOF
<a name="new"></a>
<table summary="Unique findings in Report 2" border=1 id="missingtbl">
  <tr>
    <td colspan="4" align="center" scope="row"><span class="h3_class">Unique findings in Report 2 ($newhtml_color)<br/><br/></span></td>
  </tr>

  <tr>         
      <th scope="col" rowspan="2">Type</th>
      <th scope="col" rowspan="2">Check Name</th>
      <th scope="col" colspan="2">Status On Report 2</th>
  </tr>
  <tr>
     <th scope="col">Status</th>
     <th scope="col">Status On</th>
  </tr>
EOF
;
  foreach $key (keys %checkid_list)
  {
    if ( $checkid_list{$key}->{STATUS} eq "new" )
    {
      $new++;
      print WF "<tr>\n";
      print WF "<td>$new_dh{$key}->{TYPE}</td>\n";
      print WF "<td scope=\"row\">$checkid_list{$key}->{NAME}</td>\n";
      print_node_status("td_report", "WF", \%new_dh, $key);
      print WF "</tr>\n";
    }
  }
  print WF "</table>\n";
  print WF "<a class=\"a_bgw\" href=\"#\">Top</a>\n";
  print WF "<hr><br/>\n";

  ####################################################################################
  # Create a section for checks that didn't change between the 1st html report to the 2nd one
  ####################################################################################
  print WF <<EOF
<a name="same"></a>
<table summary="Common Findings in Both Reports" border=1 id="sametbl">
  <tr>
    <td colspan="4" align="center" scope="row"><span class="h3_class">Common Findings in Both Reports<br/><br/></span></td>
  </tr>
  <tr>         
      <th scope="col" rowspan="2">Type</th>
      <th scope="col" rowspan="2">Check Name</th>
      <th scope="col" colspan="2">Status On Both Report</th>
  </tr>
  <tr>
     <th scope="col">Status</th>
     <th scope="col">Status On</th>
  </tr>
EOF
;
  foreach $key (keys %checkid_list)
  {
    if ( $checkid_list{$key}->{STATUS} eq "same" )
    {
      $same++;
      print WF "<tr>\n";
      print WF "<td>$new_dh{$key}->{TYPE}</td>\n";
      print WF "<td scope=\"row\">$checkid_list{$key}->{NAME}</td>\n";
      print_node_status("td_report", "WF", \%new_dh, $key);
      print WF "</tr>\n";
    }
  }

  print WF "</table>\n";
  print WF "<a class=\"a_bgw\" href=\"#\">Top</a>\n";
  close(WF);
  
  # Done processing the comparison report
  ####################################################################################

  # Prepare summary table to be displayed at the top of the html report
  print "Summary \n";
  print "Total   : $total\n";
  print "Missing : $missing\n";
  print "New     : $new\n";
  print "Changed : $changed\n";
  print "Same    : $same\n";
  my $row1 = "";
  my $row2 = "";
  if ( $same_cluster == 0 )
  {
    $row1 = "<tr><td class=\"td_column_second\">&nbsp;&nbsp;&nbsp;Cluster Name</td><td>".$summary{"OLD-CLUSTER"}."</td></tr>";
    $row2 = "<tr><td class=\"td_column_second\">&nbsp;&nbsp;&nbsp;Cluster Name</td><td>".$summary{"NEW-CLUSTER"}."</td></tr>";
  }
  rename $output_file, "$output_file.orig";
  open FILE, ">", $output_file;
  open ORIG, "<",  "$output_file.orig";
  while (<ORIG>) {
    print FILE <<EOF
      <H2>$machinetype Health Check Baseline Comparison summary</H2>
      <table border=1 summary="Comparison Summary" role="presentation">
      <tr><td class="td_column">Report 1</td><td>$refhtml_color</td></tr>$row1
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;Collection Date</td><td>$summary{"OLD-CDATE"}</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;${program_name} Version</td><td>$summary{"OLD-VERSION"}</td></tr>
      <tr><td class="td_column">Report 2</td><td>$newhtml_color</td></tr>$row2
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;Collection Date</td><td>$summary{"NEW-CDATE"}</td></tr>
      <tr><td class="td_column_second">&nbsp;&nbsp;&nbsp;${program_name} Version</td><td>$summary{"NEW-VERSION"}</td></tr>
      <tr><td class="td_column">Total Checks Reported</td><td>$total</td></tr>
      <tr><td class="td_column">Differences between<br/>Report 1 and Report 2</td><td>$changed</td></tr>
      <tr><td class="td_column">Unique findings<br/>in Report 1</td><td>$missing</td></tr>
      <tr><td class="td_column">Unique findings<br/>in Report 2</td><td>$new</td></tr>
      <tr><td class="td_column">Common Findings<br/>in Both Reports</td><td>$same</td></tr>
      </table>

<div id="totaldiv" class="tips" style="z-index:1000;display:none">Total number of checks reported</div>
<div id="changeddiv" class="tips" style="z-index:1000;display:none">Number of checks changed between Report 1 and Report 2</div>
<div id="missingdiv" class="tips" style="z-index:1000;display:none">Number of checks missing in Report 2 </div>
<div id="newdiv" class="tips" style="z-index:1000;display:none">Number of checks new in Report 2</div>
<div id="samediv" class="tips" style="z-index:1000;display:none">Number of checks without any change</div>
EOF
    if /<h2>Table of Contents<\/h2>/; print FILE $_;
  }
  close ORIG;
  close FILE;
  unlink "$output_file.orig";
  use Cwd qw();
  my $path = Cwd::cwd();
  print "File comparison is complete. The comparison report can be viewed in: $path/$output_file\n"
}

# This function prepares the detail for a specified check from a specified report
sub print_node_status()
{
  my $tdclass = @_[0];
  my $out = @_[1];
  my %hash = %{$_[2]};
  my $check_id = $_[3];
  my $return_next_row;
  my $rowspan = $_[4];
  if ( $hash{$check_id}->{PASS_ON} )
  {
    print $out "<td class=\"$tdclass\" rowspan=$rowspan scope=\"row\">";
    print $out "PASS</td>\n<td class=\"$tdclass\" rowspan=$rowspan>$hash{$check_id}->{PASS_ON}</td>\n";
    if ( $hash{$check_id}->{ERROR_ON} ) 
    {
      $return_next_row="<td class=\"$tdclass\" scope=\"row\">$hash{$check_id}->{ERROR_LABEL}</td>\n<td class=\"$tdclass\">$hash{$check_id}->{ERROR_ON}</td>\n";
    }
  }
  else  
  {
    print $out "<td class=\"$tdclass\" rowspan=$rowspan scope=\"row\">$hash{$check_id}->{ERROR_LABEL}</td>\n<td class=\"$tdclass\" rowspan=$rowspan>$hash{$check_id}->{ERROR_ON}</td>\n";
  }
  return $return_next_row;
}
