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
### Add sources in folder (only to create images)
APIPortal demo images
APIM License
apim-env-module-1.1.9.jar
mysql-connector-java-8.0.28.jar

### Push API Portal default image on repository
```
docker load -i Sources/APIPortal_7.7_D
ockerImage_linux-x86-64_BN663.tgz
docker tag axway/apiportal:7.7.20211130-BN663:latest docker-registry.demo.axway.com/demo-public/apim-portal-demo-7.7-20211130:1.0.0
docker push docker-registry.demo.axway.com/demo-public/apim-portal-demo-7.7-20211130:1.0.0
```

### Tools
#### Kubectl

Kubectl client is required for the following steps. The version must be egual to the Kubernetes cluster version.

```
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.23.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
```

#### Istioctl
istioctl is the client to deploy Istio components as gateways.
```
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.13.1 sh -
cd istio-1.13.1
kubectl create namespace istio-system
istioctl install --set profile=minimal -y
```
The disconnected deployment requires an additional option to use a custom repository. This step requires the istio/pilot:1.13.1 Docker image.
```
istioctl install --set profile=minimal -y –set hub=<customer repo>
```

#### Helm
Install the latest helm client:
```
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
```

To add pushing capabilities on a helm repository (optional component):
```
helm plugin install https://github.com/chartmuseum/helm-push
```

### Install External-DNS (automatic generation)
Not required in this context

https://preliminary.istio.io/latest/blog/2019/custom-ingress-gateway/

### Configure cert-manager (automatic generation)
Not required in this context

https://preliminary.istio.io/latest/blog/2019/custom-ingress-gateway/


## Deploy Ingress gateway
### Create namespaces
2 namespaces are required to following the architecture.
```
kubectl create namespace internal
kubectl create namespace external
kubectl label namespace internal istio-injection=enabled
kubectl label namespace external istio-injection=enabled
```

### Deploy Ingress Gateway objects
This architecture requires 4 components one ingress and egress for each zone.
```
cd istio-1.13.1
helm install -n internal istio-ingress-int manifests/charts/gateways/istio-ingress --set "gateways.istio-ingressgateway.name=istio-ingressgateway-int,gateways.istio-ingressgateway.labels.istio=istio-ingressgateway-int,gateways.istio-ingressgateway.serviceAnnotations.service\.beta\.kubernetes\.io/aws-load-balancer-internal=0.0.0.0/0"
helm install -n external istio-ingress-ext manifests/charts/gateways/istio-ingress --set "gateways.istio-ingressgateway.name=istio-ingressgateway-ext,gateways.istio-ingressgateway.labels.istio=istio-ingressgateway-ext"
helm install -n internal istio-egress-int manifests/charts/gateways/istio-egress --set "gateways.istio-egressgateway.name=istio-egressgateway-int,gateways.istio-egressgateway.labels.istio=istio-egressgateway-int"
helm install -n external istio-egress-ext manifests/charts/gateways/istio-egress --set "gateways.istio-egressgateway.name=istio-egressgateway-ext,gateways.istio-egressgateway.labels.istio=istio-egressgateway-ext"
```

The disconnected deployment requires an additional option to use a custom repository. This step requires the istio/proxyv2:1.13.1 Docker image.
```
global.hub=<customer hosts repository>
```

### Configure PV for events
Configure PV by changing the volumeHandle
```
kubectl apply -f Prerequisites/pv-events-aws-internal.yaml
kubectl apply -f Prerequisites/pv-events-aws-external.yaml
```

## Deploy APIM internal group
### Add Docker repository
This Docker repository contains docker images for demo. This step can be ignored if Kubernetes cluster has been configured with a private docker registry.

