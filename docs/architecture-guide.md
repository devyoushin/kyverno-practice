# Kyverno 아키텍처

Kyverno는 Kubernetes Admission Webhook으로 동작하는 정책 엔진입니다.
별도의 DSL(Domain Specific Language) 없이 **YAML로 정책을 정의**하는 것이 특징입니다.

---

## 전체 흐름

```
kubectl apply -f pod.yaml
        │
        ▼
[kube-apiserver]
        │
        │ 1. MutatingAdmissionWebhook 호출
        ▼
[Kyverno Admission Controller]
        │  Mutate Rules 실행 → 리소스 수정 후 반환
        │
        │ 2. ValidatingAdmissionWebhook 호출
        ▼
[Kyverno Admission Controller]
        │  Validate Rules 실행
        │  ├── PASS  → kube-apiserver가 etcd에 저장
        │  └── FAIL  → 요청 거부 (Enforce 모드) or 기록만 (Audit 모드)
        │
        ▼
[etcd] ← 리소스 저장

[Background Controller]  ← 기존 리소스에 Generate/Mutate existing 적용
[Reports Controller]     ← PolicyReport 생성 및 관리
[Cleanup Controller]     ← 만료된 Generate 리소스 정리
```

---

## 컴포넌트 구성

| 컴포넌트 | 역할 |
|----------|------|
| **Admission Controller** | Mutate/Validate Webhook 처리. 실시간 요청 인터셉트 |
| **Background Controller** | 기존 리소스 대상 Generate 및 Mutate Existing 처리 |
| **Reports Controller** | PolicyReport / ClusterPolicyReport 생성·갱신 |
| **Cleanup Controller** | `cleanupPolicy`로 정의된 리소스 자동 삭제 |

---

## Kyverno CRD 목록

```bash
kubectl get crd | grep kyverno
```

| CRD | 설명 |
|-----|------|
| `clusterpolicies.kyverno.io` | 클러스터 전체에 적용되는 정책 |
| `policies.kyverno.io` | 특정 네임스페이스에 적용되는 정책 |
| `policyexceptions.kyverno.io` | 정책 예외 처리 |
| `clustercleanuppolicies.kyverno.io` | 클러스터 전체 리소스 정리 정책 |
| `cleanuppolicies.kyverno.io` | 네임스페이스 리소스 정리 정책 |
| `clusteradmissionreports.kyverno.io` | Admission 시점 정책 결과 |
| `admissionreports.kyverno.io` | 네임스페이스 Admission 결과 |
| `clusterpolicyreports.kyverno.io` | 클러스터 정책 결과 집계 |
| `policyreports.wgpolicyk8s.io` | 네임스페이스 정책 결과 집계 |

---

## Policy 구조

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy           # ClusterPolicy: 클러스터 전체 / Policy: 네임스페이스 한정
metadata:
  name: policy-name
spec:
  validationFailureAction: Enforce   # Enforce(차단) or Audit(기록만)
  background: true                   # 기존 리소스에도 적용 여부
  rules:
    - name: rule-name
      match:                         # 이 규칙이 적용될 리소스 조건
        any:
        - resources:
            kinds:
              - Pod
      exclude:                       # 제외 조건 (선택)
        any:
        - resources:
            namespaces:
              - kube-system
      validate:                      # validate / mutate / generate 중 하나
        message: "위반 메시지"
        pattern:
          spec:
            containers:
              - (name): "*"
```

---

## ClusterPolicy vs Policy

| 구분 | ClusterPolicy | Policy |
|------|--------------|--------|
| 적용 범위 | 클러스터 전체 모든 네임스페이스 | 해당 네임스페이스만 |
| 리소스 유형 | Namespace-scoped + Cluster-scoped | Namespace-scoped 리소스만 |
| 관리 권한 | 클러스터 관리자 | 네임스페이스 관리자 위임 가능 |
| 사용 시점 | 조직 전체 보안 기준선 | 팀/프로젝트별 개별 정책 |

---

## validationFailureAction 모드 비교

| 모드 | 동작 | 사용 시점 |
|------|------|-----------|
| `Enforce` | 위반 시 요청 즉시 차단 (HTTP 403) | 정책이 검증된 후 운영 적용 |
| `Audit` | 위반 기록 (PolicyReport), 요청은 허용 | 정책 도입 초기, 영향도 파악 |

> 새로운 정책은 항상 `Audit`으로 시작해 기존 리소스 위반 현황을 파악한 뒤 `Enforce`로 전환하세요.

---

## 참고

- [Kyverno 공식 문서](https://kyverno.io/docs/)
- [Kyverno GitHub](https://github.com/kyverno/kyverno)
- [Kyverno Policies 라이브러리](https://kyverno.io/policies/)
