#!/bin/bash

tool_path=$(dirname $0)
vcf=$1
fileout_label=$(date "+%Y%m%d%H%M%S")
fileout_matrix=$2
fileout_plot=$3
fileout_log=$4
groups=$5


if [ -f $groups ]
  then
    cp -rf $groups input.individual_info.txt
fi

perl $tool_path/MDSbasedOnIBSmatrix.pl --in $vcf --out $fileout_label


cp $fileout_label.ibs_matrix.txt $fileout_matrix
cp $fileout_label.mds_plot.txt $fileout_plot
cp input.plink.log $fileout_log


rm -f $fileout_label.ibs_matrix.txt $fileout_label.mds_plot.txt input.plink.log
