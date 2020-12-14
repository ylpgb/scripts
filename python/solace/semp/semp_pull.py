#!/usr/bin/env python

import threading
import time
import requests

exitFlag = 0

class myThread (threading.Thread):
   def __init__(self, threadID, name, counter):
      threading.Thread.__init__(self)
      self.threadID = threadID
      self.name = name
      self.counter = counter
   def run(self):
      print ("Starting " + self.name)
      semp_request(self.name, -1, self.counter)
      print ("Exiting " + self.name)

def semp_request(threadName, counter, delay):
   while counter:
      if exitFlag:
         threadName.exit()
      time.sleep(delay)
      print ("%s: %s" % (threadName, time.ctime(time.time())))
      url     = 'http://192.168.40.11:80/SEMP'
      payload = '<rpc semp-version="soltr/8_2_0"><show><client><name>*</name><count></count><num-elements>1000</num-elements></client></show></rpc>'
      headers = {}
      res = requests.post(url, data=payload, headers=headers, auth=('admin','admin')) 
      payload = '<rpc semp-version=\"soltr/8_2_0\"><show><queue><name>*</name><count></count><num-elements>1000</num-elements></queue></show></rpc>'
      res = requests.post(url, data=payload, headers=headers, auth=('admin','admin')) 
      counter -= 1

# Create new threads
thread1 = myThread(1, "Thread-1", 0.01)
thread2 = myThread(2, "Thread-2", 0.01)
thread3 = myThread(3, "Thread-3", 0.01)
thread4 = myThread(4, "Thread-4", 0.01)
thread5 = myThread(5, "Thread-5", 0.01)
thread6 = myThread(6, "Thread-6", 0.01)
thread7 = myThread(7, "Thread-7", 0.01)
thread8 = myThread(8, "Thread-8", 0.01)
thread9 = myThread(9, "Thread-9", 0.01)
thread10 = myThread(10, "Thread-10", 0.01)
thread11 = myThread(11, "Thread-11", 0.01)
thread12 = myThread(12, "Thread-12", 0.01)

# Start new Threads
thread1.start()
thread2.start()
thread3.start()
thread4.start()
thread5.start()
thread6.start()
thread7.start()
thread8.start()
thread9.start()
thread10.start()
thread11.start()
thread12.start()

print ("Exiting Main Thread")
