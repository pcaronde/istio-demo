#!/bin/bash
# Simple script to generate some traffic for the demo
# Author: P. Caron
# pcaron.de@pm.me
if [ -n "$1" ]; then
    EXTERNAL_NAME="$1"
    SERVICE="$2"
else
    EXTERNAL_NAME="demo"
    SERVICE="headers"
fi
## loop
# ALT
# watch -n 1 curl -o /dev/null -s -w %{http_code} https://demo.k8s-pcconsultants.de/website
for i in {1..40}
do
    time curl -IL http://${EXTERNAL_NAME}.k8s-pcconsultants.de/${SERVICE} -s -o /dev/null -w 'HTTP Response: %{http_code}'
    time curl -IL https://demo.k8s-pcconsultants.de/ip -s -o /dev/null -w 'HTTP Response: %{http_code}'
    time curl -IL http://auth.k8s-pcconsultants.de/httpbin/headers -s -o /dev/null -w 'HTTP Response: %{http_code}'
    time curl -IL https://demo.k8s-pcconsultants.de/productpage -s -o /dev/null -w 'HTTP Response: %{http_code}'
    time curl -IL https://demo.k8s-pcconsultants.de/website -s -o /dev/null -w 'HTTP Response: %{http_code}'
    sleep 1s
done

