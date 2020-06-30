# /usr/bin/env perl
# Description: This script shoult able to convert IUPAC hapmap data to NPUTE inpute file format.
# Usage: makeHMPfromNPUTEoutput.pl <input.hmp.txt> <output.csv> <output.hmp.txt> 
# Contact: s.sivasubramani@cgair.org

if($ARGV[2] eq ""){
	die "Usage: makeHMPfromNPUTEoutput.pl <input.hmp.txt> <output.csv> <output.hmp.txt>\n
	input.hmp.txt	: Input file given for makeNPUTEinput.pl
	output.csv	: NPUTE output file
	output.hmp.txt	: Output hapmap file for this script

NOTE: Make sure the makers in input hapmap file and NPUTE output are in the same order.\n\n";
}

$inHMP = $ARGV[0];
$inCSV = $ARGV[1];
$outHMP = $ARGV[2];

# opening input hapmap fiile
open(HMP, $inHMP);

# opening output fiile
open(OUT, ">$outHMP") || die "Error: Could not create output file. Check permissions/space on drive\n";
chomp($head=<HMP>);

# Printing the header
print OUT "$head\n";

# opening input NPUTE matrix file
open(CSV, "$inCSV");
while(<CSV>){
	chomp(); %hash = ();
	$line = uc($_);
	# replacing missing calls (?) as N
	$line =~ s/\?/N/g;
	@arr = split(",", $line);
	chomp($hmp=<HMP>);
	@ar = split("\t", $hmp);

	$totTaxa = $#ar - 10;

	if(!@arr){
			@arr = ('N') x $totTaxa;
	}
	# Below 2 foreach loops takes care of alleles column
	foreach $nucl(@arr){
		$hash{$nucl}++;
	}
	$ar[1]="";
	foreach $nuc(sort {$hash{$b}<=>$hash{$a}} keys %hash){
		if($ar[1] eq ""){
			$ar[1] = $nuc;
		}
		else{
			$ar[1] .= "/".$nuc;
		}
	}

	# Getting column 1-11 from input hapmap file
	$hmp = join("\t", @ar[0..10]);
	# appending NPUTE output to the hapmap meta columns
	$seq = join("\t", @arr);
	# Output HAPMAP line
	print OUT "$hmp\t$seq\n";	
}
close HMP;
close CSV;
close OUT;
