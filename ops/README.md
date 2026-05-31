# Kyverno Ops

Kyverno 정책 예제와 테스트 자산을 두는 공간입니다.

| 폴더 | 내용 |
|------|------|
| `install/` | Helm 기반 Kyverno 설치 스크립트와 values |
| `upgrade/` | Kyverno 업그레이드 스크립트 |
| `policies/` | validate, mutate, generate ClusterPolicy YAML |
| `examples/` | 정책 검증용 Kubernetes 리소스 예제 |
| `tests/` | `kyverno test`용 테스트 케이스 |

정책 원리를 설명하는 문서는 `docs/`에 두고, 실제 적용 가능한 정책과 테스트 자산은 `ops/`에 둡니다.
