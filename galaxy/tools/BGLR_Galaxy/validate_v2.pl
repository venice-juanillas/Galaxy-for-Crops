#!/usr/bin/perl -w
use strict;

# validate_v2.pl
# Victor Jun M. Ulat
# v.ulat@cgiar.org
# CIMMYT
# 2018.05.21

# TODO:
# 1. How to deal with duplicates geno and pheno files?
#    Currently, the first instance is kept, the next
#    instance is discarded.
# 2. Give option to user to choose delimiter (comma or tab;
#    CSV or TSV extension (currently csv)).
# 3. Genotype file should be GOBii hapmap output. 
# 4. Add option to indicate row for phenotype header, 
#    currently assumes first row.
# usage: $0 <genotype file> <phenotype file> \
#           <gid colNum> <key vars> \ 
#           <phenotype row start>

# Regarding key variables: 
#    * single number if only one key variable, i.e.:
#      3 for column 3
#    * separated by comma if multiple columns. i.e.:
#      1,4,10 for columns 1, 4 and 10

if (@ARGV!=6){ ## add one ARGV for output
  print "\nUsage: $0 <genotype file> <phenotype file> \\ \n",
        "                        <gid colNum> <key variables> \\ \n",
        "                        <phenotype row start>\n";

  print "\n i.e.: $0 genotype.hmp phenotype.csv \\ \n",
        "                        5 3,4 \\ \n",
        "                        2 \n\n";

  exit();
} 

# Current input CSV files

my $inputGenotypeFile=$ARGV[0];
my $inputPhenotypeFile=$ARGV[1];
my $gidColNum=$ARGV[2]-1;
my $keyVarsColNums=$ARGV[3];
my $phenotypeRowStart=$ARGV[4];
#my $output="validateOut.csv";
my $output = $ARGV[5];

# Get all genotyped sample/lines
open GENO, $inputGenotypeFile or die "Cannot open $inputGenotypeFile: $!";

my %genotypedSamples=();
my $genotypeRow='';

while ($genotypeRow=readline *GENO){
  if ($genotypeRow=~/\tgermplasm_external_code/) {
    chomp $genotypeRow;
    $genotypeRow=~s/^.+?germplasm_external_code\t//g;
    last;
  } else {
    next;
  }
}

close GENO;

my @sampleNames=split(/\t/, $genotypeRow);

my $colN=1;

foreach my $sampleName (@sampleNames) {
  $sampleName=~s/\r//g;
  # check for duplicates
  # key is sample name; value is column number on the genotype input file
  if (exists($genotypedSamples{$sampleName})){
    # should this be on a log file somewhere?
    # print "$sampleName on $genotypedSamples{$sampleName} ".
    #       "is duplicated on $colN\n"; 
  } else {
    $genotypedSamples{$sampleName}=$colN;
  }
  $colN++;
}

# key variable
my @keyVarCols=();

if ($keyVarsColNums=~/\,/){
  # multi column
  my @temp=split(/\,/, $keyVarsColNums);
  foreach my $t(@temp){
    push @keyVarCols, $t-1;
  }
} else {
  # single digit
  push @keyVarCols, $keyVarsColNums-1;
}

my $preKeyVarComb='';
my $curKeyVarComb='';
my %keyVarCombSet=(); 
my $rowCount=1;
my $arrayLen=0;

open PHENO, $inputPhenotypeFile or die "Cannot open $inputPhenotypeFile: $!";
open OUT, ">$output" or die "Cannot open $output: $!";

while (my $phenotypeRow=readline *PHENO) {
  if ($rowCount>=$phenotypeRowStart) {
    chomp $phenotypeRow;
    my @phenotypeRowCell=split(/\,/, $phenotypeRow); # change the delimiter here.
    $arrayLen=scalar @phenotypeRowCell;
    #create $keyVarComb
    $curKeyVarComb='';
    foreach my $keyVarCol(@keyVarCols){
      $curKeyVarComb.=$phenotypeRowCell[$keyVarCol]."+";
    }
    $curKeyVarComb=~s/\+$//g;

    if ($rowCount==$phenotypeRowStart) {
      $preKeyVarComb=$curKeyVarComb;
    }
    if ($curKeyVarComb ne $preKeyVarComb) {
      # next set
      # add to %keyVarComSet, sample/lines that are not phenotyped.
      foreach my $gid (keys %genotypedSamples) {
         if (exists($keyVarCombSet{$gid})) {
            #do nothing, it is already there.
         } else {
           # add NAs
           my @tmp1=();
           for (my $i=0; $i<$arrayLen; $i++){
             $tmp1[$i]='NA';
           }
           $gid=~s/\r//g;
           $tmp1[$gidColNum]=$gid;
           my @tmp2=split(/\+/, $preKeyVarComb);
           my $i2=0;
           foreach my $keyVarCol (@keyVarCols){
              $tmp1[$keyVarCol]=$tmp2[$i2];
              $i2++;
           }
           my $newPhenotypeRow='';
           foreach my $tmp1(@tmp1){
             $newPhenotypeRow.=$tmp1."\,";
           }
           $newPhenotypeRow=~s/\,$//g;
           $keyVarCombSet{$gid}="1\,".$newPhenotypeRow;
         }
      } 

      # sort keys by column position (sort hash by values)
      foreach my $entry (sort {$genotypedSamples{$a} <=> $genotypedSamples{$b} } 
                         keys %genotypedSamples ) {
        print OUT $keyVarCombSet{$entry}, "\n";
      }      

      # empty %keyVarCombSet
      %keyVarCombSet=();
      $preKeyVarComb=$curKeyVarComb;
    } else {
      # something...
      # check if current entry is genotyped, ignore if it is not.
      if (exists($genotypedSamples{$phenotypeRowCell[$gidColNum]})) {
         # check if it is duplicated in the phenotype file
         if (exists($keyVarCombSet{$phenotypeRowCell[$gidColNum]})){
           # sample/line is phenotyped twice...
         } else {
           $keyVarCombSet{$phenotypeRowCell[$gidColNum]}="0\,".$phenotypeRow;
         }
      }
    }
    #print $curKeyVarComb, " -> ", $preKeyVarComb, "\n";
  } else {
    print OUT "is_added\,", $phenotypeRow;
  }
  $rowCount++;
} 

# process last set...

foreach my $gid (keys %genotypedSamples) {
  if (exists($keyVarCombSet{$gid})) {
    #do nothing, it is already there.
  } else {

    # add NAs
    my @tmp1=();
    for (my $i=0; $i<$arrayLen; $i++){
      $tmp1[$i]='NA';
    }
    $gid=~s/\r//g;
    $tmp1[$gidColNum]=$gid;
    my @tmp2=split(/\+/, $preKeyVarComb);
    my $i2=0;
    foreach my $keyVarCol (@keyVarCols){
      $tmp1[$keyVarCol]=$tmp2[$i2];
      $i2++;
    }
    my $newPhenotypeRow='';
    foreach my $tmp1(@tmp1){
      $newPhenotypeRow.=$tmp1."\,";
    }
    $newPhenotypeRow=~s/\,$//g;
    $keyVarCombSet{$gid}="1\,".$newPhenotypeRow;
  }
} 
  
# sort keys by column position (sort hash by values)
foreach my $entry (sort {$genotypedSamples{$a} <=> $genotypedSamples{$b} } 
                   keys %genotypedSamples ) {
  print OUT $keyVarCombSet{$entry}, "\n";
}      

close PHENO;
close OUT;
exit();

