#!/usr/bin/env python

import serial
import time
import threading
import sys
import argparse
import signal

usage = 'Read AT command from config file and process it. Use - for command from stdin (CTRL+D to exit).'
parser = argparse.ArgumentParser(description=usage)
parser.add_argument('com_port')
parser.add_argument('cmdfile', nargs='?', type=argparse.FileType('r'), default=sys.stdin,
                    help='config file with AT command')
parser.add_argument('logfile', nargs='?', type=argparse.FileType('w'), default=sys.stdout,
                    help='log file')

args = parser.parse_args()
com_port = args.com_port

r_ser = serial.Serial(
  port = com_port,
  baudrate = 115200,
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

#--------------------------------------------------------
# ThreadMonitor class
#--------------------------------------------------------
class ThreadMonitor(object):
  def __init__(self):
    return

  def signal_handler(self, signal, frame):
    raise KeyboardInterrupt
    return

#--------------------------------------------------------
# Logger class
#--------------------------------------------------------
class Logger(object):
  def __init__(self, logfile):
    self.logfile = logfile 
    self.start_time = time.time()
    print(self.logfile, sys.stdout)

  def log(self, string):
    elapsed_time = int( ( time.time() - self.start_time ) * 1000 )
    elapsed_time_hour = str( elapsed_time // 3600000 ).zfill(2)
    elapsed_time_min = str( elapsed_time // 60000 % 60 ).zfill(2)
    elapsed_time_sec = str( elapsed_time // 1000 % 60 ).zfill(2)
    elapsed_time_msec = str( elapsed_time % 1000 ).zfill(3)
    time_text = elapsed_time_hour + ':' + elapsed_time_min + ':' + elapsed_time_sec + '.' + elapsed_time_msec
    if(isinstance(string, str)): 
       self.logfile.write('[' + time_text + '] ' + string)
    else:
       self.logfile.write('[' + time_text + '] ' + string.decode('utf-8'))
    #if(self.logfile != sys.stdout) : print (string)
    
    return

#--------------------------------------------------------
# Parser class
#--------------------------------------------------------
class Parser(object):
  def __init__(self):
    print ("Parser init")

  def parse(self, buf):
    posStart = buf.find('+UUBTGN:')
    if(posStart != -1) :
        remain = buf[posStart:]
        posEnd = remain.find('\r\n')
        payload = remain[13:posEnd]
        try:
          print(bytes.fromhex(payload).decode('ascii'))
        except:
          pass
    
#--------------------------------------------------------
# Command class
#--------------------------------------------------------
class Command(object):
  def __init__(self, serial_port):
    self.serial_port = serial_port
    return

  def execute(self):
    raise NotImplementedError

  def at_mode(self):
    time.sleep(1)
    self.serial_port.write( b'+++' )
    time.sleep(1)
    print ("AT command mode")
    return

  def data_mode(self):
    self.serial_port.write( b'ATO1\r\n' )
    print ("Data mode")
    return

  def cmd(self, cmdString):
    if(cmdString.find("at_mode") != -1): 
       self.at_mode()
    elif(cmdString.find("wait") != -1): 
       time.sleep(0.5)
    else:
       self.cmdString = cmdString[:len(cmdString)-1]+'\r\n'
       #print ("Send cmd ", self.cmdString)
       #print ("Send encoded cmd ", self.cmdString.encode('utf-8'))
       self.serial_port.write( self.cmdString.encode('utf-8') )

#--------------------------------------------------------
# Sender class
#--------------------------------------------------------
class Sender(object):
  def __init__(self, serial_port, cmdfile, logger):
    self.serial_port = serial_port
    self.cmdfile = cmdfile 
    self.logger = logger
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
    print("If AT command from stdin, use CTRL+D to exit")
    ##self.command.at_mode()

    while not self.stop_flag:
      cmdString = self.cmdfile.readline()
      if (len(cmdString) > 1) : self.command.cmd(cmdString)
      if (len(cmdString) == 0) : 
        self.cmdfile.seek(0)
      time.sleep(0.05)
    return
      
#--------------------------------------------------------
# Receiver class
#--------------------------------------------------------
class Receiver(object):
  def __init__(self, serial_port, logger):
    self.serial_port = serial_port
    self.logger = logger
    self.parser = Parser()
    self.buf = ''
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    return

  def stop(self):
    self.stop_flag = True
    return

  def run(self):
    while ((not self.stop_flag)) :
      buf = ''
      if( self.serial_port.in_waiting > 0) :
        buf = self.serial_port.read(self.serial_port.in_waiting).decode('ascii')
        self.logger.log(buf)
        self.buf += buf
      
      if(buf.find('\r\n')!=-1):
        self.parser.parse(self.buf)
        self.buf = ''
        
      time.sleep(0.05)
    return

# Create threadmonitor instance
threadMonitor = ThreadMonitor()

# Create receiver instance
receiver = Receiver(r_ser, Logger(args.logfile))

# Create sender instance
sender = Sender(r_ser, args.cmdfile, Logger(args.logfile))

try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  sender.stop()
  receiver.stop()

