# 보안 체크리스트 — kyverno-practice

## 정책 커버리지 (필수)

### Pod 보안
- [ ] `disallow-privileged-containers`: privileged 컨테이너 금지
- [ ] `disallow-host-namespaces`: hostNetwork/hostPID/hostIPC 금지
- [ ] `disallow-host-path`: hostPath 볼륨 금지
- [ ] `require-run-as-non-root`: root 실행 금지

### 이미지 보안
- [ ] `disallow-latest-tag`: latest 태그 금지
- [ ] `allowed-image-registries`: 허용 레지스트리 제한
- [ ] `verify-image`: 이미지 서명 검증 (Cosign)

### 레이블/어노테이션
- [ ] `require-labels`: team, env, app 레이블 필수
- [ ] `require-resource-limits`: requests/limits 강제

## 정책 안전성
- [ ] 신규 정책은 반드시 Audit 모드로 시작
- [ ] 시스템 네임스페이스 (kube-system, kyverno) 제외
- [ ] `kyverno test` 통과 확인 후 배포
- [ ] PolicyReport 위반 0 확인 후 Enforce 전환

## 모니터링
- [ ] PolicyReport 정기 검토 (주 1회)
- [ ] Kyverno webhook 응답시간 모니터링
- [ ] 정책 위반 알람 설정 (PolicyReport)
