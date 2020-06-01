var http = require('http');
 
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
  port: 9000,
  path: '/T/rest/pubsub',
  method: 'POST',
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
