# /usr/bin/env perl
# Description: This script shoult able to convert IUPAC hapmap data to NPUTE inpute file format.
# Usage: makeNPUTEinpute.pl <input.hmp.txt> <output.csv> 
# Contact: s.sivasubramani@cgair.org

if($ARGV[1] eq ""){
	die "USAGE: $0 <input.hmp> <output.csv>\n";
}

$inHMP = $ARGV[0];
$outCSV = $ARGV[1];

# opening Input hapmap file
open(FA, $inHMP);
open(OUT, ">$outCSV");
while(<FA>){
	chomp();
	if($.==1){
		next;
	}
	@arr = split("\t", $_);
	@base = (); %hash = ();
	$idx = 11;
	# Some version fo hapmap file contains REFERENCE_GENOME as taxa. elemenating that column
	if($arr[11] eq "REFERENCE_GENOME"){
		$idx = 12;
	}


	for ($i=$idx;$i<=$#arr;$i++){
		# Checking if the file is in sincle nucleotide IUPAC file
		if(length($arr[$i])>1){
			die "Input file is not of IUPAC hapmap file format. Please convert to IUPAC format (not-biallelic) and run this script.\n";
		}
		# Converting non ATGC characters into missing
		if(($arr[$i] !~ /[ATGC]/i)){
			$arr[$i] = "?";
		}
		push (@base, $arr[$i]);
		$hash{$arr[$i]}++ if($arr[$i] ne "?");
	}

	$keys = keys(%hash);
	# Checking if the marker contains more than 2 alleles (excluding missing)
	if($keys gt 2){
		print "WARNING: Line $. contains more than 2 alleles. Converting third allele into missing.\n";
		foreach $nucl(sort {$hash{$b}<=>$hash{$a}} keys %hash){
			$sortOrd++;
			if($sortOrd gt 2){
				# Converting third or more minor alleles as missing
				s/$nucl/?/ for @base;
			}

		}
	}
	# pringting output
	print OUT join(",", @base),"\n";
}
close OUT;
close FA;
