#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # no color

DOCKER_GPG_KEY_PATH="/etc/apt/keyrings/docker.asc"
HOSTNAME=$(hostname)
USERNAME=$(whoami)

print_section() {
  echo -e "\n${BLUE}==>${NC} ${CYAN}$1${NC}"
}

# success message
print_success() {
  echo -e "${GREEN}✓${NC} $1"
}

# info message
print_info() {
  echo -e "${YELLOW}i${NC} $1"
}

# error message
print_error() {
  echo -e "${RED}✗${NC} $1"
}

# check if command was successful
check_success() {
  if [ $? -eq 0 ]; then
    print_success "$1"
  else
    print_error "$2"
    return 1
  fi
}

print_section "Starting VM initialization for host: ${HOSTNAME}"
print_info "Running as user: ${USERNAME}"

print_section "Updating system packages"
sudo apt-get update
check_success "Package lists updated" "Failed to update package lists"

sudo apt-get upgrade -y
check_success "Packages upgraded" "Failed to upgrade packages"

print_section "Configuring SSH"
sudo apt-get install -y openssh-server
check_success "SSH server installed" "Failed to install SSH server"

sudo systemctl enable ssh --now
check_success "SSH service started and enabled" "Failed to start/enable SSH service"

print_section "Configuring firewall"
sudo apt-get install -y ufw
check_success "UFW installed" "Failed to install UFW"

sudo ufw allow ssh
check_success "SSH allowed through firewall" "Failed to allow SSH through firewall"

sudo ufw allow http
sudo ufw allow https
check_success "HTTP/HTTPS allowed through firewall" "Failed to allow HTTP/HTTPS through firewall"

sudo ufw allow 6443/tcp
check_success "Kubernetes API server port allowed" "Failed to allow Kubernetes API server port"

sudo ufw allow 8080/tcp
check_success "ArgoCD port allowed" "Failed to allow ArgoCD port"

sudo ufw --force enable
check_success "Firewall enabled" "Failed to enable firewall"

print_section "Installing Docker"

sudo apt-get install -y ca-certificates curl gnupg
check_success "Docker dependencies installed" "Failed to install Docker dependencies"

sudo install -m 0755 -d /etc/apt/keyrings
check_success "Keyring directory created" "Failed to create keyring directory"

sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o ${DOCKER_GPG_KEY_PATH}
sudo chmod a+r ${DOCKER_GPG_KEY_PATH}
check_success "Docker GPG key added" "Failed to add Docker GPG key"

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=${DOCKER_GPG_KEY_PATH}] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
check_success "Docker repository added" "Failed to add Docker repository"

sudo apt-get update
check_success "Package lists updated with Docker repository" "Failed to update package lists"

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
check_success "Docker installed" "Failed to install Docker"

sudo usermod -aG docker ${USERNAME}
# newgrp docker
check_success "User ${USERNAME} added to docker group" "Failed to add user to docker group"

print_info "Testing Docker installation... just printing some info"
docker info
check_success "Docker test successful" "Docker test failed"

# Install kubectl
print_section "Installing kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$(dpkg --print-architecture)/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl
check_success "kubectl installed" "Failed to install kubectl"

print_section "Installing k3d"
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
check_success "k3d installed" "Failed to install k3d"

mkdir -p ~/.kube
check_success "Kubectl config directory created" "Failed to create kubectl config directory"

print_section "Installing additional tools"
sudo apt-get install -y jq git
check_success "Additional tools installed" "Failed to install additional tools"

print_section "VM initialization complete"
print_info "Docker and k3d are now installed"
print_info "The system is prepared for Kubernetes workloads"
print_info "Remember to log out and back in for Docker permissions to take effect"

print_section "Next steps"
print_info "1. Log out and log back in for Docker permissions"
print_info "2. Create a k3d cluster: k3d cluster create my-cluster"
print_info "3. Verify installation: kubectl get nodes"

print_section "VM Information"
echo -e "${YELLOW}Hostname:${NC} $(hostname)"
echo -e "${YELLOW}IP Address:${NC} $(hostname -I | awk '{print $1}')"
echo -e "${YELLOW}Docker Version:${NC} $(docker version --format '{{.Server.Version}}' 2>/dev/null || echo 'Not available until after logout/login')"
echo -e "${YELLOW}K3d Version:${NC} $(k3d version 2>/dev/null | grep k3d | awk '{print $3}' || echo 'Not available')"
echo -e "${YELLOW}Firewall Status:${NC}\n$(sudo ufw status | grep -v '^Status')"

echo -e "\n${GREEN}==>${NC} ${CYAN}You can now deploy Kubernetes applications on this VM.${NC}"
echo -e "${GREEN}==>${NC} ${CYAN}Run 'k3d cluster create' to create your first cluster.${NC}"
