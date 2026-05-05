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
├── .claude/
│   ├── settings.json
│   └── commands/              # /new-doc, /new-runbook, /review-doc, /add-troubleshooting, /search-kb
├── agents/                    # doc-writer, policy-designer, security-auditor, troubleshooter
├── templates/                 # service-doc, runbook, incident-report
├── rules/                     # doc-writing, kyverno-conventions, security-checklist, monitoring
├── policies/                  # ClusterPolicy YAML 파일
└── docs/                      # 주제별 가이드 문서
```

---

## 커스텀 슬래시 명령어

| 명령어 | 설명 | 사용 예시 |
|--------|------|---------|
| `/new-doc` | 새 정책 가이드 생성 | `/new-doc image-signing-policy` |
| `/new-runbook` | 새 런북 생성 | `/new-runbook 신규 정책 프로덕션 배포` |
| `/review-doc` | 정책/문서 검토 | `/review-doc policies/require-labels.yaml` |
| `/add-troubleshooting` | 트러블슈팅 케이스 추가 | `/add-troubleshooting Pod 생성 차단` |
| `/search-kb` | 지식베이스 검색 | `/search-kb 이미지 서명 검증` |

---

## 가이드 문서 목록

| 문서 | 주제 |
|------|------|
| `docs/install.md` | Kyverno 설치 (Helm) |
| `docs/architecture-guide.md` | Kyverno 아키텍처 |
| `docs/policy-types-guide.md` | 정책 유형 개요 |
| `docs/validate-policy-guide.md` | validate 정책 |
| `docs/mutate-policy-guide.md` | mutate 정책 |
| `docs/generate-policy-guide.md` | generate 정책 |
| `docs/verify-image-guide.md` | 이미지 서명 검증 |
| `docs/pss-guide.md` | Pod Security Standards |
| `docs/exception-guide.md` | PolicyException 처리 |
| `docs/kyverno-cli-guide.md` | kyverno CLI 활용 |
| `docs/troubleshooting-guide.md` | 트러블슈팅 |

---

## 정책 배포 원칙

```bash
# 1. Audit 모드로 배포
kubectl apply -f policies/

# 2. 위반 현황 확인
kubectl get policyreport -A
kubectl get clusterpolicyreport

# 3. 위반 0 확인 후 Enforce 전환
# validationFailureAction: Audit → Enforce

# 4. kyverno test (배포 전 필수)
kyverno test .
```
