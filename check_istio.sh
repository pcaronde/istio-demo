#!/bin/bash

if [ ! -z "$1" ]; then 
    NAMESPACE="$1"
else
    echo -e "\033\[1mUsage $0 <namespace> details\033[0m"
    exit 0
fi

if [ "$2" = "details" ]; then
    for i in virtualservice gateway destinationrule serviceentry httpapispec httpapispecbinding quotaspec quotaspecbinding servicerole servicerolebinding policy 
    do
      echo -e "\033[1mChecking $i\033[0m"
      istioctl get $i -n $1
    done 
else
    for i in virtualservice gateway destinationrule serviceentry 
    do
      echo -e "\033[1mChecking $i\033[0m"
      istioctl get $i -n $1
    done 
fi

