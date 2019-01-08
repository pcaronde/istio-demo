#!/bin/bash

INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') 
INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}') 
GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

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

echo "INGRESS_HOST: "$INGRESS_HOST
echo "INGRESS_PORT: "$INGRESS_PORT
echo "GATEWAY_URL: "$GATEWAY_URL
