새 Kyverno 정책 가이드 문서를 생성합니다.

**사용법**: `/new-doc <주제명>`

**예시**: `/new-doc image-signing-policy`

주제 분류:
- 정책 유형: validate, mutate, generate, verify-image
- 보안: pss, pod-security, rbac
- 운영: exception, cli, troubleshooting

`docs/<주제명>-guide.md` 생성 시 포함 내용:
- ClusterPolicy/Policy YAML 예시
- `kyverno test` 또는 `kyverno apply` 검증 예시
- PolicyReport 확인 명령어
- 예외 처리 방법 (PolicyException)
- 트러블슈팅 섹션
