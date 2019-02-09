# Running Ambassador with Istio

The integration is well documented at https://www.getambassador.io/user-guide/with-istio/#getting-ambassador-working-with-istio

## Annotations
Ambassador integrates using annotations in the service

```
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v1
      kind: TracingService
      name: tracing
      service: "zipkin.istio-system:9411"
      driver: zipkin
      config: {}
```

## Deploy inside demo

Make sure Ambassador is installed - see above

I then use default for the examples. WARNING: Only tested on GKE

Add these annotations to the svc or rewrite the service completely if you need to change ports.

```
---
##################################################################################################
# Ambassador httpbin service
##################################################################################################
apiVersion: v1
kind: Service
metadata:
  name: httpbin
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v1
      kind:  Mapping
      name:  httpbin_mapping
      prefix: /httpbin/
      service: httpbin.org:80
      host_rewrite: httpbin.org
spec:
  ports:
  - name: httpbin
    port: 80
```

`kubectl apply -f ambassador/httpbin.yaml`

Similarly, the bookinfo sample adds the following.
```
  annotations:
    getambassador.io/config: |
      ---
      apiVersion: ambassador/v1
      kind: Mapping
      name: productpage_mapping
      prefix: /productpage/
      rewrite: /productpage
      service: productpage:9080
```
