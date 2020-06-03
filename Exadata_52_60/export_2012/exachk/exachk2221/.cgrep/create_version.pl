#! /usr/bin/perl

use strict;

my $dir  = $ARGV[0];

my $PASS_MESSAGE 	= 'Version within recommended range.';
my $PASS_COLOR	 	= '#006600';
my $EXC_MESSAGE 	= 'Exception: Version is different from peers.';
my $EXC_COLOR	 	= '#C70303';
my $ALIGN		= 'CENTER';
my $NULL_VER_MSG        = 'N/A';

open(EFILE,">",$dir.'/versions.html');
close(EFILE);

#--------------------------CHECKS------------------------------
my $v_file 	= glob("$dir/../.*/versions.dat");
my $delimiter 	= ';';
my $h_checks;

open(CHKINP,'<',$v_file);
while(my $line = <CHKINP>) {
	next if($. <= 2);
	my ($id,$check,$threshold,$rule_eva,$dep_feature,$rec_version,$msg)= split($delimiter,$line);	
	($h_checks->{$id}->{'CHECK'}		= $check) 	=~ s/^\s*|\s*$//g;
	($h_checks->{$id}->{'THRESHOLD'}	= $threshold)	=~ s/^\s*|\s*$//g;	
	($h_checks->{$id}->{'RULE_EVALUATION'}	= $rule_eva)	=~ s/^\s*|\s*$//g;
	($h_checks->{$id}->{'DEP_FEATURE'}	= $dep_feature)	=~ s/^\s*|\s*$//g;		
	($h_checks->{$id}->{'REC_VERSION'}	= $rec_version)	=~ s/^\s*|\s*$//g;		
	($h_checks->{$id}->{'MSG'}		= $msg)		=~ s/^\s*|\s*$//g;		
}
close(CHKINP);
exit if(!$v_file);
#---------------------------FUNCTIONS-------------------------
sub create_expression {
	my $id 		= shift;	
	my $version 	= shift;

	$version = 0 if("$version" eq 'N/A');

	my @check       = split(',',$h_checks->{$id}->{'CHECK'});
	my @threshold   = split(',',$h_checks->{$id}->{'THRESHOLD'});
	my $exp;
	for(my $i=0;$i<scalar(@check);$i++){
		$threshold[$i] =~ s/\.(\d{1}$)/\.0$1/g;
	        $exp .= 'FV '.$check[$i].' '.$threshold[$i].' && ';
	}
	$exp =~ s/&& $//g;
	$version =~ s/\.(\d{1}$)/\.0$1/g;
	$exp =~ s/FV/$version/g;
	$exp =~ s/\.|-//g;	

	return $exp;
}

#--------------------------------------------------------------

my ($DB_HASH, $SS_HASH, $IBS_HASH);
my (@v_patterns);
my ($VERSION,@IDS);
my ($color, $msg);
my ($start_tr,$end_tr);
my ($rowspan);
my ($WBFC,$SFL,$SS_FOUND) =(0,0,0);

