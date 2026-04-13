# Kyverno Pod Security Standards (PSS) 가이드

Kyverno는 Kubernetes의 **Pod Security Standards** 프로파일을 정책으로 제공합니다.
`kyverno/policies` Helm Chart를 통해 Baseline / Restricted 프로파일을 손쉽게 적용할 수 있습니다.

---

## Pod Security Standards 프로파일

| 프로파일 | 수준 | 설명 |
|----------|------|------|
| `Privileged` | 최소 제한 | 제약 없음 (기본값) |
| `Baseline` | 중간 수준 | 알려진 권한 상승 차단. 일반 워크로드에 적합 |
| `Restricted` | 최고 수준 | 보안 모범 사례 강제. 보안 민감 워크로드에 적합 |

---

## kyverno/policies Helm Chart로 PSS 적용

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

# Baseline 프로파일 설치
helm install kyverno-policies kyverno/kyverno-policies \
  --namespace kyverno \
  --set podSecurityStandard=baseline \
  --set validationFailureAction=Enforce

# Restricted 프로파일 설치
helm install kyverno-policies kyverno/kyverno-policies \
  --namespace kyverno \
  --set podSecurityStandard=restricted \
  --set validationFailureAction=Enforce

# 적용 결과 확인
kubectl get clusterpolicy
```

---

## Baseline 프로파일이 차단하는 항목

```
✗ privileged: true                          # 특권 컨테이너
✗ hostPID: true / hostIPC: true             # 호스트 네임스페이스 공유
✗ hostNetwork: true                         # 호스트 네트워크 사용
✗ hostPort (모든 포트)                       # 호스트 포트 바인딩
✗ capabilities.add: [NET_ADMIN, SYS_ADMIN]  # 위험한 Linux capabilities
✗ securityContext.allowPrivilegeEscalation  # 권한 상승 허용
✗ /proc 마운트 타입 변경                     # procMount
```

---

## Restricted 프로파일이 추가로 요구하는 항목

```
✓ runAsNonRoot: true                    # 반드시 루트가 아닌 사용자로 실행
✓ runAsUser: >= 1000                    # 특정 UID 이상 사용
✓ allowPrivilegeEscalation: false       # 명시적으로 false
✓ seccompProfile.type: RuntimeDefault   # Seccomp 프로파일 적용
✓ capabilities.drop: [ALL]             # 모든 capabilities 제거
✗ capabilities.add (허용 목록 외 금지)
```

---

## 개별 정책 직접 작성 예시

PSS Chart 없이 직접 정책을 작성할 수도 있습니다.

### 예시: runAsNonRoot 강제

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-run-as-non-root
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-run-as-non-root
      match:
        any:
        - resources:
            kinds:
              - Pod
      exclude:
        any:
        - resources:
            namespaces:
              - kube-system
              - kyverno
      validate:
        message: "컨테이너는 루트(UID 0)로 실행할 수 없습니다."
        pattern:
          spec:
            =(securityContext):
              =(runAsNonRoot): "true"
            containers:
              - (name): "*"
                =(securityContext):
                  =(runAsNonRoot): "true"
```

### 예시: seccompProfile 적용 강제

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-seccomp-profile
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-seccomp
      match:
        any:
        - resources:
            kinds:
              - Pod
      validate:
        message: "seccompProfile을 RuntimeDefault 또는 Localhost로 설정해야 합니다."
        pattern:
          spec:
            securityContext:
              seccompProfile:
                type: "RuntimeDefault | Localhost"
```

---

## 네임스페이스별 프로파일 적용 (레이블 기반)

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: apply-pss-by-namespace-label
spec:
  validationFailureAction: Enforce
  rules:
    - name: baseline-for-labeled-ns
      match:
        any:
        - resources:
            kinds:
              - Pod
            namespaces:
              - "?*"
            selector:
              matchLabels:
                pss-profile: baseline
      validate:
        podSecurity:
          level: baseline
          version: latest
```

---

## 기존 리소스 위반 현황 확인

```bash
# Audit 모드로 전환 후 위반 항목 파악
helm upgrade kyverno-policies kyverno/kyverno-policies \
  --namespace kyverno \
  --set podSecurityStandard=restricted \
  --set validationFailureAction=Audit

# 위반된 Pod 목록
kubectl get policyreport -A -o json \
  | jq '.items[] | select(.results[]?.result=="fail") | {namespace: .metadata.namespace, results: [.results[] | select(.result=="fail") | {policy: .policy, resource: .resources[].name}]}'
```

---

## 참고

- [Kubernetes Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [kyverno/policies Chart](https://github.com/kyverno/kyverno/tree/main/charts/kyverno-policies)
- [Kyverno PSS 문서](https://kyverno.io/docs/pod-security/)
