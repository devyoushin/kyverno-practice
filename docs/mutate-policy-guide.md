# Kyverno Mutate Policy 가이드

Mutate Rule은 리소스를 **자동으로 수정**합니다.
사용자가 명시하지 않은 필드를 자동으로 채워넣거나 기본값을 주입할 때 사용합니다.

---

## 수정 방식 3가지

| 방식 | 설명 | 사용 시점 |
|------|------|-----------|
| `patchStrategicMerge` | Kubernetes strategic merge patch. 기존 필드와 병합 | 필드 추가/수정, 배열 병합 |
| `patchesJson6902` | RFC 6902 JSON Patch. 정확한 경로 지정 | 특정 인덱스 수정, 복잡한 경로 |
| `foreach` | 배열 요소마다 패치 반복 적용 | 모든 컨테이너에 동일한 설정 적용 |

---

## 1. patchStrategicMerge

가장 일반적인 방식입니다. 기존 값을 덮어쓰지 않고 병합합니다.

### 예시: imagePullPolicy 자동 설정

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: set-image-pull-policy
spec:
  rules:
    - name: set-pull-policy
      match:
        any:
        - resources:
            kinds:
              - Pod
      mutate:
        patchStrategicMerge:
          spec:
            containers:
              - (image): "*:latest"    # (필드): 조건 — latest 태그를 가진 컨테이너만
                imagePullPolicy: Always
```

### 예시: 기본 레이블 자동 추가

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-default-labels
spec:
  rules:
    - name: add-labels
      match:
        any:
        - resources:
            kinds:
              - Pod
      mutate:
        patchStrategicMerge:
          metadata:
            labels:
              +(managed-by): "kyverno"    # + : 필드가 없을 때만 추가 (이미 있으면 건드리지 않음)
              +(env): "unknown"
```

### `+` 연산자 vs 기본 병합

| 표현 | 동작 |
|------|------|
| `field: value` | 항상 덮어씀 |
| `+(field): value` | 필드가 없을 때만 추가 |
| `=(field): value` | 필드가 존재할 때만 수정 |

---

## 2. patchesJson6902

RFC 6902 JSON Patch 형식으로 정확한 경로를 지정합니다.

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-annotation
spec:
  rules:
    - name: add-team-annotation
      match:
        any:
        - resources:
            kinds:
              - Deployment
      mutate:
        patchesJson6902: |-
          - path: "/metadata/annotations/owner"
            op: add
            value: "platform-team"
          - path: "/metadata/annotations/reviewed-at"
            op: add
            value: "{{ request.object.metadata.creationTimestamp }}"
```

### JSON Patch 연산

| op | 설명 |
|----|------|
| `add` | 새 값 추가 (경로가 없으면 생성) |
| `replace` | 기존 값 교체 |
| `remove` | 필드 삭제 |

---

## 3. foreach — 모든 컨테이너에 적용

배열의 각 요소에 패치를 반복 적용합니다.

### 예시: 모든 컨테이너에 기본 resource limits 주입

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: add-default-resource-limits
spec:
  rules:
    - name: add-limits
      match:
        any:
        - resources:
            kinds:
              - Pod
      mutate:
        foreach:
          - list: "request.object.spec.containers"
            patchStrategicMerge:
              spec:
                containers:
                  - (name): "{{ element.name }}"
                    resources:
                      limits:
                        +(memory): "256Mi"
                        +(cpu): "500m"
                      requests:
                        +(memory): "128Mi"
                        +(cpu): "100m"
```

---

## 4. 사이드카 컨테이너 자동 주입

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: inject-logging-sidecar
spec:
  rules:
    - name: inject-sidecar
      match:
        any:
        - resources:
            kinds:
              - Pod
            selector:
              matchLabels:
                inject-logging: "true"
      mutate:
        patchStrategicMerge:
          spec:
            containers:
              - name: log-collector
                image: fluent/fluent-bit:2.2
                resources:
                  limits:
                    memory: "64Mi"
                    cpu: "100m"
                volumeMounts:
                  - name: varlog
                    mountPath: /var/log
            volumes:
              - name: varlog
                hostPath:
                  path: /var/log
```

---

## Mutate 실습 확인

```bash
# 정책 적용
kubectl apply -f policies/mutate/add-labels.yaml

# 테스트 Pod 생성
kubectl run test-pod --image=nginx:1.25

# 자동으로 추가된 레이블 확인
kubectl get pod test-pod --show-labels
# NAME       READY   STATUS    LABELS
# test-pod   1/1     Running   managed-by=kyverno,env=unknown,run=test-pod

# 적용된 패치 이력 확인 (어노테이션)
kubectl get pod test-pod -o jsonpath='{.metadata.annotations}' | jq
```

---

## 주의사항

- Mutate Rule은 **순서가 중요**합니다. 같은 Policy 내에서 위에 있는 Rule이 먼저 실행됩니다.
- `background: true`일 때 Mutate Rule은 기존 리소스에는 적용되지 않습니다. 기존 리소스 수정은 `mutateExistingOnPolicyUpdate: true` 옵션이 필요합니다.
- 다른 Mutating Webhook(예: Istio sidecar injector)과 순서가 겹칠 수 있습니다. Webhook의 `reinvocationPolicy`를 확인하세요.

---

## 참고

- [공식 문서 — Mutate](https://kyverno.io/docs/writing-policies/mutate/)
- [Strategic Merge Patch](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/update-api-object-kubectl-patch/)
