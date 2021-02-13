#!/bin/bash

logfile=$1

[[ $# < 1 ]] && { echo "Specify stat file"; exit 1; }

clientList=`grep '^GBRPSM02000' $logfile | cut -d' ' -f1 | sort | uniq`

sum=0
for client in $clientList; do 
  awkRegExp=$(echo $client | sed 's|/|\\/|g')
  #echo "$awkRegExp"

  cmd="awk '/^$awkRegExp/ && \$25>=60 {p=1}; p; /^show client GBRPSM020005372.*connections wide/ {p=0}' $logfile | grep 'Client Name.*$client' -A100 | grep 'Compressed Rate (60 sec)' | awk 'BEGIN{max=0} {if (\$5>max) max=\$5 } END{print max*8}'"
  
  ret=`eval $cmd`
  sum=$(($sum + $ret))

  echo "Client: $client: $ret bps"
done
echo "Total: $sum bps"

