#!/bin/bash

##############################################################################
# K3s Setup Test Utility.
# A utility script for deploying test workloads.
# Usage: ./k3s-deploy-test.sh
##############################################################################

set -e # Exit on error

source ./tools/shell/utils/logger.sh

# Configuration
NAMESPACE="test-ns"
DEPLOYMENT="nginx"
IMAGE="nginx"
SERVICE_PORT=80
CONTAINER_PORT=80
SERVICE_TYPE="LoadBalancer"
TIMEOUT=30

wait_for_deployment() {
  local ns=$1
  local deployment=$2
  log_info "Waiting for deployment '$deployment' to be ready..."

  kubectl rollout status deployment/"$deployment" -n "$ns" --timeout=${TIMEOUT}s || {
    log_error "Deployment failed to reach ready state"
    return 1
  }
}

# Main procedure
main() {
  log_info "Starting k3s test procedure..."

  log_info "Creating namespace '$NAMESPACE'..."
  kubectl create namespace $NAMESPACE
  log_success "Namespace created"

  log_info "Listing namespaces..."
  kubectl get namespaces

  log_info "Creating deployment '$DEPLOYMENT' in namespace '$NAMESPACE'..."
  kubectl -n $NAMESPACE create deployment $DEPLOYMENT --image=$IMAGE
  log_success "Deployment created"

  log_info "Listing deployments..."
  kubectl -n $NAMESPACE get deployments

  wait_for_deployment $NAMESPACE $DEPLOYMENT
  log_info "Listing pods..."
  kubectl -n $NAMESPACE get pods
  log_success "Pod is running"

  log_info "Exposing deployment as service..."
  kubectl -n $NAMESPACE expose deployment $DEPLOYMENT \
    --port=$SERVICE_PORT \
    --target-port=$CONTAINER_PORT \
    --type=$SERVICE_TYPE
  log_success "Service created"

  log_info "Listing services..."
  kubectl -n $NAMESPACE get svc

  log_info "Waiting for service to get external IP (this may take a moment)..."
  sleep 3

  SERVICE_IP=$(kubectl -n $NAMESPACE get svc $DEPLOYMENT -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")

  if [ -z "$SERVICE_IP" ]; then
    log_info "External IP not assigned (normal for local clusters). Using port forwarding instead..."
    log_info "You can test with: kubectl -n $NAMESPACE port-forward svc/$DEPLOYMENT 8080:$SERVICE_PORT"
  else
    log_info "Testing service at http://$SERVICE_IP:$SERVICE_PORT..."
    curl -s http://"$SERVICE_IP":"$SERVICE_PORT" | head -n 20
  fi

  log_success "Test phase complete. Services are running."

  read -r -p "Press Enter to cleanup resources, or Ctrl+C to keep them running..."
  cleanup
}

# Removes resources deployed for testing.
cleanup() {
  log_info "Starting cleanup..."

  log_info "Deleting service..."
  kubectl -n $NAMESPACE delete svc $DEPLOYMENT || true

  log_info "Deleting deployment..."
  kubectl -n $NAMESPACE delete deployment $DEPLOYMENT || true

  log_info "Deleting namespace..."
  kubectl delete namespace $NAMESPACE || true

  log_success "Cleanup complete"
}

# Trap to ensure cleanup on script interrupt
trap cleanup EXIT INT TERM

# Run main procedure
main
