#!/bin/bash

POD_NAME_PREFIX=hkjc-pubsubplus-
kubeconfig=/Users/admin/.kube/config.lp-cluster-3

poll_pod_status() {
  podName=$1
  podStatus=`kubectl --kubeconfig=$kubeconfig exec -it $podName -- curl -s -d'<rpc><show><redundancy></redundancy></show></rpc>' -u admin:admin http://localhost:8080/SEMP | grep redundancy-status | grep Up`
  echo "podStatus: $podStatus"
  podActive=`kubectl --kubeconfig=$kubeconfig exec -it $podName -- curl -s -o /dev/null -w '%{http_code}' http://localhost:5550/health-check/guaranteed-active` >> /dev/null
  #echo "podActive: $podActive"

  if [[ "$podStatus" != "" && $podActive == "200" ]] ; then
    #echo "$podName is active"
    return 0
  elif [[ "$podStatus" != "" && $podActive == "503" ]] ; then
    #echo "$podName is not active"
    return 1
  else
    return 2
  fi
}

poll_vpn_status() {
  podName=$1
  echo "podname: $podName"
  vpnStatus=`kubectl --kubeconfig=$kubeconfig exec -it $podName -- curl -s -d'<rpc><show><message-vpn><vpn-name>default</vpn-name></message-vpn></show></rpc>' -u admin:admin http://localhost:8080/SEMP | grep local-status | grep Up`
  echo "vpnStatus: $vpnStatus"
  if [[ "$vpnStatus" != "" ]] ; then
    return 0
  else
    return 1
  fi
}

delete_pod() {
  pod=$1
  matepod=2
  if [[ "$1" == "1" ]] ; then 
    matepod=0
  elif [[ "$1" == "0" ]] ; then
    matepod=1
  fi

  podName=$POD_NAME_PREFIX$pod
  matepodName=$POD_NAME_PREFIX$matepod
  echo "Deleting pod $podName. Matepod is $matepodName"

  poll_pod_status $podName
  podActive=$?

  if [[ "$podActive" != "0" ]] ; then
    echo "Pod is not active. Skipping"
  else
    kubectl --kubeconfig=$kubeconfig delete pod $podName
    sleep 5
    echo "Pod $podName is deleted. Checking mate $matepodName status"
    # put a large number here so that the script will wait if the pod readines_check fails or guarantted-active is not 200 or 503
    for ((i = 0 ; i < 9999999 ; i++)); do
       poll_pod_status $matepodName
       podActive=$?
       if [[ "$podActive" != "0" ]] ; then
         echo "Pod $matepodName is not active after $i seconds"
         sleep 1
       else
         echo "Pod $matepodName is active"
         break;
       fi
    done
   
    #mate broker is active now. Check vpn status 
    while true ; do
       poll_vpn_status $matepodName
       vpnStatus=$?
       if [[ "$vpnStatus" != "0" ]] ; then
          echo "VPN is down"
          sleep 1
       else
          break;
       fi
    done
  fi
}

for ((i = 0 ; i < 10000 ; i++)); do
    delete_pod 0
    delete_pod 1
done

