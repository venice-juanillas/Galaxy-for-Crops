#!/usr/bin/perl

use strict;

use Getopt::Long;

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -g, --geno          <genotype file>
    -p, --pheno         <phenotype file>
    -o, --output        <output basename>
~;
$usage .= "\n";

my ($geno,$pheno,$outfile);

GetOptions(
        "geno=s"     => \$geno,
	"pheno=s"    => \$pheno,
        "output=s"   => \$outfile
);

die $usage
  if ( !$geno || !$outfile || !$pheno);


my %variables;
open(GR,">$outfile.grouping");
print GR "Grouping\n";
open(OP,">$outfile.pheno");
open(P,$pheno);
my $first_line = <P>;
my $is_blup = 0;
if ($first_line =~/blup/ && $first_line =~/pevReliability/){
	$is_blup = 1;
}
my @gids;
if ($is_blup){
	my @infos = split(/\t/,$first_line);
	my @values;
	for (my $i = 3; $i <= $#infos; $i+=5){
		push(@values,$infos[$i]);
	}
	print OP "Concat_GID	".join("\t",@values)."\n";
}
else{
	print OP "Concat_GID	$first_line";
}
while(<P>){
	my $line = $_;$line =~s/\n//g;$line =~s/\r//g;
	my ($is_added,$gid,$variable) = split(/\t/,$line);
	$variables{$variable}=1;
	if ($is_blup){
		my @infos = split(/\t/,$line);
		my @values;
		for (my $i = 3; $i <= $#infos; $i+=5){
			push(@values,$infos[$i]);
		}
		print OP $gid."_".$variable."	".join("\t",@values)."\n";
	}
	else{
		print OP $gid."_".$variable."	$line\n";
	}
	push(@gids,$gid."_".$variable);
	
}
close(P);
close(OP);


open(G,$geno);
my $first_line = <G>;
open(OG,">$outfile.geno");
print OG $first_line;
my $bloc = "";
while(<G>){
	$bloc .= $_;
}
close(G);

my %corr;
my $n = 0;
foreach my $variable(keys(%variables)){
	$n++;
	$corr{$variable} = $n;
	print OG $bloc;

	}
close(OG);

foreach my $gid(@gids){
	my ($g,$variable) = split("_",$gid);
	#print "$gid $g $variable\n";
	my $n = $corr{$variable};
	print GR "$n\n";
}
close(GR);
