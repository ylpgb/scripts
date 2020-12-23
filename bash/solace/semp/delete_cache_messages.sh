#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=192.168.128.46:80
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=default
DISTRIBUTED_CACHE=dc1

for i in {00..99}; do
   number=$(printf "%02d" $i)
   curl  -s -d"<rpc><admin><distributed-cache><name>$DISTRIBUTED_CACHE</name><vpn-name>$MESSAGE_VPN</vpn-name><delete-messages><topic>cache/b/d$number*</topic></delete-messages></distributed-cache></admin></rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP
done

