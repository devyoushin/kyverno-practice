# 모니터링 지침 — kyverno-practice

## 핵심 확인 명령어

```bash
# 정책 목록 확인
kubectl get clusterpolicy
kubectl get policy -A

# PolicyReport 확인
kubectl get policyreport -A
kubectl get clusterpolicyreport

# 특정 네임스페이스 위반 확인
kubectl get policyreport -n <namespace> -o yaml | grep -A 5 "result: fail"

# Kyverno 상태
kubectl get pods -n kyverno
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno --tail=100
```

## Prometheus 메트릭

| 메트릭 | 설명 | 알람 조건 |
|--------|------|---------|
| `kyverno_policy_results_total` | 정책 결과 수 | fail 급증 |
| `kyverno_admission_requests_total` | admission 요청 수 | 처리 지연 |
| `kyverno_policy_execution_duration_seconds` | 정책 실행 시간 | p99 > 1s |

## PolicyReport 자동 검토

```bash
# 전체 위반 요약
kubectl get policyreport -A -o json | \
  jq '[.items[].results[] | select(.result=="fail")] | length'

# 네임스페이스별 위반 수
kubectl get policyreport -A -o json | \
  jq '.items[] | {ns: .metadata.namespace, fail: [.results[] | select(.result=="fail")] | length}'
```
