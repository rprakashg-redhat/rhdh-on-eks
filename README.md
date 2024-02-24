## Deploy Cluster
Deploy EKS cluster

```
terraform init
terraform plan
terraform apply --var "name=toolscluster"
```

## Install HAProxy ingress controller

Add the HAPProxy helm repo

```
helm repo add haproxytech https://haproxytech.github.io/helm-charts
```

Update helm chart lists

```
helm repo update
```

Install HAProxy ingress controller

```
helm install haproxy-kubernetes-ingress haproxytech/kubernetes-ingress \
  --create-namespace \
  --namespace haproxy-controller \
  --set controller.service.type=LoadBalancer
```

## create namespace 
Create a `developer-hub` namespace on the EKS cluster to install Red Hat developer hub

```
kubectl create namespace developer-hub
```

## Create red hat pull secret
Lets now create a red hat pull secret from the downloaded `pull-secret.txt` file from https://console.redhat.com/openshift/downloads

```
kubectl create secret generic rhdh-pull-secret \
  -n tools \
  --from-file=.dockerconfigjson=pull-secret.txt \
  --type=kubernetes.io/dockerconfigjson

```

## Create required secrets and app config configmap


## Installing Red Hat Developer Hub

```
helm repo add openshift-helm-charts https://charts.openshift.io/
```

Download the default values yaml file and review them

```
helm show values openshift-helm-charts/redhat-developer-hub > values.yaml
```

Install the Helm Chart

```
helm upgrade --namespace tools -i developer-hub -f values.yaml openshift-helm-charts/redhat-developer-hub
```

