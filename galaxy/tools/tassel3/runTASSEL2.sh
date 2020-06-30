#!/bin/bash
#print "Runnning TASSEL"

GENO_TYPE=$1 #specify if hapmap, flapjack, plink, etc
GENO_FILE=$2 # genotype file
TRAIT_FILE=$3
POP_STRUCT_FILE=$4
FILTER_MIN_FREQ=$5
GLM_PERMUTATIONS=$6
GLM_MAXP=$7
MAP_FILE=$8

GALAXY_DB_DIR="/usr/lib/galaxy-server/database/tmp"

if test "$#" == 1; then
	echo "Usage: runTASSEL.sh <genotype_file_format> <genotype_file> <trait_file> <pop_struct_file> <min_freq> <num_permutations> <max_p> <output1> <output2> <map_file if flapjack>\n"
else
	#mkdir -p $GALAXY_DB_DIR
	if [[ $1 == hapmap ]]; 
		 then
			# TO DO: this doesn't work yet
			perl /usr/lib/galaxy-server/tools/tassel3/run_pipeline.pl -fork1 -hapmap $GENO_FILE -filterAlign -filterAlignMinFreq $FILTER_MIN_FREQ -fork2 -r $TRAIT_FILE -fork3 -q $POP_STRUCT_FILE -excludeLastTrait -combine4 -input1 -input2 -input3 -intersect -glm -glmPermutations $GLM_PERMUTATIONS -glmMaxP $GLM_MAXP -export $GALAXY_DB_DIR/TASSELOUT -runfork1 -runfork2 -runfork3
	elif [[ $1 == flapjack ]];
		 then
			perl /usr/lib/galaxy-server/tools/tassel3/run_pipeline.pl -fork1 -flapjack -geno $GENO_FILE -map $MAP_FILE -filterAlign -filterAlignMinFreq $FILTER_MIN_FREQ -fork2 -r $TRAIT_FILE -fork3 -q $POP_STRUCT_FILE -excludeLastTrait -combine4 -input1 -input2 -input3 -intersect -glm -glmPermutations $GLM_PERMUTATIONS -glmMaxP $GLM_MAXP -export $GALAXY_DB_DIR/TASSELOUT -runfork1 -runfork2 -runfork3
	else 
		echo "Specify genotype file format.\n"
	fi

	#rm -rf $GALXY_DB_DIR
fi
cp $GALAXY_DB_DIR/"TASSELOUT1.txt" $9
cp $GALAXY_DB_DIR/"TASSELOUT2.txt" $10

