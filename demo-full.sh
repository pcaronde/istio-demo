#!/bin/bash
# A Simple demo to show functionality of Istio 
# Created by P. Caron 09.11.2018
# This is a script using the files and tools from Istio Authentication Policy
# pcaron.de@protonmail.com
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
WHITE='\033[0;37m'
NORMAL='\033[0m'

# Set some basic variables
kcmd="kubectl"
icmd="istictl"
namesp_array=( dagmar1 dagmar2 dagmar3 )

case $1 in
# Create three namespaces and two deployments with injected sidecar proxies
create)
    for i in "${namesp_array[@]}"
        do
            $kcmd create ns $i
            echo -e "\033[1mCreating two deployments and injecting a sidecar proxy\033[0m"
            $kcmd apply -f <(istioctl kube-inject -f httpbin.yaml) -n $i
            $kcmd apply -f <(istioctl kube-inject -f sleep.yaml) -n $i
            $kcmd get pods -n $i
        done
    echo "Completed"
    echo "Wait for all instances to start"
    echo "$kcmd get pods --all-namespaces -w"
    echo -e "${BLUE}\nShould look like this${NORMAL}"
    echo "prod           httpbin-7bc685687b-j5lzr                2/2     Running     0          2m2s"
    echo "prod           sleep-5cdc56d85d-24nm8                  2/2     Running     0          2m1s"
    echo "stage          httpbin-7bc685687b-5bgsm                2/2     Running     0          2m"
    echo "stage          sleep-5cdc56d85d-kjgrf                  2/2     Running     0          119s"

    echo -e "\n\033[0;34mNext, run $0 test\033[0m"
    exit 0
;;
# Test environment access between deplyoments (in and within namespaces)
test)
    for from in ${namesp_array[*]}; do for to in ${namesp_array[*]}; do $kcmd exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl http://httpbin.${to}:8000/ip -s -o /dev/null -w "sleep.${from} to httpbin.${to}: %{http_code}\n"; done; done

    echo -e "\n\033[1mSingle curl test:\033[0m"
    echo "$kcmd exec $(kubectl get pod -l app=sleep -n "${namesp_array[0]}" -o jsonpath={.items..metadata.name}) -c sleep -n "${namesp_array[0]}" -- curl http://httpbin."${namesp_array[0]}":8000/ip -s -o /dev/null -w '%{http_code}\n'"
    echo -e "\n\033[0;34mNext: we'll makes sure that there is no mesh policy or default destination rule\033[0m"
    echo -e "\n\033[1mAuthentication policies\033[0m"
    $kcmd get policies.authentication.istio.io --all-namespaces
    echo -e "\n\033[1mDefault mesh policy\033[0m"
    $kcmd get meshpolicies.authentication.istio.io 
    $kcmd get meshpolicies.authentication.istio.io -oyaml
    echo -e "\n\033[1mDestination rules\033[0m"
    $kcmd get destinationrules.networking.istio.io --all-namespaces

    
    echo -e "\n\033[0;34mTest egress to Google\033[0m"
    for from in ${namesp_array[*]}; do $kcmd exec $(kubectl get pod -l app=sleep -n ${from} -o jsonpath={.items..metadata.name}) -c sleep -n ${from} -- curl -I https://www.google.com -s -o /dev/null -w "sleep.${from} to Google: %{http_code}\n"; done
#    exec sleep-f8988d9dc-gpmtb -n demo1 -- curl -I https://www.google.com
    exit 0
;;
# Set basic restrictions for entire mesh
mesh)
    # Set restrictions on source (mesh-polcy.yaml) and destination (default-dest-rule.yaml)
#    $kcmd apply -f default-dest-rule.yaml
    $kcmd apply -f ./rules_policies/mesh-policy.yaml
#    $kcmd apply -f rules_policies/ns-policy.yaml -n ${namesp_array[0]}
    echo -e "\n\033[1mDefault mesh policy is now:\033[0m"
    $kcmd get meshpolicies.authentication.istio.io
