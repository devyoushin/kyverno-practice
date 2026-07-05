# Kyverno 코드 표준 관행

## ClusterPolicy 필수 설정

```yaml
spec:
  validationFailureAction: Audit    # 신규: Audit 시작, 안정 후 Enforce
  background: true                   # 기존 리소스도 스캔
  rules:
  - name: rule-name
    match:
      any:
      - resources:
          kinds: [Pod]
    exclude:
      any:
      - resources:
          namespaces:               # 시스템 네임스페이스 제외 필수
          - kube-system
          - kyverno
          - kube-public
          - monitoring
```

## 정책 배포 단계

1. **Audit 모드 배포**: 위반 탐지, 서비스 영향 없음
2. **PolicyReport 검토**: `kubectl get policyreport -A`
3. **위반 워크로드 수정**: 팀에 통보 및 수정 유예기간
4. **Enforce 전환**: `validationFailureAction: Enforce`

## PolicyException 패턴

```yaml
apiVersion: kyverno.io/v2
kind: PolicyException
metadata:
  name: <policy>-exception
  namespace: <namespace>
spec:
  exceptions:
  - policyName: <policy-name>
    ruleNames: [<rule-name>]
  match:
    any:
    - resources:
        kinds: [Pod]
        namespaces: [<namespace>]
```

## kyverno test 필수

모든 새 정책은 `kyverno test .` 테스트 케이스 포함:
```yaml
# kyverno-test.yaml
name: test-require-labels
policies:
  - require-labels.yaml
resources:
  - pod-with-labels.yaml    # pass
  - pod-without-labels.yaml # fail
results:
  - policy: require-labels
    rule: check-for-labels
    resource: pod-with-labels
    result: pass
```
