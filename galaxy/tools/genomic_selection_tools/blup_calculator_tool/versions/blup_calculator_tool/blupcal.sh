#!/bin/bash
tool_directory=$1
galaxy_tabular_file=$2
galaxy_replication_vector_column_index=$3
galaxy_genotype_vector_column_index=$4
galaxy_first_y_vector_column_index=$5
galaxy_last_y_vector_column_index=$6
galaxy_design=$7
galaxy_summarize_by=$8
galaxy_summarize_by_vector_column_index=$9
galaxy_group_variable_1=${10}
galaxy_group_variable_1_vector_column_index=${11}
galaxy_group_variable_2=${12}
galaxy_group_variable_2_vector_column_index=${13}
galaxy_output_file_path=${14}
block_vector_column_index=${15}
summary=${16}
typeblup=${17}

directory=`dirname $0`
mkdir tmpdir$$


counter=$galaxy_first_y_vector_column_index

previous="tmpdir$$/output"
echo '' >$previous
while [ $counter -le $galaxy_last_y_vector_column_index ]
do


/home/galaxy/data/R/R-3.5.1/bin/Rscript --vanilla $directory/blupcal_wrapper.R --tool_directory $tool_directory --tabular_file $galaxy_tabular_file --replication_vector_column_index $galaxy_replication_vector_column_index --genotype_vector_column_index $galaxy_genotype_vector_column_index --first_y_vector_column_index $counter --last_y_vector_column_index $counter --design $galaxy_design --summarize_by $galaxy_summarize_by --summarize_by_vector_column_index $galaxy_summarize_by_vector_column_index --group_variable_1 $galaxy_group_variable_1 --group_variable_1_vector_column_index $galaxy_group_variable_1_vector_column_index --group_variable_2 $galaxy_group_variable_2 --group_variable_2_vector_column_index $galaxy_group_variable_2_vector_column_index --output_file_path tmpdir$$/output.$counter --block_vector_column_index $block_vector_column_index
#cat tmpdir$$/output.$counter >>$galaxy_output_file_path
if [ "$counter" -gt "$galaxy_first_y_vector_column_index" ];then
if [[ "$galaxy_summarize_by" == "true" ]];then 
cut -f 3-7 tmpdir$$/output.$counter >>tmpdir$$/output.$counter.cut
cut -f 3 tmpdir$$/output.$counter >>tmpdir$$/output.$counter.cut2
fi
if [[ "$galaxy_summarize_by" == "false" ]];then
cut -f 2-6 tmpdir$$/output.$counter >>tmpdir$$/output.$counter.cut
cut -f 2 tmpdir$$/output.$counter >>tmpdir$$/output.$counter.cut2
fi
mv tmpdir$$/output.$counter.cut tmpdir$$/output.$counter
mv tmpdir$$/output.$counter.cut2 tmpdir$$/output.$counter.summary
fi
if [ "$counter" -gt "$galaxy_first_y_vector_column_index" ];then
paste $previous tmpdir$$/output.$counter >>tmpdir$$/output.$counter.$counter
paste $previous2 tmpdir$$/output.$counter.summary >>tmpdir$$/output.$counter.$counter.summary
fi
if [ "$counter" -eq "$galaxy_first_y_vector_column_index" ];then
cp tmpdir$$/output.$counter tmpdir$$/output.$counter.$counter
if [[ "$galaxy_summarize_by" == "true" ]];then
cut -f 1,2,3 tmpdir$$/output.$counter >tmpdir$$/output.$counter.$counter.summary
fi
if [[ "$galaxy_summarize_by" == "false" ]];then
cut -f 1,2 tmpdir$$/output.$counter >tmpdir$$/output.$counter.$counter.summary
fi
fi
previous="tmpdir$$/output.$counter.$counter"
previous2="tmpdir$$/output.$counter.$counter.summary"
cp -rf tmpdir$$/output.$counter.$counter $galaxy_output_file_path
cp -rf tmpdir$$/output.$counter.$counter.summary $summary
#paste $galaxy_output_file_path tmpdir$$/output.$counter >>$galaxy_output_file_path
#cut -f 3-7 tmpdir$$/output.$counter >tmpdir$$/output.$counter.cut
((counter++))
done





