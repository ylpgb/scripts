import sys
import serial
import time
import os
import random, sys

ROOT_SERVER_PATH = r'.'
ROOT_INDEX = 'index.html'
SOFTAP_SSID = "UBXWifi"
SOFTAP_PASSWORD = "topsecret"
HTTP_URL = "http://192.168.2.1:8080/setup.html"

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

HTTP_CREDENTIAL = "<html>\r\n"+\
                  "<body>\r\n"+\
                  "Credential recorded for <h1>SSID: %s</h1>\r\n"+\
                  "</body>\r\n"+\
                  "</html>"

SSID_QUERY_KEY = "SSID"
PASSWORD_QUERY_KEY = "psw"
                  
if len(sys.argv) != 2:
    print "Must specify the serial COM port"
    print "ex: python serial_http_server.py COM30"
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
def atCommand(command):
    try:
        s.write(command)
        time.sleep(.050)
        cmdComplete=False
        if(command == "+++"):
            return
        
        while(cmdComplete==False):
            while(s.inWaiting()):
                result = s.read(s.inWaiting())
                print result
                if( (result.find('OK')!=-1) or (result.find('ERROR')!=-1)):
                    cmdComplete=True
                else:
                    # prevent MCU hogging
                    time.sleep(0.05)
            # prevent MCU hogging
            time.sleep(0.05)
        #while(s.inWaiting()):
        #    result = s.read(s.inWaiting())
        #    print result
            
    except Exception, e:
        print "Exception for AT comand. Type is:",e.__class__.__name__

def commandMode():
    time.sleep(1)
    atCommand("+++")
    time.sleep(1)

def dataMode():
    atCommand("ATO1\r\n")

def factoryReset():
    atCommand("AT+UFACTORY\r\n")
    atCommand("AT+CPWROFF\r\n")
    time.sleep(3)

def setupAP():
    commandMode()
    factoryReset()
    atCommand("AT+UDSC=1,1,8080,0\r\n")
    atCommand("AT+UMSM=1\r\n")
    atCommand("AT&D0\r\n")
    atCommand("AT+UWAPC=0,16,0\r\n")  #disable hidden SSID
    atCommand("AT+UWAPC=0,0,1\r\n")
    atCommand("AT+UWAPC=0,2," + SOFTAP_SSID + "\r\n")
    atCommand("AT+UWAPC=0,4,6\r\n")
    atCommand("AT+UWAPC=0,5,3,2\r\n")
    atCommand("AT+UWAPC=0,8," + SOFTAP_PASSWORD + "\r\n")
    atCommand("AT+UWAPC=0,14,0\r\n")
    atCommand("AT+UWAPC=0,100,1\r\n")
    atCommand("AT+UWAPC=0,101,192.168.2.1\r\n")
    atCommand("AT+UWAPC=0,102,255.255.255.0\r\n")
    atCommand("AT+UWAPC=0,103,192.168.2.1\r\n")
    atCommand("AT+UWAPC=0,104,8.8.8.8\r\n")
    atCommand("AT+UWAPC=0,107,0\r\n")
    atCommand("AT+UWAPC=0,106,1\r\n")
    atCommand("AT+UWAPCA=0,3\r\n")
    dataMode()

def connectToAP(SSID,pwd):
    commandMode()
    atCommand("AT+UWAPCA=0,4\r\n")
    # Deactiving AP while there are active STAs will cause the module unable to function as STA.
    # WA: Deactive AP, Active it and deactive it again.
    time.sleep(1)
    atCommand("AT+UWAPCA=0,3\r\n")
    atCommand("AT+UWAPCA=0,4\r\n")
    time.sleep(1)
    atCommand("AT+UWSC=0,0,0\r\n")
    atCommand("AT+UWSC=0,2," + SSID + "\r\n");
    atCommand("AT+UWSC=0,5,2\r\n")
    atCommand("AT+UWSC=0,8," + pwd + "\r\n")
    atCommand("AT+UWSC=0,100,2\r\n")
    atCommand("AT+UWSC=0,107,0\r\n")
    atCommand("AT+UWSC=0,300,0\r\n")
    atCommand("AT+UWSC=0,301,1\r\n")
    atCommand("AT+UWSCA=0,3\r\n")
    time.sleep(20)
    atCommand("AT+UNSTAT\r\n")
    atCommand("AT+UWSSTAT\r\n")
    dataMode()

