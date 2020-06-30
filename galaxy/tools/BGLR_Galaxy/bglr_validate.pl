#!/usr/bin/perl -w

use strict;

# validate.pl version 0.0016 23 June 2027
# Victor Jun M. Ulat (v.ulat@cimmyt.org)
# Venice Juanillas (v.juanillas@irri.org) 
# Cross validates phenotype and genotype files. Takes input 
# phenotype and genotype file and outputs six files:
#   phenotype.trng - in rows 
#   genotype.trng  - matrix, columns are lines, rows are markers 
#   genotype.bglr  - specific to bglr contains both genotypes 
#                    that have associated phenotypes and those 
#                    that do not have phenotypes 
#   phenotype.bglr - phenotypes with and without 
#                    values/score but with genotype
#   genotype.pred  - genotype files without phenotype
#   phenotype.pred - phenotype without values/score but with 
#                    corresponding genotypes

# Usage: $0 <genotype file> <phenotype file> <column# of phenotype file containing line/variety number>
# genotype and phenotype files should be in csv format.

if (@ARGV!=10){
  print "\n\tUsage: $0 <genotype.csv> <phenotype.csv> <line name col#> <score col#> <phenotype_trng> <genotype_trng> <genotype_bglr> <phenotype_bglr> <genotype_pred > <phenotype.pred>\n";
  print "\t i.e.: $0 rAmpSeq.csv phenotype.csv 4 6\n\n";
  exit();
}

# Get the header of the genotype matrix and load into
# a hash map (sample name : column_number)

my %map=();
my @gHdr=split(/\,/, `head -1 $ARGV[0]`);
my $i=0;

foreach my $sampleID (@gHdr){
  $i++;
  $sampleID=~s/\n//g;
  if (exists($map{$sampleID})){
    # Duplicate genotype
    print "Duplicate genotype for: $sampleID!\n";
    exit();
  } else {
    $map{$sampleID}=$i;
  }
}

my $phenotype_trng = $ARGV[4];
my $phenotype_bglr = $ARGV[5];
my $phenotype_pred = $ARGV[6];
my $genotype_trng = $ARGV[7];
my $genotype_bglr = $ARGV[8];
my $genotype_pred = $ARGV[9];

# Initialize phenotype.trng, phenotype.bglr, phenotype.pred
open PHENOTRNG, ">$phenotype_trng" or die "Cannot open $phenotype_trng: $!";
open PHENOBGLR, ">$phenotype_bglr" or die "Cannot open $phenotype_bglr: $!";
open PHENOPRED, ">$phenotype_pred" or die "Cannot open $phenotype_pred: $!";

# Get phenotype column.
my $nameCol=$ARGV[2]-1;
my $scoreCol=$ARGV[3]-1;

open PHENOIN, $ARGV[1] or die "Cannot open $ARGV[1]: $!";

$i=0;
my $cols='';
while (my $line=readline *PHENOIN){
  $i++;
  chomp $line;
  my @pheno=split(/\,/, $line);
  if ($i==1){
    print PHENOTRNG $pheno[$nameCol], ",", $pheno[$scoreCol], "\n";
    print PHENOBGLR $pheno[$nameCol], ",", $pheno[$scoreCol], "\n";
    print PHENOPRED $pheno[$nameCol], ",", $pheno[$scoreCol], "\n";
  } else {
    if (exists($map{$pheno[$nameCol]})){
      #keep ... phenotype and genotype
      $cols.="\$".$map{$pheno[$nameCol]}."\",\"";
      print PHENOTRNG $pheno[$nameCol], ",", $pheno[$scoreCol], "\n";
      print PHENOBGLR $pheno[$nameCol], ",", $pheno[$scoreCol], "\n";
      # delete key/value from map...
      delete $map{$pheno[$nameCol]};
    } else {
      #discard ... phenotype only, no genotype
    }
  }
}

close PHENOIN;

$cols=~s/\"\,\"$//g;
`awk -F "," '{print($cols)}' $ARGV[0] > $genotype_trng`;

#print remaining genotype columns...
$cols='';

foreach my $s(keys %map){
  #$cols.=$map{$s}.",";
  $cols.="\$".$map{$s}."\",\"";
  #print $s, "\t", $map{$s}, "\n";
  print PHENOPRED $s, ",", "NA\n";
  print PHENOBGLR $s, ",", "NA\n";
}

close PHENOBGLR;
close PHENOPRED;

$cols=~s/\"\,\"$//g;
`awk -F "," '{print($cols)}' $ARGV[0] > $genotype_pred`;
`paste -d ',' $genotype_trng $genotype_pred > $genotype_bglr`;

exit();
