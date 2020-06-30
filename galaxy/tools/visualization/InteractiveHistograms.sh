#!/bin/bash
input=$1
output=$2
id=$3

directory=`dirname $0`
mkdir tmpdir$$


perl $directory/InteractiveHistograms.pl -i $input -o $output -n $id