def checkNetworkStatus():
    commandMode()
    time.sleep(5)
    atCommand("AT+UNSTAT\r\n")
    dataMode()
    
''' ******************************************************************************************* '''
def extractPostContent(message):
    try:
        #request = HTTPRequest(message)
        startPos = message.find('\r\n\r\n')+4
        endPos = len(message)
        content = message[startPos:endPos]
        return content
    except Exception:
        print "Unable to extract content from post message"


''' ******************************************************************************************* '''
def queryExtract(query, key):
    try:
        tokens = query.split('&')
        for i in range(len(tokens)):
            if tokens[i].find(key)!= -1:
                keyVal = tokens[i][len(key)+1:len(tokens[i])]
                return keyVal
    except Exception:
        print "Unable to extract key " + key



''' ******************************************************************************************* '''
def sendHttpResponse(clientId, fname):
    global s
    
    if (fname == '/') or (fname == '') :
        fname = ROOT_INDEX

    fname = os.path.join(ROOT_SERVER_PATH, fname)
    print ">>> Leipo: fname: " + fname + "..."
    
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

        
        # write http response data to client 
        s.write(header)
        readSize = 0
        while readSize < size:
            chunk = file.read(min(128, size- readSize))
            readSize = readSize + len(chunk)
            if chunk:
               s.write(chunk)
               time.sleep(0.05);
            else:
                break

        print  "Response sent to client %d" %clientId

    else:
        print "*****************************"
        print "FILE NOT FOUND: %s" % fname
        print "*****************************"
        # prepare http response (404) and send to client
        header = HTTP_HEADER % ('text/html', len(HTTP_NOT_FOUND))
        
        s.write(header)
        # write http response (404) data to client 
        s.write(HTTP_NOT_FOUND)
        print  "Response (404) sent to client %d" %clientId


''' ******************************************************************************************* '''
def processHttpPost(clientId, message):
    global s
    content = extractPostContent(message)
    print ("Leipo: content ", content)
    SSID=str(queryExtract(content, SSID_QUERY_KEY))
    password=str(queryExtract(content, PASSWORD_QUERY_KEY))
    
    responseMsg = HTTP_CREDENTIAL % SSID
    
    # prepare http response and send to client
    header = HTTP_HEADER % ('text/html', len(responseMsg))
    
    s.write(header)
    # write http response data to client 
    s.write(responseMsg)
    print  "Post Response sent to client %d" %clientId
    time.sleep(1)
    connectToAP(SSID,password)
    

''' ******************************************************************************************* '''
# --------------------- MAIN -------------------------
try:
    
    # set machine mode of the module
    setupAP()

    print "Serial HTTP Server Ready ..."
    print "Connect your computer to the Wi-Fi network: %s" % SOFTAP_SSID
    print "Wi-Fi password is: %s" % SOFTAP_PASSWORD
    print "Once connected, open a browser and enter: %s" % HTTP_URL
    print "This will display your webpages ..."
    
    while(True):
            # parse the client request
            requestData = ""
            buffer = ""
            while(s.inWaiting()):
                buffer = s.read(s.inWaiting())
                requestData += buffer
            request = HTTPRequest(requestData)
            if(str(request.command).lower() == "get"):
                print "----------------------------"
                print "Request Cmd: %s" % request.command
                print "----------------------------"
                print "Request Pth: %s" % request.path
                print "----------------------------"
                print "Request Str: %s" % requestData.strip()
                print "----------------------------"
                sendHttpResponse(0, request.path.lstrip('/'))
                
            if(str(request.command).lower() == "post"):
                print "----------------------------"
                print "Request Cmd: %s" % request.command
                print "----------------------------"
                print "Request Pth: %s" % request.path
                print "----------------------------"
                print "Request Str: %s" % requestData
                print "----------------------------"
                processHttpPost(0,requestData)
            
            time.sleep(0.2)
            
except Exception as e:
    print "Exception: %s" % e
    raise
finally:
    s.close()
    
print "Finished"