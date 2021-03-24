#!/bin/bash

###################################
## This script is used to reproduce the issue in SOL-44990
## How to use:
## 1. Create Kubernetes HA deployment following Solace Kubernetes quick start documentation, e.g. helm install solace-release solacecharts/pubsubplus ./values.yaml
## 2. Get pod names with "kubectl get pods". Example output is solace-release-pubsubplus-0, solace-release-pubsubplus-1 and solace-release-pubsubplus-2.
## 3. Updatfge POD_NAME_PREFIX to the pod name withotu the last digit.
## 4. Run the script  ./pod_deletion.sh | tee sol-44990.log
## 5. Monitor the log file sol-44990.log. If the deleted broker doesn't come back after some time, e.g. 2mins, use following commands to verify whether the issue is reproduced:
##    - kubectl exec -it <pod-name> -- bash
##    - curl --unix-socket /var/run/solace/consul -X GET http://127.0.0.1/v1/operator/raft/configuration | python -m json.tool (check whether all servers are valid)
##    - Enter bnroker cli console with command "cli" and verify redundancy status with CLI command "show redundancy" and redundancy group with "show redundancy group".
###################################

POD_NAME_PREFIX=solace-release-pubsubplus-

poll_pod_status() {
  podName=$1
  podStatus=`kubectl get pod $podName | grep $podName | awk '{print $3}'`
  echo "podStatus: $podStatus."
  if [[ "$podStatus" != "Running" ]] ; then
     return 2
  fi
  podStatus=`kubectl exec -it $podName -- curl -s -d'<rpc><show><redundancy></redundancy></show></rpc>' -u admin:admin http://localhost:8080/SEMP | grep redundancy-status | grep Up`
  #echo "podStatus: $podStatus"
  podActive=`kubectl exec -it $podName -- curl -s -o /dev/null -w '%{http_code}' http://localhost:5550/health-check/guaranteed-active` >> /dev/null
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
    echo "Pod $podName is deleted. Checking its status"
    # put a large number here so that the script will wait if the pod readines_check fails or guarantted-active is not 200 or 503
    for ((i = 0 ; i < 9999999 ; i++)); do
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

