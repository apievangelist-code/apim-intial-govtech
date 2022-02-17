# APIM deployment on EKS with Istio Ingress Gateway

## Limits
### TLS Terminaison
It's not possible to configure the Ingress Gateway as a TLS terminaison like other ingress. 
Envoy proxy translates HTTP1.1 requests in HTTP2 protocol. HTTP2 isn't supported by our components.
No solution exists to avoid this translation.

### Kubernetes Ingress
The architecture requires 2 ingress gateway that isn't compatible with usage of Kubernetes ingress object. According the Istio documentation, it's not possible to configure multiple Ingress class.
The Axway Helmchart is compatible to use Ingress class.


## Prerequisites
### Client tools
#### Kubectl 


#### Istioctl
istioctl is the client to deploy Istio components as gateways.
```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.8 TARGET_ARCH=x86_64 sh -
cd istio-1.12.2
export PATH=$PWD/bin:$PATH
```

#### Helm



## Configure PV

Configure PV by changing the volumeHandle
```
kubectl apply -f Prerequisites/pv-events-aws.yaml
```

## Install External-DNS
TO be written

## Install cert-manager (automatic generation)
To be written


## Create namespaces
This architecture required 2 namespaces.
Those namespaces will contains 2 API Gateway groups.

```
kubectl create namespace ingress-internal
kubectl create namespace ingress-external
kubectl create namespace internal
kubectl create namespace external
kubectl label namespace internal istio-injection=enabled
kubectl label namespace external istio-injection=enabled
```

### Deploy ingress gateway
The following config file contains both ingress gateway controller.
```
istioctl operator init
kubectl apply -f APIM/istio-op-internal.yaml
kubectl apply -f APIM/istio-op-external.yaml
```

## Add Docker repository on both Namespaces
This Docker repository contains docker images for demo. This step can be ignored if Kubernetes cluster has been configured with a private docker registry.

```
kubectl create secret docker-registry axway-demo-registry \
    --docker-server=docker-registry.demo.axway.com/demo-public \
    --docker-username='robot$poc-sggovt' \
    --docker-password="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTI2MjMxOTcsImlhdCI6MTY0NDg0NzE5NywiaXNzIjoiaGFyYm9yLXRva2VuLWRlZmF1bHRJc3N1ZXIiLCJpZCI6NTQsInBpZCI6MTYsImFjY2VzcyI6W3siUmVzb3VyY2UiOiIvcHJvamVjdC8xNi9yZXBvc2l0b3J5IiwiQWN0aW9uIjoicHVsbCIsIkVmZmVjdCI6IiJ9LHsiUmVzb3VyY2UiOiIvcHJvamVjdC8xNi9oZWxtLWNoYXJ0IiwiQWN0aW9uIjoicmVhZCIsIkVmZmVjdCI6IiJ9XX0.Ch8Z_hdZac0n-XAjMOTl388bk8inmPfmh_cDySkVGXQ8m5k5mms71unj0kJ431fMWsfaa6bGzoxgQ9snMK0w0vZ92kqoRxMNd5woR_JZ9hvgEUTUBZrQj1DRMjqCd0Wtm2ePaEBm5oAaJhYjRrKZWtPcwV6Z2zI9AAV0ptUSZtrxPXQnSvWix5QTeh56nyWgNbUiq9nHtX6P2eTKQTKEp2l1ztBSGVylYaKnqJSH0C__RkaWqLN6F7XNuzmJQLUxoEplonCIJfOZgS1CcchkHCqFC4EOQu-T3q25p7oD-WySHpmHklH-N6sLbNR2ggZKdAm521rw9fEZewyEJFdbobGF1PAWw_wFFwfBb7RoS-OaGllxalyoe2GfyzW5IfcLKVyziKu3-SQlJ56KqZd2WrBwSxzUruxOYYCccmy5jGAHwayi5HCfqzQUzktWEPCvYRLqHsCjM3cs5xws-MO3d1sy-2MSvGWuRIa2ALa_9DldWs5zc-jOs8ghd3-kcnGLDK78e5bBjZJC5d3KDupGcaZ1aTJs5klZNtRySnq2OFSXLJSwbbF3kAxutLE2wCY1sX-dx0SVJpLfjlDA4haoCzGHdwHOr93e087APsTMymG1rEEdq7WmIfc77CWrSWMSK1ke-7haWDEu9lmtGiD9uwB2ZQfoxRJLu0n0B3nmWe0" \
    --docker-email=demo@axway.com -n internal
kubectl create secret docker-registry axway-demo-registry \
    --docker-server=docker-registry.demo.axway.com/demo-public \
    --docker-username='robot$poc-sggovt' \
    --docker-password="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTI2MjMxOTcsImlhdCI6MTY0NDg0NzE5NywiaXNzIjoiaGFyYm9yLXRva2VuLWRlZmF1bHRJc3N1ZXIiLCJpZCI6NTQsInBpZCI6MTYsImFjY2VzcyI6W3siUmVzb3VyY2UiOiIvcHJvamVjdC8xNi9yZXBvc2l0b3J5IiwiQWN0aW9uIjoicHVsbCIsIkVmZmVjdCI6IiJ9LHsiUmVzb3VyY2UiOiIvcHJvamVjdC8xNi9oZWxtLWNoYXJ0IiwiQWN0aW9uIjoicmVhZCIsIkVmZmVjdCI6IiJ9XX0.Ch8Z_hdZac0n-XAjMOTl388bk8inmPfmh_cDySkVGXQ8m5k5mms71unj0kJ431fMWsfaa6bGzoxgQ9snMK0w0vZ92kqoRxMNd5woR_JZ9hvgEUTUBZrQj1DRMjqCd0Wtm2ePaEBm5oAaJhYjRrKZWtPcwV6Z2zI9AAV0ptUSZtrxPXQnSvWix5QTeh56nyWgNbUiq9nHtX6P2eTKQTKEp2l1ztBSGVylYaKnqJSH0C__RkaWqLN6F7XNuzmJQLUxoEplonCIJfOZgS1CcchkHCqFC4EOQu-T3q25p7oD-WySHpmHklH-N6sLbNR2ggZKdAm521rw9fEZewyEJFdbobGF1PAWw_wFFwfBb7RoS-OaGllxalyoe2GfyzW5IfcLKVyziKu3-SQlJ56KqZd2WrBwSxzUruxOYYCccmy5jGAHwayi5HCfqzQUzktWEPCvYRLqHsCjM3cs5xws-MO3d1sy-2MSvGWuRIa2ALa_9DldWs5zc-jOs8ghd3-kcnGLDK78e5bBjZJC5d3KDupGcaZ1aTJs5klZNtRySnq2OFSXLJSwbbF3kAxutLE2wCY1sX-dx0SVJpLfjlDA4haoCzGHdwHOr93e087APsTMymG1rEEdq7WmIfc77CWrSWMSK1ke-7haWDEu9lmtGiD9uwB2ZQfoxRJLu0n0B3nmWe0" \
    --docker-email=demo@axway.com -n external
```

