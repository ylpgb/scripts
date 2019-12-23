#!/usr/bin/env python

import threading
import sys
import time
import argparse
import signal
import os
import re
import pickle
from enum import Enum

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
# Parse class
#--------------------------------------------------------
class Parser(object):
  def __init__(self, statfile):
    self.statfile= statfile
    self.stats = {}
    self.processedStats = {}
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    return

  def stop(self):
    self.stop_flag = True
    return

  def run(self):
    dfile = open(self.statfile, 'rb')
    self.stats = pickle.load(dfile)
    dfile.close()

    print("length of dic: ", len(self.stats))
    hist={}
    for key in self.stats:
      if len(self.stats[key]) in hist.keys():
        hist[len(self.stats[key])] += 1
      else:
        hist[len(self.stats[key])] = 0

    for key in self.stats:
      index = -1
      for i in range(len(self.stats[key])):
        if self.stats[key][i]['eventType'] == EVENT_TYPE.CLIENT_CLIENT_DISCONNECT :
          if index == -1 :
            index = i
          else:
            if self.stats[key][index]['totalBytesDelivered'] < self.stats[key][i]['totalBytesDelivered'] :
              index = i

      if index != -1 and int(self.stats[key][index]['totalBytesDelivered']) > 500000000:
        self.processedStats[key] = self.stats[key][index]['totalBytesDelivered']

    print("length: ", len(self.stats), " and ", len(self.processedStats))

    for key in self.processedStats:
      print("client: ", key, " value: ", self.processedStats[key])


    for key in sorted(hist.keys()):
      print((key, hist[key]))

    print("Processing completed!!!")
    return


# Create sender instance
stats_parser = Parser(args.statfile)

try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  stats_parser.stop()
