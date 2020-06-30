import pandas
import numpy as np
import optparse
import sys
#import matplotlib.pyplot as plt

def main():
	p = optparse.OptionParser(__doc__)
	p.add_option("-f","--file", 
			dest="inputFile", 
			help="Input File", 
			default=False)
	p.add_option("-l","--log", 
			dest="logFile",
			help="Log File")
	options, args = p.parse_args()
	
	# read values from file and store in Datafframe
	df = pandas.read_table(options.inputFile, header=0)
	df['minuspvalue'] = -np.log10(df.ix[:,5]) # get -nlog10(p-val) using numpu
	#print(df[['minuspvalue']])
	#print(df.Chr)
	df.Chr = df.Chr.astype('category')
	#df.Chr = df.Chr.cat.set_categories(['ch-%i' % i for i in range(12)], ordered=True)
	df = df.sort_values('Chr')	
	print(df)

if __name__ == "__main__":
	main()