exit 0
;;
egress)
    echo -e "${BLUE}\nSet Egress for Google${NORMAL}"

    $kcmd apply -f extras/google-egress.yaml -n "${namesp_array[0]}"  
;;
override)
    echo -e "\n\033[1mOverride default mesh policy for ${namesp_array[0]}:\033[0m"
    $kcmd apply -f rules_policies/override_httpbin_policy.yaml -n ${namesp_array[0]}
;;
# Cleanup and delete demo deployments and services
cleanup)
    # Cleanup details
    echo -e "\n\033[1mCleanup is ...\033[0m"
# Not elegant
    cd rules_policies
    echo "$kcmd delete --ignore-not-found=true -f default-dest-rule.yaml"
    $kcmd delete --ignore-not-found=true -f default-dest-rule.yaml
    echo "$kcmd delete --ignore-not-found=true -f mesh-policy.yaml"
    $kcmd delete --ignore-not-found=true -f mesh-policy.yaml
    echo "$kcmd delete --ignore-not-found=true -f override_dev.yaml"
    $kcmd delete --ignore-not-found=true -f override_dev.yaml
# return to main dir
    cd ..
    echo "Delete namespaces:  ${namesp_array[*]}"
    for ns in ${namesp_array[*]}; do $kcmd delete ns ${ns}; done

    $kcmd delete -n ${namesp_array[0]} -f extras/google-egress.yaml
    echo -e "\n\033[1m \033[34mNOTE: Check destination rules to make sure nothing is left-over\033[0m"
;;
# Information about current policy and destination rules
info)
#elif [ "$1" == "info" ]; then
    
    echo -e "\n\033[1mAuthentication policies\033[0m"
    $kcmd get policies.authentication.istio.io --all-namespaces
    echo -e "\033[1mDefault mesh policy\033[0m"
    $kcmd get meshpolicies.authentication.istio.io
    echo -e "\033[1mIngress Services\033[0m"
    $kcmd get services istio-ingressgateway -n istio-system
    echo -e "\n\033[1mCurrent destination rules\033[0m"
    # Verify that there are no destination rules that apply on the example services. 
    $kcmd get destinationrules.networking.istio.io --all-namespaces -o yaml | grep "host:"
    echo -e "\n\033[1mCurrent Ingress\033[0m"
    $kcmd get svc istio-ingressgateway -n istio-system

# Cleanup details
#echo -e "\n\033[1mCleanup is ...\033[0m"
#echo "$kcmd delete ns prod stage dev"
#echo "$kcmd delete -f default-dest-rule.yaml"
#echo "$kcmd delete -f mesh-policy.yaml"
#echo "$kcmd delte -f override_dev.yaml"
echo -e "\n\033[1m \033[34mNOTE: Check destination rules to make nothing is left-over\033[0m"

# DEBUG
#    echo -e  "\n\033[1mCheck variables:\n\033[0m$0 "
#    echo "${namesp_array[1]}"
#    echo "kubectl exec $(kubectl get pod -l app=sleep -n "${namesp_array[1]}" -o jsonpath={.items..metadata.name}) -c sleep -n "${namesp_array[0]}" -- curl http://httpbin."${namesp_array[0]}":8000/ip -s -o /dev/null -w '%{http_code}'"
# DEBUG
#    echo -e  "\n\033[1mCheck array:\n\033[0m$0 "
#    echo "Array size: ${#namesp_array[*]}"
#
#    echo "Array items:"
#    for item in ${namesp_array[*]}
#        do
#            printf "   %s\n" $item
#        done
#
#    echo "Array indexes:"
#    for index in ${!namesp_array[*]}
#        do
#            printf "   %d\n" $index
#        done
#
#    echo "Array items and indexes:"
#    for index in ${!namesp_array[*]}
#        do
#            printf "%4d: %s\n" $index ${namesp_array[$index]}
#        done
;;
# Usage
*)
#else
    echo -e "\n\033[1mUsage:\n\033[0m$0 [arguments]" 
    echo -e "\033[1m ex:\033[0m $0 [create | mesh | test | info | override | cleanup]"
#fi
esac
