#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # no color

ARGOCD_NAMESPACE="argocd"
ARGOCD_PORT="8080"
ARGOCD_HOST="127.0.0.1"
ARGOCD_DATA_DIR="$HOME/.argo-data"
CPU_ARCH=$(dpkg --print-architecture)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_REPO="https://github.com/nyzss/iot_test_deploy.git"

print_section() {
  echo -e "\n${BLUE}==>${NC} ${CYAN}$1${NC}"
}

print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

print_info() {
  echo -e "${YELLOW}i${NC} $1"
}

print_error() {
  echo -e "${RED}✗${NC} $1"
}

check_success() {
  if [ $? -eq 0 ]; then
    print_success "$1"
  else
    print_error "$2"
    return 1
  fi
}

check_dependencies() {
  print_section "Checking dependencies"

  if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install it first."
    exit 1
  fi

  if ! command -v k3d &> /dev/null; then
    print_error "k3d is not installed. Please install it first."
    exit 1
  fi

  print_success "All required dependencies are installed"
}

ensure_cluster() {
  print_section "Ensuring k3d cluster is available"

  if ! k3d cluster list 2>/dev/null | grep -q ".*"; then
    print_info "No k3d cluster found. Creating a new cluster..."
    k3d cluster create argocd-cluster
    check_success "Created new k3d cluster" "Failed to create k3d cluster"
  else
    print_success "k3d cluster is available"
  fi

  # Wait for the cluster to be ready
  print_info "Waiting for the cluster to be ready..."
  kubectl wait --for=condition=Ready nodes --all --timeout=60s
  check_success "Cluster is ready" "Cluster readiness check timed out"
}

# Setup kubeconfig
setup_kubeconfig() {
  print_section "Setting up kubeconfig"

  export KUBECONFIG=~/.kube/config
  mkdir -p ~/.kube 2>/dev/null

  if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    print_info "Using k3s kubeconfig"
    sudo k3s kubectl config view --raw > "$KUBECONFIG"
    sudo chmod 600 "$KUBECONFIG"
    check_success "kubeconfig set up from k3s" "Failed to set up kubeconfig from k3s"
  else
    print_info "Using k3d kubeconfig"
    k3d kubeconfig merge --kubeconfig-switch-context
    check_success "kubeconfig set up from k3d" "Failed to set up kubeconfig from k3d"
  fi
}

install_argocd() {
  print_section "Installing ArgoCD"

  if ! kubectl get namespace $ARGOCD_NAMESPACE &>/dev/null; then
    kubectl create namespace $ARGOCD_NAMESPACE
    check_success "Created ArgoCD namespace" "Failed to create ArgoCD namespace"
  else
    print_info "ArgoCD namespace already exists"
  fi

  print_info "Applying ArgoCD manifests..."
  kubectl apply -n $ARGOCD_NAMESPACE -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
  check_success "ArgoCD manifests applied" "Failed to apply ArgoCD manifests"

  print_info "Configuring ArgoCD server as LoadBalancer..."
  kubectl patch svc argocd-server -n $ARGOCD_NAMESPACE -p '{"spec": {"type": "LoadBalancer"}}'
  check_success "ArgoCD server configured as LoadBalancer" "Failed to configure ArgoCD server"

  print_info "Waiting for ArgoCD components to be ready..."
  kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n $ARGOCD_NAMESPACE
  check_success "ArgoCD is ready" "ArgoCD readiness check timed out"
}

setup_port_forwarding() {
  print_section "Setting up port forwarding"

  if pgrep -f "kubectl port-forward.*$ARGOCD_NAMESPACE" &>/dev/null; then
    print_info "ArgoCD port forwarding is already active"
  else
    print_info "Starting port forwarding on port $ARGOCD_PORT..."
    kubectl port-forward svc/argocd-server -n $ARGOCD_NAMESPACE $ARGOCD_PORT:443 --address 0.0.0.0 &
    check_success "Port forwarding started" "Failed to start port forwarding"

    # sleep to ensure port forwarding is active
    sleep 2
  fi
}

install_argocd_cli() {
  print_section "Installing ArgoCD CLI for $CPU_ARCH"

  # argocd cli installation based on architecture (for school or personal computer)
  if [[ "$CPU_ARCH" == "arm64" ]]; then
    print_info "Detected ARM64 architecture"
    curl -sSL -o argocd-linux-arm64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-arm64
    sudo install -m 555 argocd-linux-arm64 /usr/local/bin/argocd
    rm argocd-linux-arm64
  else
    print_info "Detected AMD64 architecture"
    curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
    sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
    rm argocd-linux-amd64
  fi

  check_success "ArgoCD CLI installed" "Failed to install ArgoCD CLI"
}

get_admin_password() {
  print_section "Getting ArgoCD admin credentials"

  mkdir -p $ARGOCD_DATA_DIR

  print_info "Retrieving admin password..."
  argocd admin initial-password -n $ARGOCD_NAMESPACE > $ARGOCD_DATA_DIR/argocd-password.txt
  check_success "Admin password retrieved and stored at $ARGOCD_DATA_DIR/argocd-password.txt" "Failed to retrieve admin password"

  PASSWORD=$(grep -v "This password will expire" $ARGOCD_DATA_DIR/argocd-password.txt | head -n 1)

  print_info "Logging in to ArgoCD..."
  argocd login $ARGOCD_HOST:$ARGOCD_PORT --insecure --username admin --password "$PASSWORD"
  check_success "Logged in to ArgoCD" "Failed to log in to ArgoCD"
}

setup_application() {
  print_section "Setting up application from repository"

  # wait for argocd to be fully ready
  sleep 1

  print_info "Adding git repository: $GIT_REPO"
  argocd repo add $GIT_REPO --name iot-test-deploy
  check_success "Repository added successfully" "Failed to add repository"

  print_info "Creating application from repository manifests"

  kubectl apply -f ./app.yaml

#   argocd app create iot-app \
#     --repo $GIT_REPO \
#     --path manifests \
#     --dest-server https://kubernetes.default.svc \
#     --dest-namespace default \
#     --sync-policy automated

  check_success "Application created successfully" "Failed to create application"

  print_info "Application setup complete"
}

main() {
  print_section "Starting ArgoCD Setup"

  check_dependencies
  ensure_cluster
  setup_kubeconfig
  install_argocd
  setup_port_forwarding
  install_argocd_cli
  get_admin_password
  setup_application

  print_section "ArgoCD Setup Complete"
  print_info "ArgoCD UI is available at: https://$ARGOCD_HOST:$ARGOCD_PORT"
  print_info "Username: admin"
  print_info "Password is saved at: $ARGOCD_DATA_DIR/argocd-password.txt"
  print_info "Application iot-app has been configured with repository: $GIT_REPO"

  echo -e "\n${GREEN}==>${NC} ${CYAN}Application deployment from $GIT_REPO is now automated!${NC}"
}

main
