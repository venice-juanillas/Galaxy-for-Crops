#!/bin/bash
input=$1
output=$2
geno=$3
missing=$4

directory=`dirname $0`
mkdir tmpdir$$

 
perl $directory/ConvertPhenotypingFileForGEBV2.pl -i $input -o $output -g $geno -m $missing



