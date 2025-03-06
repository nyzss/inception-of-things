#!/bin/bash

echo "SERVER_IP: ${SERVER_IP}"

curl -sfL https://get.k3s.io | sh -

chmod 644 /etc/rancher/k3s/k3s.yaml

echo "k3s server installed"