my @ssfiles;
my @f_patterns  = ('c_cbc_exadata_versions_', 'c_cbc_CellFlashCacheMode_', 'c_cbc_smart_flashlog_');
foreach(@f_patterns) {
        push(@ssfiles, glob("$dir/$_*.out"));
	push(@ssfiles, glob("$dir/outfiles/$_*.out"));
        push(@ssfiles, glob("$dir/\.CELLDIR/$_*.out"));
}
@ssfiles = grep(!/report/,@ssfiles);
@v_patterns = ('Exadata Server software version');
my ($SFL_FOUND,$WBFC_FOUND) =(0,0);
foreach(@ssfiles){
	open(OUTFILE ,'<', $_);
	
	my $name = $_;
	$name = $2 if($name =~ m/^.*_((.*)\.)out$/);

	my $value;
	if($_ =~ m/c_cbc_smart_flashlog_/){
		$SFL_FOUND=1;
		($value  = <OUTFILE>) =~ s/^\s*|\s*$//g;
		$SS_HASH->{'EXADATA'}->{$name}->{'SMART FLASH LOG'} = $value;
	}elsif($_ =~ m/c_cbc_CellFlashCacheMode_/){
		$WBFC_FOUND=1;
		($value  = <OUTFILE>) =~ s/^\s*|\s*$//g;
		$SS_HASH->{'EXADATA'}->{$name}->{'WBFC'} = $value;	
	}

	while(my $line = <OUTFILE>) {
		next if(chomp($line) =~ m/^\s*$/);
		$line =~ s|<.+?>||g;
		$line =~ s/^\s*|\s*$//g;

		foreach my $pattern(@v_patterns) {
			$VERSION='N/A';
			$SS_FOUND=1;
			if($line =~ m/\Q$pattern/i) {
				($line = <OUTFILE>) =~ s/^\s*|\s*$//g;
				$VERSION = $1 if($line =~ m/((\d{1,3}(\.|\-))+\d+)/);
				($VERSION = $1) =~ s/\.$//g if($VERSION =~ m/((\d{1,3}\.){5})/);
				$SS_HASH->{'EXADATA'}->{$name}->{'EVERSION'} = $VERSION;
			}
		}
	}	
	close(OUTFILE);	
}
if($SFL_FOUND == 0) {
	foreach(keys %{$SS_HASH->{'EXADATA'}}) {
		$SS_HASH->{'EXADATA'}->{$_}->{'SMART FLASH LOG'} = 0;	
	}
}
if($WBFC_FOUND == 0) {
	foreach(keys %{$SS_HASH->{'EXADATA'}}) {
		$SS_HASH->{'EXADATA'}->{$_}->{'WBFC'} = 0;	
	}
}

