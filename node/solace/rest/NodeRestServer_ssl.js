var https = require('https');
var fs = require('fs');

var RC_HOST = '192.168.40.238';
var RC_PORT = 9009;

var options = {
    key: fs.readFileSync('../../../python/solace/rest/server.key'),
    cert: fs.readFileSync('../../../python/solace/rest/server.crt'),
    passphrase: 'solace1'
};

https.createServer(options, function (req, res) {
	var body = "";
	req.on('data', (chunk) => {
		body += chunk.toString();
	}).on('end', () => {
		console.log('Received message: ' + body + " at url " + req.url);
	});
	
    res.writeHead(200);
    res.write("Server is working");
    res.end();
}).listen(RC_PORT, RC_HOST);
console.log('Server running at http://'+RC_HOST+':'+RC_PORT+'/');
