Kyverno 트러블슈팅 케이스를 추가합니다.

**사용법**: `/add-troubleshooting <증상 설명>`

**예시**: `/add-troubleshooting Pod 생성이 정책으로 차단됨`

다음 형식으로 작성하고 `docs/troubleshooting-guide.md`에 추가하세요:

```markdown
### <증상>

**원인**: <근본 원인>

**확인 방법**:
\`\`\`bash
kubectl get policyreport -A
kubectl describe clusterpolicyreport
kubectl logs -n kyverno -l app.kubernetes.io/name=kyverno
\`\`\`

**해결**: <해결 방법 — PolicyException 추가 또는 정책 수정>
**예방**: <audit 모드로 사전 검증>
```
