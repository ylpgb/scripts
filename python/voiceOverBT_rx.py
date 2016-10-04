#!/usr/bin/env python

import serial
import time
import threading
import argparse
import sys
import pyaudio
import wave 

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
    self.thread2 = threading.Thread(target = self.play)
    self.thread2.start()
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
        args.dumpFile.flush()

      time.sleep(0.01)
    return

  def play(self):
    time.sleep(5)
    self.chunk = 128
    print("Play start")
    self.wf = wave.open(self.dumpFile.name, 'rb')
    self.p = pyaudio.PyAudio()
    stream = self.p.open(
       format = self.p.get_format_from_width(self.wf.getsampwidth()),
       channels = self.wf.getnchannels(),
       rate = self.wf.getframerate(),
       output = True)
    self.data = self.wf.readframes(self.chunk)

    while self.data!='' and (not self.stop_flag):
      stream.write(self.data)
      self.data = self.wf.readframes(self.chunk)

    stream.close()
    self.p.terminate()
    return

receiver = Receiver(rx_ser, args.dumpFile)


try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  receiver.stop()

