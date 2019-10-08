#!/usr/local/bin/python3
import paho.mqtt.client as mqtt
import time
from datetime import datetime
import argparse

arg_parser = argparse.ArgumentParser( description = 'Subscribe to a broker' )
arg_parser.add_argument( '-ip', required=True, type=str, help='broker ip' )
arg_parser.add_argument( '-p', default=1883, type=int, help='broker port' )
args = arg_parser.parse_args()

# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, flags, rc):
    print("Connected to " + args.ip + ":" + str(args.p) + " with result code "+str(rc))
    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("#", qos=1)

# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    print("Topic: " + msg.topic + ". Message: " + str(msg.payload) + ". QoS: " + str(msg.qos))

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

client.connect(args.ip, args.p, 60)

print("Starting loop...")
# Avoiding block to custmize publishing
client.loop_start()    
time.sleep(1)
count=1
while count < 100:
    print("Send message ", count)
    client.publish("try-me1", "message {} at {}".format(count,datetime.now()), qos=0, retain=True)
    count = count+1
    time.sleep(0.5)
client.loop_stop()
