# Helm으로 Kyverno 설치

## 1. 사전 준비
---

```bash
# 필요 도구 확인
kubectl version --client    # >= 1.25
helm version                # >= 3.10

# EKS 클러스터 연결 확인
kubectl get nodes
```

---

## 2. Helm Repository 추가
---

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
```

---

## 3. Kyverno 설치
---

### 기본 설치 (단일 레플리카 — 개발/테스트용)

```bash
kubectl create namespace kyverno

helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --version 3.2.x
```

### HA 설치 (운영 권장 — 레플리카 3개)

```bash
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --version 3.2.x \
  --set admissionController.replicas=3 \
  --set backgroundController.replicas=2 \
  --set cleanupController.replicas=2 \
  --set reportsController.replicas=2
```

---

## 4. 설치 확인
---

```bash
# Pod 상태 확인
kubectl get pods -n kyverno

# CRD 설치 확인
kubectl get crd | grep kyverno

# Webhook 등록 확인
kubectl get validatingwebhookconfigurations | grep kyverno
kubectl get mutatingwebhookconfigurations | grep kyverno
```

정상 출력 예시:
```
NAME                                         READY   STATUS    RESTARTS   AGE
kyverno-admission-controller-xxxx            1/1     Running   0          1m
kyverno-background-controller-xxxx           1/1     Running   0          1m
kyverno-cleanup-controller-xxxx              1/1     Running   0          1m
kyverno-reports-controller-xxxx              1/1     Running   0          1m
```

---

## 5. 주요 설치 옵션
---

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| `admissionController.replicas` | Admission Controller 레플리카 수 | `1` |
| `backgroundController.replicas` | Background Controller 레플리카 수 | `1` |
| `config.resourceFilters` | Kyverno가 무시할 리소스 패턴 | 기본 제외 목록 |
| `webhooksCleanup.enable` | 삭제 시 Webhook 자동 정리 | `true` |
| `policyExceptions.enabled` | PolicyException 기능 활성화 | `false` |

---

## 6. Kyverno Policy Reporter (선택)
---

정책 위반 현황을 UI로 확인하려면 Policy Reporter를 함께 설치합니다.

```bash
helm repo add policy-reporter https://kyverno.github.io/policy-reporter
helm repo update

helm install policy-reporter policy-reporter/policy-reporter \
  --namespace policy-reporter \
  --create-namespace \
  --set ui.enabled=true \
  --set kyvernoPlugin.enabled=true

# UI 접근
kubectl port-forward svc/policy-reporter-ui 8082:8080 -n policy-reporter
# http://localhost:8082
```

---

## 7. 업그레이드 및 제거
---

```bash
# 업그레이드
helm upgrade kyverno kyverno/kyverno \
  --namespace kyverno \
  --version 3.2.x

# 제거
helm uninstall kyverno -n kyverno
kubectl delete namespace kyverno

# CRD 제거 (선택 — 정책 데이터도 함께 삭제됨)
kubectl get crd | grep kyverno | awk '{print $1}' | xargs kubectl delete crd
```

> **주의**: CRD를 삭제하면 모든 ClusterPolicy, Policy, PolicyReport가 함께 삭제됩니다. 운영 환경에서는 신중하게 진행하세요.
