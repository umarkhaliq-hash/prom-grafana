#!/bin/bash

echo "🚀 Optimizing Minikube for LGTM Stack..."

# Stop current minikube
minikube stop

# Clean up resources
echo "🧹 Cleaning up Docker..."
docker system prune -f

# Start with optimized resources
echo "⚡ Starting Minikube with optimized settings..."
minikube start \
  --memory=8192 \
  --cpus=4 \
  --disk-size=50g \
  --driver=docker \
  --kubernetes-version=v1.29.0

# Enable required addons
echo "🔧 Enabling addons..."
minikube addons enable metrics-server
minikube addons enable ingress

# Check status
echo "✅ Minikube Status:"
minikube status
kubectl get nodes

echo "🎯 Resource Usage:"
kubectl top nodes

echo "📊 Ready to deploy LGTM stack!"
echo "Run: tk apply environments/dev/lgtm"