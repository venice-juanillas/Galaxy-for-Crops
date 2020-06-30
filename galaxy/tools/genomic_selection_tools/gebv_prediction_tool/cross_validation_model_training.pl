#!/usr/bin/perl

use strict;

use Getopt::Long;
use Cwd;
my $RepCourant = cwd();

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -p, --pheno                               <input phenotyping file>
    -o, --output                              <output file>
    -f, --first_phenotype_vector_column_index <first_phenotype_vector_column_index>
    -l, --last_phenotype_vector_column_index  <last_phenotype_vector_column_index>
    -s, --sample_name_vector_column_index     <sample_name_vector_column_index>
    -r, --response_type                       <response type>
    -e, --eta                                 <eta>
    -t, --tooldir                             <tool directory>
    -g, --grouping_cols                       <grouping columns>   
<opts>
    -k, --kfold                               <k folds. Default: 5> 
    -n, --nrandom                             <n randomizations. Default: 10>
~;
$usage .= "\n";

my ($pheno,$outfile,$first,$last,$sample_col,$response_type,$eta,$tooldir,$groupingcols);
my $kfold = 5;
my $nrandom = 10;
GetOptions(
        "pheno=s"    => \$pheno,
        "output=s"   => \$outfile,
	"first_phenotype_vector_column_index=s" => \$first,
	"last_phenotype_vector_column_index=s"  => \$last,
	"sample_name_vector_column_index=s"     => \$sample_col,
	"response_type=s"                       => \$response_type,
	"eta=s"                                 => \$eta,
	"tooldir=s"                             => \$tooldir,
	"kfold=s"                               => \$kfold,
	"nrandom=s"                             => \$nrandom,
	"grouping_cols=s"                       => \$groupingcols
);

die $usage
  if ( !$pheno || !$eta || !$outfile );



my ($geno,$model) = split(",",$eta);

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




open(O,">$outfile");
my $done = 0;
my $tmpdir = "dir". int(rand(100000));
mkdir $tmpdir;
foreach my $variable(sort {$a<=>$b} keys(%hash)){
	my $pheno = $hash{$variable};
	my $length = scalar split(/\n/,$pheno);
	my @samples = split(",",$samples_by_variable{$variable});

	my $variable_reformatted = $variable;
	$variable_reformatted =~s/\//_/g;

	open(IP,">$outfile.pheno.$variable_reformatted.txt");
	print IP $first_line;
	print IP $hash{$variable};
	close(IP);


	open(IG,">$outfile.geno.$variable_reformatted.txt");
	print IG join("\t",@pos)."\n";
	foreach my $sample(@samples){
		my $genoyping_line = $genotyping{$sample};
		chop($genoyping_line);
		print IG "$genoyping_line\n";
	}
	close(IG);
	
	my $cmd = "Rscript --vanilla $tooldir/gebv_prediction_wrapper2.R --input_phenotypes_file $outfile.pheno.$variable_reformatted.txt --sample_name_vector_column_index $sample_col --first_phenotype_vector_column_index $first --last_phenotype_vector_column_index $last --response_type $response_type --lower_bound_vector_column_index NULL  --upper_bound_vector_column_index NULL --eta $outfile.geno.$variable_reformatted.txt,$model --incidence_matrix_needs_transposition FALSE --weights_vector_column_index NULL  --number_of_iterations 1500  --burnin 500  --thinning 5  --saveat ''  --s0 NULL  --df0 5.0  --r2 0.5  --verbose TRUE --rmexistingfiles TRUE  --groups_vector_column_index NULL --kfold $kfold --p_out NULL --nrandom $nrandom --output_file $tmpdir/output.$variable_reformatted.txt";
	system($cmd);

	###########################
	# calculate means
	###########################
	my $res = `cat $tmpdir/output.$variable_reformatted.txt`;
	open(R,"$tmpdir/output.$variable_reformatted.txt");
	my $first_line_result = <R>;
	my %means;
	my $nb_traits;
	while(<R>){
		my $line = $_;
		$line=~s/\n//g;
		$line=~s/\r//g;
		my @infos = split(/\t/,$line);
		$nb_traits = $#infos;
		for (my $j = 1; $j <= $#infos; $j++){
			$means{$j}+=$infos[$j];
		}
	}
	close(R);

	if (!$done){	
		print O $first_line_result;
		$done = 1;
	}
	print O $variable;
	for (my $j = 1; $j <= $nb_traits; $j++){
		my $mean = $means{$j}/10;
		print O "\t$mean";
	}
	print O "\n";
	
	

	#print O "=================================\n$variable (size: $length)\n=================================\n$res\n\n\n";
	next;
	$cmd = "Rscript --vanilla $tooldir/gebv_prediction_wrapper2.R --input_phenotypes_file $outfile.pheno.$variable_reformatted.txt --sample_name_vector_column_index $sample_col --first_phenotype_vector_column_index $first --last_phenotype_vector_column_index $last --response_type $response_type --lower_bound_vector_column_index NULL  --upper_bound_vector_column_index NULL --eta $outfile.geno.$variable_reformatted.txt,$model --incidence_matrix_needs_transposition FALSE --weights_vector_column_index NULL  --number_of_iterations 1500  --burnin 500  --thinning 5  --saveat ''  --s0 NULL  --df0 5.0  --r2 0.5  --verbose TRUE --rmexistingfiles TRUE  --groups_vector_column_index NULL --kfold NULL --p_out NULL --nrandom NULL  --output_file $tmpdir/output.$variable_reformatted.2.txt";

	system($cmd);
	my $res = `cat $tmpdir/output.$variable_reformatted.2.txt`;
	print O $res."\n";
}
close(O);


