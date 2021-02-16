#!/usr/bin/python3

import requests
from requests.auth import HTTPBasicAuth
import time
import threading

hostName = "mrgjijghtuh0z.messaging.solace.cloud"
hostPort = 9000
username = 'client1'
password = 'client1'
topic = "T/rest/pubsub"

numMsgs=5000
delay=0.1
numClients=3

class client(threading.Thread):

   def __init__(self):
      threading.Thread.__init__(self)
      self.url = "http://"+hostName+":"+str(hostPort)+"/"+topic
      self.headers = {'content-type': 'text', 'Solace-delivery-mode': 'direct'}
      self.data = "Hello World Rest"

   def run(self):
      self.do_POST()

   def do_POST(self):
      i=0
      while i<numMsgs :
         i=i+1
         ret = requests.post(self.url, headers=self.headers, data=self.data, auth=HTTPBasicAuth(username, password))
         time.sleep(delay)

myClients= [client() for i in range(numClients)]
for i in range(numClients):
   myClients[i].start()

