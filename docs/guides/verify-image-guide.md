# Kyverno Image Verification 가이드

Kyverno는 **Cosign** 또는 **Notary**로 서명된 컨테이너 이미지만 배포되도록 강제할 수 있습니다.
서명되지 않은 이미지나 변조된 이미지의 배포를 사전에 차단합니다.

---

## 동작 원리

```
Pod 생성 요청
        │
        ▼
[Kyverno verifyImages Rule]
        │
        ├── OCI Registry에서 이미지 서명/attestation 확인
        │        ├── 서명 유효 → 허용
        │        └── 서명 없음 or 유효하지 않음 → 차단
        │
        └── 이미지 digest로 tag를 고정 (mutate)
                예: nginx:1.25 → nginx@sha256:abc123...
```

---

## Cosign으로 이미지 서명하기

### 1. Cosign 설치

```bash
# macOS
brew install cosign

# Linux
curl -sLO https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64
chmod +x cosign-linux-amd64 && mv cosign-linux-amd64 /usr/local/bin/cosign
```

### 2. 키 쌍 생성

```bash
cosign generate-key-pair
# cosign.key  (프라이빗 키 — 안전하게 보관)
# cosign.pub  (퍼블릭 키 — Kyverno 정책에 등록)
```

### 3. 이미지 서명

```bash
# ECR에 푸시한 이미지 서명
IMAGE=123456789.dkr.ecr.ap-northeast-2.amazonaws.com/my-app:1.0.0

cosign sign --key cosign.key $IMAGE
```

### 4. 서명 검증

```bash
cosign verify --key cosign.pub $IMAGE
```

---

## Kyverno verifyImages 정책

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  validationFailureAction: Enforce
  background: false    # Admission 시점에만 검증
  rules:
    - name: check-image-signature
      match:
        any:
        - resources:
            kinds:
              - Pod
      verifyImages:
        - imageReferences:
            - "123456789.dkr.ecr.ap-northeast-2.amazonaws.com/my-app*"
          attestors:
            - count: 1
              entries:
              - keys:
                  publicKeys: |-
                    -----BEGIN PUBLIC KEY-----
                    MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
                    -----END PUBLIC KEY-----
```

---

## 이미지 tag → digest 자동 고정

verifyImages Rule은 검증이 성공하면 이미지 태그를 **digest로 자동 변환**합니다.
이는 빌드 이후 이미지가 변조되더라도 이미 배포된 Pod가 동일한 이미지를 유지하도록 보장합니다.

```
검증 전: my-app:1.0.0
검증 후: my-app@sha256:e3d5b8a1...  (Kyverno가 자동으로 mutate)
```

이 동작을 비활성화하려면:

```yaml
verifyImages:
  - imageReferences:
      - "my-app*"
    mutateDigest: false    # 기본값: true
```

---

## Attestation 검증 (SBOM, 취약점 스캔 결과 등)

단순 서명 외에 빌드 정보, SBOM, 취약점 스캔 결과 같은 **attestation**도 검증할 수 있습니다.

```yaml
verifyImages:
  - imageReferences:
      - "my-app*"
    attestors:
      - entries:
          - keys:
              publicKeys: |-
                -----BEGIN PUBLIC KEY-----
                ...
                -----END PUBLIC KEY-----
    attestations:
      - predicateType: https://slsa.dev/provenance/v0.2    # SLSA 프로비넌스
        conditions:
          - all:
            - key: "{{ builder.id }}"
              operator: Equals
              value: "https://github.com/actions/runner"   # GitHub Actions만 허용
```

---

## ECR에서 Cosign 사용 시 IRSA 설정

ECR은 OCI 호환이므로 Cosign이 이미지 서명을 저장할 수 있습니다.
EKS에서 Kyverno가 ECR에 접근하려면 IRSA 또는 Node IAM Role 설정이 필요합니다.

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:ap-northeast-2:123456789:repository/*"
    }
  ]
}
```

---

## 검증 실습

```bash
# 1. 정책 적용
kubectl apply -f verify-image-policy.yaml

# 2. 서명된 이미지로 Pod 생성 (성공)
kubectl run signed-pod --image=123456789.dkr.ecr.ap-northeast-2.amazonaws.com/my-app:1.0.0

# 3. 서명되지 않은 이미지로 Pod 생성 (실패)
kubectl run unsigned-pod --image=nginx:latest
# Error: admission webhook denied — image signature not found

# 4. 생성된 Pod의 이미지가 digest로 변환되었는지 확인
kubectl get pod signed-pod -o jsonpath='{.spec.containers[0].image}'
# 123456789.dkr.ecr.ap-northeast-2.amazonaws.com/my-app@sha256:e3d5b8a1...
```

---

## 참고

- [공식 문서 — Image Verification](https://kyverno.io/docs/writing-policies/verify-images/)
- [Cosign 공식 문서](https://docs.sigstore.dev/cosign/overview/)
- [SLSA — Supply Chain Levels for Software Artifacts](https://slsa.dev/)
