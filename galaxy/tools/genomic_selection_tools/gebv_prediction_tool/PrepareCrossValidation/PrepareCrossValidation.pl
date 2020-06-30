#!/usr/bin/perl

use strict;

use Getopt::Long;
use Cwd;
my $RepCourant = cwd();

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -p, --pheno                               <input phenotyping file>
    -m, --matrix                              <genotyping matrix>
    -o, --output                              <output file>
    -f, --first_phenotype_vector_column_index <first_phenotype_vector_column_index>
    -l, --last_phenotype_vector_column_index  <last_phenotype_vector_column_index>
    -s, --sample_name_vector_column_index     <sample_name_vector_column_index>
    -g, --grouping_cols                       <grouping columns>   
~;
$usage .= "\n";

my ($pheno,$outfile,$first,$last,$sample_col,$matrix,$groupingcols);
GetOptions(
        "pheno=s"    => \$pheno,
        "output=s"   => \$outfile,
	"first_phenotype_vector_column_index=s" => \$first,
	"last_phenotype_vector_column_index=s"  => \$last,
	"sample_name_vector_column_index=s"     => \$sample_col,
	"grouping_cols=s"                       => \$groupingcols,
	"matrix=s"                              => \$matrix
);

die $usage
  if ( !$pheno || !$matrix );



my $geno = $matrix;

my %genotyped_samples;
my %genotyped_samples2;
my %genotyping;
open(G,$geno);
my @pos;
while(<G>){
	my $line = $_;
        $line=~s/\n//g;
        $line=~s/\r//g;
        my @infos = split(/\t/,$line);
	if (/^rs#/){
		for (my $i=11;$i<=$#infos;$i++){
			my $sample = $infos[$i];
			$genotyped_samples{$sample} = $i;
			$genotyped_samples2{$i} = $sample;
		}
	}
	else{
		my $pos = $infos[3];
		my $chrom = $infos[2];
		push(@pos,$chrom."_".$pos);
		for (my $i=11;$i<=$#infos;$i++){
			my $genotype_value = $infos[$i];
			$genotyping{$genotyped_samples2{$i}}.=$genotype_value."\t";
		}
	}
}
close(G);

my @grouping_factors = ();
push(@grouping_factors,"none");
if ($groupingcols =~/,/){
	my ($groupingcols1,$groupingcols2) = split(",",$groupingcols);
	push(@grouping_factors,$groupingcols1);
	push(@grouping_factors,$groupingcols2);
	#$groupingcols = $groupingcols1;
}
elsif ($groupingcols =~/\d+/){
	push(@grouping_factors,$groupingcols);
}

my %samples_by_variable;
my %hash;
my $first_line;
foreach my $groupingfactor(@grouping_factors){
	print "$groupingfactor\n";
	open(P,$pheno);
	$first_line = <P>;
	while(<P>){
		my $line = $_;
		$line=~s/\n//g;
		$line=~s/\r//g;
		my @infos = split(/\t/,$line);
		my $variable = "all";
		if ($groupingfactor =~/\d+/){
			$variable = $infos[$groupingfactor-1];
		}
		my $sample = $infos[$sample_col-1];
		if ($genotyped_samples{$sample}){
			$hash{$variable}.=$line."\n";
			$samples_by_variable{$variable}.=$sample.",";
		}
		else{
			print "sample: $sample not genotyped\n";
		}
	}
	close(P);
}




my $done = 0;
my $tmpdir = "dir". int(rand(100000));
mkdir $tmpdir;
foreach my $variable(sort {$a<=>$b} keys(%hash)){
	my $pheno = $hash{$variable};
	my $length = scalar split(/\n/,$pheno);
	my @samples = split(",",$samples_by_variable{$variable});

	my $variable_reformatted = $variable;
	$variable_reformatted =~s/\//_/g;

	open(IP,">$variable_reformatted.pheno.txt");
	print IP $first_line;
	print IP $hash{$variable};
	close(IP);


	open(IG,">$variable_reformatted.geno.txt");
	print IG join("\t",@pos)."\n";
	foreach my $sample(@samples){
		my $genoyping_line = $genotyping{$sample};
		chop($genoyping_line);
		print IG "$genoyping_line\n";
	}
	close(IG);

}


