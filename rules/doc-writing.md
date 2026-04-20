# 문서 작성 원칙 — kyverno-practice

## 언어
- 본문은 한국어, 기술 용어(ClusterPolicy, PolicyException)는 영어
- 서술체: `~다.`, `~한다.`

## 문서 구조
1. **개요** — 이 정책이 왜 필요한지
2. **정책 YAML** — 실제 동작 가능한 ClusterPolicy
3. **테스트** — kyverno test 예시
4. **예외 처리** — PolicyException YAML
5. **확인** — PolicyReport 조회
6. **트러블슈팅** — 정책 충돌, 성능

## YAML 주석
- `# 한국어 설명` 추가
- `validationFailureAction` 변경 이유 명시

## 주의사항
- `Enforce` 정책은 `> **차단 주의**:` 경고 블록
- 시스템 네임스페이스 제외 필수 명시
