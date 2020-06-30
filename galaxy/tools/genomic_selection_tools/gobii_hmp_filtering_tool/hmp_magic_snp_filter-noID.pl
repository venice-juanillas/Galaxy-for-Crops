#!/usr/bin/perl
# hapmap parser according to Chitra's specs
# filter out SNPs based on user-selected criteria - FOR LINES & founders
# RP Mauleon 10Dec 2013

# modified to accept GOBII-hapmap format
# Edit: VJuanillas (v.juanillas@irri.org
# Date: July 18, 2018

use warnings;
use List::Util qw( min max );  # to get min and max values in an array

my ($line, $taxa,$numTaxa, $ref,$missingCutoff);
my $ctA = $ctT = $ctC = $ctG = $monoCt = $het =0;
my $ctMissing =0; ## count of N for each SNP
my $validSampCut = 0.25 ; ## how much samples should be allowed to have missing SNP calls, for founders at least 2/8
my $maf = 0.125 ; ## minor allele frequency allowed ... optimized for 8 founders (at least 1/8 poly)
my $maxAF =1; #max allele frequency is 1
my @afs = () ; ## store NT freqs for each SNP, empty array...
my ($fA, $fT, $fC, $fG, $minAF); #allele freqs of each NT, minimum allele frequency not zero, 
my (@line,@taxa, @filteredLines);
my $het_cutoff = 0.8;	
my $hetPerc = 0;

if(!@ARGV){
	die " $! \nUsage: ./script <hapmap_file> <outputFile> <allowed-proportion-taxa-with-missing-SNPs> <MAF_cutoff> <incl_monomorphic> <hets_cutoff>\n";
}


my $infile; ## main data file is 1st parameter passed

$infile = $ARGV[0]; ## data file
my $outfile = $infile . "filtered"; ## automatic output filename ...

if ($ARGV[1]) { ## outputFilename specified
	$outfile =$ARGV[1]; 
} ## end if ARGV1

if ($ARGV[2]) { ## proportion of samples with missing SNP state allowed (default=0.25)
	$validSampCut =$ARGV[2]; 
} ## end if ARGV2

if ($ARGV[3]) { ## minor allele frequency
	$maf =$ARGV[3]; 
} ## end if ARGV3

if ($ARGV[4] == 1) { ## include monomorphic SNPs in dataset? boolean... 1=yes, any other = no
	$maxAF = 1.5; 
} ## end if ARGV4

if($ARGV[5]){ ## het cut-off threshold
	$het_cutoff = $ARGV[5]; 
}

open IN, "$infile"; # or die $!;
open OUT, ">$outfile"; ## parsed file output name


while (<IN>) {
	$line = $_;
	@line = split "\t", $line;
	$numTaxa = scalar(@line) - 12 ; ## compute number of taxa in data, the 1st 13 columns are NOT included
	
	if($line =~ m/^\#/){
		print OUT $line;
		next;
	}

	if ($line =~ m/rs\#/) { ## 1st line
		print OUT $line;
		next;
	} ## end print 1st line

	for (my $i = 11; $i < scalar(@line); $i++) { ## loop thru each array element (taxa) starting from 12...
			## some code to filter....
		## COUNT Ns
		if ($line[$i] =~ "NN") {
			$ctMissing ++;  ## increment count of N
		} ## end ct N
		## COUNT NT calls
		elsif ($line[$i] eq "AA") {
			$ctA ++;  ## increment count of A
		} ## end ct A...
		elsif ($line[$i] eq "TT") {
			$ctT ++;  ## increment count of T
		} ## end ct T...
		elsif ($line[$i] eq "CC") {
			$ctC ++;  ## increment count of C
		} ## end ct C...
		elsif ($line[$i] eq "GG") {
			$ctG ++;  ## increment count of G
		} ## end ct G...
		else{ # else
			$het ++;
		}
		
		
	} ## end for i
	##print "$numTaxa\t$ctMissing\n";
	
	#print "Het: $het\n";
	
	## CONDITIONAL printing of taxa lines ....
	$missingCutoff = sprintf("%0d", ($validSampCut * $numTaxa)); ## round off , this is the max # allowed to be missing...
	#$missingCutoff =($validSampCut * $numTaxa); ## round off , this is the max # allowed to be missing...
	$monoCt = $numTaxa - $ctMissing;  ## the number of observed non-N taxa
	if ($monoCt == 0) {
		$monoCt = 0.001 ; ## avoid div/0 error saka 
	} ## error handling...

	##compute NT frequencies
	$fA = $ctA/$monoCt;
	$fT = $ctT/$monoCt;
	$fC = $ctC/$monoCt;
	$fG = $ctG/$monoCt;
	#print "$fA\t$fT\t$fC\t$fG\n";
	
	# compute heterozygozity
	$hetPerc=$het/(scalar(@line)-11);
	
	push (@afs,  $fA) if $fA >0;
	push (@afs,  $fT) if $fT >0;
	push (@afs,  $fC) if $fC >0;
	push (@afs,  $fG) if $fG >0;
	$minAF = min @afs;  ## get the lowest number in this array - this is the min allele frequency 
	#print "$minAF\n";

	
	if ($ctMissing <= $missingCutoff && $hetPerc >= $het_cutoff ) {  ## Count of missing is less than maximum allowed...
		if ($minAF >= $maf && $minAF < $maxAF ) {  ## least frequent allele is > than MAF but not mono --> minAF = 0 
			print OUT $line;
		}
	} ## end if ctmissing < = missing cutoff
	
	
	#print "$monoCt \t $ctA \t $ctT \t $ctC \t $ctG \n";
	## reset the counters....
	$ctMissing = 0; ## reset
	$ctA = 0;
	$ctT = 0;
	$ctC = 0;
	$ctG = 0;
	$hetPerc = 0;
	@afs = ();

	
} ## end while IN

close IN;
close OUT;


