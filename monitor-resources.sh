#!/bin/bash

echo "Real-time Resource Monitoring"
echo "================================"

while true; do
  clear
  echo "$(date)"
  echo ""
  
  echo "MINIKUBE STATUS:"
  minikube status
  echo ""
  
  echo "NODE RESOURCES:"
  kubectl top nodes 2>/dev/null || echo "Metrics not ready yet..."
  echo ""
  
  echo " POD RESOURCES:"
  kubectl top pods --all-namespaces 2>/dev/null || echo "Metrics not ready yet..."
  echo ""
  
  echo "POD STATUS:"
  kubectl get pods --all-namespaces | grep -E "(Running|Pending|Error|CrashLoopBackOff)"
  echo ""
  
  echo " DOCKER DISK USAGE:"
  docker system df
  echo ""
  
  echo " Press Ctrl+C to stop monitoring"
  sleep 10
done