## Get the argocd password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

## Forward the argocd port to local
kubectl port-forward svc/argocd-server -n argocd 8080:443

## Forward the argocd-rollouts-dasvhboard port to local
kubectl port-forward svc/argo-rollout-argo-rollouts-dashboard -n argo-rollouts 8081:3100