#!/bin/bash
#==============================================================================
# This script is incomplete and untested!!! Adapt at your own risk
# P.Caron pcaron.de@protonmail.com
# 30.11.2018
# Create an HTTPS service with the Istio sidecar and mutual TLS disabled
#==============================================================================
# Variables and executables
kcmd="kubectl"
icmd="istioctl"
# Set source and target container apps (e.g. sleep and httpbin)
#source_container="sleep"
#target_container="httpbin"
#target_port="8000"
if [ -z "$2" ];then
    target_ns="demo3"
else
    target_ns="$2"
fi

echo -e "\033[0;34mCreate a ConfigMap for Nginx\033[0m"
$kcmd create configmap nginxconfigmap --from-file https/default.conf -n $target_ns

# Cleanup and create without TLS
if [ "$1" == "notls" ];then
    echo -e "\033[0;34mCreate an HTTPS service with the Istio sidecar and mutual TLS disabled\033[0m"
    $kcmd delete --ignore-not-found=true -f ./https/nginx-app.yaml -n $target_ns
    $kcmd apply -f <(istioctl kube-inject -f ./https/nginx-app.yaml) -n $target_ns

    sleep 5
    $kcmd get pods -n $target_ns
    # Test Istio enabled
    echo -e "\n\033[1m curl my-nginx\033[0m"
    $kcmd exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -n $target_ns -c sleep -- curl https://my-nginx -k

    # Test same from proxy
#    echo -e "\n\033[1m curl my-nginx\033[0m"
#    kubectl exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
# Clean up and create TLS
elif [ "$1" == "tls" ];then
    echo -e "\033[0;34mCreate an HTTPS service with the Istio sidecar and mutual TLS enabled\033[0m"    
    $kcmd delete --ignore-not-found=true -f ./https/nginx-app.yaml -n $target_ns
    $kcmd apply -f <(istioctl kube-inject -f ./https/nginx-app.yaml) -n $target_ns
    sleep 5
    $kcmd get pods -n $target_ns

    # This should fail
    echo -e "\033[0;34mMutual TLS enabled - should fail\033[0m"  
    kubectl exec $(kubectl -n $target_ns get pod -l app=sleep -o jsonpath={.items..metadata.name}) -n $target_ns -c sleep -- curl https://my-nginx -k
    # This should pass
    echo -e "\033[0;34mMutual TLS enabled - should pass\033[0m"  
    kubectl exec $(kubectl -n $target_ns get pod -l app=sleep -o jsonpath={.items..metadata.name}) -n $target_ns -c istio-proxy -- curl https://httpbin."$target_ns":8000/headers -o /dev/null -s -w '%{http_code}\n' --key /etc/certs/key.pem --cert /etc/certs/cert-chain.pem --cacert /etc/certs/root-cert.pem -k
# Test if connections are working
elif [ "$1" == "test" ];then
    $kcmd get pods -n $target_ns
    # Test Istio enabled
    echo -e "\n\033[1m curl my-nginx\033[0m"
    $kcmd exec $(kubectl -n $target_ns get pod -l app=sleep -o jsonpath={.items..metadata.name}) -n $target_ns -c sleep -- curl https://my-nginx -k

    # Test same from proxy
    echo -e "\n\033[1m curl my-nginx\033[0m"
    $kcmd exec $(kubectl -n $target_ns get pod -l app=sleep -o jsonpath={.items..metadata.name}) -n $target_ns -c istio-proxy -- curl https://my-nginx -k
fi
