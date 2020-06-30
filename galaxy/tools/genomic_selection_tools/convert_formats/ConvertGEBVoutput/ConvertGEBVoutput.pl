#!/usr/bin/perl

use strict;

use Getopt::Long;

my $usage = qq~Usage:$0 <args> [<opts>]
where <args> are:
    -i, --input         <input phenotyping file>
    -o, --output        <output file>
~;
$usage .= "\n";

my ($input,$outfile);

GetOptions(
        "input=s"    => \$input,
        "output=s"   => \$outfile
);

die $usage
  if ( !$input || !$outfile );


open(F,$input);
my $first_line = <F>;
$first_line =~s/\n//g;
$first_line =~s/\r//g;
my @infos = split("\t",$first_line);
my %hash;
my %envs;
my %traits;
my $num = 0;
foreach my $i(@infos){
	if ($i =~/^(.*)_(\w+)_(\w+)_(\w+)/){
		my $environment = $1;
		my $obs = $4;
		my $trait = $2;
		$traits{$trait} = 1;
		$hash{$num} = "$environment,$obs,$trait";
		$envs{$environment} = 1;
	}
	$num++;
}

my %samples;
my %hash2;
while(<F>){
	my $line = $_;
	$line =~s/\n//g;
	$line =~s/\r//g;
	my @infos = split("\t",$line);
	my $sample = $infos[0];
	$samples{$sample} = 1;
	my $num = 0;
	for (my $num=1; $num <= $#infos; $num++){
		my $value = $infos[$num];
		my ($environment,$obs,$trait) = split(",",$hash{$num});
		$hash2{"$environment"}{"$sample"}{"$trait"}{"$obs"} = $value;
	}
}
close(F);

open(O,">$outfile");
print O "Sample	Environment";
foreach my $trait(sort keys(%traits)){
	print O "\t". $trait."_Observed";
	print O "\t". $trait."_Predicted";
}
print O "\n";
foreach my $env(keys(%envs)){
	foreach my $sample(keys(%samples)){
		print O "$sample	$env";
		foreach my $trait(sort keys(%traits)){
	
			print O "\t".$hash2{"$env"}{"$sample"}{"$trait"}{"Observed"};
			print O "\t".$hash2{"$env"}{"$sample"}{"$trait"}{"Predicted"};
		}
		print O "\n";
	}
}
close(O);