my %SS_NAMES;
my $ss_html;
if($SS_FOUND != 0){
	@IDS = ('ID2', 'ID3');
	foreach(sort {$a cmp $b} keys %{$SS_HASH->{'EXADATA'}}){
		$SFL = $SS_HASH->{'EXADATA'}->{$_}->{'SMART FLASH LOG'};
	        if(!exists $SS_NAMES{':'.$SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'}} && !exists $SS_NAMES{'WBFC:'.$SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'}}) {
			if($SS_HASH->{'EXADATA'}->{$_}->{'WBFC'} >= 1) {
		                $SS_NAMES{'WBFC:'.$SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'}} = $_;
			}else{
		                $SS_NAMES{':'.$SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'}} = $_;
			}
	        }else{
			if($SS_HASH->{'EXADATA'}->{$_}->{'WBFC'} >= 1) {
		                $SS_NAMES{'WBFC:'.$SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'}} .= ','.$_;
			}else{
		                $SS_NAMES{':'.$SS_HASH->{'EXADATA'}->{$_}->{'EVERSION'}} .= ','.$_;
			}
	        }
	}
	$rowspan = scalar(keys %SS_NAMES);
	$ss_html     = qq|<tr align=$ALIGN>
	                        <td scope="row" rowspan=$rowspan>STORAGE SERVER</td>
				<td scope="row" rowspan=$rowspan>Exadata</td>
	                |;
	($start_tr,$end_tr) = ('','</tr>');
	foreach my $unique_version(keys %SS_NAMES){
		foreach my $id(@IDS) {
			next if($h_checks->{$id}->{'DEP_FEATURE'} eq 'WBFC' && $unique_version !~ m/WBFC/i);
			next if($h_checks->{$id}->{'DEP_FEATURE'} ne 'WBFC' && $unique_version =~ m/WBFC/i);
	
			#-----
			if($unique_version =~ m/WBFC/i) {
				$WBFC = 1;
			}else{
				$WBFC = 0;
			}
			#-----
			
			my $version = $unique_version;
			$version =~ s/^.*://g;
			my ($ltd);
			if (eval &create_expression($id,$version)) {
				$color	= $EXC_COLOR;	
				$msg	= $h_checks->{$id}->{'MSG'};
				$msg    = $NULL_VER_MSG if("$version" eq "N/A");

				$msg   .= qq|<br>|.$EXC_MESSAGE if($rowspan > 1);
				$ltd 	= qq|<td scope="row"><font color=$color>$msg</font></td>|; 
			}else{
				$color 	= $PASS_COLOR;
				$msg	= qq|<font color=$color>$PASS_MESSAGE</font>|;	
				if($rowspan > 1){
					$color = $EXC_COLOR;
					$msg   = qq|<font color=$color>$EXC_MESSAGE</font>|;
				}
				$ltd	= qq|<td scope="row">$msg</td>|;
			}		
	
			#----
			my @server_count = split(',',$SS_NAMES{$unique_version});
			my $limit = 3;
			if(scalar(@server_count) <= $limit) {
				$ss_html      .= qq|
						$start_tr
						<td scope="row">
							<div id=$unique_version>$SS_NAMES{$unique_version}</div>
						</td>
						<td scope="row">$version</td>
						<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
						$ltd
						$end_tr		
						|;
			}else{
				$ss_html      .= qq|
						$start_tr
						<td scope="row">
							<a href="javascript:ShowHideRegion('$unique_version');">|.join(',',splice(@server_count,0,$limit)).qq|</a>
							<div id=$unique_version style="DISPLAY: none">|.join(',',@server_count).
							qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
							</div>
						</td>
						<td scope="row">$version</td>
						<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
						$ltd
						$end_tr		
						|;
			}	
			#----
			$start_tr = qq|<tr align=$ALIGN>|;
		}
	}
	$ss_html = '' if(!@ssfiles);
}
#---------------

my @dbfiles;
@f_patterns  = ('o_exadata_versions_');
my ($CLUSTER,$EXADATA,$RDBMS) = (0, 0, 0);
foreach(@f_patterns) {
        push(@dbfiles, glob("$dir/$_*.out"));
	push(@dbfiles, glob("$dir/outfiles/$_*.out"));
}
@dbfiles = grep(!/report/,@dbfiles);
@v_patterns = ('Exadata Server software version','Clusterware home','RDBMS home');
foreach(@dbfiles){
	open(OUTFILE ,'<', $_);

	my $name = $_;
	$name = $2 if($name =~ m/^.*_((.*)\.)out$/);

	while(my $line = <OUTFILE>) {
		next if(chomp($line) =~ m/^\s*$/);
		$line =~ s|<.+?>||g;
		$line =~ s/^\s*|\s*$//g;

		foreach my $pattern(@v_patterns) {
			$VERSION='N/A';
			if($line =~ m/\Q$pattern/i) {
				if($pattern eq 'Exadata Server software version') {
					($line = <OUTFILE>) =~ s/^\s*|\s*$//g;
					$VERSION = $1 if($line =~ m/((\d{1,3}(\.|\-))+\d+)/);
					($VERSION = $1) =~ s/\.$//g if($VERSION =~ m/((\d{1,3}\.){5})/);
					$DB_HASH->{'EXADATA'}->{$name}->{'EVERSION'} = $VERSION;
					$EXADATA=1;
				}elsif($pattern eq 'Clusterware home') {
					my $crhome = $1 if($line =~ m/\((.*)\)/);
					
                                        while($line = <OUTFILE>) {
                                                if($line =~ m/CRS PATCH/i){
                                                        last;
                                                }else{
                                                        $line='N/A';
                                                }
                                        }
                                        $VERSION = $1 if(defined $line && $line =~ m/((\d{1,3}(\.|\-))+\d+)/);
					$DB_HASH->{'EXADATA'}->{$name}->{'CLUSTER'}->{$crhome} = $VERSION;
					$CLUSTER=1;
				}elsif($pattern eq 'RDBMS home') {
					my $rdhome = $1 if($line =~ m/\((.*)\)/);
					
                                        while($line = <OUTFILE>) {
                                                if($line =~ m/DATABASE PATCH/i){
                                                        last;
                                                }else{
                                                        $line = 0;
                                                }
                                        }
                                        $VERSION = $1 if(defined $line && $line =~ m/((\d{1,3}(\.|\-))+\d+)/);
					$DB_HASH->{'EXADATA'}->{$name}->{'RDBMS'}->{$rdhome} = $VERSION;
					$RDBMS=1;
				}
			}
		}
	}	
	close(OUTFILE);	
}

my %DB_NAMES;
my $trowspan = 0;
my ($db_html,$exadata_html,$grid_html,$rdbms_html);
$db_html = qq|<tr align=$ALIGN><td scope="row" rowspan=DBCOUNT>DATABASE SERVER</td>|;
my $dbserver_list;

if($EXADATA != 0){
	@IDS = ('ID4');
	foreach(sort {$a cmp $b} keys %{$DB_HASH->{'EXADATA'}}){
		$dbserver_list .= ','.$_;
	        if(!exists $DB_NAMES{$DB_HASH->{'EXADATA'}->{$_}->{'EVERSION'}}) {
	                $DB_NAMES{$DB_HASH->{'EXADATA'}->{$_}->{'EVERSION'}} = $_;
	        }else{
	                $DB_NAMES{$DB_HASH->{'EXADATA'}->{$_}->{'EVERSION'}} .= ','.$_;
	        }
	}
	$dbserver_list =~ s/^,//g;
	$rowspan = scalar(keys %DB_NAMES);
	$exadata_html = qq|<tr align=$ALIGN><td scope="row" rowspan=$rowspan>Exadata</td>|;
	($start_tr,$end_tr) = ('','</tr>');
	foreach my $unique_version(keys %DB_NAMES) {
	        foreach my $id(@IDS) {
	                my ($ltd);
	                if (eval &create_expression($id,$unique_version)) {
	                        $color  = $EXC_COLOR;
	                        $msg    = $h_checks->{$id}->{'MSG'};
				$msg    = $NULL_VER_MSG if("$unique_version" eq "N/A");

	                        $msg   .= qq|<br>|.$EXC_MESSAGE if($rowspan > 1);
	                        $ltd    = qq|<td scope="row"><font color=$color>$msg</font></td>|;
	                }else{
	                        $color  = $PASS_COLOR;
	                        $msg    = qq|<font color=$color>$PASS_MESSAGE</font>|;
	                        if($rowspan > 1){
	                                $color  = $EXC_COLOR;
	                                $msg    = qq|<font color=$color>$EXC_MESSAGE</font>|;
	                        }
	                        $ltd    = qq|<td scope="row">$msg</td>|;
	                }
	
			my @server_count = split(',',$DB_NAMES{$unique_version});
			my $limit = 2;
			if(scalar(@server_count) <= $limit) {
	                	$exadata_html      .= qq|
	                                $start_tr
	                                        <td scope="row">
							<div id=$unique_version>$DB_NAMES{$unique_version}</div>
						</td>
	                                        <td scope="row">$unique_version</td>
	                                        <td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
	                                        $ltd
	                                $end_tr
	                                |;
			}else{	
		                $exadata_html      .= qq|
	                                $start_tr
	                                        <td scope="row">
							<a href="javascript:ShowHideRegion('$unique_version');">|.join(',',splice(@server_count,0,$limit)).qq|</a>
							<div id=$unique_version style="DISPLAY: none">|.join(',',@server_count).
							qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
							</div>
						</td>
	                                        <td scope="row">$unique_version</td>
	                                        <td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
	                                        $ltd
	                                $end_tr
	                                |;
			}
	                $start_tr = qq|<tr align=$ALIGN>|;
	        }
	}
	$exadata_html .= qq|</tr>|;
	$trowspan=$rowspan;
}
#------------

if($CLUSTER != 0){
	if($EXADATA != 0){
		$grid_html     .= qq|<tr align=$ALIGN><td scope="row" rowspan=GRIDCOUNT>Grid Infrastructure</td>|;
	}else{
		foreach(sort {$a cmp $b} keys %{$DB_HASH->{'EXADATA'}}){
			$dbserver_list .= ','.$_;
		}
		$dbserver_list =~ s/^,//g;
		$grid_html     .= qq|<td align=$ALIGN scope="row" rowspan=GRIDCOUNT>Grid Infrastructure</td>|;
	}

	@IDS=('ID5','ID6','ID7','ID8','ID9');
	my ($cluster_home, $cluster_version);
	foreach(sort {$a cmp $b} keys %{$DB_HASH->{'EXADATA'}}){
		while(my ($key , $value) = each(%{$DB_HASH->{'EXADATA'}->{$_}->{'CLUSTER'}})) {
			$cluster_home = $key;
			$cluster_version = $value;
			last;
		}
	}
	my $trow;
	my ($cmax,$ctmp) = (0,0);
	foreach my $id(@IDS){
	        my $abs = $h_checks->{$id}->{'REC_VERSION'};
	        $abs =~ s/\.(\d{1}$)/\.0$1/g;
	        $abs =~ s/\.|-//g;
	        $ctmp =~ s/\.(\d{1}$)/\.0$1/g;
	        $ctmp =~ s/\.|-//g;
	        if($ctmp < $abs) {
	                $ctmp = $h_checks->{$id}->{'REC_VERSION'};
	                $cmax = $h_checks->{$id}->{'REC_VERSION'};
	        }
	}
	
	my ($istart_tr,$iend_tr) = ('','</tr>');
	my $FAIL = 0;
	my $gridrow;
	foreach my $id(@IDS) {
		$msg = '';
		next if($WBFC == 0 && $id eq 'ID9');
	
		if (eval &create_expression($id,$cluster_version)) {
			$color  = $EXC_COLOR;
			$msg    = $h_checks->{$id}->{'MSG'};	
			$msg    = $NULL_VER_MSG if("$cluster_version" eq "N/A");

	                $trow  .= qq|
	                                $istart_tr
	                                <td align=$ALIGN scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
	                                <td align=$ALIGN scope="row"><font color=$color>$msg</font></td>
	                                $iend_tr
	                        |;
	                $FAIL   = $FAIL+1;
		}else{
			next;
		}
		$istart_tr = qq|<tr align=$ALIGN>|;
	}
	my ($start_tr,$end_tr) = ('','</tr>');
	if($FAIL >= 1) {
		my @server_count = split(',',$dbserver_list);
		my $limit = 2;
		if(scalar(@server_count) <= $limit) {
			$gridrow= qq|
			$start_tr
				<td align=$ALIGN scope="row" rowspan=$FAIL>
	                                <div id='GI'>$dbserver_list:</div>
	                                <br>$cluster_home
	                        </td>
	                        <td align=$ALIGN scope="row" rowspan=$FAIL>$cluster_version</td>
				$trow
			$end_tr
			|;
		}else{
			$gridrow= qq|
			$start_tr
	                        <td align=$ALIGN scope="row" rowspan=$FAIL>
	                                <a href="javascript:ShowHideRegion('GI');">|.join(',',splice(@server_count,0,$limit)).qq|</a>
	                                <div id='GI' style="DISPLAY: none">|.join(',',@server_count).
	                                qq|:<a href="javascript:ShowHideRegion('GI');"> ..Hide</a>
	                                </div>
	                                <br>$cluster_home
	                        </td>
				<td align=$ALIGN scope="row" rowspan=$FAIL>$cluster_version</td>
				$trow
			$end_tr
			|;
		}
	}else{
	        $color  = $PASS_COLOR;
	        $msg    = $PASS_MESSAGE;
	
		my @server_count = split(',',$dbserver_list);
		my $limit = 2;
		if(scalar(@server_count) <= $limit) {
			$gridrow= qq|
			$start_tr
	                        <td align=$ALIGN scope="row">
	                                <div id='GI'>$dbserver_list:</div>
	                                <br>$cluster_home
	                        </td>
	                        <td align=$ALIGN scope="row">$cluster_version</td>
	                        <td align=$ALIGN scope="row">$cmax</td>
	                        <td align=$ALIGN scope="row"><font color=$color>$msg</td>
			$end_tr
			|;
	
		}else{
			$gridrow= qq|
			$start_tr
	                        <td align=$ALIGN scope="row">
	                                <a href="javascript:ShowHideRegion('GI');">|.join(',',splice(@server_count,0,$limit)).qq|</a>
	                                <div id='GI' style="DISPLAY: none">|.join(',',@server_count).
	                                qq|:<a href="javascript:ShowHideRegion('GI');"> ..Hide</a>
	                                </div>
	                                <br>$cluster_home
	                        </td>
	                        <td align=$ALIGN scope="row">$cluster_version</td>
	                        <td align=$ALIGN scope="row">$cmax</td>
	                        <td align=$ALIGN scope="row"><font color=$color>$msg</td>
			$end_tr
			|;
		}
	}
	$grid_html .= $gridrow;
	if($FAIL == 0){
		$trowspan   = $trowspan + 1;
	}else{
		$trowspan   = $trowspan + $FAIL;
	}
	$grid_html  =~ s/GRIDCOUNT/\Q$FAIL/g;
}
#------------

if($RDBMS != 0) {  
	my %RD_NAMES;
	foreach my $server(sort {$a cmp $b} keys %{$DB_HASH->{'EXADATA'}}) {
		foreach my $rdhomes(keys %{$DB_HASH->{'EXADATA'}->{$server}->{'RDBMS'}}) {
			if(!exists $RD_NAMES{$rdhomes.':'.$DB_HASH->{'EXADATA'}->{$server}->{'RDBMS'}->{$rdhomes}}) {
				$RD_NAMES{$rdhomes.':'.$DB_HASH->{'EXADATA'}->{$server}->{'RDBMS'}->{$rdhomes}}  = $server;
			}else{
				$RD_NAMES{$rdhomes.':'.$DB_HASH->{'EXADATA'}->{$server}->{'RDBMS'}->{$rdhomes}} .= ','.$server;
			}
		}
	}		
	$rdbms_html     .= qq|<td scope="row" rowspan=DBHCOUNT>Database Home</td>|;
	($start_tr,$end_tr) = ('','</tr>');
	my $rdrow;
	@IDS=('ID10','ID11','ID12','ID13','ID14');
	
	my ($max,$tmp) = (0,0);
	foreach my $id(@IDS){
		my $abs = $h_checks->{$id}->{'REC_VERSION'};
		$abs =~ s/\.(\d{1}$)/\.0$1/g;
		$abs =~ s/\.|-//g;
		$tmp =~ s/\.(\d{1}$)/\.0$1/g;
		$tmp =~ s/\.|-//g;
		if($tmp < $abs) {
			$tmp = $h_checks->{$id}->{'REC_VERSION'};
			$max = $h_checks->{$id}->{'REC_VERSION'};
		} 	
	}
	
	my $irowspan=0;
	foreach(keys %RD_NAMES) {
		my $random=  int(rand(1000));
		my ($rdhome, $version) = split(':',$_);
		my $FAIL = 0;
		my $dbrow;
		my ($istart_tr,$iend_tr) = ('','</tr>');
		foreach my $id(@IDS) {
			$msg = '';
	
			next if($SFL == 0 && $id eq 'ID14');
	
			if (eval &create_expression($id,$version)) {
	                        $color  = $EXC_COLOR;
				$msg    = $h_checks->{$id}->{'MSG'};
				$msg    = $NULL_VER_MSG if("$version" eq "N/A");
				
				$dbrow .= qq|
					$istart_tr
					<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
					<td scope="row"><font color=$color>$msg</font></td>
					$iend_tr
				|;
				$FAIL 	= $FAIL+1;
			}else{
				next;
			}
			$istart_tr = qq|<tr align=$ALIGN>|;
		}
		if($FAIL >= 1) {
			my @server_count = split(',',$RD_NAMES{$_});
			my $limit = 2;
			if(scalar(@server_count) <= $limit) {
				$rdrow= qq|
	        	               $start_tr
	                               <td scope="row" rowspan=$FAIL>
						<div id=$random.$version>$RD_NAMES{$_}:</div>
						<br>$rdhome
					</td>
	                               <td scope="row" rowspan=$FAIL>$version</td>
				       $dbrow		
	                	       $end_tr
	                       	|;
			}else{
				$rdrow= qq|
	        	               $start_tr
	                               <td scope="row" rowspan=$FAIL>
						<a href="javascript:ShowHideRegion('$random.$version')">|.join(',',splice(@server_count,0,$limit)).qq|</a>
						<div id=$random.$version style="DISPLAY: none">|.join(',',@server_count).
						qq|<a href="javascript:ShowHideRegion('$random.$version');"> ..Hide</a>
						</div>
						<br>$rdhome
					</td>
	                               <td scope="row" rowspan=$FAIL>$version</td>
				       $dbrow
	                	       $end_tr
	                       	|;
			}
		}elsif($FAIL == 0) {
			$color 	= $PASS_COLOR;
			$msg 	= $PASS_MESSAGE; 
	
			my @server_count = split(',',$RD_NAMES{$_});
			my $limit = 2;
			if(scalar(@server_count) <= $limit) {
				$rdrow= qq|
	                       		$start_tr
	                                <td scope="row">
	                                        <div id=$random.$version>$RD_NAMES{$_}:</div>
	                                        <br>$rdhome
	                                </td>
	                                <td scope="row">$version</td>
	                                <td scope="row">$max</td>
				        <td scope="row"><font color=$color>$msg</td>		
		                        $end_tr
	                       |;
			}else{
				$rdrow= qq|
	                       		$start_tr
	                                <td scope="row">
	                                        <a href="javascript:ShowHideRegion('$random.$version')">|.join(',',splice(@server_count,0,$limit)).qq|</a>
	                                        <div id=$random.$version style="DISPLAY: none">|.join(',',@server_count).
	                                        qq|<a href="javascript:ShowHideRegion('$random.$version');"> ..Hide</a>
	                                        </div>
	                                        <br>$rdhome
	                                </td scope="row">
	                                <td scope="row">$version</td>
	                                <td scope="row">$max</td>
				        <td scope="row"><font color=$color>$msg</td>		
		                        $end_tr
	                       |;
			}
		}
		$rdbms_html .=$rdrow;
	        $start_tr = qq|<tr align=$ALIGN>|;	
		if($FAIL){
			$irowspan = $irowspan + $FAIL;
		}else{
			$irowspan = $irowspan + 1;
		}
	}
	$trowspan 	= $trowspan + $irowspan;
	$rdbms_html  	=~ s/DBHCOUNT/\Q$irowspan/;
}

$db_html       .= $rdbms_html.$grid_html.$exadata_html;
$db_html  	=~ s/DBCOUNT/\Q$trowspan/;
$db_html  	= '' if(!@dbfiles);
#---------------

my @ibsfiles;
@f_patterns  = ('s_nm2version_');
foreach(@f_patterns) {
        push(@ibsfiles, glob("$dir/$_*.out"));
	push(@ibsfiles, glob("$dir/outfiles/$_*.out"));
}
@ibsfiles = grep(/report/,@ibsfiles);
@v_patterns = ('infiniband switch firmware version');
foreach(@ibsfiles){
	open(OUTFILE ,'<', $_);

	my $name = $_;
	$name =~ s/_report//g;
	$name = $2 if($name =~ m/^.*_((.*)\.)out$/);

	while(my $line = <OUTFILE>) {
		next if(chomp($line) =~ m/^\s*$/);
		$line =~ s|<.+?>||g;
		$line =~ s/^\s*|\s*$//g;

		foreach my $pattern(@v_patterns) {
			$VERSION='N/A';
			if($line =~ m/\Q$pattern/i) {
				for(my $i=0;$i<=3;$i++) {
					$line = <OUTFILE>;
				}
				$VERSION = $1 if($line =~ m/((\d{1,3}(\.|\-))+\d+)/);	
				$IBS_HASH->{'IBSWITCH'}->{$name} = $VERSION;
			}
		}
	}	
	close(OUTFILE);	
}

my %IBS_NAMES;
my $ibs_html;
@IDS = ('ID1');
foreach(sort {$a cmp $b} keys %{$IBS_HASH->{'IBSWITCH'}}){
	if(!exists $IBS_NAMES{$IBS_HASH->{'IBSWITCH'}->{$_}}) {
		$IBS_NAMES{$IBS_HASH->{'IBSWITCH'}->{$_}} = $_;	
	}else{
		$IBS_NAMES{$IBS_HASH->{'IBSWITCH'}->{$_}} .= ','.$_;
	}
}
$rowspan = scalar(keys %IBS_NAMES);
$ibs_html     = qq|<tr align=$ALIGN>
			<td scope="row" rowspan=$rowspan>IB SWITCH</td>
			<td scope="row" rowspan=$rowspan>Firmware</td>
		|;
($start_tr,$end_tr) = ('','</tr>');
foreach my $unique_version(keys %IBS_NAMES) {
	foreach my $id(@IDS) {
		my ($ltd);
		if (eval &create_expression($id,$unique_version)) {
			$color	= $EXC_COLOR;	
			$msg	= $h_checks->{$id}->{'MSG'};
			$msg    = $NULL_VER_MSG if("$unique_version" eq "N/A");

			$msg   .= qq|<br>|.$EXC_MESSAGE if($rowspan > 1);
			$ltd 	= qq|<td scope="row"><font color=$color>$msg</font></td>|; 
		}else{
			$color 	= $PASS_COLOR;
			$msg	= qq|<font color=$color>$PASS_MESSAGE</font>|;	
			if($rowspan > 1){
				$color 	= $EXC_COLOR;
				$msg    = qq|<font color=$color>$EXC_MESSAGE</font>|;
			}
			$ltd	= qq|<td scope="row">$msg</td>|;
		}

		#----
		my @server_count = split(',',$IBS_NAMES{$unique_version});
		my $limit = 3;
		if(scalar(@server_count) <= $limit){
			$ibs_html      .= qq|
				$start_tr
					<td scope="row">
					<div id=$unique_version>$IBS_NAMES{$unique_version}
					</div>
					</td>
					<td scope="row">$unique_version</td>
					<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
					$ltd
				$end_tr		
				|;
		}
		else{
			$ibs_html      .= qq|
				$start_tr
					<td scope="row">
					<a href="javascript:ShowHideRegion('$unique_version');">|.join(',',splice(@server_count,0,$limit)).qq|</a>
					<div id=$unique_version style="DISPLAY: none">|.join(',',@server_count).
					qq|<a href="javascript:ShowHideRegion('$unique_version');"> ..Hide</a>
					</div>
					</td>
					<td scope="row">$unique_version</td>
					<td scope="row">$h_checks->{$id}->{'REC_VERSION'}</td>
					$ltd
				$end_tr		
				|;
		}
		$start_tr = qq|<tr align=$ALIGN>|;
	}	
}
$ibs_html = '' if(!@ibsfiles);

#----------------------------------------------------------
my $HEADER = qq|<table id='t_versions' border=1 width=100% summary="Software Version Matrix">
		<tr align=$ALIGN>
			<th scope="col" colspan=2>Component</th>
			<th scope="col">Host/Location</th>
			<th scope="col">Found version
			<th scope="col">Recommended versions</th>
			<th scope="col">Status</th>
		</tr>|;

my $FOOTER = qq|</table>|;

my $HTML = qq|
		<tr>
		<td colspan=6 scope="row">
		$HEADER
		$db_html
		$ss_html
		$ibs_html
		$FOOTER
		</td>
		</tr>
	|;

#----------------------------------------------------------
open(GENREPORT,'>',$dir.'/versions.html');
print GENREPORT $HTML if(@dbfiles || @ssfiles || @ibsfiles);
close(GENREPORT);

