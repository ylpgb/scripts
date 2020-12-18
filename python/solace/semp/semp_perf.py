#!/usr/bin/env python

import threading
import time
import requests

def semp_request():
   url     = 'http://192.168.40.12:80/SEMP'
   payload = '<rpc semp-version="soltr/8_2_0"><show><client><name>*</name><count></count><num-elements>1000</num-elements></client></show></rpc>'
   headers = {}
   res = requests.post(url, data=payload, headers=headers, auth=('admin','admin')) 
   
   payload = '<rpc semp-version=\"soltr/8_2_0\"><show><topic-endpoint><name>*</name><count></count><num-elements>1000</num-elements></topic-endpoint></show></rpc>'
   res = requests.post(url, data=payload, headers=headers, auth=('admin','admin')) 

   payload = '<rpc semp-version=\"soltr/8_2_0\"><show><queue><name>*</name><count></count><num-elements>1000</num-elements></queue></show></rpc>'
   res = requests.post(url, data=payload, headers=headers, auth=('admin','admin')) 

# Perform the semp request
start = time.time()
for count in range(1,100):
   semp_request()      

end = time.time()
print(end-start)
