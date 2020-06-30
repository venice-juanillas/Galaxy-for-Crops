#!/bin/bash

# usage : sh plink_ld_prune.sh <input VCF file> <output file prefix> <window size in snps or add kb> <step size> <r^2 threshold>

plink=$(compgen -c plink)
plink=$(which $plink)

$plink --vcf $1 --allow-extra-chr --out $2 --indep-pairwise $3 $4 $5 2> /dev/null &&
$plink --vcf $1 --allow-extra-chr --recode vcf --extract $2.prune.in --out $2.pruned 2> /dev/null
