#!/bin/bash

[[ $# < 1 ]] && { echo "Usage: $0 ipport"; echo "ipport is the IP:PORT of the client to find, e.g. 10.9.0.7:51457";  exit 1; }

MANAGEMENT_USER=admin
MANAGEMENT_PASSWORD=admin
BROKER_SEMP_URL=192.168.40.13:80
IPPORT=$1

function searchClientInVPN
{
  MESSAGE_VPN=$1
  local URI=http://$BROKER_SEMP_URL/SEMP/v2/monitor/msgVpns/$MESSAGE_VPN/clients
  
  while [ "$URI" != "null" ]; do
    local output=`curl -s -X GET -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD "$URI"`
  
    data=`echo $output | jq -r [.data]`
    clientName=`echo "$data" | sed -n '/'$IPPORT'/,/clientName/p' | grep clientName | cut -d':' -f2 | sed 's/"//g;s/,//g;s/\ //g' ` 
    if [[ "$clientName" != "" ]] ; then
      echo "$clientName"
      exit 1;
    fi
    URI=`echo $output | jq -r [.meta.paging.nextPageUri] | jq -r .[]`
  done
}

function searchVPN
{
  local URI=http://$BROKER_SEMP_URL/SEMP/v2/monitor/msgVpns
  
  while [ "$URI" != "null" ]; do
    local output=`curl -s -X GET -u $MANAGEMENT_USER:$MANAGEMENT_PASSWORD "$URI"`
    
    data=`echo $output | jq -r [.data]`
    vpn=`echo "$data" | grep msgVpnName | cut -d':' -f2 | sed 's/"//g;s/,//g;s/\ //g' `
    for i in $vpn; do
      searchClientInVPN $i
    done
    URI=`echo $output | jq -r [.meta.paging.nextPageUri] | jq -r .[]`
  done

}

searchVPN
