#!/usr/bin/env python

import pygame
import time

'''
#--------------------------------------------
# Composer class
#--------------------------------------------
'''
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
    input = int(raw_input())
    if (input > 7 or input < 1 ) :
      continue
    comp.play(input-1)

except KeyboardInterrupt:
  pass
