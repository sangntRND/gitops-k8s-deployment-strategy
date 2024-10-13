#!/bin/bash

# Create the cluster with name personal-kind-cluster via kind if it doesn't exist
if [ $(kind get clusters | grep -c "personal-kind-cluster") -eq 0 ]; then
  # Find the file path to see where it is in the source code
  FILE_PATH=$(find . -name "kind-config.yaml")
  kind create cluster --name personal-kind-cluster --config $FILE_PATH
fi
# Change the k8s kubecontext 
kubectl config use-context kind-personal-kind-cluster

# Set Namespace variables
ARGOCD_NAMESPACE="argocd"
ROLLOUTS_NAMESPACE="argo-rollouts"

# Check if ArgoCD is already installed
ARGOCD_EXISTS=$(kubectl get deployments -n $ARGOCD_NAMESPACE -l app.kubernetes.io/name=argocd-server -o name | wc -l)

if [ $ARGOCD_EXISTS -eq 0 ]; then
  # ArgoCD doesn't exist, proceed with installation

  # Add the ArgoCD Helm repository
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update

  # Create Argo CD namespace if it doesn't exist
  kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

  # Install ArgoCD using Helm with the values file
  FILE_PATH=$(find . -name "argocd-values.yaml")
  helm upgrade --install argocd argo/argo-cd \
    --namespace $ARGOCD_NAMESPACE \
    -f $FILE_PATH

  # Optional: Wait for Argo CD to be fully deployed
  echo "Waiting for Argo CD components to be deployed..."
  kubectl wait --for=condition=available --timeout=600s deployment --all -n $ARGOCD_NAMESPACE

  echo "Argo CD has been successfully installed in namespace $ARGOCD_NAMESPACE"
else
  echo "ArgoCD is already installed in namespace $ARGOCD_NAMESPACE"
fi

# Check if Argo Rollouts is already installed
ROLLOUTS_EXISTS=$(kubectl get deployments -n $ROLLOUTS_NAMESPACE -l app.kubernetes.io/name=argo-rollouts -o name | wc -l)

if [ $ROLLOUTS_EXISTS -eq 0 ]; then
  # Argo Rollouts doesn't exist, proceed with installation

  NAMESPACE_EXISTS=$(kubectl get ns | grep $ROLLOUTS_NAMESPACE | wc -l)

  # Create Argo Rollouts namespace if it doesn't exist
  if [ $NAMESPACE_EXISTS -eq 0 ]; then
    kubectl create namespace $ROLLOUTS_NAMESPACE
  fi

  # Install Argo Rollouts
  helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update

  # Find the file path for argo-rollouts-values.yaml
  ROLLOUTS_VALUES_PATH=$(find . -name "argo-rollouts-values.yaml")

  # Install Argo Rollouts using the custom values file
  helm upgrade --install argo-rollouts argo/argo-rollouts \
    -n $ROLLOUTS_NAMESPACE \
    -f $ROLLOUTS_VALUES_PATH

  brew install argoproj/tap/kubectl-argo-rollouts

  # Optional: Wait for Argo Rollouts to be fully deployed
  echo "Waiting for Argo Rollouts components to be deployed..."
  kubectl wait --for=condition=available --timeout=600s deployment --all -n $ROLLOUTS_NAMESPACE

  echo "Argo Rollouts has been successfully installed in namespace $ROLLOUTS_NAMESPACE"
else
  echo "Argo Rollouts is already installed in namespace $ROLLOUTS_NAMESPACE"
fi

# Check if NGINX Ingress Controller is already installed
NGINX_NAMESPACE="ingress-nginx"
NGINX_EXISTS=$(kubectl get deployments -n $NGINX_NAMESPACE -l app.kubernetes.io/name=ingress-nginx-controller -o name | wc -l)

if [ $NGINX_EXISTS -eq 0 ]; then
  # NGINX Ingress Controller doesn't exist, proceed with installation

  # Create NGINX namespace if it doesn't exist
  kubectl create namespace $NGINX_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

  # Install NGINX Ingress Controller
  NGINX_INSTALL_FILE_PATH=$(find . -name "nginx-deploy.yaml")
  kubectl apply -f $NGINX_INSTALL_FILE_PATH

  echo "NGINX Ingress Controller has been successfully installed in namespace $NGINX_NAMESPACE"
else
  echo "NGINX Ingress Controller is already installed in namespace $NGINX_NAMESPACE"
fi

# Apply the ServiceMonitor
NGINX_SM_FILE_PATH=$(find . -name "nginx-service-monitor.yaml")
kubectl apply -f $NGINX_SM_FILE_PATH

echo "ServiceMonitor for NGINX Ingress Controller has been created"

# Check if Prometheus Stack is already installed
PROMETHEUS_NAMESPACE="monitoring"
PROMETHEUS_EXISTS=$(kubectl get deployments -n $PROMETHEUS_NAMESPACE -l app.kubernetes.io/name=prometheus -o name | wc -l)

if [ $PROMETHEUS_EXISTS -eq 0 ]; then
  # Prometheus Stack doesn't exist, proceed with installation

  # Create Prometheus namespace if it doesn't exist
  kubectl create namespace $PROMETHEUS_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

  # Add the Prometheus community Helm repository
  helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
  helm repo update

  # Find the file path for prometheus-stack-values.yaml
  PROMETHEUS_VALUES_PATH=$(find . -name "prometheus-stack-values.yaml")

  # Install Prometheus Stack using Helm with the values file
  helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
    --namespace $PROMETHEUS_NAMESPACE \
    -f $PROMETHEUS_VALUES_PATH

  echo "Prometheus Stack has been successfully installed in namespace $PROMETHEUS_NAMESPACE"
else
  echo "Prometheus Stack is already installed in namespace $PROMETHEUS_NAMESPACE"
fi
