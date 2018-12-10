# Demonstration of istio authentication and rules
These demos create three namespaces with two apps in each (httpbin and sleep)

The first demo `demo-1.sh` sets up and shows how a mesh works. 

The second demo `demo-2.sh` shows how mutual tls can be used.

`demo-3.sh` is incomplete and untested 

# Quick Start
`demo-full.sh create`

`demo-full.sh test`

`demo-full.sh mesh`

`demo-full.sh info`

# To install Istio from scratch
1. Helm install 
```
helm template ../istio-1.0.4/install/kubernetes/helm/istio --name istio --namespace istio-system --set global.configValidation=false --set sidecarInjectorWebhook.enabled=false --set grafana.enabled=true --set servicegraph.enabled=true --set tracing.enabled=true > istio_aws_no_injection.yaml
```
Then `kubectl create -f istio_aws_no_injection.yaml`

2. AWS EKS does not support automatice sidecar inject so it must be disabled. GCE and most stand-alone K8S support it but you may wish to disable it to start.
a. When implementing ISTIO Service Mesh with Helm you may wish to disable automatic sidecar injection. Set 'sidecarInjectorWebhook.enabled=false'
and --set global.configValidation=false
```bash
helm install \
    --wait \
    --name istio \
    --namespace istio-system \
    install/kubernetes/helm/istio \
    --set global.configValidation=false \
    --set sidecarInjectorWebhook.enabled=false
```
If you already installed and want to update
```
helm upgrade --wait \
             --set global.configValidation=false \
             --set sidecarInjectorWebhook.enabled=false \
             istio \
             install/kubernetes/helm/istio
```
If the namespace istio-system has already been created and the upgrade does not work, try deleting the ns, recreating it and running the helm again with configValidation and sidecarInjectorWehook = false
b. other option here.

To create deployment and insert sidecar manually
```bash
istioctl kube-inject -f samples/sleep/sleep.yaml | kubectl apply -f -
```
or in two steps
```bash
$ istioctl kube-inject \
    --injectConfigFile inject-config.yaml \
    --meshConfigFile mesh-config.yaml \
    --filename samples/sleep/sleep.yaml \
    --output sleep-injected.yaml
$ kubectl apply -f sleep-injected.yaml
```

To apply istio settings (inject a sidecar) into existing deployments
```bash
kubectl get deployment <my_deployment> -o yaml | istioctl kube-inject -f - | kubectl apply -f -
```
Verify
```bash
kubectl get deployment tea -o wide
NAME   DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS        IMAGES                                                      SELECTOR
tea    0         0         0            0           4h    tea,istio-proxy   nginxdemos/hello:plain-text,docker.io/istio/proxyv2:1.0.3   app=tea
```
HINT: It is a good idea to disable istio-injection on EKS. This means that sidecars have to be injected manually!
```bash
kubectl label namespace default istio-injection-
kubectl get namespace -L istio-injection
```
Finally, **External LoadBalancers (AWS,GCE)** have to be managed differently by creating a new policy and attaching it to the master role nodes.
see https://istio.io/blog/2018/aws-nlb/ for a description.
## Files
The files are
```
.
├── README.md
├── check_istio.sh
├── demo-full1.sh
├── google-egress.yaml
├── httpbin-egress.yaml
├── httpbin-gateway.yaml
├── httpbin-gw-svc.yaml
├── httpbin-ingress.yaml
├── httpbin-injected.yaml
├── httpbin-svc.yaml
├── httpbin-virtualservice.yaml
├── httpbin.yaml
├── https
│   ├── default.conf
│   └── nginx-app.yaml
├── rules_policies
│   ├── appversion-instance.yaml
│   ├── checkversion-rule.yaml
│   ├── default-dest-rule.yaml
│   ├── dest-rule-bad.yaml
│   ├── dest-rule-permissive.yaml
│   ├── dest-rule-tls.yaml
│   ├── mesh-policy.yaml
│   ├── ns-policy.yaml
│   ├── ns-prod-rule.yaml
│   ├── override_httpbin_dest-rule.yaml
│   ├── override_httpbin_policy.yaml
│   ├── service-policy.yaml
│   ├── service-rule.yaml
│   └── whitelist-handler.yaml
├── setup
│   ├── istio-aws.yaml
│   ├── istio-demo-auth.yaml
│   ├── istio-demo.yaml
│   ├── istio_aws_no_injection.yaml
│   ├── istio_aws_no_injection_trace.yaml
│   └── zipkin.yaml
├── sleep.yaml
└── webapp-cd
    ├── dest-rule-default.yaml
    ├── dest-rule-disable.yaml
    ├── dest-rule-tls.yaml
    ├── my-websites.yaml
    ├── override_website_policy.yaml
    ├── permissive-website_policy.yaml
    ├── website-routing-canary.yaml
    └── website-routing.yaml
```
