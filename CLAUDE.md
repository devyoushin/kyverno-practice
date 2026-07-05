# kyverno-practice — 프로젝트 가이드

## 프로젝트 설정
- 환경: EKS
- Kyverno 버전: 1.12.x (kyverno Helm chart)
- 네임스페이스: kyverno
- 앱 네임스페이스: default
- 앱 이름 컨벤션: my-app

---

## 디렉토리 구조

```
kyverno-practice/
├── CLAUDE.md                  # 이 파일 (자동 로드)
├── AGENTS.md -> CLAUDE.md     # Codex 작업 지침 링크
├── docs/
│   ├── README.md              # 문서 지도
│   ├── guides/                # 설치, 정책 유형, CLI, 보안, 트러블슈팅 가이드
│   ├── agents/                # doc-writer, policy-designer, security-auditor, troubleshooter
│   ├── templates/             # service-doc, runbook, incident-report
│   └── rules/                 # doc-writing, kyverno-conventions, security-checklist, monitoring
├── ops/01-installation/               # Helm 설치 스크립트와 values
├── ops/upgrade/               # Helm 업그레이드 스크립트
├── ops/policies/              # ClusterPolicy YAML 파일
├── ops/examples/              # 가이드 참조용 예제 K8s 매니페스트
└── ops/tests/                 # kyverno test 명령용 테스트 케이스
```

AI 작업 지침은 `CLAUDE.md`를 원본으로 관리하고, `AGENTS.md`는 심볼릭 링크로만 유지합니다.

---

## 커스텀 슬래시 명령어

| 명령어 | 설명 | 사용 예시 |
|--------|------|---------|
| `/new-doc` | 새 정책 가이드 생성 | `/new-doc image-signing-policy` |
| `/new-runbook` | 새 런북 생성 | `/new-runbook 신규 정책 프로덕션 배포` |
| `/review-doc` | 정책/문서 검토 | `/review-doc ops/policies/require-labels.yaml` |
| `/add-troubleshooting` | 트러블슈팅 케이스 추가 | `/add-troubleshooting Pod 생성 차단` |
| `/search-kb` | 지식베이스 검색 | `/search-kb 이미지 서명 검증` |

---

## 가이드 문서 목록

| 문서 | 주제 |
|------|------|
| `docs/02-guides/install.md` | Kyverno 설치 (Helm) |
| `docs/02-guides/architecture-guide.md` | Kyverno 아키텍처 |
| `docs/02-guides/policy-types-guide.md` | 정책 유형 개요 |
| `docs/02-guides/validate-policy-guide.md` | validate 정책 |
| `docs/02-guides/mutate-policy-guide.md` | mutate 정책 |
| `docs/02-guides/generate-policy-guide.md` | generate 정책 |
| `docs/02-guides/verify-image-guide.md` | 이미지 서명 검증 |
| `docs/02-guides/pss-guide.md` | Pod Security Standards |
| `docs/02-guides/exception-guide.md` | PolicyException 처리 |
| `docs/02-guides/kyverno-cli-guide.md` | kyverno CLI 활용 |
| `docs/02-guides/troubleshooting-guide.md` | 트러블슈팅 |

---

## 정책 배포 원칙

```bash
# 1. Audit 모드로 배포
kubectl apply -f ops/policies/

# 2. 위반 현황 확인
kubectl get policyreport -A
kubectl get clusterpolicyreport

# 3. 위반 0 확인 후 Enforce 전환
# validationFailureAction: Audit → Enforce

# 4. kyverno test (배포 전 필수)
kyverno test .
```
