#!/bin/bash

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=192.168.40.11:80
#BROKER_SEMP_URL=cloud.ylpsingapore.com:8080
MESSAGE_VPN=default

curl -d"<rpc><hardware>
        <message-spool>
            <shutdown></shutdown></message-spool></hardware></rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.7:8080/SEMP

curl -d"<rpc>
        <service>
        <msg-backbone>
            <shutdown></shutdown>
        </msg-backbone>
    </service>
</rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.7:8080/SEMP

curl -d"<rpc>
    <redundancy>
        <shutdown></shutdown>
    </redundancy>
</rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.7:8080/SEMP

curl -d"<rpc>
    <redundancy>
        <shutdown></shutdown>
    </redundancy>
</rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.5:8080/SEMP

curl -d"<rpc>
    <redundancy>
        <shutdown></shutdown>
    </redundancy>
</rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.9:8080/SEMP

curl -d"<rpc>
   <redundancy>
        <no>
            <shutdown></shutdown>
        </no>
    </redundancy>
</rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.9:8080/SEMP

curl -d"<rpc>
   <redundancy>
        <no>
            <shutdown></shutdown>
        </no>
    </redundancy>
</rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.5:8080/SEMP

curl -d"<rpc>
   <redundancy>
        <no>
            <shutdown></shutdown>
        </no>
    </redundancy>
</rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.7:8080/SEMP

curl -d"<rpc>
    <service>
        <msg-backbone>
            <no>
                <shutdown></shutdown>
            </no>
        </msg-backbone>
    </service>
</rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.7:8080/SEMP

curl -d"<rpc>
    <hardware>
        <message-spool>
            <no>
                <shutdown></shutdown>
            </no>
        </message-spool>
    </hardware>
</rpc>" -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD http://192.168.133.7:8080/SEMP
