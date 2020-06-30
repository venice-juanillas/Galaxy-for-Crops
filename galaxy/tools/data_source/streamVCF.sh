#!/bin/bash
#
# make_gz.sh
#

# Call this script with a list of s3 locations with VCF files to parse
# aws --profile NDAR s3 ls s3:/S3_URL/ | awk '{print $4}' | xargs -n1 -P4 sh make_gz.sh
# xargs -n1 -P4 accepts one argument and runs 4 parallel processes
#

#Create named pipe
mkfifo $1_pipe

#Set up stream for pipe
aws --profile vjuanillas s3 cp s3://3kricegenome/$6/$1".snp.vcf.gz" $1".snp.vcf.gz"

#Index bgzip format file
/usr/local/bin/bcftools index $1".snp.vcf.gz"

#Remove named pipe
rm $1_pipe

#Query VCF for specific region(format: chrNum:startPos-endPos), output VCF, gzip, and index.
/usr/local/bin/bcftools view --regions $3:$4-$5 $1".snp.vcf.gz" | /usr/local/bin/bgzip -c > $2
/usr/local/bin/bcftools index $2

#Remove original vcf and index files
rm $1".snp.vcf.gz"
rm $1".snp.vcf.gz.csi"
