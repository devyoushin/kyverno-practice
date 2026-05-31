#!/usr/bin/env bash
set -euo pipefail

TARGET_VERSION="${TARGET_VERSION:?set TARGET_VERSION}"
KYVERNO_NAMESPACE="${KYVERNO_NAMESPACE:-kyverno}"

kubectl get policy,clusterpolicy -A
kubectl get pods -n "${KYVERNO_NAMESPACE}"

helm repo update kyverno
helm upgrade kyverno kyverno/kyverno \
  --namespace "${KYVERNO_NAMESPACE}" \
  --version "${TARGET_VERSION}" \
  --values "$(dirname "$0")/../install/kyverno-values.yaml" \
  --wait

kubectl rollout status deployment/kyverno-admission-controller -n "${KYVERNO_NAMESPACE}"
kubectl get policyreport,clusterpolicyreport -A
