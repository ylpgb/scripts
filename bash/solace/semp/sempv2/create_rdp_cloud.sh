#!/bin/bash

MANAGEMENT_USER=lp-admin
MANAGEMENT_PASSWORD=lp-admin
BROKER_SEMP_URL=104.197.21.134:943
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=leipo-nano-bunnings-dbg
REST_SERVER=rest-server-
REST_PORT=9009

for i in {3..100}; do
   
   curl -k -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD https://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/queues -H "content-type: application/json" -d "{\"queueName\":\"Q-rdp$i-input\",\"accessType\":\"non-exclusive\",\"egressEnabled\":true,\"ingressEnabled\":true,\"permission\":\"delete\"}"
   curl -k -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD https://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/queues/Q-rdp$i-input/subscriptions -H "content-type: application/json" -d "{\"subscriptionTopic\":\"T-rest-pubsub\"}"
   curl -k -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD https://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/restDeliveryPoints -H "content-type: application/json" -d "{\"clientProfileName\":\"default\",\"enabled\":true,\"msgVpnName\":\"$MESSAGE_VPN\",\"restDeliveryPointName\":\"rdp$i\"}"
   curl -k -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD https://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/restDeliveryPoints/rdp$i/queueBindings -H "content-type: application/json" -d "{\"gatewayReplaceTargetAuthorityEnabled\":false,\"msgVpnName\":\"$MESSAGE_VPN\",\"postRequestTarget\":\"/rest/tutorials\",\"queueBindingName\":\"Q-rdp$i-input\",\"restDeliveryPointName\":\"rdp$i\"}"
   curl -k -X POST -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD https://$BROKER_SEMP_URL/SEMP/v2/config/msgVpns/$MESSAGE_VPN/restDeliveryPoints/rdp$i/restConsumers -H "content-type: application/json" -d "{\"authenticationHttpBasicUsername\":\"\",\"authenticationHttpHeaderName\":\"\",\"authenticationScheme\":\"none\",\"enabled\":true,\"httpMethod\":\"post\",\"localInterface\":\"\",\"maxPostWaitTime\":30,\"msgVpnName\":\"$MESSAGE_VPN\",\"outgoingConnectionCount\":3,\"remoteHost\":\"$REST_SERVER$i.example.com\",\"remotePort\":$REST_PORT,\"restConsumerName\":\"rc1\",\"restDeliveryPointName\":\"rdp$i\",\"retryDelay\":3,\"tlsCipherSuiteList\":\"default\",\"tlsEnabled\":false}"
done

