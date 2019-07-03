import paho.mqtt.client as mqtt
import time
from datetime import datetime

# The callback for when the client receives a CONNACK response from the server.
def on_connect(client, userdata, rc):
    print("Connected with result code "+str(rc))
    # Subscribing in on_connect() means that if we lose the connection and
    # reconnect then subscriptions will be renewed.
    client.subscribe("try-me")

# The callback for when a PUBLISH message is received from the server.
def on_message(client, userdata, msg):
    print("Message received. Topic: " + msg.topic+" "+str(msg.payload))

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message

#client.username_pw_set(username="solace-cloud-client",password="")
client.connect("192.168.1.36", 1883, 60)


# Avoiding block to custmize publishing
client.loop_start()    
time.sleep(1)
count=1
while count < 100:
    client.publish("try-me", "message {} at {}".format(count,datetime.now()))
    count = count+1
    time.sleep(0.5)
client.loop_stop()