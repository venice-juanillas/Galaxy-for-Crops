#!/usr/bin/perl

use strict;

use Getopt::Long;

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -i, --input         <input phenotyping file>
    -g, --geno          <input genotyping file>
    -o, --output        <output phenotyping file>
    -m, --missing_geno  <output name for list of samples phenotyped but not genotyped>
~;
$usage .= "\n";

my ($input,$outfile,$geno,$missing_file);


GetOptions(
        "input=s"    => \$input,
        "output=s"   => \$outfile,
	"geno=s"     => \$geno,
        "missing_geno=s"=> \$missing_file
);

die $usage
  if ( !$input || !$outfile || !$geno || !$missing_file);


my $line_samples_geno = `grep 'rs#' $geno`;

$line_samples_geno=~s/\n//g;$line_samples_geno=~s/\r//g;
my @elements = split(/\t/,$line_samples_geno);
my %genotyped_samples;
my @samples_to_output;
for (my $i = 11; $i <= $#elements; $i++){
	my $sample = $elements[$i];
	$genotyped_samples{$sample} = 1;
	push(@samples_to_output,$sample);
}

my %hash;
my %variables;
open(P,$input) or die "Can't open $input";

my $first_line = <P>;
my $trait;
my %phenotyped_samples;
if ($first_line =~/\t(\w+)_blue/){$trait = $1;}
my ($first,$second,$third) = split(/\t/,$first_line);
######################
# No summarizing
######################
if ($second =~/_blue/){
	while(<P>){
		my ($sample,$blue,$blup) = split(/\t/,$_);
		$phenotyped_samples{$sample} = 1;
		my $variable = "_";
		$hash{$sample}{$variable}{"blue"} = $blue;
		$variables{$variable}++;
		$hash{$sample}{$variable}{"blup"} = $blup;
	}
	
}
######################
# With summarizing
######################
elsif ($third =~/_blue/){
	while(<P>){
		my ($sample,$variable,$blue,$blup) = split(/\t/,$_);
		$phenotyped_samples{$sample} = 1;
		$hash{$sample}{$variable}{"blue"} = $blue;
		$variables{$variable}++;
		$hash{$sample}{$variable}{"blup"} = $blup;	
	}
}
close(P);

open(M,">$missing_file");
foreach my $sample(sort keys(%phenotyped_samples)){
	if (!$genotyped_samples{$sample}){
		print M "$sample\n";
	}
}
close(M);

open(O,">$outfile") or die "Can't open $outfile";
print O "Sample";
foreach my $variable(keys(%variables)){
	$variable =~s/ /_/g;
	print O "\t". $variable."_$trait"."_blue";
	print O "\t". $variable."_$trait"."_blup";	
}
#foreach my $variable(keys(%variables)){
#        $variable =~s/ /_/g;
#        print O "\t". $variable."_$trait"."_blup";
#}
print O "\n";
foreach my $sample(@samples_to_output){
	
	print O "$sample";
	foreach my $variable(keys(%variables)){
		my $blup = "NA";
		my $blue = "NA";
		if ($hash{$sample}{$variable}{"blue"}){
			$blue = $hash{$sample}{$variable}{"blue"};
		}
		if ($hash{$sample}{$variable}{"blup"}){
                        $blup = $hash{$sample}{$variable}{"blup"};
                }
		print O "\t$blue";
		print O "\t$blup";
	}
	#foreach my $variable(keys(%variables)){
        #        print O "\t".$hash{$sample}{$variable}{"blup"};
	#}
	print O "\n";
}
close(O);
