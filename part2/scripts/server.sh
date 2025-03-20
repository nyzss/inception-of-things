#!/bin/bash

echo "SERVER_IP: ${SERVER_IP}"

# sh -s - --node-ip 192.168.56.110
# curl -sfL https://get.k3s.io | sh -s - --node-ip ${SERVER_IP}
curl -sfL https://get.k3s.io | sh -s - --node-external-ip ${SERVER_IP}

chmod 644 /etc/rancher/k3s/k3s.yaml

echo "k3s server installed"

kubectl apply -f /vagrant_deployments/app1-deployments.yaml
kubectl apply -f /vagrant_deployments/app2-deployments.yaml
kubectl apply -f /vagrant_deployments/app3-deployment.yaml

kubectl get pods

kubectl apply -f /vagrant_services/app1-service.yaml
kubectl apply -f /vagrant_services/app2-service.yaml
kubectl apply -f /vagrant_services/app3-service.yaml

kubectl get services

kubectl apply -f /vagrant_ingress/ingress.yaml

kubectl get ingress

