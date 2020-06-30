#!/usr/python

import os
import datetime
import sys
import boto
import boto3
import gzip

BUCKET_NAME = sys.argv[1] # replace with your bucket name
KEY = sys.argv[2] # replace with your object key
OUTFILE = sys.argv[3]

s3 = boto3.resource('s3')
conf = boto3.s3.transfer.TransferConfig()

try:
    s3.Bucket(BUCKET_NAME).download_fileobject(KEY, OUTFILE,)
except botocore.exceptions.ClientError as e:
    if e.response['Error']['Code'] == "404":
        print("The object does not exist.")
    else:
        raise