```
kubectl create secret docker-registry axway-demo-registry \
    --docker-server=docker-registry.demo.axway.com/demo-public \
    --docker-username='robot$poc-sggovt' \
    --docker-password="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTI2MjMxOTcsImlhdCI6MTY0NDg0NzE5NywiaXNzIjoiaGFyYm9yLXRva2VuLWRlZmF1bHRJc3N1ZXIiLCJpZCI6NTQsInBpZCI6MTYsImFjY2VzcyI6W3siUmVzb3VyY2UiOiIvcHJvamVjdC8xNi9yZXBvc2l0b3J5IiwiQWN0aW9uIjoicHVsbCIsIkVmZmVjdCI6IiJ9LHsiUmVzb3VyY2UiOiIvcHJvamVjdC8xNi9oZWxtLWNoYXJ0IiwiQWN0aW9uIjoicmVhZCIsIkVmZmVjdCI6IiJ9XX0.Ch8Z_hdZac0n-XAjMOTl388bk8inmPfmh_cDySkVGXQ8m5k5mms71unj0kJ431fMWsfaa6bGzoxgQ9snMK0w0vZ92kqoRxMNd5woR_JZ9hvgEUTUBZrQj1DRMjqCd0Wtm2ePaEBm5oAaJhYjRrKZWtPcwV6Z2zI9AAV0ptUSZtrxPXQnSvWix5QTeh56nyWgNbUiq9nHtX6P2eTKQTKEp2l1ztBSGVylYaKnqJSH0C__RkaWqLN6F7XNuzmJQLUxoEplonCIJfOZgS1CcchkHCqFC4EOQu-T3q25p7oD-WySHpmHklH-N6sLbNR2ggZKdAm521rw9fEZewyEJFdbobGF1PAWw_wFFwfBb7RoS-OaGllxalyoe2GfyzW5IfcLKVyziKu3-SQlJ56KqZd2WrBwSxzUruxOYYCccmy5jGAHwayi5HCfqzQUzktWEPCvYRLqHsCjM3cs5xws-MO3d1sy-2MSvGWuRIa2ALa_9DldWs5zc-jOs8ghd3-kcnGLDK78e5bBjZJC5d3KDupGcaZ1aTJs5klZNtRySnq2OFSXLJSwbbF3kAxutLE2wCY1sX-dx0SVJpLfjlDA4haoCzGHdwHOr93e087APsTMymG1rEEdq7WmIfc77CWrSWMSK1ke-7haWDEu9lmtGiD9uwB2ZQfoxRJLu0n0B3nmWe0" \
    --docker-email=demo@axway.com -n internal
```

Results : 
secret/axway-demo-registry created

### Create Certs secrets
Create secrets for internal access
```
kubectl create secret generic anm-ingress-cert --from-file="Certs/anm-int/privkey.pem" --from-file="Certs/anm-int/chain.pem" --from-file="Certs/anm-int/cert.pem" -n internal
kubectl create secret generic manager-ingress-cert --from-file="Certs/manager-int/privkey.pem" --from-file="Certs/manager-int/chain.pem" --from-file="Certs/manager-int/cert.pem" -n internal
kubectl create secret generic traffic-ingress-cert --from-file="Certs/traffic-int/privkey.pem" --from-file="Certs/traffic-int/chain.pem" --from-file="Certs/traffic-int/cert.pem" -n internal
```

### Deploy Internal components
Change the following parameters on examples sg-govt-deployment-external.yaml and sg-govt-deployment-internal.yaml:
- Domainname
- anm-internal-ingress

```
helm install apim-demo-int Helmchart/ -n internal -f Deployment/sg-govt-deployment-internal.yaml
```

## Deploy APIM external group
### Add Docker repository
This Docker repository contains docker images for demo. This step can be ignored if Kubernetes cluster has been configured with a private docker registry.

