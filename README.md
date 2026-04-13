# kyverno-practice

A hands-on repository for learning Kyverno on Kubernetes.
- **Environment**: EKS / Kyverno 1.12.x
- **Namespace**: `kyverno`
- **App namespace**: `default`

---

## Learning Path

```
1. Installation    → install.md
2. Core Concepts   → architecture-guide.md, policy-types-guide.md
3. Policy Types
   ├── Validate    → validate-policy-guide.md
   ├── Mutate      → mutate-policy-guide.md
   └── Generate    → generate-policy-guide.md
4. Advanced
   ├── Security    → pss-guide.md, verify-image-guide.md
   └── Exception   → exception-guide.md
5. CLI & Testing   → kyverno-cli-guide.md
6. Troubleshooting → troubleshooting-guide.md
```

---

## Documents

### Installation
| File | Description |
|------|-------------|
| [install.md](./install.md) | Helm으로 Kyverno 설치 및 초기 설정 |

### Core Concepts
| File | Description |
|------|-------------|
| [architecture-guide.md](./architecture-guide.md) | Kyverno 동작 원리 — Admission Webhook 흐름 |
| [policy-types-guide.md](./policy-types-guide.md) | ClusterPolicy vs Policy, Rule 종류(Validate/Mutate/Generate) |

### Policy Types
| File | Description |
|------|-------------|
| [validate-policy-guide.md](./validate-policy-guide.md) | Validate — 리소스 검증, 차단/감사(Audit) 모드 |
| [mutate-policy-guide.md](./mutate-policy-guide.md) | Mutate — 리소스 자동 수정, patchStrategicMerge / patchesJson6902 |
| [generate-policy-guide.md](./generate-policy-guide.md) | Generate — 리소스 자동 생성, 네임스페이스별 기본 정책 배포 |

### Advanced
| File | Description |
|------|-------------|
| [pss-guide.md](./pss-guide.md) | Pod Security Standards — Baseline/Restricted 프로파일 적용 |
| [verify-image-guide.md](./verify-image-guide.md) | Image Verification — Cosign 서명 검증, attestation |
| [exception-guide.md](./exception-guide.md) | PolicyException — 특정 리소스를 정책에서 예외 처리 |

### CLI & Testing
| File | Description |
|------|-------------|
| [kyverno-cli-guide.md](./kyverno-cli-guide.md) | kyverno CLI — `test`, `apply` 명령으로 로컬 정책 검증 |

### Troubleshooting
| File | Description |
|------|-------------|
| [troubleshooting-guide.md](./troubleshooting-guide.md) | 정책 디버깅, PolicyReport 분석, 자주 발생하는 문제 |

---

## Manifest Structure

```
policies/
├── validate/
│   ├── require-labels.yaml          # 필수 레이블 강제
│   ├── disallow-latest-tag.yaml     # latest 태그 금지
│   ├── require-resource-limits.yaml # CPU/Memory limits 강제
│   └── disallow-privileged.yaml     # privileged 컨테이너 금지
├── mutate/
│   ├── add-labels.yaml              # 레이블 자동 추가
│   ├── add-resource-limits.yaml     # 기본 resource limits 주입
│   └── inject-sidecar.yaml          # 사이드카 컨테이너 자동 주입
└── generate/
    ├── default-networkpolicy.yaml   # 네임스페이스 생성 시 NetworkPolicy 자동 생성
    └── copy-configmap.yaml          # ConfigMap을 신규 네임스페이스에 복사
```

---

## Key Concept Summary

**Policy → Rule → Match + Condition + Action** 이 Kyverno의 핵심 구조입니다.

```
kubectl apply / create
        │
        ▼
[Kubernetes API Server]
        │
        ▼ Admission Webhook 호출
[Kyverno Admission Controller]
        │
        ├── Mutate Rules    → 리소스 수정 (labels, annotations, limits 자동 추가)
        │       ↓ 수정된 리소스 반환
        ├── Validate Rules  → 검증 (통과 → API Server 저장 / 실패 → 차단)
        │
        └── Generate Rules  → 연관 리소스 자동 생성 (NetworkPolicy, ConfigMap 등)

[PolicyReport / ClusterPolicyReport]  ← Audit 모드 결과 기록
```

| Rule 종류 | 목적 | 예시 |
|-----------|------|------|
| **Validate** | 정책 위반 차단 또는 감사 | latest 태그 금지, resource limits 필수 |
| **Mutate** | 리소스 자동 수정 | 기본 레이블 주입, imagePullPolicy 강제 |
| **Generate** | 연관 리소스 자동 생성 | 네임스페이스 생성 시 NetworkPolicy 자동 배포 |
| **VerifyImages** | 컨테이너 이미지 서명 검증 | Cosign으로 서명된 이미지만 허용 |

> `validationFailureAction: Enforce`는 즉시 차단, `Audit`는 기록만 합니다.
> 처음 도입 시 Audit → Enforce 순서로 점진적으로 적용하세요.
