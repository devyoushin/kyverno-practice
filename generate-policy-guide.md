# Kyverno Generate Policy 가이드

Generate Rule은 특정 이벤트가 발생했을 때 **새로운 리소스를 자동으로 생성**합니다.
가장 대표적인 사용 사례는 네임스페이스 생성 시 기본 NetworkPolicy, ResourceQuota, RBAC 등을 자동으로 배포하는 것입니다.

---

## 동작 원리

```
새 Namespace 생성
        │
        ▼
[Generate Rule 트리거]
        │
        ▼
Kyverno Background Controller가
해당 Namespace에 리소스 자동 생성

예: NetworkPolicy, ResourceQuota, LimitRange, ConfigMap 복사
```

---

## 생성 방식 2가지

| 방식 | 설명 |
|------|------|
| `data` | 정책 내에 리소스 내용을 직접 정의 |
| `clone` | 다른 네임스페이스의 기존 리소스를 복사 |

---

## 1. data — 인라인 리소스 정의

### 예시: 네임스페이스 생성 시 기본 NetworkPolicy 자동 생성

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: default-networkpolicy
spec:
  rules:
    - name: generate-networkpolicy
      match:
        any:
        - resources:
            kinds:
              - Namespace
      generate:
        apiVersion: networking.k8s.io/v1
        kind: NetworkPolicy
        name: default-deny-ingress
        namespace: "{{ request.object.metadata.name }}"    # 생성된 네임스페이스에 배포
        synchronize: true        # 정책 변경 시 생성된 리소스도 동기화
        data:
          spec:
            podSelector: {}      # 네임스페이스 내 모든 Pod 대상
            policyTypes:
              - Ingress
```

### 예시: ResourceQuota 자동 생성

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: default-resourcequota
spec:
  rules:
    - name: generate-resourcequota
      match:
        any:
        - resources:
            kinds:
              - Namespace
            selector:
              matchLabels:
                env: production     # production 레이블이 있는 네임스페이스에만 적용
      generate:
        apiVersion: v1
        kind: ResourceQuota
        name: default-quota
        namespace: "{{ request.object.metadata.name }}"
        synchronize: true
        data:
          spec:
            hard:
              requests.cpu: "4"
              requests.memory: "8Gi"
              limits.cpu: "8"
              limits.memory: "16Gi"
              pods: "20"
```

---

## 2. clone — 기존 리소스 복사

다른 네임스페이스에 있는 리소스를 새 네임스페이스로 복사합니다.
Secret, ConfigMap 같은 공통 설정을 여러 네임스페이스에 배포할 때 유용합니다.

### 예시: default 네임스페이스의 ConfigMap을 신규 네임스페이스로 복사

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: copy-registry-configmap
spec:
  rules:
    - name: clone-configmap
      match:
        any:
        - resources:
            kinds:
              - Namespace
      generate:
        apiVersion: v1
        kind: ConfigMap
        name: registry-config
        namespace: "{{ request.object.metadata.name }}"
        synchronize: true
        clone:
          namespace: default          # 복사 원본 위치
          name: registry-config       # 복사할 리소스 이름
```

### 예시: TLS Secret 복사 (도커 레지스트리 인증)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: copy-image-pull-secret
spec:
  rules:
    - name: clone-pull-secret
      match:
        any:
        - resources:
            kinds:
              - Namespace
            selector:
              matchLabels:
                copy-secrets: "true"
      generate:
        apiVersion: v1
        kind: Secret
        name: registry-credentials
        namespace: "{{ request.object.metadata.name }}"
        synchronize: true
        clone:
          namespace: default
          name: registry-credentials
```

---

## synchronize 옵션

`synchronize: true`로 설정하면 Kyverno가 생성된 리소스를 계속 관리합니다.

| 동작 | synchronize: true | synchronize: false |
|------|-------------------|---------------------|
| 정책 변경 시 | 생성된 리소스도 업데이트 | 생성 후 방치 |
| 생성된 리소스 삭제 시 | Kyverno가 재생성 | 재생성하지 않음 |
| 소유 네임스페이스 삭제 시 | 함께 삭제 | 함께 삭제 |

> `synchronize: true` 상태에서는 사람이 생성된 리소스를 직접 수정해도 Kyverno가 원래 값으로 되돌립니다.

---

## 실습: 네임스페이스 생성 시 NetworkPolicy 자동 생성

```bash
# 1. Generate 정책 적용
kubectl apply -f policies/generate/default-networkpolicy.yaml

# 2. 새 네임스페이스 생성
kubectl create namespace test-team

# 3. NetworkPolicy 자동 생성 확인
kubectl get networkpolicy -n test-team
# NAME                   POD-SELECTOR   AGE
# default-deny-ingress   <none>         3s

# 4. 정책 변경 후 동기화 확인 (synchronize: true)
# 정책의 data 내용을 수정하면 기존 네임스페이스의 NetworkPolicy도 업데이트됩니다.
```

---

## Generate 이벤트 및 상태 확인

```bash
# Generate 정책으로 만들어진 리소스 확인 (ownerReference에 Kyverno 정보 있음)
kubectl get networkpolicy -n test-team -o yaml | grep -A5 ownerReferences

# Kyverno 이벤트 확인
kubectl get events -n kyverno --sort-by='.metadata.creationTimestamp'

# GenerateRequest 오브젝트 확인 (처리 상태)
kubectl get generaterequests -n kyverno
```

---

## 참고

- [공식 문서 — Generate](https://kyverno.io/docs/writing-policies/generate/)
- [Generate 정책 예시 모음](https://kyverno.io/policies/?policytypes=generate)
