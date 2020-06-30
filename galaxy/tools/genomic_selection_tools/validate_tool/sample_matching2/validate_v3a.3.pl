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
print "ARGV[8]: $ARGV[8]\n";
print "ARGV[9]: $ARGV[9]\n";

if (@ARGV!=11 && @ARGV!=10){
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
my $add_NA=$ARGV[8];
my $membership_file=$ARGV[9];
my $trait_columns=$ARGV[10];

#`awk {''} $inputPhenotypeFile`;


# Get all genotyped sample/lines

my %genotypedSamples=();
my $genotypeRow='';


#############################################
# added by Alexis:  based on header line
#############################################
# add fake grouping column if not exists
my $initial_keyVarsColNums = $keyVarsColNums;
if ($keyVarsColNums eq 'none'){

	open(P2,">$inputPhenotypeFile.2");
	open(P,"$inputPhenotypeFile");
	while(<P>){
		my $line = "1\t".$_;
		print P2 $line;
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

my %phenotypes;
my $numfactor = 0; #added by Alexis
my %hash; # added by Alexis
open PHENO, $inputPhenotypeFile or die "Cannot open $inputPhenotypeFile: $!";
open OUT, ">$output" or die "Cannot open $output: $!";
open MEMBER, ">$membership_file" or die "Cannot open $membership_file: $!"; # added by Alexis
print MEMBER "Grouping\n";  # added by Alexis
#my @columns_to_be_reported_in_genotyping; # added by Alexis
my %columns_to_be_reported_in_genotyping;
#push @columns_to_be_reported_in_genotyping, '1';  # added by Alexis
$columns_to_be_reported_in_genotyping{1}++;
while (my $phenotypeRow=readline *PHENO) {
  if ($rowCount>=$phenotypeRowStart) {
    chomp $phenotypeRow;
    my @phenotypeRowCell=split(/\t/, $phenotypeRow); # change the delimiter here.
    my $identifier = $phenotypeRowCell[$gidColNum]; # added by Alexis
    if (!$identifier or $identifier eq ""){next;} # added by Alexis
    $arrayLen=scalar @phenotypeRowCell;
    #create $keyVarComb
    $curKeyVarComb='';

    foreach my $keyVarCol(@keyVarCols){
      $curKeyVarComb.=$phenotypeRowCell[$keyVarCol]."+";
    }
    $curKeyVarComb=~s/\+$//g;
    my $identifier2 = $identifier."|".$curKeyVarComb;

    # added by Alexis
    if (!$hash{$curKeyVarComb}){
       $numfactor++; 
    }
    $hash{$curKeyVarComb} = $numfactor;
    #print $curKeyVarComb."  $preKeyVarComb  $identifier\n";
$phenotypes{$identifier2} = $phenotypeRow;

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
           if ($add_NA eq "TRUE"){
                my $column_geno = $genotypedSamples{$identifier};#added by Alexis
                #push(@columns_to_be_reported_in_genotyping,$column_geno);#added by Alexis
		$columns_to_be_reported_in_genotyping{$column_geno}++;
                print MEMBER $hash{$curKeyVarComb}."\n"; #added by Alexis
                $keyVarCombSet{$gid}=$newPhenotypeRow;
                #$keyVarCombSet{$gid}="1\t".$newPhenotypeRow;
           }
         }
      }
       
      # sort keys by column position (sort hash by values)
      foreach my $entry (sort {$genotypedSamples{$a} <=> $genotypedSamples{$b} } 
                         keys %genotypedSamples ) {
        if($keyVarCombSet{$entry}){ print OUT $keyVarCombSet{$entry}, "\n";}
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
           if ($add_NA eq "TRUE"){
               #$keyVarCombSet{$phenotypeRowCell[$gidColNum]}="0\t".$phenotypeRow;
               $keyVarCombSet{$phenotypeRowCell[$gidColNum]}=$phenotypeRow; #added by Alexis
               my $column_geno = $genotypedSamples{$identifier};#added by Alexis
               #push(@columns_to_be_reported_in_genotyping,$column_geno);#added by Alexis
		$columns_to_be_reported_in_genotyping{$column_geno}++;
               print MEMBER $hash{$curKeyVarComb}."\n"; #added by Alexis
           }
           else{
               my $column_geno = $genotypedSamples{$identifier};#added by Alexis
               #push(@columns_to_be_reported_in_genotyping,$column_geno);#added by Alexis
		$columns_to_be_reported_in_genotyping{$column_geno}++;
               $keyVarCombSet{$phenotypeRowCell[$gidColNum]}=$phenotypeRow; 
               print MEMBER $hash{$curKeyVarComb}."\n"; #added by Alexis
           }
         }
      }
    }
    #print $curKeyVarComb, " -> ", $preKeyVarComb, "\n";
  } else {
    if ($add_NA eq "TRUE"){
        #print OUT "is_added\t", $phenotypeRow;
	print OUT $phenotypeRow;
    }
    else{
        print OUT $phenotypeRow;
    }
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
    if ($add_NA eq "TRUE"){
       my $column_geno = $genotypedSamples{$gid};#added by Alexis
       #push(@columns_to_be_reported_in_genotyping,$column_geno);#added by Alexis
	$columns_to_be_reported_in_genotyping{$column_geno}++;
       $keyVarCombSet{$gid}=$newPhenotypeRow;
       #$keyVarCombSet{$gid}="1\t".$newPhenotypeRow;
    }
    
  }
} 
  
