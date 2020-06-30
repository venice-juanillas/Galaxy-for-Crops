

infile=${1?"Please specify input vcf.gz file.\n"}
missRate=${2?"Please specify missing call rate.\n"}
outfile=${3?"Please specify output VCF file"}


#gunzip -c  $infile |
awk -v missRate="$missRate" -v OFS="\t" '

$0~/^#/ {print $0}

$0 !~/^#/{
 for( i=10; i<= NF ; i++){
  if(rand() < missRate){
    $i="./.";
  }
 }  ;
 print $0;
}
' $infile  >  $outfile

