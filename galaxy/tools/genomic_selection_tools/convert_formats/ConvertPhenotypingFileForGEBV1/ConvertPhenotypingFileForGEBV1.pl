#!/usr/bin/perl

use strict;

use Getopt::Long;

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -i, --input         <input phenotyping file>
    -o, --output        <output file>
<opts> are:
    -t, --type          <type: blue or blup. Default: blue>
~;
$usage .= "\n";

my ($input,$outfile,$type);
$type =  "blue";

GetOptions(
        "input=s"    => \$input,
        "output=s"   => \$outfile,
	"type=s"     => \$type
);

die $usage
  if ( !$input || !$outfile );

my %hash;
my %variables;
open(P,$input) or die "Can't open $input";
my $test_is_added = `grep -c is_added $input`;
$test_is_added=~s/\n//g;
$test_is_added=~s/\r//g;
my $start = 2;
if ($test_is_added > 0){
	$start = 3;
}

my $first_line = <P>;
my %traits;
my %traits2;
my @infos1 = split(/\t/,$first_line);

if ($infos1[1] =~/blue/){
	$start = 1;
}
if ($infos1[2] =~/blue/){
        $start = 2;
}
if ($infos1[3] =~/blue/){
        $start = 3;
}
for (my $i = $start; $i <= $#infos1; $i+=5){
	my $blue_header = $infos1[$i];
	if ($blue_header =~/(\w+)_blue/){
		my $trait = $1;
		$traits{$i} = $trait;
		$traits2{$trait} = $i;
	}
}
my @samplenames;
while(<P>){

	my ($isadded,$sample,$variable,$blue,$blup) = split(/\t/,$_);
	my @infos = split(/\t/,$_);
		
	if ($test_is_added > 0){
		if ($start == 3){
			$sample = $infos[1];
			$variable = $infos[2];
		}
		elsif ($start == 2){
			$sample = $infos[1];
			$variable = "";
		}
	} 
	else{
		if ($start == 2){
			$sample = $infos[0];
			$variable = $infos[1];
		}
		elsif ($start == 1){
			$sample = $infos[0];
			$variable = "";
		}
	}
	
	if (!$hash{$sample}){
		push(@samplenames,$sample);
	}
	for (my $i = $start; $i <= $#infos; $i+=5){
		my $blue = $infos[$i];
		my $blup = $infos[$i+1];
		my $trait = $traits{$i};
		
		$hash{$sample}{$variable}{$trait}{"blue"} = $blue;
		$hash{$sample}{$variable}{$trait}{"blup"} = $blup;
	}	
	$variables{$variable}++;
}
close(P);


open(O,">$outfile") or die "Can't open $outfile";
print O "<Trait>";
foreach my $variable(keys(%variables)){
	$variable =~s/ /_/g;
	foreach my $trait(sort keys(%traits2)){
		print O "\t". $variable."_$trait"."_$type";
		#print O "\t". $variable."_$trait"."_blup";	
	}
}
#foreach my $variable(keys(%variables)){
#        $variable =~s/ /_/g;
#        print O "\t". $variable."_$trait"."_blup";
#}
print O "\n";
foreach my $sample(@samplenames){
	
	print O "$sample";
	foreach my $variable(keys(%variables)){
		foreach my $trait(sort keys(%traits2)){	
			print O "\t".$hash{$sample}{$variable}{$trait}{"$type"};
			#print O "\t".$hash{$sample}{$variable}{$trait}{"blup"};
		}
	}
	print O "\n";
}
close(O);
