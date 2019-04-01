#!/usr/bin/env python

import socket
import sys

try: 
  s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  print ("Socket successfully created")
except socket.error as err:
  print ("Socket creation failed with error ", err)

port = 8080

try:
  host_ip = socket.gethostbyname("b202-thingsboard.ddns.net")
except socket.gaierror:
  print ("There was an error resolving the host")
  sys.exit()

s.connect((host_ip, port))

print ("The socket has successfully connected to ", host_ip)

message = "POST /api/v1/00000000000000000000/telemetry HTTP/1.1\r\nHost: b202-thingsboard.ddns.net:8080\r\nContent-Type: application/json\r\nContent-Length: "

payload = '{"lat":47.2850880,"long":8.5657170,"fix":0,"temperature":20.37}'

message += str(len(payload)) + "\r\n\r\n" + payload


print(message)

s.send(message.encode('utf-8'))
