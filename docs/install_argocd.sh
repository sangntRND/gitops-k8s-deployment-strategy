#!/bin/bash

# Change the k8s kubecontext 
kubectl config use-context kind-personal-kind-cluster

# Set Namespace variables
ARGOCD_NAMESPACE="argocd"
ROLLOUTS_NAMESPACE="argo-rollouts"

# Check if ArgoCD is already installed
ARGOCD_EXISTS=$(kubectl get deployments -n $ARGOCD_NAMESPACE -l app.kubernetes.io/name=argocd-server -o name | wc -l)

if [ $ARGOCD_EXISTS -eq 0 ]; then
  # ArgoCD doesn't exist, proceed with installation

  NAMESPACE_EXISTS=$(kubectl get ns | grep $ARGOCD_NAMESPACE | wc -l)

  # Create Argo CD namespace if it doesn't exist
  if [ $NAMESPACE_EXISTS -eq 0 ]; then
    kubectl create namespace $ARGOCD_NAMESPACE
  fi

  # Install Argo CD
  kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

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
  helm upgrade --install argo-rollout argo/argo-rollouts --set dashboard.enabled=true -n $ROLLOUTS_NAMESPACE

  brew install argoproj/tap/kubectl-argo-rollouts
  # Optional: Wait for Argo Rollouts to be fully deployed
  echo "Waiting for Argo Rollouts components to be deployed..."
  kubectl wait --for=condition=available --timeout=600s deployment --all -n $ROLLOUTS_NAMESPACE

  echo "Argo Rollouts has been successfully installed in namespace $ROLLOUTS_NAMESPACE"
else
  echo "Argo Rollouts is already installed in namespace $ROLLOUTS_NAMESPACE"
fi
