#!/bin/bash
# Brings up a local single-node Kubernetes cluster via Minikube
# and applies the manifests in ./manifests.
#
# NOTE: do not run as root -- minikube refuses the docker driver under root.
# The invoking user must be in the `docker` group.

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$SCRIPT_DIR/../lib/common.sh"
source "$SCRIPT_DIR/../lib/deps.sh"

MANIFESTS=$SCRIPT_DIR/manifests

if ! docker ps >/dev/null 2>&1; then
    die "current user can't talk to Docker -- add yourself to the docker group:
    sudo usermod -aG docker \$USER
then log out, log back in, and re-run this script"
fi

log "installing minikube and kubectl (if missing)"
install_minikube_binary
install_kubectl_binary

log "starting cluster"
minikube start --driver=docker

# Let the control plane finish coming up before applying manifests.
sleep 20

log "applying manifests"
kubectl apply -f "$MANIFESTS/nginx-pod.yaml"
kubectl apply -f "$MANIFESTS/nginx-service.yaml"
kubectl apply -f "$MANIFESTS/busybox-deployment.yaml"

# Give the scheduler a moment before we list everything.
sleep 5

echo
echo "Pods:";        kubectl get pods
echo
echo "Services:";    kubectl get services
echo
echo "Deployments:"; kubectl get deployments
