#!/usr/bin/env python

import serial
import time
import threading
import argparse
import pygame
import sys

rx_ser = serial.Serial(
  port = "COM9",
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
parser.add_argument('dumpFile', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
                    help='dump file')

args = parser.parse_args()


class Receiver(object):
  def __init__(self, serial_port, dumpFile):
    self.serial_port = serial_port
    self.dumpFile = dumpFile 
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    #self.thread2 = threading.Thread(target = self.play)
    #self.thread2.start()
    return

  def stop(self):
    self.stop_flag = True
    return

  def run(self):
    #print("Receiver start")
    while not self.stop_flag:
      if( self.serial_port.in_waiting > 0) :
        self.buf = self.serial_port.read(self.serial_port.in_waiting)
        args.dumpFile.write(self.buf)
        args.dumpFile.flush()

      time.sleep(0.01)
    return

  def play(self):
    time.sleep(5)
    #print("Play start")
    self.voiceFile = open(self.dumpFile.name, 'rb')
    pygame.init()
    pygame.mixer.pre_init(frequency=44100, size=-16, channels=2,buffer=1024)
    pygame.mixer.init()
    while True:
      self.voiceBuf = self.voiceFile.read(1024*1024)
      if(len(self.voiceBuf)==0): break
      self.sound = pygame.mixer.Sound(buffer=buffer(self.voiceBuf, 44, len(self.voiceBuf)))
      self.sound.play()
      time.sleep(5)
    return

receiver = Receiver(rx_ser, args.dumpFile)


try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  receiver.stop()

