#!/usr/bin/perl
use strict; use warnings;
#use system;
if(!@ARGV || scalar(@ARGV)!= 4){
	#input: alignment file from Blat
	#	reference genome output file 
	print("Usage: ./<program> <position file> <reference> <outputfile> <coord_format> \n");
}else{
	main(@ARGV);
}
sub main{
	my ($inputFile, $reference, $outputFile, $coordType)=@_;
	my $linecount = 1;
	my $lineMax = 0; ##starting line with coordinates
	my ($chrom, $st , $end); 
	open(IN, "<$inputFile") || die "Cannot open $inputFile";
	#open(OUT, ">$outputFile") || die "Cannot open $outputFile"; ##by Mau
	#read per line
	## routine for format definition ...

	if ($coordType eq "psl") {
		$lineMax = 5; ## 5th line
		$chrom = 13;
		$st = 15;
		$end = 16;
	}
        if ($coordType eq "3col") {
                $lineMax = 0; ## no header, 1st line is informative already
                $chrom = 0;
                $st = 1;
                $end = 2;
        }


	while(my $line=<IN>){
		

		#blat result hold info skip lines (by default= 5)
		if($linecount > $lineMax){
			#get rid of all new lines
			chomp $line;
			my @cont = split('\t',$line);
			#get only the columns for chr, startPos, and 
			#endPos
			my ($seqName,$start,$end) = ($cont[$chrom],$cont[$st],$cont[$end]);
			system("samtools faidx $reference $seqName:$start-$end >> $outputFile ");

			#print OUT "$seqName\t$start\t$end\n"; function 
			#call to samtools faidx
			#open(SAM,system("samtools faidx ".$reference." ".$seqName.":".$start."-".$end." ")); ## by Mau
			#while(my $line2=<SAM>){ #Mau
				#output to file
			#	print OUT $line2; #Mau
			#} #Mau
		}	
		$linecount++;
		#chomp $line; my
	} ## END WHILE <IN>...
	close(IN);
	#close(OUT); ## Mau
}
