#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=35.197.149.246:8080
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=default
REST_SERVER=rest-server-
REST_PORT=9009

for i in {1..100}; do
   
   curl -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/queues -H "content-type: application/json" -d "{\"queueName\":\"Q-rdp$i-input\",\"accessType\":\"non-exclusive\",\"egressEnabled\":true,\"ingressEnabled\":true,\"permission\":\"delete\"}"
   curl -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/queues/Q-rdp$i-input/subscriptions -H "content-type: application/json" -d "{\"subscriptionTopic\":\"T-rest-pubsub\"}"
   curl -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/restDeliveryPoints -H "content-type: application/json" -d "{\"clientProfileName\":\"default\",\"enabled\":true,\"msgVpnName\":\"$MESSAGE_VPN\",\"restDeliveryPointName\":\"rdp$i\"}"
   curl -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/restDeliveryPoints/rdp$i/queueBindings -H "content-type: application/json" -d "{\"gatewayReplaceTargetAuthorityEnabled\":false,\"msgVpnName\":\"$MESSAGE_VPN\",\"postRequestTarget\":\"/rest/tutorials\",\"queueBindingName\":\"Q-rdp$i-input\",\"restDeliveryPointName\":\"rdp$i\"}"
   curl -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/restDeliveryPoints/rdp$i/restConsumers -H "content-type: application/json" -d "{\"authenticationHttpBasicUsername\":\"\",\"authenticationHttpHeaderName\":\"\",\"authenticationScheme\":\"none\",\"enabled\":true,\"httpMethod\":\"post\",\"localInterface\":\"\",\"maxPostWaitTime\":30,\"msgVpnName\":\"$MESSAGE_VPN\",\"outgoingConnectionCount\":3,\"remoteHost\":\"$REST_SERVER$i.example.com\",\"remotePort\":$REST_PORT,\"restConsumerName\":\"rc1\",\"restDeliveryPointName\":\"rdp$i\",\"retryDelay\":3,\"tlsCipherSuiteList\":\"default\",\"tlsEnabled\":false}"
done

