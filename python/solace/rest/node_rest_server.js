var http = require('http');

http.createServer(function (req, res) {
    console.log(req.method, req.url, req.headers);
    let body = '';
    req.on('data', (chunk) => {
        body += chunk;
    });
    req.on('end', () => {
        console.log("body: ", body);
        res.writeHead(200);
        res.end();
    });
}).listen(9001, '192.168.2.151');
console.log('Server running at http://192.168.2.151:9001/');
