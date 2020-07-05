#!/bin/bash

KC_REALM=master
KC_USERNAME=client1
KC_PASSWORD=solace1
KC_CLIENT=client1
KC_CLIENT_SECRET=2b114282-aea0-42ab-80c4-93738ba57bff
KC_SERVER=https://ylptest.ddns.net:8443
KC_CONTEXT=auth


# Request Tokens for credentials
KC_RESPONSE=$( \
   curl -k -v -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$KC_USERNAME" \
        -d "password=$KC_PASSWORD" \
        -d 'grant_type=password' \
        -d "client_id=$KC_CLIENT" \
        -d "client_secret=$KC_CLIENT_SECRET" \
	-d "scope=openid" \
        $KC_SERVER/$KC_CONTEXT/realms/$KC_REALM/protocol/openid-connect/token \
	| jq .
)


echo Response=$KC_RESPONSE

KC_ACCESS_TOKEN=$(echo $KC_RESPONSE| jq -r .access_token)
KC_ID_TOKEN=$(echo $KC_RESPONSE| jq -r .id_token)
KC_REFRESH_TOKEN=$(echo $KC_RESPONSE| jq -r .refresh_token)

echo "ACCESS_TOKEN: $KC_ACCESS_TOKEN"
echo "ID_TOKEN: $KC_ID_TOKEN"

# Show all keycloak env variables
#set | grep KC_*

# Introspect Keycloak Request Token
curl -k -v \
     -X POST \
     -u "$KC_CLIENT:$KC_CLIENT_SECRET" \
     -d "token=$KC_ACCESS_TOKEN" \
   "$KC_SERVER/$KC_CONTEXT/realms/$KC_REALM/protocol/openid-connect/token/introspect" \
   | jq .

