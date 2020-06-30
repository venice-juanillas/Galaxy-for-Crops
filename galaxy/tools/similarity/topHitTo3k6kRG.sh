#!/bin/bash

ntasks=$3

tassel=/home/john.ignacio/Softwares/tassel-5-standalone/run_pipeline.pl
hmp3k6k=/scratch2/john.ignacio/similarity/add_ref_alt/3k6k.hmp.txt
removeSites=/scratch2/john.ignacio/similarity/remove_sites.txt

file=$(basename "$1")
filename="${file%.*}"

nsample=`awk '{print NF; exit}' $1`
nsample=$((nsample-11))
n3k=`awk '{print NF; exit}' $hmp3k6k`
n3k=$((n3k-11))

$tassel -Xmx8g -h $1 -excludeSiteNamesInFile $removeSites -export rmv.tmp.hmp.txt -exportType HapmapDiploid
$tassel -Xmx8g -mergeAlignmentsSameSites -input $hmp3k6k,rmv.tmp.hmp.txt -output merged.3k6k.rmv.hmp.txt
$tassel -Xmx8g -h merged.3k6k.rmv.hmp.txt -distanceMatrix -export distMatrix.tmp.txt

startLine=6
endLine=$((n3k+5))

head -n1 $1 | cut -f 11- | sed 's/QCcode//' > toSortDistMatrix.txt
sed '6,3028!d' distMatrix.tmp.txt | cut -f 1,3025- >> toSortDistMatrix.txt

rm top3HitsTo3k6k.txt
echo -e "SAMPLE\tTOP1\tDISTANCE1\tTOP2\tDISTANCE2\tTOP3\tDISTANCE3" > top3HitsTo3k6k.txt

ntimes=$((nsample/ntasks))
nlast=$((nsample%ntasks))

for i in `seq 0 $((ntimes-1))`
	do
		for k in `seq $ntasks`
			do
				x=$((i*ntasks+k))
				echo "Processing sample no. $x."
				cut -f 1,$((x+1)) toSortDistMatrix.txt | sort -k2n | head -n4 | tr '\n' '\t' | awk '{print}' | sed -e 's/^\t//' >> top3HitsTo3k6k.txt &
			done
			wait
	done
for i in `seq $nlast`
	do
		x=$((ntimes*ntasks+i))
		echo "Processing sample no. ${x} of ${nsample}."
		cut -f 1,$((x+1)) toSortDistMatrix.txt | sort -k2n | head -n4 | tr '\n' '\t' | awk '{print}' | sed -e 's/^\t//' >> top3HitsTo3k6k.txt &
	done
wait
sed -i.bak '1!d' top3HitsTo3k6k.txt
sed '1d' top3HitsTo3k6k.txt.bak | sort -k1n >> top3HitsTo3k6k.txt 
rm top3HitsTo3k6k.txt.bak
rm rmv.tmp.hmp.txt
rm merged.3k6k.rmv.hmp.txt
rm distMatrix.tmp.txt
rm toSortDistMatrix.txt

