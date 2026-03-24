## 1. Helm 저장소 추가
가장 먼저 Kyverno 공식 Helm 차트 저장소를 로컬에 추가하고 최신 상태로 업데이트합니다.

```bash
# Kyverno 리포지토리 추가
helm repo add kyverno https://kyverno.github.io/kyverno/

# 최신 차트 정보 업데이트
helm repo update
```

## 2. Kyverno 네임스페이스 생성
관리의 편의성을 위해 전용 네임스페이스를 생성합니다. (설치 명령어에서 `--create-namespace` 옵션을 써도 무방합니다.)

```bash
kubectl create namespace kyverno
```

## 3. Helm 차트 설치
Kyverno는 크게 두 가지 방식으로 설치할 수 있습니다. 본인의 환경에 맞는 방식을 선택하세요.

### A. 학습용/테스트용 (단일 노드)
가장 기본적인 설치 방법입니다.

```bash
helm install kyverno kyverno/kyverno -n kyverno
```

### B. 운영 환경용 (High Availability)
서비스 안정성을 위해 컨트롤러들을 고가용성 모드(레플리카 분산)로 실행하는 것을 권장합니다.

```bash
helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --set admissionController.replicas=3 \
  --set backgroundController.replicas=2 \
  --set cleanupController.replicas=2 \
  --set reportsController.replicas=2
```

## 4. (필수) 기본 정책 패키지 설치
Kyverno 엔진만 설치하면 클러스터에 아무런 규칙이 적용되지 않습니다. Kyverno 팀에서 제공하는 **표준 정책 세트(Pod 보안 표준 등)**를 함께 설치해 주는 것이 좋습니다.

```bash
helm install kyverno-policies kyverno/kyverno-policies -n kyverno
```
---

## 5. 설치 결과 확인
모든 Pod이 `Running` 상태인지 확인해 봅시다.

```bash
kubectl get pods -n kyverno
```
