#!/bin/bash

nextPage=`curl -s -X GET -u admin:admin http://192.168.40.233:8080/SEMP/v2/action/msgVpns/default/queues/test/msgs | jq ".meta.paging.nextPageUri"`
echo "nextPage: $nextPage"
links=`curl -s -X GET -u admin:admin http://192.168.40.233:8080/SEMP/v2/action/msgVpns/default/queues/test/msgs | jq ".links.deleteUri"`
echo "$links"
for i in "$links"; do 
 echo "--> $i"
done

