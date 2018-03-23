#!/usr/bin/env python

from datetime import datetime
import urllib2
import httplib
import time
import re
import logging

hostname = "http://ubloxsingapore.asuscomm.com:4004/latencytest"
#hostname = "http://10.122.253.32:8007/latencytest"
count = 3600 * 24
pretag = "Timestamp :"
posttag = "; "
timeformat = "%Y-%m-%d %H-%M-%S-%f"

logging.basicConfig(level=logging.DEBUG,
                    format='%(asctime)s %(levelname)s %(message)s',
                    filename='latency_rover.log',
                    filemode='w')

for ite in range(1, count):
   time.sleep(1)
   ctime = datetime.now()
   try:
      request = urllib2.Request(hostname)
      response = urllib2.urlopen(request)
      code = response.getcode()
      content = response.read()
      if (code == 200):
         #print content
         response.close()
      elif (code == 304):
         print "No data on the server"
         continue
      else:
         print "GET returned: " + str(code)
         continue
   except urllib2.HTTPError, e:
      print 'HTTPError = ' + str(e.code)
      break;
   except urllib2.URLError, e:
      print 'URLError = ' + str(e.reason)
      break;
   except httplib.HTTPException, e:
      print 'HTTPException'
      break;
   except Exception, e:
      print 'generic exception: ',e
      break;

   try:
      ### match the last time stamp
      #pattern = '.*' + pretag + '(.+?)' + posttag + '$';
      ### match the first time stamp
      pattern = pretag + '(.+?)' + posttag;

      ptime = re.search(pattern, content).group(1)
      #print "found time is " + ptime
      try:
         ptime = datetime.strptime(ptime, timeformat)
      except ValueError:
         ptime = ctime
   except AttributeError:
      ptime = ctime

   latency_ms = int((ctime - ptime).total_seconds() * 1000)
   #print (ctime, ptime)
   print str(latency_ms) + "ms"
   if (latency_ms > 5000 ) :
      logging.error(str(latency_ms) + "ms")
   elif (latency_ms > 2000) :
      logging.warning(str(latency_ms) + "ms")
   elif (latency_ms > 1000) :
      logging.info(str(latency_ms) + "ms")
   else:
      logging.debug(str(latency_ms) + "ms")
   

