#!/bin/bash
input=$1
output=$2
type=$3

directory=`dirname $0`
mkdir tmpdir$$

 
perl $directory/ConvertPhenotypingFileForGEBV1.pl -i $input -o $output -t $type



