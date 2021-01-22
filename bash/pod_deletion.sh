#!/bin/bash

POD_NAME_PREFIX=solace-release-pubsubplus-

poll_pod_status() {
  podName=$1
  kubectl exec -it $podName -- /mnt/disks/solace/readiness_check.sh >> /dev/null
  podStatus=$?
  #echo "podStatus: $podStatus"
  podActive=`kubectl exec -it $podName -- curl -s -o /dev/null -w '%{http_code}' http://localhost:5550/health-check/guaranteed-active` >> /dev/null
  #echo "podActive: $podActive"

  if [[ "$podStatus" == "0" && $podActive == "200" ]] ; then
    #echo "$podName is active"
    return 0
  elif [[ "$podStatus" == "0" && $podActive == "503" ]] ; then
    #echo "$podName is not active"
    return 1
  else
    return 2
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
    kubectl delete pod $podName
    echo "Pod $podName is deleted. Checking it's status"
    # wait for 2 mins for the pod to come up
    for ((i = 0 ; i < 120 ; i++)); do
       poll_pod_status $podName
       podActive=$?
       if [[ "$podActive" != "0" && "$podActive" != "1" ]] ; then
         echo "Pod is not coming up after $i seconds"
         sleep 1
       else
         echo "Pod is up"
         return 0
       fi
    done
    
  fi
}

for ((i = 0 ; i < 10000 ; i++)); do
    delete_pod 0
    delete_pod 1
done

