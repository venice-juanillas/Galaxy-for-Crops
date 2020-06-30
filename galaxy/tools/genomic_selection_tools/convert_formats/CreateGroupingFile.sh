#!/bin/bash
geno=$1
pheno=$2
outgeno=$3
outpheno=$4
grouping=$5

directory=`dirname $0`
mkdir tmpdir$$

 
perl $directory/CreateGroupingFile.pl -g $geno -p $pheno -o tmpdir$$/out

mv tmpdir$$/out.pheno $outpheno
mv tmpdir$$/out.geno $outgeno
mv tmpdir$$/out.grouping $grouping



