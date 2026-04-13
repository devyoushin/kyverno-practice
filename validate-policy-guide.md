# Kyverno Validate Policy 가이드

Validate Rule은 리소스가 정책을 준수하는지 검사합니다.
위반 시 `Enforce` 모드에서는 요청을 차단하고, `Audit` 모드에서는 PolicyReport에 기록합니다.

---

## 검증 방식 3가지

| 방식 | 설명 | 사용 시점 |
|------|------|-----------|
| `pattern` | 리소스 필드가 패턴과 일치하는지 검사 | 필드 존재 여부, 값 범위 검증 |
| `deny` | 조건 표현식이 참이면 거부 | 복잡한 조건, 여러 필드 교차 검증 |
| `cel` | CEL(Common Expression Language) 표현식 | 고급 조건 — Kubernetes 1.26+ |

---

## 1. pattern 방식

필드 값을 패턴으로 검증합니다.

### 예시: app 레이블 필수 요구

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-app-label
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-app-label
      match:
        any:
        - resources:
            kinds:
              - Pod
      validate:
        message: "Pod에는 반드시 'app' 레이블이 있어야 합니다."
        pattern:
          metadata:
            labels:
              app: "?*"    # ?* : 1자 이상의 임의 문자열
```

### 패턴 와일드카드

| 패턴 | 의미 |
|------|------|
| `"?*"` | 1자 이상 임의 문자열 (필드가 존재하고 비어있지 않음) |
| `"*"` | 임의 문자열 (빈 문자열 포함) |
| `"!latest"` | "latest"가 아닌 값 |
| `">=1 & <=10"` | 1 이상 10 이하 |

### 예시: resource limits 필수 요구

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-resource-limits
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-resource-limits
      match:
        any:
        - resources:
            kinds:
              - Pod
      validate:
        message: "모든 컨테이너에 CPU/Memory limits를 설정해야 합니다."
        pattern:
          spec:
            containers:
              - (name): "*"
                resources:
                  limits:
                    memory: "?*"
                    cpu: "?*"
```

---

## 2. deny 방식

CEL 또는 JMESPath 조건이 참이면 요청을 거부합니다.

### 예시: latest 태그 금지

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-latest-tag
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-image-tag
      match:
        any:
        - resources:
            kinds:
              - Pod
      validate:
        message: "latest 태그 또는 태그 없는 이미지 사용이 금지됩니다."
        deny:
          conditions:
            any:
            - key: "{{ request.object.spec.containers[].image }}"
              operator: AnyIn
              value:
                - "*:latest"
                - "*/latest"
```

### 예시: privileged 컨테이너 금지

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: disallow-privileged
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-privileged
      match:
        any:
        - resources:
            kinds:
              - Pod
      validate:
        message: "privileged 컨테이너는 허용되지 않습니다."
        pattern:
          spec:
            containers:
              - =(securityContext):    # = : 필드가 존재할 때만 검사
                  =(privileged): "false | null"
```

---

## 3. Audit 모드로 기존 리소스 위반 파악

```yaml
spec:
  validationFailureAction: Audit    # 차단하지 않고 기록만
  background: true                  # 기존 리소스도 검사
```

```bash
# 위반 리포트 확인
kubectl get policyreport -n default -o wide

# 위반 상세 내용
kubectl describe policyreport -n default

# 위반된 리소스 목록만 추출
kubectl get policyreport -n default -o json \
  | jq '.items[].results[] | select(.result=="fail") | .resources[].name'
```

---

## 실습: 정책 적용 후 검증

```bash
# 1. 정책 적용
kubectl apply -f policies/validate/require-labels.yaml

# 2. 위반하는 Pod 생성 시도
kubectl run test-pod --image=nginx
# Error: admission webhook "validate.kyverno.svc" denied the request:
# Pod에는 반드시 'app' 레이블이 있어야 합니다.

# 3. 정책을 준수하는 Pod 생성
kubectl run test-pod --image=nginx --labels="app=test"
# pod/test-pod created

# 4. 정책 상태 확인
kubectl get clusterpolicy require-app-label
```

---

## 참고

- [공식 문서 — Validate](https://kyverno.io/docs/writing-policies/validate/)
- [Kyverno JMESPath 레퍼런스](https://kyverno.io/docs/writing-policies/jmespath/)
