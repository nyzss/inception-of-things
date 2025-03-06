#!/bin/bash

echo "Installing k3s worker"

echo "SERVER_IP: ${SERVER_IP}"
echo "SERVER_WORKER_IP: ${SERVER_WORKER_IP}"

TOKEN=$(cat /vagrant_shared/token)

curl -sfL https://get.k3s.io | K3S_URL=https://${SERVER_IP}:6443 K3S_TOKEN=${TOKEN} sh -

echo "k3s worker installed"
