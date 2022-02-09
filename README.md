# Prerequisites


## Product versions
Istio version 1.6.8


# Connect to AWS cluster


## Install cert-manager
To be written

## Install External-DNS
TO be written


## Create namespaces
```
kubectl create namespace external
kubectl create namespace internal
```

## Add Docker repository on both Namespaces
This Docker repository contains docker images for demo. This step can be ignored if Kubernetes cluster has been configured with a private docker registry.

```
kubectl create secret docker-registry axway-demo-registry \
    --docker-server=axwayproductsdemo.azurecr.io \
    --docker-username=apim-demo \
    --docker-password=3mL3FoB8Pb/lqIWZwmaf3oYV2zKr0W68 \
    --docker-email=demo@axway.com -n external
```
```
kubectl create secret docker-registry axway-demo-registry \
    --docker-server=axwayproductsdemo.azurecr.io \
    --docker-username=apim-demo \
    --docker-password=3mL3FoB8Pb/lqIWZwmaf3oYV2zKr0W68 \
    --docker-email=demo@axway.com -n internal
```

Results : 
secret/axway-demo-registry created

## Install Istio ingress Gateway
### Install Istio ingress gateway
curl -L https://istio.io/downloadIstio | ISTIO_VERSION=1.6.8 TARGET_ARCH=x86_64 sh -
cd istio-1.12.2
export PATH=$PWD/bin:$PATH

Install the default installation
```
istioctl install --set profile=demo
```

### Deploy ingress gateway
The following config file contains both ingress gateway controller.
```
istioctl install -f APIM/istio-op-demo.yaml
```


### Deploy Internal components
Change the following parameters on examples sg-govt-deployment-external.yaml and sg-govt-deployment-internal.yaml:
- Domainname
- anm-internal-ingress

```
helm install apim-demo-int https://github.com/Axway/Cloud-Automation/releases/download/apim-helm-v2.3.0/helm-chart-axway-apim-2.3.0.tgz -n internal -f Deployment/sg-govt-deployment-internal.yaml
```

### Deploy External components


```
helm install apim-demo-ext https://github.com/Axway/Cloud-Automation/releases/download/apim-helm-v2.3.0/helm-chart-axway-apim-2.3.0.tgz -n external -f Deployment/sg-govt-deployment-external.yaml
```

