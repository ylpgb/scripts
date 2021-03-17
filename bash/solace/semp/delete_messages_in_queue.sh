#!/bin/bash

#cli-to-semp admin message-spool message-vpn default delete-messages queue test

curl -d"
<rpc>
    <admin>
        <message-spool>
            <vpn-name>default</vpn-name>
            <delete-messages>
                <queue-name>test</queue-name>
            </delete-messages>
        </message-spool>
    </admin>
</rpc>
"  -u admin:admin http://192.168.40.233:8080/SEMP
