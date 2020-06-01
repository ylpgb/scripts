#!/bin/bash

# It requires SOlOS version 9.3. The command has to be run over HTTPS.
curl -u admin:admin -H "Content-Type: application/json" -X PATCH -k -d@server.json https://192.168.133.15:1943/SEMP/v2/config/