# sort keys by column position (sort hash by values)
foreach my $entry (sort {$genotypedSamples{$a} <=> $genotypedSamples{$b} } 
                   keys %genotypedSamples ) {
  if ($keyVarCombSet{$entry}){print OUT $keyVarCombSet{$entry}, "\n";}
}      

close PHENO;
close OUT;
close MEMBER;

foreach my $c(keys(%columns_to_be_reported_in_genotyping)){
	if ($c !~/\d/){delete $columns_to_be_reported_in_genotyping{$c};}
}

#foreach my $c(@columns){
my $number = 0;
foreach my $c(sort {$a<=>$b} keys(%columns_to_be_reported_in_genotyping)){ # corrected/added by Alexis
	  $number++; # added by Alexis
  # you can parallelize hex
#  my $nnn = $columns_to_be_reported_in_genotyping{$c};
#print "$c $number $nnn\n";
  	cut($genoNumLines, $c, $number); # modified by Alexis
}
genMatrix();

#####################################
# added by Alexis
#####################################
open(O2,">$hmpout.2");
open MEMBER, ">$membership_file" or die "Cannot open $membership_file: $!"; # added by Alexis
print MEMBER "Grouping\n";  # added by Alexis
my $first_line = `head -1 $hmpout`;
print O2 $first_line;
for (my $i=1; $i <= $numfactor; $i++){
	open(I,$hmpout);	
	<I>;
	while(<I>){
		print O2 $_;
		print MEMBER "$i\n";
	}
	close(I);
}
close(O2);
close(MEMBER);
rename("$hmpout.2",$hmpout);

###########################################
# added by Alexis (concatenate id+factor)
###########################################
my $head = `head -2 $inputPhenotypeFile | tail -1`;
my $headers = `head -1 $inputPhenotypeFile`;
$headers =~s/\n//g;$headers =~s/\r//g;
my @infos_headers = split("\t",$headers);