```
kubectl create secret docker-registry axway-demo-registry \
    --docker-server=docker-registry.demo.axway.com/demo-public \
    --docker-username='robot$demo-internal' \
    --docker-password="eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTM2ODYzODQsImlhdCI6MTY0NTkxMDM4NCwiaXNzIjoiaGFyYm9yLXRva2VuLWRlZmF1bHRJc3N1ZXIiLCJpZCI6NTksInBpZCI6MTYsImFjY2VzcyI6W3siUmVzb3VyY2UiOiIvcHJvamVjdC8xNi9yZXBvc2l0b3J5IiwiQWN0aW9uIjoicHVsbCIsIkVmZmVjdCI6IiJ9LHsiUmVzb3VyY2UiOiIvcHJvamVjdC8xNi9oZWxtLWNoYXJ0IiwiQWN0aW9uIjoicmVhZCIsIkVmZmVjdCI6IiJ9XX0.whe87WXZi4U_C7WUlhojR5JTEsvSzU--2IetqUY7L7IkPMqi1aR1-V5AFdM73lhfLYl-eiH5XqxnjhYUmNfR2oIdkZIuq-XQADsv4yJzibcRluIv_EFAmqIme2zQBSYltV5HqNyuURMOpwWgrvSsCaUKV-pCt3tc5JmbSDzYqfY3uf4ZqrZwD72tz0qG7JT7ijgBYRF8nB8Lfzh5QngUKbp-X8_cwSRVDLYsDJcIH958JUJ5n5-7KlOfN_1mPvfk8a712idSm9SqLkpa1sYsp-YmwmVfXlJwfxZMPBWn85w2VTB5ibyPBiw8rStnSCK6FdLbFj9v_uVd0bFKow51xCZ7Ej8vXfGsesxa6Yh54tFFyn5yOQkEIzXnPOT2Qb5sNl9R0Ubd0RCcP78tBl9_RYJFvl3dYQDCkESx3l-IMkjJnRWA07BjFqeWZe9nDSeltuW24uWrDhP1hTZcofIOjO3YiG_QFYdCJZTqe_LNkb0vt8eGP6e44lBeHRJfM4quxU1tTgZRp8GHEj0CHCloOG-Wh3BNtAWJWP0slEnUZ5yMk7mcvCQRsHX9w5pkC0KYBD9RcqhotiB70lgYh3jqkzR0_QwrHE_ERDjrbIUGjyb18fmCdsp8jlloLecHfJEVd3gi3Gsav3OcAeYp9mF-b7-HUpUckypcSJBdvYjaJg4" \
    --docker-email=demo@axway.com -n external
```

Results : 
secret/axway-demo-registry created

### Create Certs secrets
Rename the apiportal pem certs to cert and key format. The following naming is mandatory.
```
cp Certs/portal-ext/privkey.pem Certs/portal-ext/apache.key
openssl x509 -outform der -in Certs/portal-ext/cert.pem -out Certs/portal-ext/apache.crt
```


Create secrets for ingress access
```
kubectl create secret generic portal-ingress-cert --from-file="Certs/portal-ext/apache.key" --from-file="Certs/portal-ext/apache.crt" -n external
kubectl create secret generic manager-ingress-cert --from-file="Certs/manager-ext/privkey.pem" --from-file="Certs/manager-ext/chain.pem" --from-file="Certs/manager-ext/cert.pem" -n external
kubectl create secret generic traffic-ingress-cert --from-file="Certs/traffic-ext/privkey.pem" --from-file="Certs/traffic-ext/chain.pem" --from-file="Certs/traffic-ext/cert.pem" -n external
```

Create secret for mysql user password. The value must be the same than the internal deployment.
```
kubectl create secret generic mysqlmetrics --from-literal=mysql-password='changeme' -n external
```

### Deploy External components

```
helm install apim-demo-ext Helmchart/ -n external -f Deployment/sg-govt-deployment-external.yaml
```








## Deploy Analytics components
### Customize values


### Deploy Helmchart
Edit file 



helm install -n apim-demo-elk -f Deployment/sg-govt-deployment-elk.yaml https://github.com/Axway-API-Management-Plus/apigateway-openlogging-elk/releases/download/v4.1.0/helm-chart-apim4elastic-v4.1.0.tgz -n internal


Note : List of all values is here : https://github.com/Axway-API-Management-Plus/apigateway-openlogging-elk/blob/develop/helm/values.yaml


## Post Deployment step
### API Portal configuration
The basic demo images isn't compatible with multiple api-manager configuration. The easiest way is to connect on the Joomla Administrator interface and then deploying it.


## Support
### Ingress gateway debug log
istioctl proxy-config log istio-ingressgateway-int-548495f848-nh2sv -n internal  --level=info



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

Istio installation : https://preliminary.istio.io/latest/docs/setup/additional-setup/gateway/#dedicated-application-gateway
ELK stack deployment : https://github.com/Axway-API-Management-Plus/apigateway-openlogging-elk
APIM Helmchart : https://github.com/Axway/Cloud-Automation/tree/master/APIM/Helmchart
Externalization : https://github.com/Axway-API-Management-Plus/apim-password-cert-env