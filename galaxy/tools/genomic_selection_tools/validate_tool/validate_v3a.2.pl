#!/usr/bin/perl -w
use strict;

# validate_v3.pl
# Victor Jun M. Ulat
# v.ulat@cgiar.org
# CIMMYT
# 2018.05.21

# 2018.07.20
# 1. Changed delimiter for all inputs to tab (.tsv)
# 2. Changed output of genotype file from hapmap to 
#    a matrix where rows are the samples and the 
#    columns are the markers
# 3. Inputs remain the same (see usage bellow).
# 4. Muddled the code too much.

# TODO:
# 1. How to deal with duplicates geno and pheno files?
#    Currently, the first instance is kept, the next
#    instance is discarded.
# 2. Genotype file should be GOBii hapmap output. 
# 3. Currently uses one processor for transposing hmp 
#    (markers x lines/samples) to generic matrix 
#    (lines/samples x markers). This can be parallelized
#    easily using the perl module: Parallel::ForkManager
#    but dangerous if you do not know the server confi-
#    guration.

# USAGE: $0 <genotype file> <phenotype file> \
#           <gid colNum> <key vars> \ 
#           <phenotype row start>

# Regarding key variables: 
#    * single number if only one key variable, i.e.:
#      3 for column 3
#    * separated by comma if multiple columns. i.e.:
#      1,4,10 for columns 1, 4 and 10

print "ARGV[0]: $ARGV[0]\n";
print "ARGV[1]: $ARGV[1]\n";
print "ARGV[2]: $ARGV[2]\n";
print "ARGV[3]: $ARGV[3]\n";
print "ARGV[4]: $ARGV[4]\n";
print "ARGV[5]: $ARGV[5]\n";
print "ARGV[6]: $ARGV[6]\n";
print "ARGV[7]: $ARGV[7]\n";

if (@ARGV!=8){
  print "\nUsage: $0 <genotype file> <phenotype file> \\ \n",
        "                        <gid colNum> <key variables> \\ \n",
        "                        <phenotype row start> <out.tsv> <hmp_out.mtx>\n";

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
my $output=$ARGV[5];
my $hmpout=$ARGV[6];
my $sampleNamesInfo=$ARGV[7];
my $genoNumLines=0;



# Get all genotyped sample/lines

my %genotypedSamples=();
my $genotypeRow='';


#############################################
# added by Alexis:  based on header line
#############################################
# add fake grouping column if not exists
if ($keyVarsColNums eq 'none'){

	open(P2,">$inputPhenotypeFile.2");
	open(P,"$inputPhenotypeFile");
	while(<P>){
		my $line = $_;
		print P2 "1\t".$line;
	}
	close(P);
	close(P2);
	$inputPhenotypeFile = "$inputPhenotypeFile.2";
	$keyVarsColNums = 1;
	$gidColNum++;
}

my $size_metadata = `grep -c '^#' $inputGenotypeFile`;
$size_metadata =~s/\n//g;$size_metadata =~s/\r//g;
$genoNumLines=`cat $inputGenotypeFile | wc -l `;

if ($sampleNamesInfo eq 'headers'){
	$genotypeRow = `grep 'rs#' $inputGenotypeFile`;
	if ($genotypeRow =~/QCcode\t(.*)$/){
		$genotypeRow = $1;
	}
}
else{
	open GENO, $inputGenotypeFile or die "Cannot open $inputGenotypeFile: $!";
	while (my $row=readline *GENO){
		if ($row=~/\t$sampleNamesInfo/) {
			chomp $row;
			($genotypeRow=$row)=~s/^.+?$sampleNamesInfo\t//g;
				last;
			} else {
		next;
		}
	}
	close GENO;
}
#############################################
# end added by Alexis
#############################################

my @sampleNames=split(/\t/, $genotypeRow);



my $colNum=11;
my @columns=();
push @columns, '1';


foreach my $sampleName (@sampleNames) {
  $sampleName=~s/\r//g;
  $colNum++;
  # check for duplicates
  # key is sample name; value is column number on the genotype input file
  if (exists($genotypedSamples{$sampleName})){
    # should this be on a log file somewhere?
    # print "$sampleName on $genotypedSamples{$sampleName} ".
    #       "is duplicated on $colN\n"; 
	next;
  } else {
    $genotypedSamples{$sampleName}=$colNum;
	push @columns, $colNum;
  }
}

foreach my $c(@columns){
  # you can parallelize hex
  cut($genoNumLines, $c);
}

genMatrix();

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
    my @phenotypeRowCell=split(/\t/, $phenotypeRow); # change the delimiter here.
    $arrayLen=scalar @phenotypeRowCell;
    #create $keyVarComb
    $curKeyVarComb='';

    my $identifier = $phenotypeRowCell[$gidColNum]; # added by Alexis
    if (!$identifier){next;} # added by Alexis

    foreach my $keyVarCol(@keyVarCols){
      $curKeyVarComb.=$phenotypeRowCell[$keyVarCol]."+";
    }
    $curKeyVarComb=~s/\+$//g;
    
    print $curKeyVarComb."\n";

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
             $newPhenotypeRow.=$tmp1."\t";
           }
           $newPhenotypeRow=~s/\t$//g;
           $keyVarCombSet{$gid}="1\t".$newPhenotypeRow;
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
           $keyVarCombSet{$phenotypeRowCell[$gidColNum]}="0\t".$phenotypeRow;
         }
      }
    }
    #print $curKeyVarComb, " -> ", $preKeyVarComb, "\n";
  } else {
    print OUT "is_added\t", $phenotypeRow;
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
      $newPhenotypeRow.=$tmp1."\t";
    }
    $newPhenotypeRow=~s/\t$//g;
    $keyVarCombSet{$gid}="1\t".$newPhenotypeRow;
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



sub cut {
  my ($numLines, $colNum)=@_;
  my $tmpFile="TMP".sprintf("%08d", $colNum).".tmp";
  my $trColmn="TMP".sprintf("%08d", $colNum).".trp";
  
  `cut -d'\t' -f$colNum $inputGenotypeFile > $tmpFile`;
  
  open TMP, $tmpFile or die "Cannot open $tmpFile: $!";
  open OUT, ">$trColmn" or die "Cannot open $trColmn: $!";
  
  my $i=1;
  
  while(my $row=readline *TMP){
    chomp $row;
	$row=~s/\r//g;
	$row=~s/^rs\#/samples\/markers/g;
      
	if ($i > ($size_metadata+1)) {
	  if ($i==$numLines){
	    print OUT $row, "\n";
	  } else {
	    print OUT $row, "\t";
	  }
	}
	$i++;
  }
  close TMP;
  `rm -fr $tmpFile`;
  close OUT;
}

sub genMatrix {
  `cat *.trp > $hmpout`;
  `rm -fr *.trp`;
}
