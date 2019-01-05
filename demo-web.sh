#!/bin/bash
#==============================================================================
# A demo of a canary release with Istio
# This script implements an Istio Tutorial created by Oleg Chunikhin , Oleg Atamanenko , reviewed by Daniel Bryant on Nov 20, 2018.
# https://www.infoq.com/articles/istio-service-mesh-tutorial
# P.Caron pcaron.de@gmail.com
# 24.11.2018
#==============================================================================
kcmd="kubectl"
icmd="istioctl"
target_ns="default"

#==============================================================================
# Do stuff to the deployments
#==============================================================================
# Apply
if [ "$1" == "apply" ];then
    action="apply"
    $kcmd apply -f <(istioctl kube-inject -f webapp-cd/my-websites.yaml) -n $target_ns
# Delete
elif [ "$1" == "delete" ];then
    action="delete"
    $kcmd delete -f webapp-cd/my-websites.yaml -n $target_ns
elif [ "$1" == "test" ];then
# Test access
sleep=`kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n $target_ns`
    if [ ! -z "$sleep" ]; then
        $kcmd exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n $target_ns) -c istio-proxy -- curl https://my-nginx -k
        echo -e "\033[34mExpect:\033[0m <h1>Welcome to nginx!</h1>"
    else 
        echo "Nothing seems to be running!"
    fi
# Usage
else 
    echo -e "\033[1mUsage:\033[0m\n $0 [apply | delete | test ]"
fi

#==============================================================================
# Do stuff with the routing, rules, policies and ingresses
#==============================================================================
$kcmd $action -f webapp-cd/website-routing-canary.yaml
$kcmd $action -f webapp-cd/<ingress>

$kcmd get pods,svc,gateways,virtualservices,ing -n $target_ns
