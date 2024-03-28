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
Check if load balancer provisioned successfully in AWS. 

```
kubectl describe service haproxy-ingress -n haproxy-controller
```

## create namespace 
Create a `tools` namespace on the EKS cluster to install Red Hat developer hub

```
kubectl create namespace tools
```

## Create red hat pull secret
Lets now create a red hat pull secret from the downloaded `pull-secret.txt` file from https://console.redhat.com/openshift/downloads

```
kubectl create secret generic rhdh-pull-secret \
  -n tools \
  --from-file=.dockerconfigjson=pull-secret.txt \
  --type=kubernetes.io/dockerconfigjson
```
Patch the  default service account to be able to pull images from redhat registries

```
kubectl patch sa default -n tools -p '{"imagePullSecrets": [{"name": "rhdh-pull-secret"}]}'
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
--from-literal=GITLAB_APP_CLIENT_ID=${GITLAB_APP_CLIENT_ID} \
--from-literal=GITLAB_APP_CLIENT_SECRET=${GITLAB_APP_CLIENT_SECRET} \
--from-literal=GITHUB_APP_APP_ID=${GITHUB_APP_APP_ID} \
--from-literal=GITHUB_APP_CLIENT_ID=${GITHUB_APP_CLIENT_ID} \
--from-literal=GITHUB_APP_CLIENT_SECRET=${GITHUB_APP_CLIENT_SECRET} \
--from-literal=GITHUB_ORG=${GITHUB_ORG} \
--from-literal=GITHUB_APP_WEBHOOK_URL=${GITHUB_APP_WEBHOOK_URL} \
--from-literal=GITHUB_APP_WEBHOOK_SECRET=${GITHUB_APP_WEBHOOK_SECRET} \
--from-literal=GITHUB_TOKEN=${GITHUB_TOKEN} \
--from-literal=TECHDOCS_AWS_ACCOUNT_ID=${BACKSTAGE_AWS_ACCOUNT_ID} \
--from-literal=AWS_ACCESS_KEY_ID=${BACKSTAGE_AWS_ACCESS_KEY_ID} \
--from-literal=AWS_SECRET_ACCESS_KEY=${BACKSTAGE_AWS_SECRET_ACCESS_KEY} \
--from-literal=TECHDOCS_AWSS3_BUCKET_NAME=${TECHDOCS_AWSS3_BUCKET_NAME} \
--from-literal=TECHDOCS_AWSS3_BUCKET_URL=${TECHDOCS_AWSS3_BUCKET_URL} \
--from-literal=AWS_REGION=${AWS_REGION} \
--from-literal=EKS_CLUSTER_URL=${EKS_CLUSTER_URL} \
--from-literal=EKS_CLUSTER_NAME=${EKS_CLUSTER_NAME} \
--from-literal=BACKSTAGE_ROLE_ARN_TO_ASSUME=${BACKSTAGE_ROLE_ARN_TO_ASSUME} \
--from-literal=AWS_EXTERNAL_ID=${AWS_EXTERNAL_ID} \
--from-literal=EKS_SA_TOKEN=${EKS_SA_TOKEN} \
--from-literal=ARGOCD_USER_ID=${ARGOCD_USER_ID} \
--from-literal=ARGOCD_USER_PWD=${ARGOCD_USER_PWD} \
--from-literal=AWS_RDS_POSTGRESQL_HOST=${AWS_RDS_POSTGRESQL_HOST} \
--from-literal=AWS_RDS_POSTGRESQL_PORT=${AWS_RDS_POSTGRESQL_PORT} \
--from-literal=AWS_RDS_POSTGRESQL_USER=${AWS_RDS_POSTGRESQL_USER} \
--from-literal=AWS_RDS_POSTGRESQL_PASSWORD=${AWS_RDS_POSTGRESQL_PASSWORD} \
--from-literal=AUTH_OKTA_SECRET=${AUTH_OKTA_SECRET}
```

Create secret from Github private key that was downloaded when you created the app in github

```
kubectl create secret generic -n tools gh-app-key \
--from-file=GITHUB_APP_PRIVATE_KEY="/Users/rgopinat/keys/demo-rhdh.2024-02-26.private-key.pem"
```

Create developer hub app config configmap. You can find the app config configmap I used here
https://github.com/rprakashg-redhat/rhdh-on-eks/blob/main/deploy/rhdh/developer-hub-appconfig.yaml

```
kubectl apply -f deploy/rhdh/developer-hub-appconfig.yaml
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



TechDocs

AWS S3 policy that grants permission to publish to bucket

```
{
	"Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "ListObjectsInBucket",
			"Effect": "Allow",
			"Action": [
				"s3:ListBucket",
				"s3:DeleteObjectVersion",
				"s3:PutObjectAcl"
			],
			"Resource": [
				"arn:aws:s3:::techdocs-devhub"
			]
		},
		{
			"Sid": "AllObjectActions",
			"Effect": "Allow",
			"Action": "s3:*Object",
			"Resource": [
				"arn:aws:s3:::techdocs-devhub/*"
			]
		}
	]
}
```

Kubernetes plugin configuration

Download the EKS CA certificate from console and save to a file and create a kubernetes secret

```
kubectl create secret generic -n tools eks-ca-data \
--from-file=EKS_CA_DATA=eks-ca.txt
```

Get the control plane endpoint by running command below or from AWS console and set it in local.env file as EKS_CLUSTER_URL

```
kubectl cluster-info
```

Create service account for backstage

```
kubectl create serviceaccount devhub-sa -n tools
```

Create secret for Service account token

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: devhub-sa-token
  namespace: tools
  annotations:
    kubernetes.io/service-account.name: devhub-sa
type: kubernetes.io/service-account-token
EOF
```

Create a readonly cluster role
```
cat <<EOF | kubectl apply -f -
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: backstage-read-only
rules:
  - apiGroups:
      - '*'
    resources:
      - pods
      - configmaps
      - services
      - deployments
      - replicasets
      - horizontalpodautoscalers
      - ingresses
      - statefulsets
      - limitranges
      - resourcequotas
      - daemonsets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - batch
    resources:
      - jobs
      - cronjobs
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - metrics.k8s.io
    resources:
      - pods
    verbs:
      - get
      - list
  - apiGroups: 
      - tekton.dev
    resources: 
      - tasks
      - clustertasks 
      - taskruns 
      - pipelines
      - pipelineruns
      - customruns"
      - stepactions
    verbs: ["get", "list", "watch"]
  - apiGroups:
      - route.openshift.io
    resources:
      - routes
    verbs: ["get", "list", "watch"] 
EOF
```

Bind the readonly role to service account

```
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: backstage-read-only
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: backstage-read-only
subjects:
- kind: ServiceAccount
  name: devhub-sa
  namespace: tools
EOF

```

Get SA Token

```
kubectl get secret -n tools devhub-sa-token -o jsonpath="{.data.token}" | base64 -d | pbcopy
```


Create a GHCR image pull secret

```
kubectl create secret docker-registry ghcr-creds \
-n demos --docker-server https://ghcr.io --docker-username=rprakashg-redhat --docker-password=${GHCR_TOKEN} \
--docker-email=rgopinat@redhat.com
```


