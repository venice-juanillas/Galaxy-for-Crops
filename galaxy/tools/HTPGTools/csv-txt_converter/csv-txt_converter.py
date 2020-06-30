#!/bin/env python
#For more info: wkigoni@gmail.com
#Description: This script converts a .csv to a tab-delimited format .txt file
#Usage: ./csv-txt_converter.py $csv_file $txt_file

import sys, csv
csv_file = sys.argv[1]
txt_file = sys.argv[2]
with open(txt_file, "w") as my_output_file:
    with open(csv_file, "r") as my_input_file:
        [ my_output_file.write("\t".join(row)+'\n') for row in csv.reader(my_input_file)]
    my_output_file.close()
