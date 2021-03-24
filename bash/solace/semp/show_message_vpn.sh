#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=http://a7f6886a0658f4d2683b127da32625d3-2074040571.ap-northeast-1.elb.amazonaws.com:8080
MESSAGE_VPN=default

#MANAGEMENT_USER=lp-test-admin
#MANAGEMENT_PASSWORD=5o2thabl2ejrfecrm9bnf6jfrg
#BROKER_SEMP_URL=https://mrgjijghtuh0z.messaging.solace.cloud:943
#MESSAGE_VPN=lp-test

max=0
for i in {1..30000}; do
   ret=`curl -s -k -d"<rpc><show><message-vpn><vpn-name>$MESSAGE_VPN</vpn-name></message-vpn></show></rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD $BROKER_SEMP_URL/SEMP`
   count=`echo "$ret" | grep "connections-service-rest-incoming" | grep -v max | sed -n 's/.*>\([1-9]*\)<.*/\1/p'`
   echo "Current: $count. Max: $max"
   if [[ $count -gt $max ]] ; then
    max=$count
   fi
done

echo "Max: $max"
