#!/usr/bin/env python

import threading
import sys
import datetime
import time
import argparse
import re
import pickle
from enum import Enum
import matplotlib.pyplot as plt
import json

usage = 'load and manipulate the statistics from the parsed event log'
parser = argparse.ArgumentParser(description=usage)
parser.add_argument('statfile', nargs='?', type=str, default="dump.pkl",
                    help='stat file')

args = parser.parse_args()

#--------------------------------------------------------
# EVENT_TYPE class
#--------------------------------------------------------
class EVENT_TYPE(Enum):
  CLIENT_CLIENT_CONNECT = 1
  CLIENT_CLIENT_DISCONNECT = 2


#--------------------------------------------------------
# EnumEncoder class
#--------------------------------------------------------
PUBLIC_ENUMS = {
    'EVENT_TYPE': EVENT_TYPE,
    # ...
}
class EnumEncoder(json.JSONEncoder):
    def default(self, obj):
        if type(obj) in PUBLIC_ENUMS.values():
            return {"__enum__": str(obj)}
        return json.JSONEncoder.default(self, obj)


#--------------------------------------------------------
# Parse class
#--------------------------------------------------------
class Parser(object):
  def __init__(self, statfile):
    self.statfile= statfile
    self.stats = {}
    self.processedStats = {}
    self.hist = {}
    self.timeHist = {}
    self.run()
    return

  def process_for_key_threshold(self, value, threshold):
    ## generate processedStats based on certain criteria
    for key in self.stats:
      index = -1
      for i in range(len(self.stats[key])):
        if self.stats[key][i]['eventType'] == EVENT_TYPE.CLIENT_CLIENT_DISCONNECT :
          if index == -1 :
            index = i
          else:
            if self.stats[key][index][value] < self.stats[key][i][value] :
              index = i

      if index != -1 and int(self.stats[key][index][value]) > threshold:
        self.processedStats[key] = self.stats[key][index][value]

  def process_for_key_value(self, k, value):
    ## generate processedStats based on certain criteria
    for key in self.stats:
      for i in range(len(self.stats[key])):
        if self.stats[key][i]['eventType'] == EVENT_TYPE.CLIENT_CLIENT_DISCONNECT and self.stats[key][i][k] == value:
          self.processedStats[key] = self.stats[key]
          break;


  def process_for_time(self):
    ## generate processedStats for the time that the client is connected
    for key in self.stats:
      connect_time_obj = None
      disconnect_time_obj = None
      maxTimeDiff = datetime.timedelta(0)
      for i in range(len(self.stats[key])):
        if self.stats[key][i]['eventType'] == EVENT_TYPE.CLIENT_CLIENT_CONNECT :
            #connect_time_obj = time.strptime(self.stats[key][i]['time'],'%Y-%m-%dT%H:%M:%S.%f%z')
            connect_time_obj = datetime.datetime.fromisoformat(self.stats[key][i]['time'])
        if self.stats[key][i]['eventType'] == EVENT_TYPE.CLIENT_CLIENT_DISCONNECT :
            #disconnect_time_obj = time.strptime(self.stats[key][i]['time'],'%Y-%m-%dT%H:%M:%S.%f%z')
            disconnect_time_obj = datetime.datetime.fromisoformat(self.stats[key][i]['time'])
            if connect_time_obj != None and disconnect_time_obj - connect_time_obj > maxTimeDiff :
                maxTimeDiff = disconnect_time_obj - connect_time_obj

        if maxTimeDiff > datetime.timedelta(0) :
          self.processedStats[key] = disconnect_time_obj - connect_time_obj

  def dump(self, d):
    for key in d:
      print("key: " + key)
      print(json.dumps(d[key], cls=EnumEncoder, indent=4))

  def plot(self, hist):
    lists = sorted(hist.items())
    x, y = zip(*lists)
    plt.plot(x,y,'bo',linestyle='dashed')
    plt.show()

  def run(self):
    dfile = open(self.statfile, 'rb')
    self.stats = pickle.load(dfile)
    dfile.close()

    print("length of dic: ", len(self.stats))
    ## examine stats. Maybe too overwhelming
    #for key in self.stats:
    #  print("key ", key, " value: ", self.stats[key])

    ## generate the histogram of event for the numbero events
    for key in self.stats:
      if len(self.stats[key]) in self.hist.keys():
        self.hist[len(self.stats[key])] += 1
      else:
        self.hist[len(self.stats[key])] = 1

    for key in sorted(self.hist.keys()):
      print((key, self.hist[key]))


    ## generate processedStats based on certain criteria
    self.process_for_key_value('reason', 'Forced Logout')
    self.dump(self.processedStats)

    #self.process_for_key_threshold('topicBytesDelivered', 500000000)

    """ based on connection time 
    self.process_for_time()
    print("length of result: ", len(self.processedStats))
    if len(self.processedStats) < 1000 :
      for key in self.processedStats:
        print("client: ", key, " value: ", self.processedStats[key])
    else:
      print("Too many entries to print")

    for i in range(25) :
      self.timeHist[i] = 0
    for key in self.processedStats:
      if self.processedStats[key] > datetime.timedelta(days=1):
        self.timeHist[24] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*12):
        self.timeHist[23] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*11):
        self.timeHist[22] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*10):
        self.timeHist[21] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*9):
        self.timeHist[20] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*8):
        self.timeHist[19] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*7):
        self.timeHist[18] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*6):
        self.timeHist[17] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*5):
        self.timeHist[16] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*4):
        self.timeHist[15] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*3):
        self.timeHist[14] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60*2):
        self.timeHist[13] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*60):
        self.timeHist[12] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*50):
        self.timeHist[11] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*40):
        self.timeHist[10] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*30):
        self.timeHist[9] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*20):
        self.timeHist[8] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*10):
        self.timeHist[7] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=60*1):
        self.timeHist[6] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=50):
        self.timeHist[5] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=40):
        self.timeHist[4] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=30):
        self.timeHist[3] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=20):
        self.timeHist[2] += 1
      elif self.processedStats[key] > datetime.timedelta(seconds=10):
        self.timeHist[1] += 1
      else :
        self.timeHist[0] += 1

    self.plot(self.timeHist)
    """
    print("Processing completed!!!")


# Create sender instance
stats_parser = Parser(args.statfile)

try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  stats_parser.stop()
