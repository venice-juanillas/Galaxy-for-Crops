#!/bin/python

#This script generates 12-digit random UIDs
#More info: m.kigoni@cgiar.org

import uuid, sys

number_to_generate = int(sys.argv[1])
output = sys.argv[2]


f=open(output,'w')
i=0
while i < number_to_generate:
	f.write(str(uuid.uuid4().hex[:12])+'\n')
	i+=1
f.close
