Kyverno 정책 문서 또는 YAML을 검토합니다.

**사용법**: `/review-doc <파일 경로>`

**예시**: `/review-doc policies/require-labels.yaml`

검토 기준:

**정책 YAML**
- [ ] `validationFailureAction`: 신규는 `Audit` 시작, 안정 후 `Enforce`
- [ ] `background: true` 설정 (기존 리소스 스캔)
- [ ] `match`/`exclude` 규칙 명확성
- [ ] 시스템 네임스페이스(`kube-system`, `kyverno`) 제외 여부
- [ ] `message` 필드로 위반 이유 명확히 안내

**보안 정책**
- [ ] PSS 기준 (Restricted/Baseline/Privileged) 적절성
- [ ] 이미지 서명 검증 설정 (verify-image)
- [ ] RBAC 최소 권한 확인

**문서 품질**
- [ ] `kyverno test` 테스트 케이스 포함 여부
- [ ] PolicyException 처리 방법 설명 여부
