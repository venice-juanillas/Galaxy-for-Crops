#!/usr/python

import os
import datetime
import sys
import boto
import boto3
import gzip
from boto.s3.key import Key
from boto.s3.connection import S3Connection


def look_up(bucket,filename,output):
	nonexistent=bucket.lookup(filename)
	if nonexistent is None:
		print "No such file in bucket."
	else:
		print nonexistent.key
		file_key = bucket.get_key(filename)
		file_key.get_contents_to_filename(output)


def decompress(gzfile,output):
	f = gzip.open(gzfile,'rb')
	o = open(output,'wb')
	o.write(f.read())
	f.close()
	o.close()
		

if __name__ == '__main__':
	#conn=S3Connection('AKIAIUKZTDGGLWYKB77A','MUgODBw7lc9zFMns7IAYd4+Y2VERu5Sg2BPO2K7l')
	conn=S3Connection(sys.argv[1],sys.argv[2])
	bucket=conn.get_bucket('3kricegenome');
	#download(bucket,'Nipponbare/B001.realigned.bam')
	reference=sys.argv[3]
	variety=sys.argv[4]
	output=sys.argv[5]
	finput=reference+"/"+variety+".snp.vcf.gz"
	foutput="temp.vcf.gz"

	look_up(bucket,finput, foutput)
	#decompress(foutput,output)
	with gzip.open(foutput,'rb') as f_in, gzip.open(output,'wb') as f_out:
		f_out.write(f_in.read())
