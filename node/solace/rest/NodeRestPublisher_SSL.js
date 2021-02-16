var https = require('https');
const fs  = require('fs');
 
var userString = "Hello World JavaScript";
username = 'client100';
password = 'client100';

var msgCount = 50000;
var postDelayinMs = 100;

//var keepAliveAgent = new https.Agent({ keepAlive: true, maxSockets: 1 });
//var keepAliveAgent = new https.Agent({ keepAlive: false, maxSockets: 1 });
var keepAliveAgent = new https.Agent({ keepAlive: true, maxSockets: 90 });


function sendPost() {
   var headers = {
     'Content-Type': 'text/plain',
     'Authorization': 'Basic ' + new Buffer(username + ":" + password).toString("base64"),
     'Content-Length': userString.length
   };
    
   var options = {
     host: 'mr1oqbbo5q9o6t.messaging.solace.cloud',
     port: 9443,
     path: '/T/rest/pubsub',
     agent: keepAliveAgent,
     method: 'POST',
     // Uncomment key and cert to enable two-way SSL authentication 
     key: fs.readFileSync('certs2/client1.pem'),
     cert: fs.readFileSync('certs2/client1.crt'),
     ca: fs.readFileSync('certs2/DigiCert_Global_Root_CA.pem'),
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
