#!/usr/bin/env bash
set -euo pipefail

KYVERNO_VERSION="${KYVERNO_VERSION:-3.3.4}"
KYVERNO_NAMESPACE="${KYVERNO_NAMESPACE:-kyverno}"

helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update kyverno

kubectl create namespace "${KYVERNO_NAMESPACE}" --dry-run=client -o yaml | kubectl apply -f -

helm upgrade --install kyverno kyverno/kyverno \
  --namespace "${KYVERNO_NAMESPACE}" \
  --version "${KYVERNO_VERSION}" \
  --values "$(dirname "$0")/kyverno-values.yaml" \
  --wait

kubectl get pods -n "${KYVERNO_NAMESPACE}"
kubectl get validatingwebhookconfiguration,mutatingwebhookconfiguration | grep kyverno || true
