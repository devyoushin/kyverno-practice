# Kyverno Docs

Kyverno 학습 문서와 AI 작업 보조 자료를 관리합니다.

## 구성

| 폴더 | 내용 |
|------|------|
| `guides/` | 설치, 정책 유형, CLI, 보안, 트러블슈팅 가이드 |
| `agents/` | 문서 작성, 정책 설계, 보안 감사, 트러블슈팅 AI 작업 지침 |
| `rules/` | 문서 작성 규칙, Kyverno 컨벤션, 보안/모니터링 체크리스트 |
| `templates/` | 서비스 문서, 런북, 장애 보고서 템플릿 |

## 가이드 문서

| 문서 | 내용 |
|------|------|
| `guides/README.md` | 가이드 읽는 순서 |
| `guides/install.md` | Helm 기반 설치 |
| `guides/architecture-guide.md` | 아키텍처와 동작 방식 |
| `guides/policy-types-guide.md` | 정책 유형 |
| `guides/validate-policy-guide.md` | validate 정책 |
| `guides/mutate-policy-guide.md` | mutate 정책 |
| `guides/generate-policy-guide.md` | generate 정책 |
| `guides/exception-guide.md` | 예외 처리 |
| `guides/verify-image-guide.md` | 이미지 검증 |
| `guides/pss-guide.md` | Pod Security Standards |
| `guides/kyverno-cli-guide.md` | Kyverno CLI |
| `guides/troubleshooting-guide.md` | 문제 해결 |

## 코드 위치

| 경로 | 내용 |
|------|------|
| `../ops/install/` | Helm 설치 스크립트와 values |
| `../ops/upgrade/` | Helm 업그레이드 스크립트 |
| `../ops/policies/` | validate, mutate, generate ClusterPolicy YAML |
| `../ops/examples/` | 정책 검증용 Kubernetes 리소스 예제 |
| `../ops/tests/` | `kyverno test`용 테스트 케이스 |

처음 읽을 문서는 `guides/install.md`입니다.
