# Kyverno CLI 가이드

Kyverno CLI를 사용하면 **클러스터 없이 로컬에서** 정책을 테스트하고 적용 결과를 미리 확인할 수 있습니다.
CI/CD 파이프라인에서 매니페스트 검증에 활용하기 좋습니다.

---

## 설치

```bash
# macOS (Homebrew)
brew install kyverno

# Linux (직접 다운로드)
curl -sLO https://github.com/kyverno/kyverno/releases/latest/download/kyverno_linux_amd64.tar.gz
tar -xzf kyverno_linux_amd64.tar.gz
mv kyverno /usr/local/bin/

# 버전 확인
kyverno version
```

---

## kyverno apply — 정책 즉시 적용 결과 확인

클러스터 없이 정책 파일과 리소스 파일을 로컬에서 매칭합니다.

### 기본 사용법

```bash
# 단일 정책, 단일 리소스
kyverno apply policies/validate/require-labels.yaml \
  --resource manifests/pod.yaml

# 여러 정책을 디렉토리로 지정
kyverno apply policies/validate/ \
  --resource manifests/pod.yaml

# 여러 리소스 파일
kyverno apply policies/ \
  --resource manifests/
```

### 출력 예시

```
Applying 1 policy rule to 1 resource...

policy require-app-label -> resource default/Pod/test-pod
  FAIL: Pod에는 반드시 'app' 레이블이 있어야 합니다.

pass: 0, fail: 1, warn: 0, error: 0, skip: 0
```

### 유용한 옳션

```bash
# 상세 출력
kyverno apply policy.yaml --resource pod.yaml --detailed-results

# Audit 모드 (위반해도 WARN으로 출력)
kyverno apply policy.yaml --resource pod.yaml --audit-warn

# 특정 네임스페이스 지정
kyverno apply policy.yaml --resource pod.yaml -n production
```

---

## kyverno test — 테스트 케이스 실행

`kyverno test`는 정책, 리소스, 예상 결과를 함께 정의하여 **자동화 테스트**를 수행합니다.

### 디렉토리 구조

```
tests/
├── kyverno-test.yaml         # 테스트 정의 파일
├── policies/
│   └── require-labels.yaml
└── resources/
    ├── pod-with-label.yaml   # 통과해야 하는 리소스
    └── pod-no-label.yaml     # 실패해야 하는 리소스
```

### kyverno-test.yaml 작성

```yaml
name: require-labels-test
policies:
  - policies/require-labels.yaml
resources:
  - resources/pod-with-label.yaml
  - resources/pod-no-label.yaml
results:
  - policy: require-app-label
    rule: check-app-label
    resource: pod-with-label
    kind: Pod
    result: pass             # 통과 예상

  - policy: require-app-label
    rule: check-app-label
    resource: pod-no-label
    kind: Pod
    result: fail             # 실패 예상
```

### 테스트 실행

```bash
# 단일 테스트 디렉토리 실행
kyverno test tests/

# 상세 출력
kyverno test tests/ --detailed-results

# 예상 결과와 다른 경우만 출력
kyverno test tests/ --fail-only
```

### 출력 예시

```
Loading test  ( tests/kyverno-test.yaml ) ...
  Loading values/variables ...
  Loading policies ...
  Loading resources ...
  Applying 1 policy to 2 resources ...
  Checking results ...

│────│─────────────────│──────────────────│───────────│──────│────────│
│ #  │ POLICY          │ RULE             │ RESOURCE  │ TYPE │ RESULT │
│────│─────────────────│──────────────────│───────────│──────│────────│
│  1 │ require-app-label│ check-app-label │ pod-with-label │ Pod │ Pass │
│  2 │ require-app-label│ check-app-label │ pod-no-label   │ Pod │ Pass │
│────│─────────────────│──────────────────│───────────│──────│────────│

Test Summary: 2 tests passed and 0 tests failed
```

---

## CI/CD 파이프라인 통합

### GitHub Actions 예시

```yaml
name: Kyverno Policy Test

on:
  pull_request:
    paths:
      - 'manifests/**'
      - 'policies/**'

jobs:
  kyverno-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Kyverno CLI
        run: |
          curl -sLO https://github.com/kyverno/kyverno/releases/latest/download/kyverno_linux_amd64.tar.gz
          tar -xzf kyverno_linux_amd64.tar.gz
          sudo mv kyverno /usr/local/bin/

      - name: Run Kyverno tests
        run: kyverno test tests/ --detailed-results

      - name: Validate manifests against policies
        run: kyverno apply policies/ --resource manifests/ --detailed-results
```

---

## kyverno apply와 dry-run 비교

| 방법 | 클러스터 필요 | 사용 시점 |
|------|--------------|-----------|
| `kyverno apply` | 불필요 | 로컬 개발, CI/CD |
| `kubectl apply --dry-run=server` | 필요 | 실제 Webhook 통과 여부 확인 |

```bash
# 실제 클러스터 Webhook으로 검증 (dry-run)
kubectl apply --dry-run=server -f pod.yaml
```

---

## 참고

- [Kyverno CLI 공식 문서](https://kyverno.io/docs/kyverno-cli/)
- [kyverno test 레퍼런스](https://kyverno.io/docs/kyverno-cli/usage/test/)
