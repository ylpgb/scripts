var https = require('https');
const fs  = require('fs');
 
var userString = "Hello World JavaScript";
username = 'client2';
password = 'client2';

var headers = {
  'Content-Type': 'text/plain',
  'Authorization': 'Basic ' + new Buffer(username + ":" + password).toString("base64"),
  'Content-Length': userString.length
};
 
var options = {
  host: '192.168.40.245',
  port: 9443,
  path: '/T/rest/pubsub',
  method: 'POST',
  // Uncomment key and cert to enable two-way SSL authentication 
  key: fs.readFileSync('certs2/client1.pem'),
  cert: fs.readFileSync('certs2/client1.crt'),
  ca: fs.readFileSync('certs2/MyRootCaCert.pem'),
  headers: headers,
  checkServerIdentity: (servername, crt) => {
    if(servername !== crt.subject.CN) {
      //throw new Error(`Servername ${servername} does not match CN ${crt.subject.CN}`);
      console.log(`WARN: Servername ${servername} does not match CN ${crt.subject.CN}`);
    }
  }
};
 
 
// Setup the request.  The options parameter is
// the object we defined above.
var req = https.request(options, function(res) {
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
