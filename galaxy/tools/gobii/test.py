import requests
import json
import sys
import pandas as pd

def main(output):
	response = requests.get("http://hackathon.gobii.org:8081/gobii-dev/brapi/v1/variantsets", auth=('vjuanillas','Sc0tl4nd'))
	#response = requests.get(url)
	if(response.status_code) == 200:
		#print("OK")
		#print(response.json())
		#data = json.loads(response.text)
		#for x in range(len(data)):
		#	print(data[x])
		df = pd.read_json(response.text,orient='records')
		df.to_csv(output, header=False,index=False,index_label=None,sep='\t',mode='a')
	else:
		print(response.status_code)
	#print("Hello, Goodbye!")

if __name__ == "__main__":
	main(sys.argv[1])
