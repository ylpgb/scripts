#!/usr/bin/python3

import socket
from http.server import BaseHTTPRequestHandler, HTTPServer
import time
import sys

hostName = "192.168.2.151"
hostPort = 9001

class MyServer(BaseHTTPRequestHandler):

   #    GET is for clients geting the predi
   def do_GET(self):
      self.send_response(200)
      self.end_headers()
      self.wfile.write(bytes("<p>You accessed path: %s</p>\n" % self.path, "utf-8"))

   #    POST is for submitting data.
   def do_POST(self):
      print( "==> incomming http: ", self.path )
      print("headers: ", self.headers)
      content_length = int(self.headers['Content-Length']) # <--- Gets the size of data
      post_data = self.rfile.read(content_length) # <--- Gets the data itself
      # rfile need to be closed. Else client will complain transfer closed with outstanding read data remaining.
      self.rfile.close()
      print("post_data: ", post_data, ".")
      self.protocol_version = "HTTP/1.1"
      self.send_response(200, message="OK")
      self.send_header('Content-Length', '0')
      self.end_headers()

myServer = HTTPServer((hostName, hostPort), MyServer)
print(time.asctime(), "Server Starts - %s:%s" % (hostName, hostPort))

try:
   myServer.serve_forever()
except KeyboardInterrupt:
   pass

myServer.server_close()
print(time.asctime(), "Server Stops - %s:%s" % (hostName, hostPort))
