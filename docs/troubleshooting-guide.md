# Kyverno 트러블슈팅 가이드

---

## 1. 정책이 적용되지 않는 경우

### 증상
정책을 `kubectl apply`했는데 위반하는 Pod가 생성됩니다.

### 원인 및 해결

**1) validationFailureAction이 Audit인지 확인**

```bash
kubectl get clusterpolicy <policy-name> -o jsonpath='{.spec.validationFailureAction}'
# Audit → 차단하지 않음, Enforce로 변경 필요
```

**2) match 조건이 리소스와 일치하는지 확인**

```bash
# 특정 리소스에 어떤 정책이 적용되는지 확인
kubectl get pod <pod-name> -o yaml | grep -A5 labels

# 정책의 match 조건 확인
kubectl describe clusterpolicy <policy-name>
```

**3) exclude에 걸린 건 아닌지 확인**

```bash
kubectl get clusterpolicy <policy-name> -o jsonpath='{.spec.rules[*].exclude}'
```

**4) Kyverno Webhook이 정상 동작하는지 확인**

```bash
kubectl get validatingwebhookconfigurations kyverno-resource-validating-webhook-cfg -o yaml | grep failurePolicy
# failurePolicy: Ignore → Kyverno가 오류 시 통과시킴
# failurePolicy: Fail   → Kyverno가 오류 시 차단
```

---

## 2. PolicyReport에 결과가 나오지 않는 경우

### 증상
정책을 적용했지만 `kubectl get policyreport`에 아무것도 없습니다.

### 원인 및 해결

**1) background: false인지 확인**

```bash
kubectl get clusterpolicy <policy-name> -o jsonpath='{.spec.background}'
# false → 기존 리소스 스캔 안 함. true로 변경 필요
```

**2) Reports Controller 상태 확인**

```bash
kubectl get pods -n kyverno | grep reports
kubectl logs -n kyverno -l app.kubernetes.io/component=reports-controller --tail=50
```

**3) 리소스가 생성된 뒤 스캔 완료까지 시간이 걸릴 수 있음**

```bash
# 강제 재스캔: 정책을 잠깐 touch
kubectl annotate clusterpolicy <policy-name> kyverno.io/last-applied-at=$(date -u +%Y-%m-%dT%H:%M:%SZ) --overwrite
```

---

## 3. Pod 생성이 차단되는 이유를 모를 때

### 증상
`kubectl run test --image=nginx` 실행 시 에러가 나는데 메시지가 불명확합니다.

### 해결

```bash
# 에러 메시지 전문 확인 (kubectl describe 대신 -v=8 사용)
kubectl run test --image=nginx -v=8 2>&1 | grep "admission webhook"

# Kyverno 로그에서 차단 상세 확인
kubectl logs -n kyverno -l app.kubernetes.io/component=admission-controller --tail=100 | grep -i "deny\|block\|fail"

# 특정 리소스에 어떤 정책이 걸리는지 확인 (kyverno CLI)
kyverno apply policies/ --resource <your-pod.yaml> --detailed-results
```

---

## 4. Mutate Rule이 적용되지 않는 경우

### 증상
정책을 적용했지만 Pod에 레이블이 자동으로 추가되지 않습니다.

### 원인 및 해결

**1) Mutate Rule은 기존 리소스에 자동 적용되지 않음**

Mutate Rule은 기본적으로 **새로 생성되는** 리소스에만 적용됩니다.

```bash
# 기존 Pod 삭제 후 재생성으로 확인
kubectl delete pod <pod-name>
kubectl run <pod-name> --image=nginx
kubectl get pod <pod-name> --show-labels
```

**2) Mutating Webhook 확인**

```bash
kubectl get mutatingwebhookconfigurations kyverno-resource-mutating-webhook-cfg -o yaml
```

**3) 다른 Mutating Webhook과 충돌**

Istio sidecar injector 등 다른 Webhook이 먼저 실행되어 충돌하는 경우:

```bash
kubectl get mutatingwebhookconfigurations
# 여러 Webhook의 순서 확인 (reinvocationPolicy: IfNeeded 확인)
```

---

## 5. Generate Rule이 동작하지 않는 경우

### 증상
네임스페이스를 생성했지만 NetworkPolicy가 자동 생성되지 않습니다.

### 원인 및 해결

**1) Background Controller 상태 확인**

```bash
kubectl get pods -n kyverno | grep background
kubectl logs -n kyverno -l app.kubernetes.io/component=background-controller --tail=50
```

**2) GenerateRequest 오브젝트 확인**

```bash
kubectl get generaterequests -n kyverno
kubectl describe generaterequest <name> -n kyverno
# Status.Message 에서 오류 원인 확인
```

**3) RBAC 권한 확인**

Kyverno Background Controller가 대상 리소스를 생성할 권한이 있는지 확인합니다.

```bash
kubectl auth can-i create networkpolicies \
  --as=system:serviceaccount:kyverno:kyverno-background-controller \
  -n test-namespace
```

---

## 6. 자주 발생하는 오류

### `Internal error occurred: failed calling webhook`

Kyverno Pod가 다운되었을 때 `failurePolicy: Fail`이면 모든 리소스 생성이 차단됩니다.

```bash
# Kyverno Pod 상태 확인
kubectl get pods -n kyverno

# 임시 해결: failurePolicy를 Ignore로 변경 (운영 중 Kyverno 재시작 시)
kubectl patch validatingwebhookconfiguration kyverno-resource-validating-webhook-cfg \
  --type=json \
  -p='[{"op":"replace","path":"/webhooks/0/failurePolicy","value":"Ignore"}]'
```

### `resource not found` in Generate Rule

generate 타겟 리소스의 API 버전이 잘못된 경우:

```bash
# 올바른 apiVersion 확인
kubectl api-resources | grep networkpolicies
# networking.k8s.io/v1
```

### PolicyReport가 계속 `fail`인데 리소스가 정상인 경우

stale PolicyReport가 남아있을 수 있습니다. 정책을 재적용하거나 Reports Controller를 재시작합니다.

```bash
kubectl rollout restart deployment kyverno-reports-controller -n kyverno
```

---

## 유용한 디버깅 명령어 모음

```bash
# Kyverno 전체 컴포넌트 상태 한 번에 확인
kubectl get pods -n kyverno -o wide

# 모든 정책 상태 한 번에 확인
kubectl get clusterpolicy -o wide

# 클러스터 전체 정책 위반 요약
kubectl get clusterpolicyreport -o json | jq '.items[] | {name: .metadata.name, pass: .summary.pass, fail: .summary.fail}'

# 네임스페이스별 위반 요약
kubectl get policyreport -A -o json | jq '.items[] | {ns: .metadata.namespace, fail: .summary.fail} | select(.fail > 0)'

# Kyverno 전체 이벤트 최신순 확인
kubectl get events -n kyverno --sort-by='.lastTimestamp' | tail -20
```

---

## 참고

- [Kyverno 트러블슈팅 공식 문서](https://kyverno.io/docs/troubleshooting/)
- [Kyverno GitHub Issues](https://github.com/kyverno/kyverno/issues)
