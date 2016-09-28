#!/usr/bin/env python

import pygame
import time
import readchar

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
    input = readchar.readchar()
    if (input=='\x03'): break

    inputNum = str2Num(input).num
    print ("inputNum", inputNum)

    if (inputNum > 7 or inputNum < 1 ) : continue

    comp.play(inputNum-1)

except KeyboardInterrupt:
  pass
