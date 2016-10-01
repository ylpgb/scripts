#!/usr/bin/env python

import serial
import time
import threading
import sys
import argparse

parser = argparse.ArgumentParser(description='Read AT command from config file and process it')
parser.add_argument('infile', nargs='?', type=argparse.FileType('r'), default=sys.stdin,
                    help='config file with AT command')
parser.add_argument('outfile', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
                    help='log file')

args = parser.parse_args()

r_ser = serial.Serial(
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

class Log(object):
  def __init__(self, outfile):
    self.outfile = outfile
    self.start_time = time.time()
    return

  def log(self, string):
    elapsed_time = int( ( time.time() - self.start_time ) * 1000 )
    elapsed_time_hour = str( elapsed_time // 3600000 ).zfill(2)
    elapsed_time_min = str( elapsed_time // 60000 % 60 ).zfill(2)
    elapsed_time_sec = str( elapsed_time // 1000 % 60 ).zfill(2)
    elapsed_time_msec = str( elapsed_time % 1000 ).zfill(3)
    time_text = elapsed_time_hour + ':' + elapsed_time_min + ':' + elapsed_time_sec + '.' + elapsed_time_msec
    self.outfile.write('[' + time_text + '] ' + string)
    return

class Command(object):
  def __init__(self, serial_port):
    self.serial_port = serial_port
    return

  def execute(self):
    raise NotImplementedError

  def at_mode(self):
    print ("Setting AT command mode")
    time.sleep(1)
    self.serial_port.write( b'+++\n' )
    time.sleep(1)
    print ("Setting AT command mode done")
    return

  def data_mode(self):
    print ("Setting data command mode")
    self.serial_port.write( b'ATO1\r\n' )
    print ("Setting data command mode done")
    return

  def cmd(self, cmdString):
    self.cmdString = cmdString[:len(cmdString)-1]+'\r\n'
    print ("Send cmd ", self.cmdString)
    self.serial_port.write( self.cmdString )

class Sender(object):
  def __init__(self, serial_port, infile):
    self.serial_port = serial_port
    self.infile = infile
    self.start_time = time.time()
    self.command = Command(self.serial_port)
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    return
  
  def stop(self):
    self.stop_flag = True
    return
  
  def run(self):
    print("Sender start")
    self.command.at_mode()

    while not self.stop_flag:
      cmdString = self.infile.readline()
      if (len(cmdString) > 1) : self.command.cmd(cmdString)
      if (len(cmdString) == 0) : 
        print("Command completed!!!")
        break 
      time.sleep(0.2)
    return
      
class Receiver(object):
  def __init__(self, serial_port, logger):
    self.serial_port = serial_port
    self.logger = logger
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    return

  def stop(self):
    self.stop_flag = True
    return

  def run(self):
    print("Receiver start")
    while ((not self.stop_flag)) :
      if( self.serial_port.in_waiting > 0) :
        self.buf = self.serial_port.read(self.serial_port.in_waiting)
        self.logger.log(self.buf)

      time.sleep(0.01)
    return

# Create sender instance
sender = Sender(r_ser, args.infile)

# Create receiver instance
receiver = Receiver(r_ser, Log(args.outfile))

try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  sender.stop()
  receiver.stop()

