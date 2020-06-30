#!/bin/bash
input=$1
output=$2
x_axis=$3
y_axis=$4
z_axis=$5
id=$6
category=$7
root_dir=$8

directory=`dirname $0`
mkdir tmpdir$$


perl $directory/InteractiveScatter.pl -i $input -o $output -x $x_axis -y $y_axis -n $id -c $category -z $z_axis -r $root_dir
