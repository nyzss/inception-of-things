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
# kubectl port-forward svc/argocd-server -n argocd 8080:443

#? ON AMD64
# argocd-linux-arm64

# curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
# sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
# rm argocd-linux-amd64

# #? ON ARM64
# curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
# sudo install -m 555 argocd-linux-arm64 /usr/local/bin/argocd
# rm argocd-linux-arm64
