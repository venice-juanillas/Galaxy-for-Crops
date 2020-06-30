#!/usr/bin/perl

use strict;

use Getopt::Long;
use Cwd;
my $RepCourant = cwd();

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -c, --correlations             <collection of correlations>
    -t, --type                     <type of results to summarize: correlations/predictions> 
    -o, --out                      <output>
~;
$usage .= "\n";

my ($correlations,$output,$type);
GetOptions(
        "out=s"            => \$output,
	"type=s"           => \$type,
	"correlations=s"   => \$correlations
);

die $usage
  if ( !$correlations || !$output || !$type);

my $done = 0;
open(O,">$output") or die "Can not open file $output: $!";
my @files = split(",",$correlations);
if ($type eq "correlations"){
	foreach my $file(@files){

        	###########################
	        # calculate means
        	###########################
	        open(R,$file) or die "Can not open file $file: $!";
        	my $first_line_result = <R>;
		my $group = "col";
		if ($first_line_result =~/Randomization.Number.([^\s]+)\t/){
			$group = $1;
		}
	        my %means;
        	my $nb_traits;
		my $nlines=0;
        	while(<R>){
			$nlines++;
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
	        print O $group;
        	for (my $j = 1; $j <= $nb_traits; $j++){
                	my $mean = $means{$j}/$nlines;
	                print O "\t$mean";
        	}
	        print O "\n";

	}
}
elsif ($type eq "predictions"){
	
	foreach my $file(@files){
		open(R,$file) or die "Can not open file $file: $!";
		my $first_line_result = <R>;
		if (!$done){
			print O "Factor	$first_line_result";
			$done = 1;
		}
		while(<R>){
			my $line = $_;
			$line=~s/\n//g;
			$line=~s/\r//g;
			my @infos = split(/\t/,$line);
			my $id_and_factor = $infos[0];
			if ($id_and_factor =~/\|/){
				my ($id,$factor) = split(/\|/,$id_and_factor);
				$line =~s/\|$factor//g;
				print O $factor."\t".$line."\n";
			}
		}
		close(R);
	}	
}
close(O);
