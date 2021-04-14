#!/bin/bash

[[ $# < 1 ]] && { echo "Usage: $0 ipport"; echo "ipport is the IP:PORT of the client to find, e.g. 10.9.0.7:51457";  exit 1; }

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=192.168.40.13:80
IPPORT=$1

curl -s -o tmp.txt -d'
<rpc>
    <show>
        <client>
            <name>*</name>
            <connections></connections>
        </client>
    </show>
</rpc>
' -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://$BROKER_SEMP_URL/SEMP

clientName=`sed -n '/name/h;/'$IPPORT'/!d;x;/name/p;q' tmp.txt | cut -d'>' -f2 | cut -d'<' -f1` 
echo $clientName
