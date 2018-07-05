# <html><body>
# <h1>You need to update your python script settings!</h1>        <br />
# <h4>If you're seeing this page in the web browser then you      <br />
# need to configure the following variables in the python script: <br /><br />

# Change this variable to point to your webpage files directory   <br />
ROOT_SERVER_PATH = '.'                                           #<br /><br />

# This should be the default webpage (i.e. index.html)           <br />
#ROOT_INDEX = 'serial_http_server.py'
ROOT_INDEX = 'index.html'

# <br /><br /><br /><br /></h4></body></html>

SOFTAP_SSID = "HTTP Server Demo"
SOFTAP_PASSWORD = "password"
HTTP_URL = "demo.com"



import sys
try:
    import serial
except Exception as e:
    print "Failed to import 'serial' python module"
    print "This may be installed with the command: 'pip install serial'"
    print "It may also be found here: https://pypi.python.org/pypi/pyserial"
    sys.exit(1)
    
import time
import os
import random, sys



MAX_READ_LENGTH  = 65000

STATUS_NO_DATA = 0
STATUS_DATA = 1
STATUS_CLOSED = 2

HTTP_HEADER     = "HTTP/1.1 200 OK\r\n"+\
                  "Server: SerialHTTP\r\n" +\
                  "Date: Wed, 29 Jul 2015 15:02:26 GMT\r\n" +\
                  "Content-Type: %s\r\n" +\
                  "Connection: Close\r\n" +\
                  "Content-Length: %d\r\n\r\n"
              
HTTP_NOT_FOUND  = "<html>\r\n"+\
                  "<body>\r\n"+\
                  "<h1>File not found. Error 404</h1>\r\n"+\
                  "</body>\r\n"+\
                  "</html>"

                  
if len(sys.argv) != 2:
    print "Must specify the serial COM port"
    print "ex: python serial_http_server.py COM35"
    sys.exit(1)

print "Opening serial port: %s" % sys.argv[1]
try:
    s = serial.Serial(sys.argv[1], baudrate=115200, rtscts=False , timeout=0.1, writeTimeout=10)
except Exception as e:
    raise Exception("Failed to open serial port: %s. Is the module using that serial port? Is the port opened by another program?" % sys.argv[1])


from BaseHTTPServer import BaseHTTPRequestHandler
from StringIO import StringIO


''' ******************************************************************************************* '''
class HTTPRequest(BaseHTTPRequestHandler):
    def __init__(self, request_text):
        self.rfile = StringIO(request_text)
        self.raw_requestline = self.rfile.readline()
        self.error_code = self.error_message = None
        self.parse_request()

    def send_error(self, code, message):
        self.error_code = code
        self.error_message = message


''' ******************************************************************************************* '''
def getCmdResponse(printRes=True):
    global s
    header = ""
    while True:
        while len(header) == 0 or (header[0] != 'R' and header[0] != 'L'):
            header = s.readline().strip()
            if len(header) > 0 and (ord(header[0]) > 126 or ord(header[0]) < 32):
                header = header[1:]
            if '[Ready]' in header:
                return None
        if printRes:
            print "<- %s" % header
        statusCode = header[1]
        l = int(header[2:])
        if l > 0:
            data = s.read(l)
            if printRes or statusCode != '0':
                print "<- %s" % data
            if header[0] == 'R' :
                if statusCode == '0':
                    return data[:-2]
                else:
                    #raise Exception("Command failed %s" % statusCode)
                    print "Command failed"
                    return ""
            else:
                header = ""
        else:
            return None
            

''' ******************************************************************************************* '''
def sendCommand(cmd, printRes=True, printCmd=True):
    global s
    if printCmd:
        print "-> %s" % cmd
    s.write(cmd + "\r\n")

    return getCmdResponse(printRes)


''' ******************************************************************************************* '''
def sendHttpResponse(clientId, fname):
    global s
    
    if fname == '/':
        fname = ROOT_INDEX

    fname = os.path.join(ROOT_SERVER_PATH, fname)
    
    if(os.path.isfile(fname)):
        file = open(fname, 'r+b')
        size = os.stat(fname).st_size
        
        if fname.endswith('.png'):
            contentType = 'image/png'
        elif fname.endswith('.ico'):
            contentType = 'image/icon'
        elif fname.endswith('.txt'):
            contentType = 'text/plain'
        else:
            contentType = 'text/html; charset=UTF-8'
            
        header = HTTP_HEADER % (contentType, size)

        # prepare http response and send to client
        cmd = "stream_write %d %d" % (clientId, len(header) + size)
        print "-> %s" % cmd
        s.write(cmd + "\r\n")
        
        # write http response data to client 
        s.write(header)
        readSize = 0
        while readSize < size:
            chunk = file.read(min(128, size- readSize))
            readSize = readSize + len(chunk)
            #print "Total read size = %d " % readSize
            if chunk:
               #print "Writing chunk of %d bytes" % len(chunk)
               s.write(chunk)
               time.sleep(0.05);
            else:
                break

        getCmdResponse(False)
        print  "Response sent to client %d" %clientId

    else:
        print "*****************************"
        print "FILE NOT FOUND: %s" % fname
        print "*****************************"
        # prepare http response (404) and send to client
        header = HTTP_HEADER % ('text/html', len(HTTP_NOT_FOUND))
        cmd = "stream_write %d %d" % (clientId, len(header) + len(HTTP_NOT_FOUND))
        print "-> %s" % cmd
        s.write(cmd + "\r\n")
        
        s.write(header)
        # write http response (404) data to client 
        s.write(HTTP_NOT_FOUND)
        getCmdResponse(False)
        print  "Response (404) sent to client %d" %clientId
        
        

