#!/bin/bash
# 

for((i=0; i<100000; i++))
do
echo "Iteration $i..." | tee -a upgrade_reset.log
./upgrade_reset1.sh 192.168.130.39,192.168.130.40 | tee -a upgrade_reset.log
done

