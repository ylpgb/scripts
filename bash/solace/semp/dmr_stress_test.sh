#!/bin/bash

USER=admin
PASS=admin
URL1=192.168.133.84:8080
URL2=192.168.133.85:8080

check_message_vpn_Upstatus() {
      VPNStatus=`curl -s -d'<rpc><show><message-vpn><vpn-name>default</vpn-name></message-vpn></show></rpc>' -u $USER:$PASS http://$1/SEMP | grep local-status | grep Up`
      if [[ "$VPNStatus" != "" ]] ; then
        return 1
      else
        return 0
      fi
}

release_redundancy() {
      ret=`curl -s -d'<rpc><redundancy><release-activity></release-activity></redundancy></rpc>' -u $USER:$PASS http://$1/SEMP`
      ret=`curl -s -d'<rpc><redundancy><no><release-activity></release-activity></no></redundancy></rpc>' -u $USER:$PASS http://$1/SEMP`
}

check_redundancyStatus() {
      VPNStatus=`curl -s -d'<rpc><show><redundancy></redundancy></show></rpc>' -u $USER:$PASS http://$1/SEMP | grep redundancy-status | grep Up`
      if [[ "$VPNStatus" != "" ]] ; then
        return 1
      else
        return 0
      fi
}

is_localActive() {
      VPNStatus=`curl -s -d'<rpc><show><redundancy></redundancy></show></rpc>' -u $USER:$PASS http://$1/SEMP | grep "activity.*Local Active"`
      if [[ "$VPNStatus" != "" ]] ; then
        return 1
      else
        return 0
      fi
}

failover() {
      URL=$1
      if [[ "$URL" == "$URL1" ]] ; then
         active=$URL1
         mate=$URL2
      else
         active=$URL2
         mate=$URL1
      fi

      is_localActive $active
      ret=$?
      if [[ "$ret" == "0" ]] ; then
          echo "Broker $active is not active"
          return 0
      fi

      echo "Releasing activity for $active"
      release_redundancy $active
      while true ; do
          check_redundancyStatus $mate
          ret=$?
          if [[ "$ret" == "1" ]] ; then
             break 
          fi
          echo "Redundancy on $mate is not up yet"
          sleep 1
      done 

      check_message_vpn_Upstatus $mate
      status=$?
      if [[ "$status" == "1" ]] ; then
         echo "VPN on $mate is up"
      else
         while true ; do
            echo "VPN on $mate is down"
            sleep 1
         done
      fi
}

stress_test() {
      for ((i=1; i<10000000; i++)); do
         failover $URL1
         failover $URL2
      done
}

stress_test
