#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=192.168.40.11:80
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=default

   
curl -X GET -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/monitor/msgVpns/$MESSAGE_VPN/clients | grep uri 
curl -X PUT -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP/v2/action/msgVpns/$MESSAGE_VPN/clients/lp-ubuntu-18-04-4%2F24317%2F%2300100004%2FyR8bzz8Bmj/disconnect -H "content-type: application/json" -d '{}' 

