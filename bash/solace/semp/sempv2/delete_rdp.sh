#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=192.168.133.71:8080
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=default
REST_SERVER=perf-131-66-
REST_PORT=9009

for i in {1..10}; do
   
   curl -X DELETE -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/restDeliveryPoints/rdp$i/restConsumers/rc1 
   curl -X DELETE -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/restDeliveryPoints/rdp$i
   curl -X DELETE -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/queues/Q-rdp$i-input
done

