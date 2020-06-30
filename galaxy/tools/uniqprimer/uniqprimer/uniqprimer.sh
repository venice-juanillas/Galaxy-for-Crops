#!/bin/bash
include=$1
exclude=$2
product_size_range=$3
primer_size=$4
min_size=$5
max_size=$6
crossvalidate=$7
outfile=$8
log=$9
fasta=${10}

directory=`dirname $0`
other_inputs_line=""


#which eprimer3 >>$log
#exit

j=1
for i in $*
do
	if [[ $j -ge 11 ]]
	then other_inputs_line=${other_inputs_line}" "$i
	fi
	j=$((j+1))
done


if [[ $crossvalidate == "Yes" ]] 
then python $directory/uniqprimer-0.5.0/uniqprimer.py -i $include -x $exclude --productsizerange $product_size_range --primersize $primer_size --minprimersize $min_size --crossvalidate --keeptempfiles --maxprimersize $max_size -o $outfile -f $fasta -l $log $other_inputs_line >>$log 2>&1
elif [[ $crossvalidate = "No" ]]
then python $directory/uniqprimer-0.5.0/uniqprimer.py -i $include -x $exclude --productsizerange $product_size_range --primersize $primer_size --minprimersize $min_size --keeptempfiles --maxprimersize $max_size -o $outfile -f $fasta -l $log $other_inputs_line >>$log 2>&1
fi



