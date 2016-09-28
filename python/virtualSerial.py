#!/usr/bin/env python

import os, pty, serial
import time, threading

master, slave = pty.openpty()
s_name = os.ttyname(slave)

s_ser = serial.Serial(
  port = s_name,
  baudrate = 115200,
  bytesize = serial.EIGHTBITS,
  parity = serial.PARITY_NONE,
  stopbits = serial.STOPBITS_ONE,
  timeout = None,
  xonxoff = False,
  rtscts = True,
  dsrdtr = False,
  write_timeout = None,
  inter_byte_timeout = None
)

class Sender(object):
  def __init__(self, serial_port):
    self.serial_port = serial_port
    self.start_time = time.time()
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
      time.sleep(1)
      self.buf = "Sending text at " + str(time.time()-self.start_time)
      self.serial_port.write(self.buf)
      print("data write is: " + self.buf)
    return
      
class Receiver(object):
  def __init__(self):
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    return

  def stop(self):
    self.stop_flag = True
    return

  def run(self):
    print("Receiver start")
    while not self.stop_flag:
      self.buf = os.read(master, 1000)
      print("data read is: " + self.buf)
    return

# Create sender instance
sender = Sender(s_ser)

# Create receiver instance
receiver = Receiver()

try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  sender.stop()
  receiver.stop()

