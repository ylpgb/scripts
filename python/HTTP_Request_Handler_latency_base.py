#!/usr/bin/env python

from datetime import datetime
import urllib2
import httplib
import time

hostname = "http://ubloxsingapore.asuscomm.com:4004/latencytest"
#hostname = "http://10.122.253.32:8007/latencytest"
count = 3600*24
pretag = "Timestamp :"
posttag = "; "
timeformat = "%Y-%m-%d %H-%M-%S-%f"

for ite in range(1, count):
   time.sleep(0.5)
   ctime = datetime.now()
   payload = pretag + ctime.strftime(timeformat) + posttag
   try:
      response = urllib2.urlopen(hostname, data=payload)
   except urllib2.HTTPError, e:
      print 'HTTPError = ' + str(e.code)
      break
   except urllib2.URLError, e:
      print 'URLError = ' + str(e.reason)
      break
   except httplib.HTTPException, e:
      print 'HTTPException'
      break
   except Exception:
      print 'generic exception: '
      break
   else:
      response.close()


