#!/bin/bash

INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') 
INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}') 
GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT

if [ ! -z "$1" ]; then 
    NAMESPACE="$1"
else
    NAMESPACE="istio-system" 
fi

if [ "$2" = "details" ]; then
    echo "Namespace: " $1
    for i in virtualservice gateway destinationrule serviceentry httpapispec httpapispecbinding quotaspec quotaspecbinding servicerole servicerolebinding policy 
    do
      echo -e "\033[1mChecking $i\033[0m"
      istioctl get $i -n $NAMESPACE
    done 
elif [ -z "$2" ]; then 
    echo "Namespace: " $NAMESPACE
    for i in virtualservice gateway destinationrule serviceentry 
    do
      echo -e "\033[1mChecking $i\033[0m"
      istioctl get $i -n $NAMESPACE
    done 
else
    echo -e "\033[1mUsage $0 <namespace> details\033[0m"
    exit 0
fi

echo -e "\n\033[1mFor details: $0 <namespace> details\033[0m"
echo -e "\n\033[1mINGRESS_HOST:\033[0m "$INGRESS_HOST
echo -e "\033[1mINGRESS_PORT:\033[0m "$INGRESS_PORT
#echo "GATEWAY_URL: "$GATEWAY_URL
echo -e "\033[1mIngress ports for istio-system\033[0m"
kubectl -n istio-system get service istio-ingressgateway
