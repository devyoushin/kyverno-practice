# Kyverno 업그레이드 가이드

Kyverno 업그레이드는 Admission Controller와 Background/Cleanup/Reports Controller, CRD를 함께 갱신합니다. 정책 평가가 클러스터 admission 경로에 영향을 주므로 운영 환경에서는 사전 점검과 롤백 경로를 준비합니다.

## 1. 사전 점검

```bash
export TARGET_VERSION="3.2.7"
export KYVERNO_NAMESPACE="kyverno"

kubectl get policy,clusterpolicy -A
kubectl get policyreport,clusterpolicyreport -A
kubectl get pods -n ${KYVERNO_NAMESPACE}
helm get values kyverno -n ${KYVERNO_NAMESPACE} > kyverno-values-before-upgrade.yaml
```

업그레이드 전에 Kyverno 릴리즈 노트에서 policy schema, exception, webhook 동작 변경을 확인합니다. 차단 정책이 많은 클러스터에서는 테스트 네임스페이스에서 먼저 검증합니다.

## 2. Helm 업그레이드

이 저장소의 실행 스크립트를 사용합니다.

```bash
TARGET_VERSION=${TARGET_VERSION} \
KYVERNO_NAMESPACE=${KYVERNO_NAMESPACE} \
./ops/upgrade/upgrade-kyverno-helm.sh
```

직접 실행하려면 아래 명령을 사용합니다.

```bash
helm repo update kyverno
helm upgrade kyverno kyverno/kyverno \
  --namespace ${KYVERNO_NAMESPACE} \
  --version ${TARGET_VERSION} \
  --values ops/01-installation/kyverno-values.yaml \
  --wait
```

## 3. 업그레이드 확인

```bash
kubectl rollout status deployment/kyverno-admission-controller -n ${KYVERNO_NAMESPACE}
kubectl get pods -n ${KYVERNO_NAMESPACE}
kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations | grep kyverno
kubectl get policyreport,clusterpolicyreport -A
```

정책 검증용 Pod 또는 예제 리소스를 적용해 admission deny/allow 결과가 의도대로 동작하는지 확인합니다.

## 4. 롤백

```bash
helm history kyverno -n ${KYVERNO_NAMESPACE}
helm rollback kyverno <REVISION> -n ${KYVERNO_NAMESPACE} --wait
kubectl rollout status deployment/kyverno-admission-controller -n ${KYVERNO_NAMESPACE}
```

CRD가 갱신된 후에는 이전 버전 controller가 새 필드를 이해하지 못할 수 있습니다. 메이저 버전 변경은 정책 백업과 테스트 클러스터 검증 후 진행합니다.

