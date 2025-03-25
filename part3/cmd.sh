#!/bin/bash

curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

# # vm password n stuff
# # nyzs
# # password123
#### https://devops.stackexchange.com/questions/16043/error-error-loading-config-file-etc-rancher-k3s-k3s-yaml-open-etc-rancher

# export KUBECONFIG=~/.kube/config

# mkdir ~/.kube 2> /dev/null
# sudo k3s kubectl config view --raw > "$KUBECONFIG"
# chmod 600 "$KUBECONFIG"

# kubectl create namespace argocd
# kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
# kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

####! old # kubectl port-forward svc/argocd-server -n argocd 8080:443
#? detach this?
# kubectl port-forward svc/argocd-server -n argocd 8080:443 --address 0.0.0.0 &

#? ON AMD64 (school computer)
# curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
# sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
# rm argocd-linux-amd64

# #? ON ARM64 (macbook / personal computer)
# curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
# sudo install -m 555 argocd-linux-arm64 /usr/local/bin/argocd
# rm argocd-linux-arm64

# ? mkdir -p ~/.argo-data

# ? get password
# argocd admin initial-password -n argocd > ~/.argo-data/argocd-password.txt

# PASSWORD=$(cat ~/.argo-data/argocd-password.txt)

# ? argocd login
# argocd login 127.0.0.1:8080 --insecure --username admin --password $PASSWORD



