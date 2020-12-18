#!/bin/bash

USER=admin
PASS=admin
URL=192.168.40.12:80
FILE=$URL.log

rm $FILE
semp_request() {
   for i in {1..200}; do
      curl -s -d'<rpc semp-version="soltr/8_2_0"><show><client><name>*</name><count></count><num-elements>1000</num-elements></client></show></rpc>' -u $USER:$PASS http://$URL/SEMP >> $FILE
      curl -s -d'<rpc semp-version=\"soltr/8_2_0\"><show><topic-endpoint><name>*</name><count></count><num-elements>1000</num-elements></topic-endpoint></show></rpc>' -u $USER:$PASS http://$URL/SEMP >> $FILE
      curl -s -d'<rpc semp-version=\"soltr/8_2_0\"><show><queue><name>*</name><count></count><num-elements>1000</num-elements></queue></show></rpc>' -u $USER:$PASS http://$URL/SEMP >> $FILE
   done
}

# Perform the semp request
time semp_request
