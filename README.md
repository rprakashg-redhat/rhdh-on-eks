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
Create a `tools` namespace on the EKS cluster to install Red Hat developer hub

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

Create secrets used in app config for Red Hat developer hub instance. I was playing with OKTA, GITLAB, GITHUB integrations which is why you see secrets for those below

```
 kubectl create secret generic rhdh-secrets \
  -n tools \
  --from-literal=AUTH_OKTA_CLIENT_ID=${AUTH_OKTA_CLIENT_ID} \
--from-literal=AUTH_OKTA_CLIENT_SECRET=${AUTH_OKTA_CLIENT_SECRET} \
--from-literal=AUTH_OKTA_DOMAIN=${AUTH_OKTA_DOMAIN} \
--from-literal=AUTH_OKTA_ADDITIONAL_SCOPES=${AUTH_OKTA_ADDITIONAL_SCOPES} \
--from-literal=GITLAB_TOKEN=${GITLAB_TOKEN} \
--from-literal=GITLAB_APP_APP_ID=${GITLAB_APP_APP_ID} \
--from-literal=GITLAP_APP_CLIENT_ID=${GITLAP_APP_CLIENT_ID} \
--from-literal=GITLAB_APP_CLIENT_SECRET=${GITLAB_APP_CLIENT_SECRET} \
--from-literal=GITHUB_APP_APP_ID=${GITHUB_APP_APP_ID} \
--from-literal=GITHUB_APP_CLIENT_ID=${GITHUB_APP_CLIENT_ID} \
--from-literal=GITHUB_APP_CLIENT_SECRET=${GITHUB_APP_CLIENT_SECRET} \
--from-literal=GITHUB_ORG=${GITHUB_ORG} \
--from-literal=GITHUB_APP_WEBHOOK_URL=${GITHUB_APP_WEBHOOK_URL} \
--from-literal=GITHUB_APP_WEBHOOK_SECRET=${GITHUB_APP_WEBHOOK_SECRET} \
--from-literal=GITHUB_TOKEN=${GITHUB_TOKEN}
```

Create secret from Github private key that was downloaded when you created the app in github

```
kubectl create secret generic -n tools gh-app-key \
--from-file=GITHUB_APP_PRIVATE_KEY="/Users/rgopinat/keys/demo-rhdh.2024-02-26.private-key.pem"
```

## Installing Red Hat Developer Hub

```
helm repo add openshift-helm-charts https://charts.openshift.io/
```

Download the default values yaml file and review them

```
helm show values openshift-helm-charts/redhat-developer-hub > values.yaml
```

Customize the values yaml. You can see version I used for EKS install here -> https://github.com/rprakashg-redhat/rhdh-on-eks/blob/main/deploy/rhdh/values.yaml

Install the Helm Chart

```
helm upgrade --namespace tools -i developer-hub -f values.yaml openshift-helm-charts/redhat-developer-hub
```

