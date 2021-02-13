#!/bin/bash
clientList="
GBRPSM020005372/1304/#00000001
GBRPSM020005372/1304/#00000001
GBRPSM020005372/2360/#00000001
GBRPSM020005372/3332/#00000001
GBRPSM020005372/5388/#00000001
GBRPSM020005372/2668/#00000001
GBRPSM020005372/6632/#00000001
GBRPSM020005372/7580/#00000001
GBRPSM020005372/7836/#00000001
"


for client in $clientList; do 
  awkRegExp=$(echo $client | sed 's|/|\\/|g')
  #echo "$awkRegExp"

  cmd="awk '/^$awkRegExp/ && \$25>=60 {p=1}; p; /^show client GBRPSM020005372.*connections wide/ {p=0}' rt47936-stats.txt | grep 'Client Name.*$client' -A100 | grep 'Compressed Rate (60 sec)' | awk 'BEGIN{max=0} {if (\$5>max) max=\$5 } END{print max*8}'"
  
  ret=`eval $cmd`
  echo "Client: $client: $ret bps"
done


