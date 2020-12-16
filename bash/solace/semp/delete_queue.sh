#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=192.168.40.11:80
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=default

for i in {1..5000}; do
   curl -d"<rpc><message-spool><vpn-name>$MESSAGE_VPN</vpn-name><queue><name>test_q$i</name><shutdown></shutdown></queue></message-spool></rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP
   curl -d"<rpc><message-spool><vpn-name>$MESSAGE_VPN</vpn-name><no><queue><name>test_q$i</name></queue></no></message-spool></rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP
done

