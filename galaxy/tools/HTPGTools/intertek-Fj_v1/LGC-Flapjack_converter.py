#!/bin/env python
#This script converts LGC genotype data to Flapjack genotype format
#For more info: wkigoni@gmail.com
#Usage: ./LGC-Flapjack_converter.py genotype_file.txt Fj_file.txt


import os, sys
intertek_file =sys.argv[1]
flapjack_file =sys.argv[2]


LGC_id = 'DNA \\ Assay'
fj_header = '# fjFile = GENOTYPE'
missing_string = 'NN'

def replacer(a):
    s = a.replace('DNA \\ Assay','')
    search_list = ['?','DUPE','Bad','NTC','Unused','empty','Uncallable','NA']
    for item in search_list:
	s = s.replace(item, missing_string)
    x = s.replace ('Missing', '-')    
    y = x.replace(',', '\t')
    z = y.replace(':','')
    return z

#Extracting genotypic data in Flapjack format
out_file = open(flapjack_file, 'w')
raw_LGC_data = open(intertek_file,'rb')		
out_file.write(fj_header + "\n")
lines = raw_LGC_data.readlines()
always_print = False
for line in lines:
    if always_print or LGC_id  in line:
       	always_print = True
        out_file.write(replacer(line))
