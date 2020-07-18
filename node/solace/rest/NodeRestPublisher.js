// keepAlive true will reuse the same TCP connection. Note that it is different from "connection: keep-alive". 
// For Solace REST, connection is always keep-alive regarldess of "connection" header in request.
// Also note that if there is no delay betweeo post requests, even keepAlive is set to false, same TCP connection will be used. 
// This may be due to that the next request is sent before connection is closed,
// 
// maxSockets specifies the maximum number of TCP connections to be used. 
// More TCP connections is required for higher publishing message rate.
// If maxSockets is omited, default is Infinity. 

var http = require('http');
var keepAliveAgent = new http.Agent({ keepAlive: true, maxSockets: 1 });
//var keepAliveAgent = new http.Agent({ keepAlive: false, maxSockets: 1 });
//var keepAliveAgent = new http.Agent({ keepAlive: true, maxSockets: 90 });

var userString = "Hello World JavaScript";
 
var username = 'default';
var password = 'default';

var msgCount = 10;
var postDelayinMs = 100;

function sendPost() {
	var headers = {
	  'Content-Type': 'text/plain',
	  'Authorization': 'Basic ' + Buffer.from(username + ":" + password).toString("base64"),
	  'Content-Length': userString.length,
	  'Connection': 'close'
	  //'Connection': 'keep-alive'
	  //'Solace-Client-Name': 'NodeRestPublisher',
	  //'Solace-Client-Description': 'NodeRestPublisherDescription'
	};
	 
	var options = {
	  host: '192.168.40.230',
	  port: 9000,
	  path: '/T/rest/pubsub',
	  method: 'POST',
	  agent: keepAliveAgent,
	  headers: headers
	};
	 
	 
	// Setup the request.  The options parameter is
	// the object we defined above.
	var req = http.request(options, function(res) {
	  console.log('STATUS: ' + res.statusCode);
	  console.log('HEADERS: ' + JSON.stringify(res.headers));
	  res.setEncoding('utf8');
	  res.on('data', function (chunk) {
	    console.log('BODY: ' + chunk);
	  });
	});
	 
	req.on('error', function(e) {
	  console.log('problem with request: ' + e.message);
	});
	 
	req.write(userString);
	req.end();
}

function batchPost() {
  for (var i=0; i<msgCount; i++) {
    sendPost();
  }
}

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function delayedBatchPost() {
  for(var i=0; i<msgCount; i++) {
    sendPost();
    await sleep(postDelayinMs);
  }
}

delayedBatchPost();
//batchPost();
