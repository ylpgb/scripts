# -*- coding: utf-8 -*-

import argparse
import serial
import threading
import queue
import time
import sys
import re
import binascii

pattern_ok_event = re.compile( 'OK' )
pattern_error_event = re.compile( 'ERROR' )
pattern_ubtbd_event = re.compile( '^\+UBTBD:([0-9A-F]{12})*' )
pattern_uudpc_event = re.compile( '^\+UUDPC:([0-9])' )
pattern_uudpd_event = re.compile( '^\+UUDPD:([0-9])' )

data_value = 0

#==================================================
# sub routine
#==================================================

def count_generator():
	count = 0
	while( True ):
		yield count
		count += 1

#--------------------------------------------------
# command class
#--------------------------------------------------

def print_log( string ):
	elapsed_time = int( ( time.time() - start_time ) * 1000 )
	elapsed_time_hour = str( elapsed_time // 3600000 ).zfill(2)
	elapsed_time_min = str( elapsed_time // 60000 % 60 ).zfill(2)
	elapsed_time_sec = str( elapsed_time // 1000 % 60 ).zfill(2)
	elapsed_time_msec = str( elapsed_time % 1000 ).zfill(3)
	time_text = elapsed_time_hour + ':' + elapsed_time_min + ':' + elapsed_time_sec + '.' + elapsed_time_msec
	print( '[', time_text, ']', string )
	return

class Command():
	
	def __init__( self, serial_port ):
		self.serial_port = serial_port
		return
	
	def execute( self ):
		raise NotImplementedError
	
	def send_edm_at_request( self, message ):
		payload_length = len( message ) + 2
		data = bytearray( [0xAA] )
		data.append( payload_length // 0x100 )
		data.append( payload_length % 0x100 )
		data.append( 0x00 )
		data.append( 0x44 )
		data.extend( message.encode( 'utf-8' ) )
		data.append( 0x55 )
		self.serial_port.write( data )
		print_log( '<EDM AT Request> ' + message.strip() )
		return

class EnterEdmModeCommand( Command ):
	
	def execute( self ):
		self.serial_port.write( b'ATO2\r\n' )
		return

class AcquireDumpInfo( Command ):
	
	def execute( self ):
		self.serial_port.write( b'AT+UMDUMP\r\n' )
		return

class EdmSetConnectabilityCommand( Command ):
	
	def __init__( self, serial_port, connectability ):
		self.serial_port = serial_port
		self.connectability = connectability
		return
	
	def execute( self ):
		if ( self.connectability ):
			text = '2'
		else:
			text = '1'
		self.send_edm_at_request( 'AT+UBTCM=' + text + '\r\n' )
		return

class EdmGetPairedDeviceInfoCommand( Command ):
	
	def execute( self ):
		self.send_edm_at_request( 'AT+UBTBD=0\r\n' )
		return

class EdmConnectPeerCommand( Command ):
	
	def __init__( self, serial_port, bd_addr ):
		self.serial_port = serial_port
		self.bd_addr = bd_addr
		return
	
	def execute( self ):
		self.send_edm_at_request( 'AT+UDCP=spp://' + self.bd_addr + 'p\r\n' )
		return

#--------------------------------------------------
# event class
#--------------------------------------------------

class Event():
	
	class EVENT_TYPE:
		UNKNOWN = 0
		STARTUP = 1
		OK = 2
		EDM_START_EVENT = 3
		EDM_CONNECTED_EVENT = 4
		EDM_DISCONNECTED_EVENT = 5
		EDM_DATA_EVENT = 6
		EDM_AT_RESPONSE = 7
		EDM_AT_EVENT = 8
		TIMEOUT = 9
	
	def __init__( self ):
		return
	
	def get_event_type( self ):
		raise NotImplementedError

class TimeoutEvent( Event ):
	
	def get_event_type( self ):
		return Event.EVENT_TYPE.TIMEOUT

class StartupEvent( Event ):
	
	def get_event_type( self ):
		return Event.EVENT_TYPE.STARTUP

class OkEvent( Event ):
	
	def get_event_type( self ):
		return Event.EVENT_TYPE.OK

class EdmStartEvent( Event ):
	
	def get_event_type( self ):
		return Event.EVENT_TYPE.EDM_START_EVENT

class EdmConnectedEvent( Event ):
	
	def __init__( self, count, channel, bd_address, frame_size ):
		self.count = count
		self.channel = channel
		self.bd_address = bd_address
		self.frame_size = frame_size
		return
	
	def get_event_type( self ):
		return Event.EVENT_TYPE.EDM_CONNECTED_EVENT

class EdmDisconnectedEvent( Event ):
	
	def __init__( self, count, channel ):
		self.count = count
		self.channel = channel
		return
	
	def get_event_type( self ):
		return Event.EVENT_TYPE.EDM_DISCONNECTED_EVENT

class EdmDataEvent( Event ):
	
	def __init__( self, message ):
		self.message = message
		return

	def get_event_type( self ):
		return Event.EVENT_TYPE.EDM_DATA_EVENT

class EdmAtResponseEvent( Event ):
	
	def __init__( self, message ):
		self.message = message
		return
	
	def get_event_type( self ):
		return Event.EVENT_TYPE.EDM_AT_RESPONSE

class EdmAtEventEvent( Event ):
	
	def __init__( self, message ):
		self.message = message
		return
	
	def get_event_type( self ):
		return Event.EVENT_TYPE.EDM_AT_RESPONSE

class SendDataCommand( Command ):
	
	def __init__( self, serial_port, channel, data_size ):
		Command.__init__( self, serial_port )
		self.channel = channel
		self.data_size = data_size
	
	def execute( self ):
		payload_length = self.data_size + 3
		data = bytearray( [0xAA] )
		data.append( payload_length // 0x100 )
		data.append( payload_length % 0x100 )
		data.append( 0x00 )
		data.append( 0x36 )
		data.append( self.channel )
		if self.data_size >= 30:
			data.append( 0xFF )
			data.append( 0xFF )
			data.append( 0xF0 )
			data.append( 0xF0 )
			for i in range( 0, 24 ):
				data.append( data_value )
			data.append( 0x00 )
			data.append( 0x00 )
			for i in range( 0 , self.data_size - 30 ):
				data.append( data_value )
		else:
			for i in range( 0 , self.data_size ):
				data.append( data_value )
		data.append( 0x55 )
		self.serial_port.write( data )

#--------------------------------------------------
# receiver class
#--------------------------------------------------

class Receiver():
	
	class MODE:
		COMMAND_MODE = 0
		EXTENDED_DATA_MODE = 1
	
	class PARSE_STATE:
		START = 0
		PAYLOAD_LENGTH = 1
		PAYLOAD = 2
		STOP = 3
	
	def parse_payload( self, payload ):
		payload_type_msb = payload[0]
		payload_type_lsb = payload[1]
		if payload_type_msb == 0x00 and payload_type_lsb == 0x71:
			self.event_handler( EdmStartEvent() )
		elif payload_type_msb == 0x00 and payload_type_lsb == 0x11:
			self.edm_connect_count = self.edm_connect_count + 1
			channel = payload[2]
			bd_address = payload[5:11]
			frame_size = payload[11] * 0x100 + payload[12]
			self.event_handler( EdmConnectedEvent( self.edm_connect_count, channel, bd_address, frame_size ) )
		elif payload_type_msb == 0x00 and payload_type_lsb == 0x21:
			self.edm_disconnect_count = self.edm_disconnect_count + 1
			channel = payload[2]
			self.event_handler( EdmDisconnectedEvent( self.edm_disconnect_count, channel ) )
		elif payload_type_msb == 0x00 and payload_type_lsb == 0x31:
			message = binascii.hexlify(payload[2:]).decode('ascii')
			self.event_handler( EdmDataEvent(message) )
		elif payload_type_msb == 0x00 and payload_type_lsb == 0x45:
			message = payload[2:].decode( 'utf-8' ).strip()
			self.event_handler( EdmAtResponseEvent( message ) )
		elif payload_type_msb == 0x00 and payload_type_lsb == 0x41:
			message = payload[2:].decode( 'utf-8' ).strip()
			self.event_handler( EdmAtEventEvent( message ) )
		else:
			print_log( 'Unknown EDM Event...' )
		return
	
	def receive_process_in_command_mode( self ):
		try:
			received_data = serial_port.readline().decode( 'utf-8' ).strip()
			print_log( received_data )
			if received_data == '+STARTUP':
				self.event_handler( StartupEvent() )
			elif received_data == 'OK':
				self.event_handler( OkEvent() )
		except:
			pass
		
		return
	
	def receive_process_in_extended_data_mode( self ):
		if self.parse_state_in_edm == self.PARSE_STATE.START:
			read_data = self.serial_port.read( 1 )
			byte = read_data[0]
			if byte == 0xAA:
				self.parse_state_in_edm = self.PARSE_STATE.PAYLOAD_LENGTH
		elif self.parse_state_in_edm == self.PARSE_STATE.PAYLOAD_LENGTH:
			read_data = self.serial_port.read( 2 )
			self.payload_length = read_data[0] * 0x100 + read_data[1]
			self.parse_state_in_edm = self.PARSE_STATE.PAYLOAD
		elif self.parse_state_in_edm == self.PARSE_STATE.PAYLOAD:
			self.payload = self.serial_port.read( self.payload_length )
			self.parse_state_in_edm = self.PARSE_STATE.STOP
		elif self.parse_state_in_edm == self.PARSE_STATE.STOP:
			read_data = self.serial_port.read( 1 )
			byte = read_data[0]
			if byte == 0x55:
				self.parse_payload( self.payload )
			else:
				print_log( 'EDM Packet is invalid...' )
			self.parse_state_in_edm = self.PARSE_STATE.START
		else:
			print_log( 'EDM Packet is invalid...' )
			self.parse_state_in_edm = self.PARSE_STATE.START
		return
	
	def __init__( self, serial_port, event_handler ):
		self.mode = self.MODE.COMMAND_MODE
		self.serial_port = serial_port
		self.event_handler = event_handler
		self.parse_state_in_edm = self.PARSE_STATE.START
		self.edm_connect_count = 0
		self.edm_disconnect_count = 0
		self.thread = threading.Thread( target = self.run )
		self.thread.setDaemon( True )
		self.thread.start()
		return
	
	def run( self ):
#		print( '=== start receiver thread ===' )
		while 1:
			if self.mode == self.MODE.COMMAND_MODE:
				self.receive_process_in_command_mode()
			else:
				self.receive_process_in_extended_data_mode()
		return
	
	def set_mode( self, mode ):
		self.mode = mode
		return

#--------------------------------------------------
# sender class
#--------------------------------------------------

class Sender():
	
	class REQUEST_TYPE:
		SEND_MESSAGE = 0
		SEND_DATA = 1
	
	def __init__( self, serial_port ):
		self.serial_port = serial_port
		self.event = threading.Event()
		self.command_queue = queue.Queue()
		self.thread = threading.Thread( target = self.run )
		self.thread.setDaemon( True )
		self.thread.start()
		return
	
	def run( self ):
#		print( '=== start sender thread ===' )
		while 1:
			command = self.command_queue.get( True )
			command.execute()
		return
	
	def enter_edm_mode( self ):
		self.command_queue.put( EnterEdmModeCommand( self.serial_port ) )
		return
	
	def edm_set_connectability_mode( self, connectability ):
		self.command_queue.put( EdmSetConnectabilityCommand( self.serial_port, connectability ) )
		return
	
	def acquire_dump_info( self ):
		self.command_queue.put( AcquireDumpInfo( self.serial_port ) )
		return
	
	def edm_get_paired_device_info( self ):
		self.command_queue.put( EdmGetPairedDeviceInfoCommand( self.serial_port ) )
		return
	
	def edm_connect_peer( self, bd_addr ):
		self.command_queue.put( EdmConnectPeerCommand( self.serial_port, bd_addr ) )
		return
	
	def send_data( self, channel, data_size ):
		self.command_queue.put( SendDataCommand( self.serial_port, channel, data_size ) )
		return

#--------------------------------------------------
# interval timer class
#--------------------------------------------------

class IntervalTimer():
	
	def __init__( self, sender ):
		self.is_active = False
		self.sender = sender
		return;
	
	def interval_process( self ):
		if self.is_active == True:
			thread = threading.Timer( 0.03, self.interval_process )
			thread.setDaemon( True )
			thread.start()
		self.sender.send_data( self.channel, self.data_size )
		return
	
	def set_parameter( self, channel, data_size ):
		self.channel = channel
		self.data_size = data_size
		return
	
	def active( self ):
		self.is_active = True
		self.interval_process()
		return
	
	def inactive( self ):
		self.is_active = False
		return

#--------------------------------------------------
# controller class
#--------------------------------------------------

class Controller():
	
	def fire_timeout_event( self ):
		self.event_handler( TimeoutEvent() )
		return
	
	def state_connected( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.EDM_AT_RESPONSE:
			is_match = pattern_uudpd_event.match( event.message )
			if ( is_match ):
				self.sender.edm_set_connectability_mode( False )
				return self.state_wait_edm_disable_connectability_result
		elif event_type == Event.EVENT_TYPE.STARTUP:
			self.sender.acquire_dump_info()
		return self.state_connected
	
	def state_wait_edm_connected_from_remote_peer( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.TIMEOUT:
			self.sender.edm_set_connectability_mode( False )
			return self.state_wait_edm_disable_connectability_result
		elif event_type == Event.EVENT_TYPE.EDM_AT_RESPONSE:
			is_match = pattern_uudpc_event.match( event.message )
			if ( is_match ):
				self.timeout_thread.cancel()
				return self.state_connected
		elif event_type == Event.EVENT_TYPE.STARTUP:
			self.sender.acquire_dump_info()
		return self.state_wait_edm_connected_from_remote_peer
	
	def state_wait_edm_enable_connectability_result( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.EDM_AT_RESPONSE:
			is_match = pattern_ok_event.match( event.message )
			if ( is_match ):
				global interval_of_udcp
				self.timeout_thread = threading.Timer( interval_of_udcp, self.fire_timeout_event )
				self.timeout_thread.setDaemon( True )
				self.timeout_thread.start()
				return self.state_wait_edm_connected_from_remote_peer
		elif event_type == Event.EVENT_TYPE.STARTUP:
			self.sender.acquire_dump_info()
		return self.state_wait_edm_enable_connectability_result
	
	def state_wait_edm_connect_peer_result( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.EDM_AT_RESPONSE:
			for record in event.message.split( '\r\n' ):
				is_match_uudpd = pattern_uudpd_event.match( record )
				if ( is_match_uudpd ):
					self.sender.edm_set_connectability_mode( True )
					return self.state_wait_edm_enable_connectability_result
		elif event_type == Event.EVENT_TYPE.STARTUP:
			self.sender.acquire_dump_info()
		return self.state_wait_edm_connect_peer_result
	
	def state_wait_edm_disable_connectability_result( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.EDM_AT_RESPONSE:
			is_match = pattern_ok_event.match( event.message )
			if ( is_match ):
				self.sender.edm_connect_peer( self.bd_addr )
				return self.state_wait_edm_connect_peer_result
		return self.state_wait_edm_disable_connectability_result
	
	def state_wait_edm_get_paired_device_info_result( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.EDM_AT_RESPONSE:
			is_match = pattern_ubtbd_event.match( event.message )
			if ( is_match ):
				self.bd_addr = is_match.group( 1 )
				self.sender.edm_set_connectability_mode( False )
				return self.state_wait_edm_disable_connectability_result
			else:
				time.sleep( 1 )
				self.sender.edm_get_paired_device_info()
		return self.state_wait_edm_get_paired_device_info_result
	
	def state_wait_edm_mode_start_event( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.EDM_START_EVENT:
			self.sender.edm_get_paired_device_info()
			return self.state_wait_edm_get_paired_device_info_result
		return self.state_wait_edm_mode_start_event
	
	def state_wait_enter_edm_mode_result( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.OK:
			self.receiver.set_mode( Receiver.MODE.EXTENDED_DATA_MODE )
			return self.state_wait_edm_mode_start_event
		return self.state_wait_enter_edm_mode_result
	
	def state_wait_startup( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.STARTUP:
			self.sender.enter_edm_mode()
			return self.state_wait_enter_edm_mode_result
		return self.state_wait_startup
	
	def event_process( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.EDM_CONNECTED_EVENT:
			self.interval_timer.set_parameter( event.channel, 30 )
			self.interval_timer.active()
			self.connected_channel = event.channel
			self.connected_status = True
		elif event_type == Event.EVENT_TYPE.EDM_DISCONNECTED_EVENT:
			if ( event.channel == self.connected_channel ):
				self.interval_timer.inactive()
				self.connected_channel = 0
				self.connected_status = False
		return
	
	def print_event_log( self, event ):
		event_type = event.get_event_type()
		if event_type == Event.EVENT_TYPE.STARTUP:
			pass
		elif event_type == Event.EVENT_TYPE.OK:
			pass
		elif event_type == Event.EVENT_TYPE.EDM_START_EVENT:
			print_log( '<EDM Start Event>' )
		elif event_type == Event.EVENT_TYPE.EDM_CONNECTED_EVENT:
			self.edm_connect_count = next( self.count_generator )
			log_text = '<EDM Connect Event>    count : '
			log_text += str( self.edm_connect_count )
			log_text += ', CH : '
			log_text += str( event.channel )
			log_text += ', BD_ADDR : '
			log_text += hex( event.bd_address[0] ).lstrip('0x').upper().zfill(2) + '-'
			log_text += hex( event.bd_address[1] ).lstrip('0x').upper().zfill(2) + '-'
			log_text += hex( event.bd_address[2] ).lstrip('0x').upper().zfill(2) + '-'
			log_text += hex( event.bd_address[3] ).lstrip('0x').upper().zfill(2) + '-'
			log_text += hex( event.bd_address[4] ).lstrip('0x').upper().zfill(2) + '-'
			log_text += hex( event.bd_address[5] ).lstrip('0x').upper().zfill(2)
			log_text += ', FS : ' + str( event.frame_size )
			print_log( log_text )
		elif event_type == Event.EVENT_TYPE.EDM_DISCONNECTED_EVENT:
			log_text = '<EDM Disconnect Event> count : '
			log_text += str( self.edm_connect_count )
			log_text += ', CH : '
			log_text += str( event.channel )
			print_log( log_text )
		elif event_type == Event.EVENT_TYPE.EDM_DATA_EVENT:
			print_log( '<EDM Data Event>' + event.message )
		elif event_type == Event.EVENT_TYPE.EDM_AT_RESPONSE:
			string = event.message.replace( '\r', '<CR>' )
			string = string.replace( '\n', '<LF>' )
			print_log( '<EDM AT Response> ' + string )
		elif event_type == Event.EVENT_TYPE.EDM_AT_EVENT:
			print_log( '<EDM AT Event> ' + event.message )
		return
	
	def event_handler( self, event ):
		self.print_event_log( event )
		self.event_process( event )
		self.state_func = self.state_func( event )
		return
	
	def __init__( self, serial_port ):
		self.serial_port = serial_port
		self.edm_connect_count = 0
		self.count_generator = count_generator()
		self.state_func = self.state_wait_startup
		self.connected_channel = 0
		self.connected_status = False
		self.thread = threading.Thread( target = self.run )
		self.thread.setDaemon( True )
		self.thread.start()
		return
	
	def run( self ):
		# print( '=== start controller thread ===' )
		print( '*** TEST START [', time.strftime( '%X %x' ), '] ***' )
		global data_value
		global start_time
		start_time = time.time()
		self.sender = Sender( self.serial_port )
		self.receiver = Receiver( self.serial_port, self.event_handler )
		self.interval_timer = IntervalTimer( self.sender )
		while 1:
			time.sleep( 1 )
			data_value = ( data_value + 1 ) % 0x0100
			if self.serial_port.dsr is False:
				self.interval_timer.inactive()
				self.receiver.set_mode( Receiver.MODE.COMMAND_MODE )
		return

#==================================================
# main routine
#==================================================

# prepare command line argument parser
arg_parser = argparse.ArgumentParser( description = 'test for auto connection' )
arg_parser.add_argument( 'comm_port' )
arg_parser.add_argument(
	'-i',
	type = int,
	nargs = 1,
	default = [5],
	help = 'Interval of UDCP'
)
args = arg_parser.parse_args()

# get input parameters
comm_port = args.comm_port
interval_of_udcp = args.i[0]

# print parameters
print( 'Port             : ', comm_port )
print( 'Interval of UDCP : ', interval_of_udcp )
print( '' )

# open port
serial_port = serial.Serial(
	port = comm_port,
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

# run threads
controller = Controller( serial_port )

try:
	while 1:
		key = input().strip()
		if key == 'AT':
			controller.sender.edm_at()
			
except KeyboardInterrupt:
	pass
