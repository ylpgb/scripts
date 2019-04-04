#!/usr/bin/env python

import serial
import time
import threading
import sys
import argparse
import signal
import queue
import json
import http.client, urllib.parse

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

    return

        
#--------------------------------------------------------
# Commander class
#--------------------------------------------------------
class Commander(object):
  def __init__(self, cmdfile):
    self.cmdfile = cmdfile
    self.cmd_queue = queue.Queue(maxsize=50)
    self.stop_flag = False
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    return
  
  def stop(self):
    self.stop_flag = True
    return

  def cmd(self, cmdString):
    self.cmdString = cmdString.rstrip()+'\r\n'
    try:
      #print("cmdString", self.cmdString)
      self.cmd_queue.put(self.cmdString, block=True)
    except queue.Full:
      pass

  def get_command(self):
    cmdString = self.cmd_queue.get(block=True)
    return (cmdString)

  def run(self):
    while not self.stop_flag:
        cmdString = self.cmdfile.readline()
        if(cmdString != ''):
          self.cmd(cmdString)
        else:
          self.cmdfile.seek(0)
          continue
          
        time.sleep(0.1)
  
#--------------------------------------------------
# event class
#--------------------------------------------------
class Event():
  class BLE_ROLE_TYPE:
    DISABLED = 0
    CENTRAL = 1
    PERIPHERAL = 2
    CENTRAL_AND_PERIPHERAL = 3
    
  class EVENT_TYPE:
    UNKNOWN = 0
    STARTUP = 1
    CMD_OK = 2
    CMD_ERROR = 3
    CMD_COMPLETE = 10
    GATT_ACL_CONNECTED = 4
    GATT_ACL_DISCONNECTED = 5
    GATT_NOTIFICATION = 6
    BLE_ROLE = 7
    BLE_DISCOVER = 8
    WIFI_SCAN = 9

    
  def __init__( self ):
    return

  def get_event_type( self ):
    raise NotImplementedError

class StartupEvent( Event ):
  def get_event_type( self ):
    return Event.EVENT_TYPE.STARTUP

class CMDOkEvent( Event ):
  def get_event_type( self ):
    return Event.EVENT_TYPE.CMD_OK

class CMDErrorEvent( Event ):
  def get_event_type( self ):
    return Event.EVENT_TYPE.CMD_ERROR

class CMDCompleteEvent( Event ):
  def get_event_type( self ):
    return Event.EVENT_TYPE.CMD_COMPLETE
    
class GATTACLConnectedEvent( Event ):	
  def get_event_type( self ):
    return Event.EVENT_TYPE.GATT_ACL_CONNECTED

class GATTACLDisconnectedEvent( Event ):
  def get_event_type( self ):
    return Event.EVENT_TYPE.GATT_ACL_DISCONNECTED

class GATTNotificationEvent( Event ):
  def __init__( self, payload ):
    pos = payload.rfind(',')
    self.payload = payload[pos+1:]
    try:
      print(bytes.fromhex(self.payload).decode('utf-8'))
    except:
      pass
      
  def get_event_type( self ):
    return Event.EVENT_TYPE.GATT_NOTIFICATION
    
class BLERoleEvent( Event ):
  def __init__( self, payload ):
    pos = payload.rfind(':')
    role = payload[pos+1:]
    #print("role:", role)
    self.ble_role = int(role)

  def get_event_type( self ):
    return Event.EVENT_TYPE.BLE_ROLE
    
  def get_ble_role( self ):
    return self.ble_role

class BLEDiscoverEvent( Event ):
  def __init__( self, payload ):
    token_list = payload.split(',')
    pos = token_list[0].find(':')
    self.bd_addr = token_list[0][pos+1:]
    self.name = token_list[2].strip('"')

  def get_event_type( self ):
    return Event.EVENT_TYPE.BLE_DISCOVER
    
  def get_name( self ):
    return self.name
  
  def get_bd_addr( self ):
    return self.bd_addr
    
class WIFIScanEvent( Event ):
  def __init__( self, payload ):
    tokens = payload[payload.find(':')+1:].split(',')
    self.bssid = tokens[0]
    self.ssid = tokens[2]
    self.rssi = tokens[4]
      
  def get_event_type( self ):
    return Event.EVENT_TYPE.WIFI_SCAN
  
  def get_bssid( self ):
    return self.bssid
  
  def get_ssid( self ):
    return self.ssid
    
  def get_rssi( self ):
    return self.rssi
    
