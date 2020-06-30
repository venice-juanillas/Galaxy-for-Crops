#!/usr/bin/perl

use strict;

use Getopt::Long;
use Cwd;
my $RepCourant = cwd();

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -p, --pheno                               <input phenotyping file>
    -m, --matrix                              <genotyping matrix>
~;
$usage .= "\n";

my ($pheno,$outfile,$matrix,$groupingfile);
GetOptions(
        "pheno=s"    => \$pheno,
	"matrix=s"   => \$matrix
);

die $usage
  if ( !$pheno || !$matrix );



my $geno = $matrix;

my $first_line_pheno = `head -1 $pheno`;
my $first_line_geno = `head -1 $matrix`;


my %hash_pheno;
my %hash_num;
my $num = 0;
open(P,$pheno);
<P>;
while(<P>){
	$num++;
	my $line = $_;
	$line=~s/\n//g;
	$line=~s/\r//g;
	my @infos = split(/\t/,$line);	
	my ($id,$factor) = split(/\|/,$infos[0]);
	$hash_pheno{$factor}.=$line."\n";
	$hash_num{$num} = $factor;
}
close(P);

my %hash_geno;
my $num = 0;
open(G,$geno);
<G>;
while(<G>){
	$num++;
	my $line = $_;
	$line=~s/\n//g;
	$line=~s/\r//g;
	my $factor = $hash_num{$num};
	$hash_geno{$factor}.=$line."\n";
}
close(G);


my $nb = 0;
my $done = 0;
foreach my $variable(sort {$a<=>$b} keys(%hash_pheno)){
	$nb++;
	if ($nb > 60){last;}
        my $pheno = $hash_pheno{$variable};
        #my $length = scalar split(/\n/,$pheno);
        #my @samples = split(",",$samples_by_variable{$variable});

        my $variable_reformatted = $variable;
        $variable_reformatted =~s/\//_/g;

        open(IP,">$variable_reformatted.pheno.txt");
        print IP $first_line_pheno;
        print IP $hash_pheno{$variable};
        close(IP);

	open(IG,">$variable_reformatted.geno.txt");
        print IG $first_line_geno;
        print IG $hash_geno{$variable};
        close(IG);
}

