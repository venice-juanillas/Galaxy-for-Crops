#!/bin/bash

# usage : sh plink_vcf2bed.sh <input VCF file> <output file prefix>

plink=$(compgen -c plink)
plink=$(which $plink)

$plink --vcf $1 --allow-extra-chr --out $2 2> /dev/null
