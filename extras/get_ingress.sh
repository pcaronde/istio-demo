#!/bin/bash
service="$1"
namespace="$2"
if [ -z "$1" ]; then 
    kubectl describe svc $service --namespace $namespace | grep Ingress | awk '{print $3}'
else
    echo "Usage: $0 service namespace"
fi