open(O3,">$output.3") or die "Can't open file $output.3: $!";
if ($initial_keyVarsColNums =~/\d+/){
	
	print O3 $infos_headers[$gidColNum];
	foreach my $keyVarCol (@keyVarCols){
		print O3 "|".$infos_headers[$keyVarCol];
	}
}
else{
	print O3 $infos_headers[$gidColNum];
}
if (!$trait_columns){
	my @tab_for_new_line;
	for (my $i = 0; $i<= $#infos_headers; $i++){
		print "$i \n";
		foreach my $keyVarCol (@keyVarCols){
			if ($i != $gidColNum && $i != $keyVarCol){
				push(@tab_for_new_line,$infos_headers[$i]);
			}
		}
	}
	print O3 "\t".join("\t",@tab_for_new_line);
}
else{
	my @traits = split(",",$trait_columns);
	foreach my $traitcol(@traits){
		my $trait_value=$infos_headers[$traitcol-1];
		if ($initial_keyVarsColNums =~/\d+/){
			$trait_value = $infos_headers[$traitcol-1];
		}
		else{
			$trait_value = $infos_headers[$traitcol];
		}
		print O3 "\t$trait_value";
	}
}
print O3 "\n";
my %reversehash = reverse(%hash);
for (my $i=1; $i <= $numfactor; $i++){
	my $factor_value = $reversehash{$i};
	foreach my $entry (sort {$genotypedSamples{$a} <=> $genotypedSamples{$b} }keys %genotypedSamples ) {
		my $identifier = "$entry|$factor_value";
		my $addNA = 0;
		my @infos;
		if ($phenotypes{$identifier}){
			my $phenoline = $phenotypes{$identifier};
			@infos = split("\t",$phenoline);
		}
		else{
			@infos = split("\t",$head);
			$addNA = 1;
		}
		if ($addNA == 1 && $add_NA eq "FALSE"){next;}
		if ($ARGV[3] =~/\d+/){
				#my $factor = $infos[$keyVarCol];
				#$factor =~s/\n//g;$factor =~s/\r//g;
				print O3 $identifier;
			
		}
		else{
			my $identifier = $infos[$gidColNum];
			print O3 $entry;
		}
		if (!$trait_columns){
			my $new_line = "";
			my @tab_for_new_line;
			for (my $i = 0; $i<= $#infos; $i++){
				if ($i != $gidColNum && $i != ($keyVarsColNums-1)){
					if ($addNA && $add_NA eq "TRUE"){push(@tab_for_new_line,"NA");}
					else{push(@tab_for_new_line,$infos[$i]);}
				}
			}
			print O3 "\t".join("\t",@tab_for_new_line);
		}
		else{
			my @traits = split(",",$trait_columns);
			foreach my $traitcol(@traits){
				my $trait_value="NA";
				if ($initial_keyVarsColNums =~/\d+/){
					$trait_value = $infos[$traitcol-1];
				}
				else{
					$trait_value = $infos[$traitcol];
				}
				if ($addNA && $add_NA eq "TRUE"){$trait_value="NA";}
				print O3 "	$trait_value";
			}
		}
		print O3 "\n";
	}
}
close(O3);
open(O,$output) or die "Can't open file $output: $!";;
open(O2,">$output.2") or die "Can't open file $output.2: $!";
while(<O>){
	my $line = $_;
	$line =~s/\n//g;$line =~s/\r//g;
	my @infos = split("\t",$line);
	my $identifier = $infos[$gidColNum];
	
	if ($ARGV[3] =~/\d+/){
		my $factor = $infos[$keyVarsColNums-1];
		print O2 $identifier."|".$factor;
	}
	else{
		my $identifier = $infos[$gidColNum];
		print O2 $identifier;
	}
	if (!$trait_columns){
		my $new_line = "";
		my @tab_for_new_line;
		for (my $i = 0; $i<= $#infos; $i++){
			if ($i != $gidColNum && $i != ($keyVarsColNums-1)){
				push(@tab_for_new_line,$infos[$i]);
			}
		}
		print O2 "\t".join("\t",@tab_for_new_line);
	}
	else{
		my @traits = split(",",$trait_columns);
		foreach my $traitcol(@traits){
			my $trait_value;
			if ($ARGV[3] =~/\d+/){
				$trait_value = $infos[$traitcol-1];
			}
			else{
				$trait_value = $infos[$traitcol];
			}
			print O2 "	$trait_value";
		}
	}
	print O2 "\n";
}
close(O);
rename("$output.3",$output);
############################
# end added by Alexis
############################

exit();



sub cut {
  my ($numLines, $colNum, $numb)=@_; # modified by Alexis

  #my $tmpFile="TMP".sprintf("%08d", $colNum).".tmp";
  #my $trColmn="TMP".sprintf("%08d", $colNum).".trp";
  my $tmpFile="TMP".sprintf("%08d", $numb).".tmp";
  my $trColmn="TMP".sprintf("%08d", $numb).".trp";

  
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
