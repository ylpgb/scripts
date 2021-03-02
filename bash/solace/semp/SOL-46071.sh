#!/bin/bash

USER=admin
PASS=admin
URL1=192.168.133.12:8080
URL2=192.168.133.43:8080

reboot_broker() {
      #ret=`curl -s -d'<rpc><redundancy><release-activity></release-activity></redundancy></rpc>' -u $USER:$PASS http://$1/SEMP`
      #ret=`curl -s -d'<rpc><redundancy><no><release-activity></release-activity></no></redundancy></rpc>' -u $USER:$PASS http://$1/SEMP`
      #ret=`curl -s -d'<rpc><reload></reload></rpc>' -u $USER:$PASS http://$1/SEMP`
      BROKER=`echo $1 | cut -d':' -f1`
      echo "Rebooting broker $BROKER"
      #ret=`sshpass -p sysadmin ssh sysadmin@$BROKER sudo reboot`
      ret=`sshpass -p sysadmin ssh sysadmin@$BROKER sudo docker exec solace killall solacedaemon`
      echo "Reboot broker returned $?"
      sleep 5
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
      reboot_broker $active
      while true ; do
          check_redundancyStatus $mate
          status=$?
          is_localActive $mate
          ret=$?
          if [[ "$ret" == "1" && "$status" == "1" ]] ; then
             echo "Redundancy is up and broker is active"
             break 
          fi
          echo "Redundancy on $mate is not up or not active"
          sleep 1
      done 
}

stress_test() {
      for ((i=1; i<10000000; i++)); do
         failover $URL1
         failover $URL2
      done
}

stress_test

