# Demonstration of istio authentication and rules
These demos create three namespaces with two apps in each (httpbin and sleep)

The first demo `demo-full.sh` sets up and shows how a mesh works. 

# Quick start
If Istio is already installed, the demo can be used directly.
I have collected some useful commands which might save typing time.
`check_istio.sh`
`istio-debug.sh`		

If you just want to dive in and see what happens, 
`demo-full.sh`		works in GKE
`demo-tls-no-sidecar.sh ` needs testing
`demo-tls.sh`	needs testing	
`demo-web.sh`	works in GKE

**WARNING**
This is intended to be used as a learning demonstration. Your milage may vary. 

**Do not do this on a production system.**

# To install Istio from scratch
1. Helm install 
```
helm template ../istio-1.0.4/install/kubernetes/helm/istio --name istio --namespace istio-system --set global.configValidation=false --set sidecarInjectorWebhook.enabled=false --set grafana.enabled=true --set servicegraph.enabled=true --set tracing.enabled=true > istio_aws_no_injection.yaml
```
Then `kubectl create -f istio_aws_no_injection.yaml`

2. As of November 2018, AWS EKS did not support automatic sidecar injection so it had be disabled. (AWS EKS supports automatic injection as of December 2018) GCE and most stand-alone K8S support it but you may wish to disable it to start.
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
Another option is to use the helm template and adjust your setting inside the resulting yaml file. This method allows you to see exactly what is going to happen and make adjustments at any time. The minimal option is
```
helm template install/kubernetes/helm/istio \
  --name istio \
  --namespace istio-system \
  --set security.enabled=false \
  --set galley.enabled=false \
  --set sidecarInjectorWebhook.enabled=false \
  --set mixer.enabled=false \
  --set prometheus.enabled=false \
  --set global.proxy.envoyStatsd.enabled=false \
  --set pilot.sidecar=false > istio-minimal.yaml
``` 
If you already installed Istio and and want to update use the follwoing as with any helm installation
```
helm upgrade --wait \
             --set global.configValidation=false \
             --set sidecarInjectorWebhook.enabled=false \
             istio \
             install/kubernetes/helm/istio
```
If the namespace istio-system has already been created and the upgrade does not work, try deleting the ns, recreating it and running the helm again with configValidation and sidecarInjectorWehook = false
b. other option here.

To create deployment and insert sidecar manually in a single step (recommended)
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
3. Once Istio is installed and working, you can proceed to do things with it.

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

If you choose to use multiple ingress controllers, you'll need to pay attention to ingress class settings and selector in the gateway definition (Istio) or in the ingress for each service (traefik or nginx)

*Istio Gateway*
```
spec:
  selector:
    istio: ingressgateway # use Istio default gateway implementation
```
*Traefik example* (https://docs.traefik.io/user-guide/kubernetes/)
```
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: traefik

```

# Some Istio Utilities
`kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=kiali -o jsonpath='{.items[0].metadata.name}') 20001:20001`
`kubectl -n istio-system port-forward $(kubectl -n istio-system get pod -l app=grafana -o jsonpath='{.items[0].metadata.name}') 3000:3000`
If you have Weave installed
`kubectl -n weave port-forward $(kubectl -n weave get pod -l name=weave-scope-app -o jsonpath='{.items[0].metadata.name}') 4040:4040`

## Files
The files for this demo are (mostly) tested. I have run the basic demos on EKS and GCE as well as a "standard" K8S v.1.11.5. But I make no promises.
```
├── README.md
├── check_istio.sh
├── cheese
│   ├── cheese-deployments.yaml
│   ├── cheese-ingress.yaml
│   └── cheese-services.yaml
├── debug_istio.sh
├── demo-full.sh
├── demo-tls-no-sidecar.sh
├── demo-tls.sh
├── demo-web.sh
├── extras
│   ├── dockerio-egress.yaml
│   ├── google-egress.yaml
│   ├── httpbin-egress.yaml
│   └── httpbin-injected.yaml
├── get_ingress.sh
├── httpbin-gateway.yaml
├── httpbin-gw-svc.yaml
├── httpbin-ingress.yaml
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
│   ├── dest-local.yaml
│   ├── dest-rule-bad.yaml
│   ├── dest-rule-permissive.yaml
│   ├── dest-rule-tls.yaml
│   ├── mesh-policy.yaml
│   ├── ns-demo3-rule.yaml
│   ├── ns-policy.yaml
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
├── ssl
│   ├── tls.crt
│   └── tls.key
├── traefik-ui.yaml
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
