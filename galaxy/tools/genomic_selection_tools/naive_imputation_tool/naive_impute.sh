#!/bin/bash
input=$1
output=$2
method=$3
colStart=$4

directory=`dirname $0`
mkdir tmpdir$$

skip=$(grep -c '^#' $input)

/home/galaxy/data/R/R-3.5.1/bin/Rscript --vanilla $directory/naive_impute_corrected.R -f $input -o $output -i $method -c $colStart -n $skip
 
sed -r -i "s/\w+\t#/#/g" $output;sed -r -i "s/\w+\trs#/rs#/g" $output;sed -i "s/ //g" $output



