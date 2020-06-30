VCF_FILE=$1.snp.vcf.gz
VCF_TBI=$1.snp.vcf.gz.tbi

aws --profile vjuanillas s3 cp s3://3kricegenome/$2/$VCF_FILE $1.snp.vcf.gz
aws --profile vjuanillas s3 cp s3://3kricegenome/$2/$VCF_TBI $1.snp.vcf.gz.tbi

#Query VCF for location, output VCF, gzip, and index.
/usr/bin/bcftools view -r $3:$4-$5 $VCF_FILE | /usr/bin/bgzip > $6
/usr/bin/bcftools index $6

#Remove original vcf and index files
rm $VCF_FILE
rm $VCF_TBI


