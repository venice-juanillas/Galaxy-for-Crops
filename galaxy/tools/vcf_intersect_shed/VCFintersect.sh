#!/bin/bash
vcf1=$1
vcf2=$2
unique_vcf1=$3
unique_vcf2=$4
common_vcf1=$5
common_vcf2=$6

directory=`dirname $0`
mkdir tmpdir$$

cp -rf $1 tmpdir$$/vcf1.vcf
cp -rf $2 tmpdir$$/vcf2.vcf

bgzip tmpdir$$/vcf1.vcf
bgzip tmpdir$$/vcf2.vcf
tabix -p vcf tmpdir$$/vcf1.vcf.gz
tabix -p vcf tmpdir$$/vcf2.vcf.gz
bcftools isec -p isec_output -Oz tmpdir$$/vcf1.vcf.gz tmpdir$$/vcf2.vcf.gz

gunzip isec_output/0000.vcf.gz
cp -rf isec_output/0000.vcf $unique_vcf1

gunzip isec_output/0001.vcf.gz
cp -rf isec_output/0001.vcf $unique_vcf2

gunzip isec_output/0002.vcf.gz
cp -rf isec_output/0002.vcf $common_vcf1

gunzip isec_output/0003.vcf.gz
cp -rf isec_output/0003.vcf $common_vcf2

rm -rf tmpdir$$ isec_output
#mv output$$/abundance.tsv $abundance;
