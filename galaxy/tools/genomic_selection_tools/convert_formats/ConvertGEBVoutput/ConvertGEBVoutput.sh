#!/bin/bash
input=$1
output=$2

directory=`dirname $0`
mkdir tmpdir$$

 
perl $directory/ConvertGEBVoutput.pl -i $input -o $output



