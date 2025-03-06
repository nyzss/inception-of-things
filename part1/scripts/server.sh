#!/bin/bash

echo "SERVER_IP: ${SERVER_IP}"
echo "SERVER_WORKER_IP: ${SERVER_WORKER_IP}"

curl -sfL https://get.k3s.io | sh -

chmod 644 /etc/rancher/k3s/k3s.yaml

mkdir -p /vagrant_shared

touch /vagrant_shared/token

cat /var/lib/rancher/k3s/server/token > /vagrant_shared/token

echo "k3s server installed"