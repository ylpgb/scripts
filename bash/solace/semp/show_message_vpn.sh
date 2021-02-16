#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=default

max=0
for i in {1..30000}; do
   ret=`curl -s -d"<rpc><show><message-vpn><vpn-name>$MESSAGE_VPN</vpn-name></message-vpn></show></rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP`
   count=`echo "$ret" | grep "connections-service-rest-incoming" | grep -v max | sed -n 's/.*>\([1-9]*\)<.*/\1/p'`
   echo "Current: $count. Max: $max"
   if [[ $count -gt $max ]] ; then
    max=$count
   fi
done

echo "Max: $max"
