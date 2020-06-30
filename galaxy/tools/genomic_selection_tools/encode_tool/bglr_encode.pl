#!/usr/bin/perl

## Program Name: bglr_encode.pl
## Arguments:   <format type>- possible values: dominant,iupac
## 		<genotype_file>- genotype matrix to encode
## 		<coding_scheme>- codes for alleles (e.g (0,2) translates to minor homozygous, major homozygous respectively)
## 		<output>- standard output
##
## Date: June 22, 2017
## Author: Victor Jun Ulat (v.ulat@cgiar.org)
## Author: Venice Juanillas (v.juanillas@irri.org)


use strict;
use warnings;


## Usage:bglr_encode.pl <format_type> <genotype_file> <coding_scheme> <output>

if(!@ARGV || @ARGV!=4){
	print "Usage: bglr_encode.pl <format_type> <genotype_file> <coding_scheme> <output>\n";
	print "Example: bglr_encode.pl dominant GENOTYPE.csv 0,2 GENOTYPE_ENOCDED.csv\n";
	print "Example: bglr_encode.pl iupac GENOTYPE.csv 0,1,2,NA GENOTYPE_ENOCDED.csv\n";
	print "Example: bglr_encode.pl 2letter GENOTYPE.csv 0,1,2,NA GENOTYPE_ENOCDED.csv\n";
}

## get command line args
my $dataType = $ARGV[0]; 
my $gFile = $ARGV[1];
my $codingScheme = $ARGV[2];
my $output = $ARGV[3]; 

## what datatype?
if($dataType eq "dominant"){
	encodeDominant($gFile,$codingScheme,$output);
}elsif($dataType eq "iupac"){
	encodeIUPAC($gFile,$codingScheme,$output);
	#print "Encoding IUPAC";
}elsif($dataType eq "2letter"){
	encode2letter($gFile,$codingScheme,$output);
}

################## functions ###################
sub encode2letter{
	my ($geno, $code, $output) = @_;
	my ($homoMaj,$het,$homoMin, $miss) = split(/,/,$code);
	open(IN,'<',$geno) || die "Cannot open $geno.\n";
	open(OUT,'>',$output);
	
	## read the file line by line	
	while(my $line = <IN>){
		$line =~/^#/ and print OUT $line and next; ## skip of beginning with comment char '#'
		
		## start data processing at start of real hapmap header: look for " rs# " 
		if($line =~/^rs#/){
			chomp $line;
			## do we really need to split th eheader only to write it bacck again as tab-delimited????
			my @header = split(/\t/, $line);
			for(my $i = 0; $i <= $#header; $i++){
				$header[$i] =~ s/\s$//g;
				print OUT $header[$i]."\t";
			}	
			print OUT "\n";
		}else{
			## actual data matrix
			chomp $line;
			$line =~s/^\s$//g; ## remove empty lines
			my @row = split(/\t/,$line); ## split each row
			
			my ($allele1, $allele2) = split(/\//,$row[1]); ## split the alleles at column 2. Format is allele1/allele2
			## samples start at column 12.
			## replace according to code given
			for(my $i = 11; $i <= $#row; $i++){
				#print OUT "\t";
				$row[$i] =~ s/\s$//g;
				if($row[$i] eq join("",$allele1,$allele1)){ ## homo major
					$row[$i] = $homoMaj;
					#print OUT "\t".$homoMaj;
				}elsif($row[$i] eq join("",$allele2,$allele2)){ ## homo minor
					$row[$i] = $homoMin;
					#print OUT "\t".$homoMin;
				}elsif(($row[$i] eq join("",$allele1,$allele2)) or ($row[$i] eq join("",$allele2,$allele1))){ ## het
					$row[$i] = $het;
					#print OUT "\t".$het;
				}elsif(($row[$i] eq "NN") or ($row[$i] eq "--") or ($row[$i] eq "NA") ){ ## missing
					$row[$i] = $miss;
				}
			}
			
			## output encoded genotypes
			for(my $j = 0; $j <= $#row; $j++){
				print OUT $row[$j]."\t";
			}
			print OUT "\n";
		}
	}	

	close(IN);
	close(OUT);
}

## encode Dominant format
## if dominant, encoding scheme will always be (x,y) where:
## x = 1st allele
## y = 2nd allele
sub encodeDominant{
	my ($geno, $code, $output) =@_;
	my $linecount = 0;
	my @header;
	my @lines;
	my ($a,$b) = split(',',$code);
	open(IN, '<', $geno) or die "Cannot open $geno.\n";
	open(OUT, '>', $output);

	# encode as we read per line
	while(my $line = <IN>){
		$line=~m/^#\s/ and print OUT $line and next;
		chomp $line;
		if($linecount == 0){ ## parse header to get the lines	
			print OUT $line."\n";
		}else{
			@lines = split(',', $line); # split row contents
			for (@lines){s/0/$a/g}	# change all 0 to first number given in the code
			for (@lines){s/1/$b/g} # change all 0 to 2nd number given in the code
			my $row = join(',',@lines); # join everything
			print OUT $row."\n"; # output as encoded
		}
		$linecount++;
	}
	close(IN);
	close(OUT);
}

## encode IUPAC or bi-allelic format
##  Encoding scheme:
## 0- minor homo (w)
## 1- hets (x)
## 2- major homo (y)
## 3- missing (z)
## code = (w,x,y,z)
sub encodeIUPAC{
	my ($geno,$code,$output) = @_;
	my $linecount = 0;
	my @row;
	my ($w,$x,$y,$z) = split(',',$code);	
	my $useThisCode = $z; # default is set to missing
	## open files
	open(IN, '<', $geno) or die "Cannot open file: $geno\n";
	open(OUT, '>', $output);	

	## go through the lines in the genotype
	while(my $line = <IN>){
		$line=~m/^#\s/ and print OUT $line and next;	
		chomp $line;	
		if($linecount == 0){ #print header
			print OUT $line."\n";
		}else{ # parse succeeding data rows
			@row = split(',',$line);
			
			## skip first 11 columns
			#for(my $i = 11; $i < $#row; $i++) {
				## randomize what to use for minor or major homo
				if(int(rand(2)) == 0){
					$useThisCode = $w
				}else{$useThisCode=$y;}
				for (@row){s/A|C|T|G/$useThisCode/g} # encode every DNA base in the line
				for (@row){s/R|K|M|S|W|Y/$x/g} # encode all hets 
				for (@row){s/N|^-$|^\.$/$z/g} # encode missing values

				my $encoded = join(',',@row); # join everything
				print OUT $encoded."\n"; # output as encoded
			#}
		}
		$linecount++;
	}
	close(IN);
	close(OUT);
}

###### end of encode ########





