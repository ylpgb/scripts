#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=192.168.40.11:80
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=default

for i in {1..3000}; do
   curl -d"<rpc semp-version=\"soltr/8_2_0\"><show><queue><name>*</name><count></count><num-elements>1000</num-elements></queue></show></rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP
done