#--------------------------------------------------------
# Parser class
#--------------------------------------------------------
class Parser(object):
  def __init__(self):
    self.cmd_event_queue = queue.Queue(maxsize=50)
    self.status_event_queue = queue.Queue(100)
    self.status_event_queue.put(StartupEvent())
  
  def process_serial_data(self, buf):
    logger.log(buf)
    buf = buf.strip();
    #print("event: ", buf)
    if(buf.startswith('+STARTUP')):
      self.status_event_queue.put(StartupEvent())
    elif(buf.startswith('OK')):
      if(controller.sender.command_written == True):
        self.cmd_event_queue.put(CMDOkEvent())
        if(controller.notify_cmd_complete == True):
          self.status_event_queue.put(CMDCompleteEvent())
        controller.sender.command_written = False
    elif(buf.startswith('ERROR')):
      if(controller.sender.command_written == True):
        self.cmd_event_queue.put(CMDErrorEvent())
        if(controller.notify_cmd_complete == True):
          self.status_event_queue.put(CMDCompleteEvent())
        controller.sender.command_written = False
    elif(buf.startswith('+UUBTACLC:')):
      self.status_event_queue.put(GATTACLConnectedEvent())
    elif(buf.startswith('+UUBTACLD:')):
      self.status_event_queue.put(GATTACLDisconnectedEvent())
    elif(buf.startswith('+UUBTGN:')):
      self.status_event_queue.put(GATTNotificationEvent(buf))
    elif(buf.startswith('+UBTLE:')):
      self.status_event_queue.put(BLERoleEvent(buf))
    elif(buf.startswith('+UBTD:')):
      self.status_event_queue.put(BLEDiscoverEvent(buf))
    elif(buf.startswith('+UWSCAN:')):
      self.status_event_queue.put(WIFIScanEvent(buf))
    elif(buf.startswith('AT') or buf.startswith('at') or buf == ''):
      pass
    else:
      pass
      
#--------------------------------------------------------
# Sender class
#--------------------------------------------------------
class Sender(object):
  def __init__(self, controller):
    self.serial_port = controller.serial_port
    self.parser = controller.parser
    self.stop_flag = False
    self.command_written = False;
    self.thread = threading.Thread(target = self.run)
    self.thread.start()
    return
  
  def stop(self):
    self.stop_flag = True
    return
  
  def run(self):
    while not self.stop_flag:
      cmdString = commander.get_command()
      if(cmdString!=''):
        ## wait as a way to add delay
        if(cmdString.find('wait') != -1):
          time.sleep(1)
          continue     
          
        self.serial_port.write(cmdString.encode('utf-8'))
        #print("*** written {}.".format(cmdString.encode('utf-8')))
        self.command_written = True;
        try:
          event = self.parser.cmd_event_queue.get(block=True, timeout=2)
        except queue.Empty:
          pass
    return

      
#--------------------------------------------------------
# Receiver class
#--------------------------------------------------------
class Receiver(object):
  def __init__(self, controller):
    self.serial_port = controller.serial_port
    self.parser = controller.parser
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
      '''
      buf = self.serial_port.readline().decode('utf-8')
      if (buf != ''):
        self.parser.process_serial_data(buf)
      '''
      c = self.serial_port.read(1)
      if(c == b''):
        continue
      if(c != b'\n'):
        self.buf += c.decode('utf-8')
      else:
        self.parser.process_serial_data(self.buf)
        self.buf = ''

    return

