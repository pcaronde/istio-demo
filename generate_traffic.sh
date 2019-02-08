#!/bin/bash
# Simple script to generate some traffic for the demo
# Author: P. Caron
# pcaron.de@pm.me

## sleep loop
for i in {1..10}
do
    time curl -IL http://35.246.103.254/website -s -o /dev/null -w 'HTTP Response: %{http_code}'
    #time curl -IL http://website-test.aws.atu.de/website -s -o /dev/null -w 'HTTP Response: %{http_code}'
    sleep 3s
done

#while [ : ]
#do
#    clear
#    tput cup 5 5
#    date
#    tput cup 6 5
#    echo -e "\033[32mHostname:\033[0m $(hostname)"
#    sleep 1
#done
