import sys
import os
import re

def get_field_gid_options(dataset):
	options = []
	line=os.popen("grep '^#' %s"%dataset.file_name+" | awk -F '\t' {'print $11'}").read()[:-1].split('\n')
	#line=os.popen("grep '^S0' %s"%dataset.file_name+" | awk -F '\t' {'print $1'}").read()[:-1].split('\n')
        
	for opt in line[1:] :
		
		options.append((opt,opt, True))
	return options

#print get_field_samples_options("/home/galaxy/data/alexis_dereeper/database/files/007/dataset_7961.dat")
