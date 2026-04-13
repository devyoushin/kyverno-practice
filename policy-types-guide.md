# Kyverno Policy 종류 가이드

Kyverno의 Policy는 하나 이상의 **Rule**로 구성됩니다.
각 Rule은 `match`로 대상 리소스를 지정하고, `validate` / `mutate` / `generate` / `verifyImages` 중 하나의 액션을 수행합니다.

---

## Rule 종류 요약

| Rule 타입 | 실행 시점 | 목적 |
|-----------|-----------|------|
| `validate` | Validating Webhook | 리소스가 정책을 준수하는지 검증. 위반 시 차단 또는 감사 |
| `mutate` | Mutating Webhook | 리소스를 자동으로 수정 (필드 추가/변경) |
| `generate` | 리소스 생성/업데이트 이벤트 | 연관 리소스를 자동으로 생성 또는 복사 |
| `verifyImages` | Mutating Webhook | 컨테이너 이미지의 서명·attestation 검증 |

---

## match 조건 작성법

```yaml
match:
  any:                         # OR 조건
  - resources:
      kinds:
        - Pod
      namespaces:
        - production
  - resources:
      kinds:
        - Deployment
      selector:
        matchLabels:
          env: prod
```

### match 주요 필드

| 필드 | 설명 | 예시 |
|------|------|------|
| `kinds` | 적용할 리소스 종류 | `Pod`, `Deployment`, `Namespace` |
| `namespaces` | 적용할 네임스페이스 | `["default", "production"]` |
| `selector` | 레이블 셀렉터 | `matchLabels: {env: prod}` |
| `annotations` | 어노테이션 조건 | `{"team": "backend"}` |
| `operations` | 트리거 이벤트 | `CREATE`, `UPDATE`, `DELETE` |

---

## exclude 조건 작성법

```yaml
exclude:
  any:
  - resources:
      namespaces:
        - kube-system
        - kyverno
  - subjects:                   # 특정 사용자/그룹/서비스어카운트 제외
    - kind: ServiceAccount
      name: system-deployer
      namespace: kube-system
```

---

## 하나의 Policy에 여러 Rule 작성

Rule은 **순서대로** 실행됩니다. 특히 Mutate Rule은 위에서부터 순차적으로 적용됩니다.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: pod-best-practices
spec:
  validationFailureAction: Enforce
  rules:
    - name: require-labels         # Rule 1: 레이블 검증
      match:
        any:
        - resources:
            kinds: [Pod]
      validate:
        message: "app 레이블이 필요합니다."
        pattern:
          metadata:
            labels:
              app: "?*"

    - name: disallow-latest        # Rule 2: latest 태그 금지
      match:
        any:
        - resources:
            kinds: [Pod]
      validate:
        message: "latest 태그 사용이 금지됩니다."
        deny:
          conditions:
            any:
            - key: "{{ images.containers.*.tag }}"
              operator: AnyIn
              value: ["latest", ""]
```

---

## background 모드

`background: true`로 설정하면 Kyverno가 **기존 리소스**도 검사합니다.
Background Controller가 주기적으로 스캔하여 PolicyReport를 갱신합니다.

```yaml
spec:
  background: true    # 기본값: true
```

> `background: false`이면 신규로 생성/변경되는 리소스에만 적용됩니다.
> Validate 정책의 경우 `background: true`로 두어야 PolicyReport에서 기존 위반을 확인할 수 있습니다.

---

## 정책 상태 확인

```bash
# 설치된 정책 목록
kubectl get clusterpolicy
kubectl get policy -A

# 특정 정책 상세
kubectl describe clusterpolicy require-labels

# 정책 위반 리포트 (네임스페이스)
kubectl get policyreport -n default
kubectl describe policyreport -n default

# 클러스터 전체 위반 리포트
kubectl get clusterpolicyreport
```

---

## 참고

- [Kyverno 정책 라이브러리](https://kyverno.io/policies/)
- [공식 문서 — Writing Policies](https://kyverno.io/docs/writing-policies/)
