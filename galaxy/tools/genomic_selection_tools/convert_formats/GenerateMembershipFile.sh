#!/bin/bash
groupfile=$1
pheno=$2
output=$3

directory=`dirname $0`
mkdir tmpdir$$

 
perl $directory/GenerateMembershipFile.pl -g $groupfile -p $pheno -o $output



