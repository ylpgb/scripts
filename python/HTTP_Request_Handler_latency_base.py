#!/usr/bin/env python

from datetime import datetime
import urllib2
import time

hostname = "http://ubloxsingapore.asuscomm.com:4004/latencytest"
#hostname = "http://10.122.253.32:8007/latencytest"
count = 3600*24
pretag = "Timestamp :"
posttag = "; "
timeformat = "%Y-%m-%d %H-%M-%S-%f"

for ite in range(1, count):
   time.sleep(0.1)
   ctime = datetime.now()
   payload = pretag + ctime.strftime(timeformat) + posttag
   response = urllib2.urlopen(hostname, data=payload)
   response.close()


