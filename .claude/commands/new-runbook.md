새 Kyverno 운영 런북을 생성합니다.

**사용법**: `/new-runbook <작업명>`

**예시**: `/new-runbook 신규 정책 프로덕션 배포`

작업 유형:
- `정책 배포`: audit → enforce 단계 전환
- `예외 처리`: PolicyException 추가
- `정책 롤백`: 정책 비활성화 또는 삭제
- `업그레이드`: Kyverno 버전 업그레이드

런북 포함 내용:
- 사전 체크리스트 (audit 모드 위반 현황 확인)
- PolicyReport 검토 절차
- audit → enforce 전환 단계
- 롤백 절차 (정책 삭제 또는 audit 전환)
