#!/usr/bin/perl -w
use strict;

print "ARGV[0]: $ARGV[0]\n";
print "ARGV[1]: $ARGV[1]\n";
print "ARGV[2]: $ARGV[2]\n";
print "ARGV[3]: $ARGV[3]\n";
print "ARGV[4]: $ARGV[4]\n";
print "ARGV[5]: $ARGV[5]\n";
print "ARGV[6]: $ARGV[6]\n";
print "ARGV[7]: $ARGV[7]\n";
print "ARGV[8]: $ARGV[8]\n";
print "ARGV[9]: $ARGV[9]\n";

if (@ARGV!=11 && @ARGV!=10){
  print "\nUsage: $0 <genotype file> <phenotype file> \\ \n",
        "                        <gid colNum> <key variables> \\ \n",
        "                        <phenotype row start> <out.tsv> <hmp_out.mtx>\n";

  print "\n i.e.: $0 genotype.hmp phenotype.csv \\ \n",
        "                        5 3,4 \\ \n",
        "                        2 \n\n";

  exit();
} 

# Current input CSV files

my $inputGenotypeFile=$ARGV[0];
my $inputPhenotypeFile=$ARGV[1];
my $gidColNum=$ARGV[2]-1;
my $keyVarsColNums=$ARGV[3];
my $phenotypeRowStart=$ARGV[4];
my $output=$ARGV[5];
my $hmpout=$ARGV[6];
my $sampleNamesInfo=$ARGV[7];
my $genoNumLines=0;
my $add_NA=$ARGV[8];
my $membership_file=$ARGV[9];
my $trait_columns=$ARGV[10];

my @markers;
my %samples_geno;
my %genotyping;
open(H,$inputGenotypeFile);
while(<H>){
	my $line = $_;
	$line =~s/\n//g;$line =~s/\r//g;
	if (/alleles/){
		my @infos = split(/\t/,$line);		
		for (my $i = 11; $i <= $#infos; $i++){
			my $sample_name = $infos[$i];
			$samples_geno{$i} = $sample_name;
		}
	}
	elsif (!/#/){
		my @infos = split(/\t/,$line);
		my $marker = $infos[0];
		push(@markers,$marker);
		for (my $i = 11; $i <= $#infos; $i++){
			my $sample_name = $samples_geno{$i};
			$genotyping{$sample_name} .= $infos[$i]."\t";
		}
	}
}
close(H);


if (!$trait_columns){
	my $header = `head -1 $inputPhenotypeFile`;
	$header =~s/\n//g;$header =~s/\r//g;
	my @infos_header = split("\t",$header);
	my $factor_columns = ",".$keyVarsColNums.",";
	for (my $j = 0; $j <= $#infos_header; $j++){
		my $k = $j+1;
		if ($gidColNum ne $j && $factor_columns !~/,$k,/){
			$trait_columns .= "$k,"
		}
	}
	chop($trait_columns);
}


my @trait_cols = split(",",$trait_columns);
my @factor_cols = split(",",$keyVarsColNums);

open(OP,">$output");
my %concat_factors;
my %phenotyping;
open(P,$inputPhenotypeFile);
my $first_line_pheno = <P>;
$first_line_pheno =~s/\n//g;$first_line_pheno =~s/\r//g;
my @infos_fl = split(/\t/,$first_line_pheno);
print OP $infos_fl[$gidColNum];
foreach my $col(@factor_cols){
	my $val = $infos_fl[$col-1];
	print OP "|$val";
}
foreach my $col(@trait_cols){
	my $val = $infos_fl[$col-1];
	print OP "\t".$val;
}
print OP "\n";
my $numline = 1;
while(<P>){
	$numline++;
	if ($numline < $phenotypeRowStart){next;}
	my $line = $_;
	$line =~s/\n//g;$line =~s/\r//g;
	my @infos = split(/\t/,$line);
	my $sample_name = $infos[$gidColNum];
	my $concat_factor = "";
	foreach my $col(@factor_cols){
		my $val = $infos[$col-1];
		$concat_factor .= $val."|";
	}
	chop($concat_factor);
	$concat_factors{$concat_factor} = 1;
	foreach my $col(@trait_cols){
		my $val_pheno = $infos[$col-1];
		$phenotyping{$concat_factor}{$sample_name} .= "\t".$val_pheno;
	}
}
close(P);

open(OM,">$membership_file");
print OM "Grouping\n";
open(OG,">$hmpout");
print OG join("\t",@markers)."\n";
my $num_factor = 0;
foreach my $concat_factor(keys(%concat_factors)){
	$num_factor++;
	foreach my $sample_name(sort keys(%genotyping)){
		my $genoline = $genotyping{$sample_name};
		chop($genoline);
		if (exists $phenotyping{$concat_factor}{$sample_name}){
			my $pheno = $phenotyping{$concat_factor}{$sample_name};
			print OP "$sample_name|$concat_factor"."$pheno\n";
			print OG "$genoline\n";
			print OM "$num_factor\n";
		}
		elsif ($add_NA eq 'TRUE'){
			print OP "$sample_name|$concat_factor";
			foreach my $col(@trait_cols){
				print OP "\tNA";
			}		
			print OP "\n";
			print OG "$genoline\n";
			print OM "$num_factor\n";
		}
	}
}
close(OP);
close(OG);
close(OM);
