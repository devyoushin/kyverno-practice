# AGENTS.md — kyverno-practice Codex 작업 지침

이 저장소는 Kyverno 정책 학습/운영 지식 베이스입니다. Codex 작업 시 `CLAUDE.md`와 `docs/rules/`의 규칙을 동일하게 따릅니다.

## 공통 원칙

- 정책 설명 문서는 `docs/`에 둡니다.
- ClusterPolicy, 테스트 리소스, `kyverno test` 자산은 `ops/`에 둡니다.
- 정책은 validate, mutate, generate, cleanup 성격을 명확히 구분합니다.
- 운영 정책은 적용 범위, 예외, audit/enforce 전환 절차를 함께 설명합니다.

## Claude와의 싱크

- `CLAUDE.md`는 Claude용 프로젝트 지침입니다.
- `AGENTS.md`는 Codex 작업 시작점입니다.
- 공통 문서/정책 작성 규칙은 `docs/rules/`를 기준으로 유지합니다.

## 작업 체크리스트

- 기존 사용자 변경 확인
- 정책 YAML 문법 검사
- `kyverno test` 자산 추가 시 테스트 경로 확인
- 링크 검사와 `git diff --check` 수행
