#!/usr/bin/python3

from flask import Flask, request
import os

hostName = "192.168.40.238"
hostPort = 9009

ASSETS_DIR = os.path.dirname(os.path.abspath(__file__))
app = Flask(__name__)


@app.route('/')
def index():
    return 'Flask is running!'


@app.route('/<path:text>', methods=['GET', 'POST'])
def all_routes(text):
    print("==> incoming http " + request.method + " request at " + request.path)
    if request.method == 'GET':
        return ("GET OK")
    elif request.method == 'POST':
        print("Post data: ", request.data)
        return ("POST OK")
    else:
        print("Unhandled request type")

if __name__ == '__main__':
    context = ('server.crt', 'server.key')#certificate and key files
    app.run(debug=False, ssl_context=context, host=hostName, port=hostPort)



