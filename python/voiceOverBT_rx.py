#!/usr/bin/env python

import serial
import time
import threading
import argparse
import pygame
import sys

rx_ser = serial.Serial(
  port = "/dev/ttyUSB1",
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
    self.totalReadSize = 0
    #pygame.init()
    #pygame.mixer.pre_init(frequency=8000, size=-16, channels=2, buffer=4096)
    #pygame.mixer.init()
    #self.sound = pygame.mixer.Sound(self.dumpFile)
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    return

  def stop(self):
    self.stop_flag = True
    return

  def run(self):
    print("Receiver start")
    while not self.stop_flag:
      if( self.serial_port.in_waiting > 0) :
        self.buf = self.serial_port.read(self.serial_port.in_waiting)
        args.dumpFile.write(self.buf)
        self.totalReadSize += len(self.buf)

      if(self.totalReadSize>0):
        #self.sound = pygame.mixer.Sound(file=self.dumpFile)
        #self.sound.play()
        pass

      time.sleep(0.01)
    return

receiver = Receiver(rx_ser, args.dumpFile)


try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  receiver.stop()