Results : 
secret/axway-demo-registry created

### Create Certs secrets
Create secrets for internal access
```
kubectl create secret generic anm-ingress-cert --from-file="Certs/anm-int/privkey.pem" --from-file="Certs/anm-int/chain.pem" --from-file="Certs/anm-int/cert.pem" -n internal
kubectl create secret generic manager-ingress-cert --from-file="Certs/manager-int/privkey.pem" --from-file="Certs/manager-int/fullchain.pem" -n internal
kubectl create secret generic traffic-ingress-cert --from-file="Certs/traffic-int/privkey.pem" --from-file="Certs/traffic-int/fullchain.pem" -n internal
```

Create secrets for external access
```
kubectl create secret generic anm-ingress-cert --from-file="Certs/anm-int/privkey.pem" --from-file="Certs/anm-int/fullchain.pem" -n internal
kubectl create secret generic manager-ingress-cert --from-file="Certs/manager-int/privkey.pem" --from-file="Certs/manager-int/fullchain.pem" -n internal
kubectl create secret generic traffic-ingress-cert --from-file="Certs/traffic-int/privkey.pem" --from-file="Certs/traffic-int/fullchain.pem" -n internal
```


### Create PV for events (EKS only)
```
kubectl apply -f Prerequisites/pv-events-aws.yaml
```

### Deploy Internal components
Change the following parameters on examples sg-govt-deployment-external.yaml and sg-govt-deployment-internal.yaml:
- Domainname
- anm-internal-ingress

```
helm install apim-demo-int Helmchart/ -n internal -f Deployment/sg-govt-deployment-internal.yaml
```

### Deploy External components


```
helm install apim-demo-ext Helmchart/ -n external -f Deployment/sg-govt-deployment-external.yaml
```

### Deploy Ingress Gateway objects

```
kubectl apply -f Deployment/ingress-gateway-istio-internal.yaml
kubectl apply -f Deployment/ingress-gateway-istio-external.yaml

```

## Support
### Ingress gateway debug log
istioctl proxy-config log istio-ingressgateway-int-548495f848-nh2sv -n internal  --level=info


## Deploy analytics components
This solution is based on ELK stacks.





### Customize deployment

#### Change namespace name



#### Changeporu





### Uninstall
#### APIM
helm uninstall apim-demo-int -n internal
helm uninstall apim-demo-ext -n external

#### Istio
Remove Operator
```
istioctl operator remove -n istio-system
```

Delete CRD
```
kubectl get crds | grep 'istio.io' |   xargs -n1 -I{} sh -c "kubectl delete crd {}"
```

#### Delete resources


### Sources

Istio installation : 
ELK stack deployment : https://github.com/Axway-API-Management-Plus/apigateway-openlogging-elk
APIM Helmchart : https://github.com/Axway/Cloud-Automation/tree/master/APIM/Helmchart
Externalization : https://github.com/Axway-API-Management-Plus/apim-password-cert-env