#!/usr/bin/env python

import serial
import time
import threading
import argparse
import sys

tx_ser = serial.Serial(
  port = "/dev/ttyUSB0",
  baudrate = 3000000,
  bytesize = serial.EIGHTBITS,
  parity = serial.PARITY_NONE,
  stopbits = serial.STOPBITS_ONE,
  timeout = 0,
  xonxoff = False,
  rtscts = True,
  dsrdtr = False,
  write_timeout = None,
  inter_byte_timeout = None
)

parser = argparse.ArgumentParser(description='Send voice file over Bluetooth')
parser.add_argument('voiceFile', nargs='?', type=argparse.FileType('r'), default=sys.stdin,
                    help='voice file')

args = parser.parse_args()


class Sender(object):
  def __init__(self, serial_port, voiceFile):
    self.serial_port = serial_port
    self.voiceFile = voiceFile
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    return

  def stop(self):
    self.stop_flag = True
    return

  def run(self):
    print("Sender start")
    while not self.stop_flag:
      self.buf = self.voiceFile.read(1)
      print("Read ", len(self.buf), " bytes")
      if (len(self.buf)==0) :
        print("Reading file completed!!")
        break
      self.serial_port.write(self.buf)
    return

sender = Sender(tx_ser, args.voiceFile)


try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  sender.stop()

