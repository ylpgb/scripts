#!/bin/bash

POD_NAME_PREFIX=hkjc-ha-pubsubplus-
kubeconfig=/Users/admin/.kube/config

poll_pod_status() {
  pod=$1
  podStatus=`kubectl --kubeconfig=$kubeconfig exec -it $pod -- curl -s -d'<rpc><show><redundancy></redundancy></show></rpc>' -u admin:admin http://localhost:8080/SEMP | grep redundancy-status | grep Up`
  #echo "podStatus: $podStatus"
  podActive=`kubectl --kubeconfig=$kubeconfig exec -it $pod -- curl -s -o /dev/null -w '%{http_code}' http://localhost:5550/health-check/guaranteed-active` >> /dev/null
  #echo "podActive: $podActive"

  if [[ "$podStatus" != "" && $podActive == "200" ]] ; then
    #echo "$pod is active"
    return 0
  elif [[ "$podStatus" != "" && $podActive == "503" ]] ; then
    #echo "$pod is not active"
    return 1
  else
    return 2
  fi
}

release_activity() {
  pod=$1
  ret=`kubectl --kubeconfig=$kubeconfig exec -it $pod -- curl -s -d'<rpc><redundancy><release-activity></release-activity></redundancy></rpc>' -u admin:admin http://localhost:8080/SEMP`
  ret=`kubectl --kubeconfig=$kubeconfig exec -it $pod -- curl -s -d'<rpc><redundancy><no><release-activity></release-activity></no></redundancy></rpc>' -u admin:admin http://localhost:8080/SEMP`
  sleep 2
}

poll_vpn_status() {
  pod=$1
  echo "pod: $pod"
  vpnStatus=`kubectl --kubeconfig=$kubeconfig exec -it $pod -- curl -s -d'<rpc><show><message-vpn><vpn-name>default</vpn-name></message-vpn></show></rpc>' -u admin:admin http://localhost:8080/SEMP | grep local-status | grep Up`
  echo "vpnStatus: $vpnStatus"
  if [[ "$vpnStatus" != "" ]] ; then
    return 0
  else
    return 1
  fi
}

delete_pod() {
  pod=$1
  kubectl --kubeconfig=$kubeconfig delete pod $pod
  sleep 5
}

failover() {
  active=$1
  standby=$2
  count=$3

  echo "count is $count"

  for((idx=0;idx<$count;idx++)); do
    echo "Performing failover number $idx"
    # perform failover and failback before deleting the pod
    echo "Failover: Release activity on $active"
    release_activity $active    
    for ((i = 0 ; i < 9999999 ; i++)); do
      poll_pod_status $standby
      podActive=$?
      if [[ "$podActive" != "0" ]] ; then
         echo "Pod $standby is not active after $i seconds"
         sleep 1
       else
         echo "Pod $standby is active"
         break;
       fi
    done

    echo "Failback: Release activity on $standby "
    release_activity $standby
    for ((i = 0 ; i < 9999999 ; i++)); do
      poll_pod_status $active
      podActive=$?
      if [[ "$podActive" != "0" ]] ; then
         echo "Pod $active s not active after $i seconds"
         sleep 1
       else
         echo "Pod $active is active"
         break;
       fi
    done
  done

}

delete_pod_test() {
  pod=$1
  matepod=2
  if [[ "$1" == "1" ]] ; then 
    matepod=0
  elif [[ "$1" == "0" ]] ; then
    matepod=1
  fi

  podName=$POD_NAME_PREFIX$pod
  matepodName=$POD_NAME_PREFIX$matepod

  poll_pod_status $podName
  podActive=$?

  if [[ "$podActive" != "0" ]] ; then
    echo "Pod is not active. Skipping"
  else
    failover $podName $matepodName 5   

    delete_pod $podName
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
  fi
}

for ((i = 0 ; i < 10000 ; i++)); do
    delete_pod_test 0
    delete_pod_test 1
done

