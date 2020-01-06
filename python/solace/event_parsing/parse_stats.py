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

usage = 'Parse stats from broker event log'
parser = argparse.ArgumentParser(description=usage)
parser.add_argument('logfile', nargs='+', type=argparse.FileType('r'), default=sys.stdin,
                    help='log file')

args = parser.parse_args()

#--------------------------------------------------------
# EVENT_TYPE class
#--------------------------------------------------------
class EVENT_TYPE(Enum):
  CLIENT_CLIENT_CONNECT = 1
  CLIENT_CLIENT_DISCONNECT = 2
  
#--------------------------------------------------------
# CLIENT_CONNECT_EventParse class
#--------------------------------------------------------
class CLIENT_CONNECT_EventParser(object):
  def __init__(self, event):
    self.event = event
    self.stats = {}
    self.stats['eventType'] = EVENT_TYPE.CLIENT_CLIENT_CONNECT
    
    self.parse()

  def parse(self):
    m = re.search('CLIENT_CLIENT_CONNECT.*: (.+?) Client', self.event)
    if m:
      self.stats['clientName'] = m.group(1)

    m = re.search('^(.+?) <', self.event)
    if m:
      self.stats['time'] = m.group(1)
      
#--------------------------------------------------------
# CLIENT_DISCONNECT_EventParse class
#--------------------------------------------------------
class CLIENT_DISCONNECT_EventParser(object):
  def __init__(self, event):
    self.event = event
    self.stats = {}
    self.stats['eventType'] = EVENT_TYPE.CLIENT_CLIENT_DISCONNECT
    
    self.parse()

  def parse(self):
    m = re.search('CLIENT_CLIENT_DISCONNECT.*: (.+?) Client', self.event)
    if m:
      self.stats['clientName'] = m.group(1)

    m = re.search('^(.+?) <', self.event)
    if m:
      self.stats['time'] = m.group(1)
      
    m = re.search('dp\((.+?)\)', self.event)
    if m:
      stats = m.group(1).split(', ')

      self.stats['controlMsgsReceived'] = stats[0]
      self.stats['controlMsgsDelivered'] = stats[1]
      self.stats['topicMsgsReceived'] = stats[2]
      self.stats['topicMsgsDelivered'] = stats[3]
      self.stats['totalMsgsReceived'] = stats[4]
      self.stats['totalMsgsDelivered'] = stats[5]
      self.stats['controlBytesReceived'] = stats[6]
      self.stats['controlBytesDelivered'] = stats[7]
      self.stats['topicBytesReceived'] = stats[8]
      self.stats['topicBytesDelivered'] =stats[9]
      self.stats['totalBytesReceived'] = stats[10]
      self.stats['totalBytesDelivered'] = stats[11]
      self.stats['curMsgRateIngress'] = stats[12]
      self.stats['curMsgRateEgress'] = stats[13]
      self.stats['avgMsgRateIngress'] = stats[14]
      self.stats['avgMsgRateEgress'] = stats[15]
      self.stats['deniedDuplicateClients'] = stats[16]
      self.stats['discardsNoSubscriptionMatch'] = stats[17]
      self.stats['discardsTopicParseError'] = stats[18]
      self.stats['discardsParseError'] = stats[19]
      self.stats['discardsMsgTooBig'] = stats[20]
      self.stats['discardsTransmitCongestion'] = stats[21]

    m = re.search('conn\((.+?)\)', self.event)
    if m:
      stats = m.group(1).split(', ')

      self.stats['recvQBytes'] = stats[0]
      self.stats['sendQBytes'] = stats[1]
      self.stats['clientAddr'] = stats[2]
      self.stats['state'] = stats[3]
      self.stats['outOfOrder'] = stats[4]
      self.stats['fastRetransmit'] = stats[5]
      self.stats['timedRetransmit'] = stats[6]

    m = re.search('zip\((.+?)\)', self.event)
    if m:
      stats = m.group(1).split(', ')

      self.stats['compressedBytesReceived'] = stats[0]
      self.stats['compressedBytesDelivered'] = stats[1]
      self.stats['uncompressedBytesReceived'] = stats[2]
      self.stats['uncompressedBytesDelivered'] = stats[3]
      self.stats['compressionRatioIngress'] = stats[4]
      self.stats['compressionRatioEgress'] = stats[5]
      self.stats['curCompressedByteRateIngress'] = stats[6]
      self.stats['curCompressedByteRateEgress'] = stats[7]
      self.stats['curUncompressedByteRateIngress'] = stats[8]
      self.stats['curUncompressedByteRateEgress'] = stats[9]
      self.stats['avgCompressedByteRateIngress'] = stats[10]
      self.stats['avgCompressedByteRateEgress'] = stats[11]
      self.stats['avgUncompressedByteRateIngress'] = stats[12]
      self.stats['avgUncompressedByteRateEgress'] = stats[13]

    m = re.search('web\((.+?)\)', self.event)
    if m:
      stats = m.group(1).split(', ')

      self.stats['webMsgsReceived'] = stats[0]
      self.stats['webMsgsDelivered'] = stats[1]
      self.stats['webBytesReceived'] = stats[2]
      self.stats['webBytesDelivered'] = stats[3]
      self.stats['webOutOfOrder'] = stats[4]
      self.stats['webFastRetransmit'] = stats[5]
      self.stats['webTimedRetransmit'] = stats[6]

    m = re.search('reason\((.+?)\)', self.event)
    if m:
      self.stats['reason'] = m.group(1)

      
#--------------------------------------------------------
# Parse class
#--------------------------------------------------------
class Parser(object):
  def __init__(self, logfile):
    self.logfile = logfile
    print("logfile, ", (logfile))
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.msgThreshould = 20000
    self.bytesThreshould = 300000000
    self.stats = {}
    self.thread.start()
    return
  
  def stop(self):
    self.stop_flag = True
    return
  
  def run(self):
    print("If logfile is from stdin, use CTRL+D to exit")

    while not self.stop_flag:
      for file in self.logfile :
        print("Processing file: " + file.name)
        for event in file :
          #event = file.readline()
          event_parser = None
          if(event.find('CLIENT_CLIENT_CONNECT') != -1):
            event_parser = CLIENT_CONNECT_EventParser(event)
          elif(event.find('CLIENT_CLIENT_DISCONNECT') != -1):
            event_parser = CLIENT_DISCONNECT_EventParser(event)
        
          if event_parser:
            if event_parser.stats['clientName'] in self.stats.keys():
              try:
                self.stats[event_parser.stats['clientName']].append(event_parser.stats)
              except:
                print("Unable to append to the list for key " + event_parser.stats['clientName'])
            else:
              self.stats[event_parser.stats['clientName']] = [event_parser.stats]
            
      print("dict length: ", len(self.stats))
      dfile = open('dump.pkl', 'wb')
      pickle.dump(self.stats, dfile)
      dfile.close()
      os.kill(os.getpid(), signal.SIGUSR1)
      break 
    exit(0)
      

# Create sender instance
stats_parser = Parser(args.logfile[::-1])

try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  stats_parser.stop()

