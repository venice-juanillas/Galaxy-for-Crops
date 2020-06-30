#!/usr/bin/perl

use strict;

open(F,"Combined_SNPs_GID_acrossyears.transposed.txt");
print "rs#	alleles	chrom	pos	strand	assembly#	center	protLSID	assayLSID	panelLSID	QCcode	";
my $n=0;
while(<F>){
	$n++;
	if ($n == 1){
		print $_;
	}
	else{
		print "1_$n	A/C	1	$n	+	NA	NA	NA	NA	NA	NA	".$_;	
	}
}
close(F);
