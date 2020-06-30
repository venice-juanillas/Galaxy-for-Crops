#!/usr/bin/bash

work_pwd=`pwd`
url=$1
username=$2
password=$3
variantset=$4
matrix=$5
vid=$6

touch $matrix

token=`python3 /usr/bin/GOBii_extract_for_Galaxy.py -m Authenticate -U $url -u $username -p $password`

python3 /usr/bin/GOBii_extract_for_Galaxy.py -m Variantset -U $url -x $token -o $variantset

cat $variantset

python3 /usr/bin/GOBii_extract_for_Galaxy.py -m Extract -U $url -x $token -v $vid -o $matrix




	
