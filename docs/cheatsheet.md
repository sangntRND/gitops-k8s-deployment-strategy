## Get the argocd password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

kubectl argo rollouts get rollout canary-demo --watch -n canary