#--------------------------------------------------
# controller class
#--------------------------------------------------
class Controller():

  def state_wait_startup( self, event ):
    event_type = event.get_event_type()
    print("state_wait_startup")
    time.sleep(5)
    if event_type == Event.EVENT_TYPE.STARTUP:
      self.notify_cmd_complete = True
      commander.cmd('AT+UWSCAN')
      return self.state_wait_wifi_scan_result
    return self.state_wait_startup

  def get_location( self ):
    geolocation_request = {}
    geolocation_request['considerIp'] = 'false'
    geolocation_request['wifiAccessPoints'] = []
    for key, ap in self.aplist.items():
      mac = ':'.join(ap[0][i:i+2] for i in range(0,12,2))
      geolocation_request['wifiAccessPoints'].append({'macAddress':mac, 'signalStrength':int(ap[1]), 'signalToNoiseRatio':0})

    host = "www.googleapis.com"
    url = "/geolocation/v1/geolocate?key=" + apikey
    header = {"Content-type": "application/json"}
    conn = http.client.HTTPSConnection(host)
    conn.request("POST", url, json.dumps(geolocation_request), headers=header)
    position = conn.getresponse().read().decode('utf-8')
    print(position)
    
    if( len(tbdevicekey) == 20 ):
      response_json = json.loads(position);
      telemetry = {}
      telemetry['lat'] = response_json['location']['lat']
      telemetry['long'] = response_json['location']['lng']
      telemetry['accuracy'] = response_json['accuracy']
      tbhost = "b202-thingsboard.ddns.net"
      tburl = "/api/v1/" + tbdevicekey + "/telemetry"
      tbconn = http.client.HTTPConnection(tbhost, 8080)
      tbconn.request("POST", tburl, json.dumps(telemetry), headers=header)
      response = tbconn.getresponse().read().decode()
      print("position uploaded to thingsboard server")
      
  def state_wait_wifi_scan_result( self, event ):
    event_type = event.get_event_type()
    if event_type == Event.EVENT_TYPE.WIFI_SCAN:
      print("found AP {} {}".format(event.get_bssid(), event.get_ssid()))
      if(event.get_ssid() != ''):
        self.aplist[event.get_bssid()] = (event.get_bssid(), event.get_rssi(), event.get_ssid())
      return self.state_wait_wifi_scan_result
    elif event_type == Event.EVENT_TYPE.CMD_COMPLETE:
      print("scan complete")
      self.get_location()
      self.aplist = {}
      self.notify_cmd_complete = False
      self.parser.status_event_queue.put(StartupEvent())
      return self.state_wait_startup
    return self.state_wait_wifi_scan_result
    
  def state_wait_ble_role_result( self, event ):
    event_type = event.get_event_type()
    if event_type == Event.EVENT_TYPE.BLE_ROLE:
      if(event.get_ble_role() == Event.BLE_ROLE_TYPE.CENTRAL ):
        commander.cmd('AT+UBTD=4,1')
        return self.state_wait_ble_discover_result
      else:
        commander.cmd('AT+UBTLE=1')
        commander.cmd('AT&W')
        commander.cmd('AT+CPWROFF')
        return self.state_wait_startup
    return self.state_wait_ble_role_result
    
  def state_wait_ble_discover_result( self, event ):
    event_type = event.get_event_type()
    if event_type == Event.EVENT_TYPE.BLE_DISCOVER:
      if event.get_name().find('MJ_HT') != -1 :
        controller.sensor_bd_addr = event.get_bd_addr()
        cmdString = "AT+UBTACLC=" + controller.sensor_bd_addr
        commander.cmd(cmdString)
        return self.state_wait_gatt_connect_result
    return self.state_wait_ble_discover_result
    
  def state_wait_gatt_connect_result( self, event ):
    event_type = event.get_event_type()
    if event_type == Event.EVENT_TYPE.GATT_ACL_CONNECTED:
      commander.cmd('AT+UBTGWC=0,16,1')
      return self.state_wait_gatt_notification_result
    return self.state_wait_gatt_connect_result
    
  def state_wait_gatt_notification_result( self, event ):
    event_type = event.get_event_type()
    if event_type == Event.EVENT_TYPE.GATT_ACL_DISCONNECTED:
      cmdString = "AT+UBTACLC=" + controller.sensor_bd_addr
      commander.cmd(cmdString)
      return self.state_wait_gatt_connect_result
    return self.state_wait_gatt_notification_result
    
  def event_handler( self, event ):
    self.state_func = self.state_func( event )
    return
        
  def __init__( self, serial_port):
    self.serial_port = serial_port
    self.parser = Parser();
    self.stop_flag = False
    self.sensor_bd_addr = ''
    self.notify_cmd_complete = False
    self.aplist = {}
    self.state_func = self.state_wait_startup
    self.thread = threading.Thread( target = self.run )
    self.thread.setDaemon( True )
    self.thread.start()
    return
    
  def stop(self):
    self.stop_flag = True
    return
    
  def run( self ):
    self.receiver = Receiver( self )
    self.sender = Sender( self )
    while not self.stop_flag:
      try:
        event = self.parser.status_event_queue.get(block=True, timeout=None)
        self.event_handler(event)
      except queue.Empty:
          pass
    return

#--------------------------------------------------
# main function
#--------------------------------------------------
usage = 'Read AT command from config file and process it. (CTRL+D to exit).'
parser = argparse.ArgumentParser(description=usage)

parser.add_argument('com_port')

parser.add_argument('apikey')

parser.add_argument('devicekey', 
                    nargs='?', 
                    help='thingsboard device key')
                    
parser.add_argument('cmdfile', 
                    nargs='?', 
                    type=argparse.FileType('r'), 
                    default=sys.stdin,
                    help='config file with AT command')
                    
parser.add_argument('logfile', 
                    nargs='?', 
                    type=argparse.FileType('w'), 
                    default=sys.stdout,
                    help='log file')

args = parser.parse_args()
com_port = args.com_port
apikey = args.apikey

tbdevicekey = ''
if (args.devicekey != None):
  tbdevicekey = args.devicekey


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

# Create threadmonitor instance
threadMonitor = ThreadMonitor()

# Create Logger
logger = Logger(args.logfile)

# Create Commander
commander = Commander(args.cmdfile)

# Create Controller
controller = Controller(r_ser)

try:
  while 1:
    time.sleep(1)
except KeyboardInterrupt:
  print("Exiting program")
  commander.stop()
  controller.sender.stop()
  controller.receiver.stop()
  controller.stop()
  


