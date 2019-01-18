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
    $kcmd apply -f <(istioctl kube-inject -f websites-config/websites-demo.yaml) -n $target_ns
    #==============================================================================
    # Apply routing, rules, policies and ingresses
    #==============================================================================
#    $kcmd -n $target_ns apply -f websites-config/website-routing-canary.yaml
# Delete
elif [ "$1" == "delete" ];then
    action="delete"
    $kcmd delete -f websites-config/websites-demo.yaml -n $target_ns
    #==============================================================================
    # Delete routing, rules, policies and ingresses
    #==============================================================================
#    $kcmd -n $target_ns delete -f websites-config/website-routing-canary.yaml
elif [ "$1" == "test" ];then
# Test access
echo -e "\033[34mRunning curl against http://website\033[0m "
echo -e "\033[34mExpect:\033[0m HTTP/1.1 200 OK\033[0m"
sleep=`kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name} -n "$target_ns"`
    if [ ! -z "$sleep" ]; then
        $kcmd exec $sleep -n "$target_ns" -n default -- curl -I http://website
# check version
echo -e "\033[34mExpect a version number: \033[34mv1 70%, v2 25%, v3 5%\033[0m"
        $kcmd exec $sleep -n "$target_ns" -n default -- curl http://website | grep "version"
    else 
        echo -e "\033[35mSomething went wrong\033[0m"
    fi
# Usage
else 
    echo -e "\033[1mUsage:\033[0m\n $0 [apply | delete | test ]"
    exit 0
fi

# Uncomment if needed
#$kcmd $action -f websites-config/<ingress>
echo -e "\033[32m"
read -p "Press [Enter] key to display istio settings for $target_ns"
echo -e "\033[0m"
$kcmd get pods,svc,gateways,virtualservices,ing -n $target_ns