''' ******************************************************************************************* '''
# --------------------- MAIN -------------------------
try:
    clientList = {}
    
    # set machine mode of the module
    sendCommand("set system.cmd.mode machine")
    sendCommand("set system.print_level all")
    sendCommand("set bus.log_bus uart0")
    sendCommand("set network.buffer.size 25000")
    sendCommand("set network.buffer.rxtx_ratio 50")
    sendCommand("set bus.command.rx_bufsize 2048")
    sendCommand("set tcp.keepalive.enabled 0")
    sendCommand("set tcp.keepalive.initial_timeout 7")
    sendCommand("set tcp.keepalive.retry_count 3")
    sendCommand("set tcp.keepalive.retry_timeout 3")
    sendCommand("set tcp.server.auto_start 1")
    sendCommand("set tcp.server.auto_interface softap")
    sendCommand("set tcp.server.port 80")
    sendCommand("set tcp.server.idle_timeout 30")
    sendCommand("set tcp.server.max_clients 4")
    sendCommand("set softap.auto_start 1")
    sendCommand("set softap.ssid \"%s\"" % SOFTAP_SSID)
    sendCommand("set softap.passkey \"%s\"" % SOFTAP_PASSWORD)
    #sendCommand("set softap.url %s,www.%s" % (HTTP_URL, HTTP_URL)) # renamed in ZentriOS 3.0
    sendCommand("set softap.dns_server.url %s,www.%s" % (HTTP_URL, HTTP_URL))    
    sendCommand("set stream.auto_close 0")
    sendCommand("save")
    sendCommand("get all")    
    sendCommand("reboot")
    time.sleep(3)
    

    print "Serial HTTP Server Ready ..."
    print "Connect your computer to the Wi-Fi network: %s" % SOFTAP_SSID
    print "Wi-Fi password is: %s" % SOFTAP_PASSWORD
    print "Once connected, open a browser and enter: %s" % HTTP_URL
    print "This will display your webpages ..."
    
    while(True):
        # poll all the connections for their current status
        # NOTE: this makes the assumption that all connections
        #       are TCP server connections
        poll = sendCommand('poll all', False, False)
        
        # if there are no open connections then just sleep for a bit
        # and try again later
        if poll == 'None' or poll.find(',') == -1:
            time.sleep(1)
            continue
            
        # split the poll into entries
        connList = []
        for x in poll.split('|'):
            x = x.split(',')
            connList.append({'handle' : int(x[0]), 'status' : int(x[1])})
            
        # for each connection in the polled list
        for conn in connList:
            # has the client closed the connection?
            if conn['status'] == STATUS_CLOSED:
                # yes, so close the connection
                print "Client status closed, closing: %d" % conn['handle']
                sendCommand('close %d' % conn['handle'])
                # remove from list (if necessary)
                if conn['handle'] in clientList:
                    del clientList[conn['handle']]
                # continue to next connection
                continue
            
            # is this client in our list?
            if not conn['handle'] in clientList:
                # no, add it now
                clientList[conn['handle']] = ''
                
            # has the client's response already been sent?
            # if so have we wait long enough for it to recieve the response?
            if isinstance(clientList[conn['handle']], float):
                if time.time() - clientList[conn['handle']] > 20.0:
                    # yes, so force the connection closed
                    print "Forcing client connection closed: %d" % conn['handle']
                    del clientList[conn['handle']]
                    sendCommand('close %d' % conn['handle'])
                    continue
    
            # does the client have data?
            if conn['status'] != STATUS_DATA:
                # no, continue to next connection
                continue 
            
            # yes, so read it now
            data = sendCommand('read %d %d' % (conn['handle'], MAX_READ_LENGTH), False)
            if data != None:
                # buffer the HTTP request data
                clientList[conn['handle']] += data
                
            # Have we received \r\n\r\n ? 
            # If so then the client sent a full HTTP request
            if clientList[conn['handle']].find('\r\n\r\n') == -1:
                # no, haven't received full request yet, continue to next client
                continue

            # parse the client request
            requestData = clientList[conn['handle']]
            request = HTTPRequest(requestData)
            
            # check if this is a GET request to send response
            if(request.command.lower() == "get"):
                print "----------------------------"
                print "Request Cmd: %s" % request.command
                print "----------------------------"
                print "Request Pth: %s" % request.path
                print "----------------------------"
                print "Request Str: %s" % requestData.strip()
                print "----------------------------"
                
                sendHttpResponse(conn['handle'], request.path)
                
                # wait a bit and close the connection if the client doesn't
                clientList[conn['handle']] = time.time()
                
except Exception as e:
    print "Exception: %s" % e
    raise
finally:
    s.close()
    
print "Finished"