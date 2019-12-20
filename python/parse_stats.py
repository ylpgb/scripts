#!/usr/bin/env python

import threading
import sys
import time
import argparse
import signal
import os
import re

usage = 'Parse stats from broker event log'
parser = argparse.ArgumentParser(description=usage)
parser.add_argument('logfile', nargs='?', type=argparse.FileType('r'), default=sys.stdin,
                    help='log file')

args = parser.parse_args()

#--------------------------------------------------------
# EventParse class
#--------------------------------------------------------
class EventParser(object):
  def __init__(self, event):
    self.event = event

    self.controlMsgsReceived = 0
    self.controlMsgsDelivered = 0
    self.topicMsgsReceived = 0
    self.topicMsgsDelivered = 0
    self.totalMsgsReceived = 0
    self.totalMsgsDelivered = 0
    self.controlBytesReceived = 0
    self.controlBytesDelivered = 0
    self.topicBytesReceived = 0
    self.topicBytesDelivered =0
    self.totalBytesReceived = 0
    self.totalBytesDelivered = 0
    self.curMsgRateIngress = 0
    self.curMsgRateEgress = 0
    self.avgMsgRateIngress = 0
    self.avgMsgRateEgress = 0
    self.deniedDuplicateClients = 0
    self.discardsNoSubscriptionMatch = 0
    self.discardsTopicParseError = 0
    self.discardsParseError = 0
    self.discardsMsgTooBig = 0
    self.discardsTransmitCongestion = 0
    
    self.parse()

  def parse(self):
    m = re.search('dp\((.+?)\)', self.event)
    if m:
      stats = m.group(1).split(', ')

      self.controlMsgsReceived = stats[0]
      self.controlMsgsDelivered = stats[1]
      self.topicMsgsReceived = stats[2]
      self.topicMsgsDelivered = stats[3]
      self.totalMsgsReceived = stats[4]
      self.totalMsgsDelivered = stats[5]
      self.controlBytesReceived = stats[6]
      self.controlBytesDelivered = stats[7]
      self.topicBytesReceived = stats[8]
      self.topicBytesDelivered =stats[9]
      self.totalBytesReceived = stats[10]
      self.totalBytesDelivered = stats[11]
      self.curMsgRateIngress = stats[12]
      self.curMsgRateEgress = stats[13]
      self.avgMsgRateIngress = stats[14]
      self.avgMsgRateEgress = stats[15]
      self.deniedDuplicateClients = stats[16]
      self.discardsNoSubscriptionMatch = stats[17]
      self.discardsTopicParseError = stats[18]
      self.discardsParseError = stats[19]
      self.discardsMsgTooBig = stats[20]
      self.discardsTransmitCongestion = stats[21]


#--------------------------------------------------------
# Parse class
#--------------------------------------------------------
class Parser(object):
  def __init__(self, logfile):
    self.logfile = logfile 
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.msgThreshould = 20000
    self.bytesThreshould = 300000000
    self.count = 0
    self.thread.start()
    return
  
  def stop(self):
    self.stop_flag = True
    return
  
  def run(self):
    print("If logfile is from stdin, use CTRL+D to exit")

    while not self.stop_flag:
      event = self.logfile.readline()
      if (len(event) > 1) : 
        event_parser = EventParser(event)
        if ((int(event_parser.totalBytesDelivered) > self.bytesThreshould) & (int(event_parser.totalMsgsDelivered) > self.msgThreshould) & (int(event_parser.totalMsgsDelivered) < 30000)):
          self.count = self.count + 1
          print(event)
          print("totalMsgsDelivered: ", event_parser.totalMsgsDelivered, " totalBytesDelivered: ", event_parser.totalBytesDelivered)

      if (len(event) == 0) : 
        print("Command completed!!! Found event meeting criteria " + str(self.count))
        os.kill(os.getpid(), signal.SIGUSR1)
        break 
    return
      

# Create sender instance
stats_parser = Parser(args.logfile)

try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  stats_parser.stop()

