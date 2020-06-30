#!/bin/bash
input=$1
output=$2
format=$3
keep=$4

directory=`dirname $0`
mkdir tmpdir$$

 
perl $directory/ConvertGenotypingFormats.pl -i $input -o $output -f $format -k $keep -d $directory



