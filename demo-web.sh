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
action="apply"
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
echo -e "\033[34mExpect:\033[0m HTTP/1.1 200 OK"
sleep=`kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n "$target_ns"`
    if [ ! -z "$sleep" ]; then
        $kcmd exec $sleep -n "$target_ns" -n default -- curl -I http://website
    else 
        echo -e "\033[35mSomething went wrong\033[0m"
    fi
# Usage
else 
    echo -e "\033[1mUsage:\033[0m\n $0 [apply | delete | test ]"
    exit 0
fi

#==============================================================================
# Do stuff with the routing, rules, policies and ingresses
#==============================================================================
$kcmd -n $target_ns $action -f webapp-cd/website-routing-canary.yaml
# Uncomment if needed
#$kcmd $action -f webapp-cd/<ingress>
echo -e "\033[33m"
read -p "Press [Enter] key to display istio settings for $target_ns"
echo -e "\033[0m"
$kcmd get pods,svc,gateways,virtualservices,ing -n $target_ns
