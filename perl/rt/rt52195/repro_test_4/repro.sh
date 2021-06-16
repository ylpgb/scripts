#!/bin/bash 

for ((i=0; i<100000; i++))
do
echo "--> Iteration $i" | tee -a rt52195.txt
./release_redundancy.sh 192.168.129.8,192.168.129.77 | tee -a rt52195.txt
done
