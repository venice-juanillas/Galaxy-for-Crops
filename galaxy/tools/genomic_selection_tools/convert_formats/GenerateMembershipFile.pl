#!/usr/bin/perl

use strict;

use Getopt::Long;

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -g, --groups        <group file from sNMF or Admixture>
    -p, --pheno         <phenotype file>
    -o, --output        <output file>
~;
$usage .= "\n";

my ($groupfile,$pheno,$outfile);

GetOptions(
        "groups=s"   => \$groupfile,
	"pheno=s"    => \$pheno,
        "output=s"   => \$outfile
);

die $usage
  if ( !$groupfile || !$outfile || !$pheno);

my %groups;
my %groupnames;
open(F,$groupfile);
<F>;
while(<F>){
	my $line = $_;
	$line =~s/\n//g;
	$line =~s/\r//g;
	my ($sample,$group) = split(";",$line);
	$groups{$sample} = $group;
	$groupnames{$group} = 1;
}
close(F);

my $nbgroups = scalar keys(%groupnames);

my %groupnumbers;
my $num = 0;
foreach my $group(keys(%groupnames)){
	$num++;
	$groupnumbers{$group} = $num;
}

open(O,">$outfile");
print O "Grouping\n";
open(P,$pheno);
<P>;
while(<P>){
	my $line = $_;
	$line =~s/\n//g;
	$line =~s/\r//g;
	my ($sample,$environment,$samplebis) = split("\t",$line);
	my $group;
	if ($groups{$sample}){
		$group = $groups{$sample};
	}
	if ($groups{$environment}){
		$group = $groups{$environment};
	}
	if ($groups{$samplebis}){
		 $group = $groups{$samplebis};
	}
	my $num = $groupnumbers{$group};
	print O "$num\n";
}
close(P);
close(O);

#`paste $outfile $pheno >$output.2`;

