## canary

- Install Argo Rollouts
    - kubectl create namespace argo-rollouts
    - kubectl apply -n argo-rollouts -f https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml

    - Install Argo rollouts plugin and enable UI (https://argo-rollouts.readthedocs.io/en/stable/installation/)
        kubectl create ns rollouts
        helm upgrade --install argo-rollout argo/argo-rollouts --set dashboard.enabled=true -n rollouts

- Create namespace
    kubectk create ns argocd
    kubectl create ns rollouts
    kubectl create ns canary
- Install traefik
    helm repo add traefik https://helm.traefik.io/traefik
    helm repo update
    helm upgrade --install traefik --set rbac.enabled=true traefik/traefik -n canary
- Install ArgoCD
    helm repo add argo https://argoproj.github.io/argo-helm
    helm repo update
    helm upgrade --install argocd argo/argo-cd --set server.service.type=LoadBalancer -n argocd


- Deploy
    kubectl apply -f https://raw.githubusercontent.com/LocTaRND/argocd/main/canary/canary-app-localcluster.yaml

- Monitor:
    kubectl argo rollouts get rollout rollouts-demo --watch -n canary

- Sync:
    - Install Argocd cli:
        curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
        sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
        rm argocd-linux-amd64
    - Kubectl Plugin Installation
        curl -LO https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64
        chmod +x ./kubectl-argo-rollouts-linux-amd64
        sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
        kubectl argo rollouts version
        
    - Argocd login
        argocd login 4.236.203.118
            user:
            password:
    - ArgoCd sync
        argocd app list
        argocd app sync argocd/canary
    - Promote
        kubectl argo rollouts promote rollouts-demo -n canary


https://medium0.com/@imacq/argo-rollouts-quick-guide-canary-deployments-3973db254b37


## BlueGreen

- Deploy
    kubectl apply -f https://raw.githubusercontent.com/LocTaRND/argocd/main/bluegreen/bluegreen.yaml

    argocd app sync argocd/bluegreen

    kubectl argo rollouts get rollout bluegreen-demo --watch -n bluegreen


    https://devopsvn.tech/kubernetes-practice/automating-bluegreen-deployment-with-argo-rollouts


