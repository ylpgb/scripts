#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=192.168.40.11:80
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=default

for i in {1..2000}; do
   
   curl -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/queues -H "content-type: application/json" -d "{\"queueName\":\"test_q$i\",\"accessType\":\"non-exclusive\",\"egressEnabled\":true,\"ingressEnabled\":true,\"permission\":\"delete\"}"
   curl -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/queues/test_q$i/subscriptions -H "content-type: application/json" -d "{\"subscriptionTopic\":\"a\"}"
done

