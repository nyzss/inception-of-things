#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # no color

set -e

ARGOCD_NAMESPACE="argocd"
APP_NAMESPACE="dev"
ARGOCD_PORT="8080"
GITHUB_REPO="https://github.com/nyzss/iot_test_deploy.git"
CPU_ARCH=$(dpkg --print-architecture)
USERNAME=$(whoami)

print_section() {
  echo -e "\n${BLUE}==>${NC} ${CYAN}$1${NC}"
}

print_log() {
  echo -e "${GREEN}[LOG] $1${NC}\n"
}

print_info() {
  echo -e "${YELLOW}[INFO] $1${NC}\n"
}

print_section "Creating K3d cluster"
if ! k3d cluster list | grep -q "${USERNAME}"; then
  print_log "Creating new K3d cluster named '${USERNAME}'..."
  k3d cluster create ${USERNAME} --servers 1 --agents 2 --wait
else
  print_info "Cluster '${USERNAME}' already exists, using it"
fi

print_log "Setting up kubeconfig..."
k3d kubeconfig merge ${USERNAME} --kubeconfig-switch-context

print_section "Creating namespaces"
kubectl create namespace $ARGOCD_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace $APP_NAMESPACE --dry-run=client -o yaml | kubectl apply -f -
print_log "Namespaces created/verified"

print_section "Installing ArgoCD"
print_log "Applying ArgoCD manifests..."
kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# print_info "Waiting for ArgoCD to be ready..."
# kubectl wait --for=condition=available --timeout=180s deployment/argocd-server -n $ARGOCD_NAMESPACE || true
# print_log "ArgoCD installed"

print_section "Exposing ArgoCD server"
print_log "Setting up port-forward for ArgoCD server..."
kubectl patch svc argocd-server -n $ARGOCD_NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'
kubectl port-forward svc/argocd-server -n "$ARGOCD_NAMESPACE" $ARGOCD_PORT:443 --address 0.0.0.0 > /dev/null 2>&1 &
sleep 3
print_log "ArgoCD server exposed on port $ARGOCD_PORT"

print_section "Installing ArgoCD CLI for $CPU_ARCH"

if [[ "$CPU_ARCH" == "arm64" ]]; then
  print_info "Detected ARM64 architecture"
  if ! command -v argocd &> /dev/null; then
    print_log "Installing ArgoCD CLI for ARM64..."
    curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
    sudo install -m 555 argocd-linux-arm64 /usr/local/bin/argocd
    rm argocd-linux-arm64
  else
    print_info "ArgoCD CLI already installed"
  fi
else
  print_info "Detected AMD64 architecture"
  if ! command -v argocd &> /dev/null; then
    print_log "Installing ArgoCD CLI for AMD64..."
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
  else
    print_info "ArgoCD CLI already installed"
  fi
fi

print_section "Retrieving ArgoCD credentials"
print_log "Getting admin password..."

for i in {1..10}; do
  if kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NAMESPACE &>/dev/null; then
    break
  fi
  print_info "Waiting for ArgoCD secret to be created... (attempt $i/10)"
  sleep 5
done

ARGO_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n $ARGOCD_NAMESPACE -o jsonpath="{.data.password}" | base64 --decode)

if [ -z "$ARGO_PASSWORD" ]; then
  print_info "Unable to retrieve ArgoCD password, using default 'admin'"
  ARGO_PASSWORD="admin"
fi

print_section "Logging into ArgoCD"
print_log "Authenticating with ArgoCD..."
argocd login localhost:$ARGOCD_PORT --username admin --password $ARGO_PASSWORD --insecure || true

print_section "Adding repository to ArgoCD"
print_log "Adding Git repository: $GITHUB_REPO"
argocd repo add $GITHUB_REPO --name iot-test-deploy --insecure || true

print_section "Creating ArgoCD application"
print_log "Applying application from app.yaml..."

# argocd app create iot-app \
#   --repo $GITHUB_REPO \
#   --path manifests \
#   --dest-server https://kubernetes.default.svc \
#   --dest-namespace $APP_NAMESPACE \
#   --sync-policy automated \
#   --upsert || true

kubectl apply -f "./app.yaml"
print_log "Application created from app.yaml"

sleep 5

print_section "Verifying deployment"
print_log "Checking application status..."
kubectl get pods -n $APP_NAMESPACE || true

# Get the application name from the app.yaml file
APP_NAME=$(grep "name:" "./app.yaml" | head -1 | awk '{print $2}')
if [ -n "$APP_NAME" ]; then
  print_log "Checking status of application: $APP_NAME"
  argocd app get $APP_NAME || true
else
  print_info "Could not determine application name from app.yaml, skipping status check"
fi

print_section "Setup complete!"
echo -e "${GREEN}ArgoCD is available at:${NC} http://localhost:$ARGOCD_PORT"
echo -e "${GREEN}Username:${NC} admin"
echo -e "${GREEN}Password:${NC} $ARGO_PASSWORD"
echo -e "\n${CYAN}Your application from $GITHUB_REPO is now being deployed by ArgoCD!${NC}"
