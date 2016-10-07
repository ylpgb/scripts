#!/usr/bin/env python

import pygame
import time
import serial

rx_ser = serial.Serial(
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


#--------------------------------------------
# str2Num class
#--------------------------------------------
class str2Num(object):
  def __init__(self, value):
    try:
      self.num = int(value)
    except ValueError:
      self.num = 0

#--------------------------------------------
# Composer class
#--------------------------------------------
class Composer(object):
  def __init__(self):
    pygame.init()
    pygame.mixer.init()
    self.soundFiles = [ "../bash/tunes/piano/"+chr(i+ord('a'))+".wav" for i in range(7) ]
    self.sound = [ pygame.mixer.Sound(f) for f in self.soundFiles ]

  def play(self, idx):
    self.sound[idx].play()


#--------------------------------------------
# Composer instance
#--------------------------------------------
comp = Composer();

try:
  while 1:
    if( rx_ser.in_waiting > 0) :
      input = rx_ser.read(rx_ser.in_waiting)
    else:
      time.sleep(0.01)
      continue

    inputNum = str2Num(input[0]).num

    if (inputNum > 7 or inputNum < 1 ) : continue

    print ("inputNum", inputNum)
    comp.play(inputNum-1)

except KeyboardInterrupt:
  print ("Exit program")
  
