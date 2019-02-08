#!/bin/bash
# Simple script to generate some traffic for the demo
# Author: P. Caron
# pcaron.de@pm.me

EXTERNAL_IP="$1"
## loop
for i in {1..10}
do
    time curl -IL http://${EXTERNAL_IP}/headers -s -o /dev/null -w 'HTTP Response: %{http_code}'
    #time curl -IL http://k8s-pcconsultants.de/website -s -o /dev/null -w 'HTTP Response: %{http_code}'
    sleep 3s
done

