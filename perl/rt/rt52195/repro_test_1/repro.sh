#!/bin/bash 

for ((i=0; i<100000; i++))
do
echo "--> Iteration $i" | tee -a rt52195.txt
./reload.sh 192.168.129.80,192.168.129.82 | tee -a rt52195.txt
done
