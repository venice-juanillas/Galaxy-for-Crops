#!/bin/bash

tool_path=$(dirname $0)

filein=$1
fileout=$2
groups=$3

perl $tool_path/InTreeGreat.pl $filein $fileout $groups

