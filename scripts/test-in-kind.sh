#!/usr/bin/env bash
# Full local Kubernetes deployment test using kind (Kubernetes-in-Docker).
#
# Builds the real rubra-server Dockerfile, loads it into a throwaway kind
# cluster, installs this chart via Helm, waits for a healthy rollout, and
# port-forwards the service — a genuine end-to-end deploy test with no
# registry and no cloud cluster required.
#
# Requires: docker, kind, helm, kubectl. All three are installed
# automatically inside the rubra-server devcontainer/Codespace.
#
# Usage (from the rubra-deploy repo root):
#   ./scripts/test-in-kind.sh [path-to-rubra-server]
#
# Defaults to ../rubra-server, matching the devcontainer's sibling-clone layout.

set -euo pipefail

SERVER_DIR="${1:-../rubra-server}"
CLUSTER_NAME="rubra-test"
IMAGE_TAG="rubra-server:kind-test"

if [ ! -d "$SERVER_DIR" ]; then
  echo "rubra-server not found at $SERVER_DIR — clone it as a sibling directory or pass its path."
  exit 1
fi

echo "==> Creating kind cluster ($CLUSTER_NAME) if it doesn't exist"
kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$" || kind create cluster --name "$CLUSTER_NAME"

echo "==> Building rubra-server image from $SERVER_DIR"
docker build -t "$IMAGE_TAG" "$SERVER_DIR"

echo "==> Loading image into the kind cluster"
kind load docker-image "$IMAGE_TAG" --name "$CLUSTER_NAME"

echo "==> Installing/upgrading the Helm release"
helm upgrade --install rubra ./helm/rubra \
  --kube-context "kind-${CLUSTER_NAME}" \
  --set image.repository="rubra-server" \
  --set image.tag="kind-test" \
  --set image.pullPolicy=Never \
  --wait --timeout 120s

echo "==> Waiting for the rollout to be healthy"
kubectl --context "kind-${CLUSTER_NAME}" rollout status deployment/rubra --timeout=90s

echo ""
echo "==> Deployed. Port-forwarding http://localhost:8000 (Ctrl+C to stop)"
kubectl --context "kind-${CLUSTER_NAME}" port-forward svc/rubra 8000:8000
