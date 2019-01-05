#!/bin/bash
#==============================================================================
# A demo of an HTTPS deploy without sidecar
# P.Caron pcaron.de@gmail.com
# 24.11.2018
#==============================================================================
kcmd=kubectl
icmd=istioctl

if [ "$1" == "apply" ];then
    action="apply"
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tmp/nginx.key -out /tmp/nginx.crt -subj "/CN=my-nginx/O=my-nginx"
    $kcmd create secret tls nginxsecret --key /tmp/nginx.key --cert /tmp/nginx.crt
    $kcmd create configmap nginxconfigmap --from-file=./https/default.conf
    # This section creates a NGINX-based HTTPS service.
    $kcmd $action -f ./https/nginx-app.yaml
    # Then, create another pod to call this service.
    $kcmd $action -f <(istioctl kube-inject -f sleep.yaml) -n default
elif [ "$1" == "delete" ];then
    action="delete"
    rm /tmp/nginx.key /tmp/nginx.crt
    $kcmd delete secret nginxsecret 
    $kcmd delete configmap nginxconfigmap 
    $kcmd $action -f ./https/nginx-app.yaml
    $kcmd $action -f sleep.yaml
    exit 0    
elif [ "$1" == "test" ];then
# Test access
sleep=`kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}`
    if [ ! -z "$sleep" ]; then
        $kcmd exec $(kubectl get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c istio-proxy -- curl https://my-nginx -k
        echo -e "\033[34mExpect:\033[0m <h1>Welcome to nginx!</h1>"
    else 
        echo "Nothing running!"
    fi

else 
    echo -e "\033[1mUsage:\033[0m\n $0 [apply | delete | test ]"
fi
