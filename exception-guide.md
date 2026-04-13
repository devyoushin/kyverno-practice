# Kyverno PolicyException 가이드

**PolicyException**은 특정 리소스를 Kyverno 정책에서 예외 처리합니다.
정책 자체를 수정하지 않고, 예외 대상만 별도로 선언합니다.

---

## 사용 시점

- 클러스터 시스템 컴포넌트(kube-system, monitoring 등)가 보안 정책을 위반할 때
- 레거시 워크로드를 즉시 수정하기 어려울 때 임시 예외 처리
- 팀별로 정책 예외를 요청/승인하는 워크플로우 구현

---

## PolicyException 활성화

Kyverno 1.11부터 기본 비활성화 상태입니다. Helm으로 활성화합니다.

```bash
helm upgrade kyverno kyverno/kyverno \
  --namespace kyverno \
  --set features.policyExceptions.enabled=true \
  --set features.policyExceptions.namespace=kyverno  # Exception을 허용할 네임스페이스
```

---

## PolicyException 작성

### 예시: 특정 Deployment를 정책에서 제외

```yaml
apiVersion: kyverno.io/v2alpha1
kind: PolicyException
metadata:
  name: allow-legacy-app
  namespace: kyverno       # Exception은 반드시 허용된 네임스페이스에 생성
spec:
  exceptions:
    - policyName: require-resource-limits    # 예외 적용할 정책 이름
      ruleNames:
        - check-resource-limits              # 예외 적용할 Rule 이름
  match:
    any:
    - resources:
        kinds:
          - Pod
        namespaces:
          - legacy
        names:
          - "legacy-app-*"                   # legacy-app- 으로 시작하는 Pod
```

---

## 여러 정책에 동시 예외 처리

```yaml
apiVersion: kyverno.io/v2alpha1
kind: PolicyException
metadata:
  name: system-workload-exceptions
  namespace: kyverno
spec:
  exceptions:
    - policyName: require-labels
      ruleNames:
        - check-app-label
    - policyName: disallow-latest-tag
      ruleNames:
        - check-image-tag
    - policyName: require-resource-limits
      ruleNames:
        - check-resource-limits
  match:
    any:
    - resources:
        kinds:
          - Pod
          - Deployment
        namespaces:
          - monitoring
          - logging
```

---

## 임시 예외 (만료일 설정)

```yaml
apiVersion: kyverno.io/v2alpha1
kind: PolicyException
metadata:
  name: temporary-exception
  namespace: kyverno
  annotations:
    kyverno.io/expires: "2024-12-31T23:59:59Z"    # 만료 날짜 어노테이션 (문서화 목적)
spec:
  exceptions:
    - policyName: require-resource-limits
      ruleNames:
        - check-resource-limits
  match:
    any:
    - resources:
        kinds:
          - Pod
        namespaces:
          - migration-team
```

> Kyverno 자체 만료 기능은 없습니다. 만료일은 어노테이션으로 문서화하고, 운영 절차로 관리하거나 `cleanupPolicy`로 자동 삭제를 설정하세요.

---

## exclude vs PolicyException 비교

| 구분 | `exclude` (정책 내 작성) | `PolicyException` |
|------|------------------------|-------------------|
| 위치 | ClusterPolicy spec 내부 | 별도 리소스 |
| 관리 주체 | 정책 작성자 | 네임스페이스 팀 (권한 위임 가능) |
| 감사 추적 | git diff로 추적 | 별도 오브젝트 이력 |
| 유연성 | 정책 수정 필요 | 독립적으로 생성/삭제 |
| 권장 시점 | 전역적이고 영구적인 제외 | 팀별·임시 예외 |

---

## PolicyException 확인

```bash
# 등록된 예외 목록
kubectl get policyexception -n kyverno

# 특정 예외 상세
kubectl describe policyexception allow-legacy-app -n kyverno

# 예외가 적용되고 있는지 이벤트 확인
kubectl get events -n kyverno | grep PolicyException
```

---

## 참고

- [공식 문서 — PolicyException](https://kyverno.io/docs/writing-policies/exceptions/)
