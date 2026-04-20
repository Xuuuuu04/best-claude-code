# 运维部署工程师 — Anti-Patterns Reference

## Named Anti-Patterns

---

### Anti-Pattern 1: Root Container (CRITICAL)

**Definition**: Dockerfile without USER directive, causing the container to run as root (UID 0).

**Manifestations**:
```dockerfile
# BAD — FORBIDDEN: no USER directive
FROM python:3.12.4-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD ["python", "app.py"]
# Container runs as root — UID 0
```

**Why it's dangerous**: If an attacker exploits the application, they gain root privileges inside the container. Container escape vulnerabilities (CVE-2019-5736, CVE-2022-0847) become kernel-level compromises when the container runs as root. Even without escape, root inside the container can modify system files, install malware, and pivot to other containers.

**Correction**: Always add non-root user before CMD.

```dockerfile
# GOOD — non-root user
FROM python:3.12.4-slim
WORKDIR /app

# Create non-root user
RUN addgroup --system --gid 1000 appgroup && \
    adduser --system --uid 1000 --ingroup appgroup appuser

# Install dependencies as root (for layer caching)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application with correct ownership
COPY --chown=appuser:appgroup . .

# Switch to non-root user
USER appuser

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s CMD curl -f http://localhost:8000/health || exit 1
CMD ["python", "app.py"]
```

**Verification**:
```bash
docker build -t app:test .
docker run --rm --entrypoint whoami app:test
# Expected: appuser (NOT root)
```

---

### Anti-Pattern 2: Latest Tag (CRITICAL)

**Definition**: Using `:latest` tag for container images in any non-local environment.

**Manifestations**:
```yaml
# BAD — FORBIDDEN: latest in K8s manifest
spec:
  containers:
    - name: api
      image: nginx:latest  # NON-REPRODUCIBLE
```

```dockerfile
# BAD — FORBIDDEN: latest in Dockerfile
FROM node:latest  # Changes without warning
```

```yaml
# BAD — FORBIDDEN: latest in CI
- run: docker push myapp:latest  # Overwrites previous latest
```

**Why it's dangerous**: `:latest` is a moving target. The image referenced today may be different tomorrow. Incident root-cause analysis becomes impossible: "we were running latest" tells you nothing about what actually ran. Rollback to "previous latest" is undefined. Reproducible builds are impossible.

**Correction**: Pin explicit version tags everywhere.

```yaml
# GOOD — pinned version
spec:
  containers:
    - name: api
      image: nginx:1.25.3-alpine-slim  # Explicit, immutable
```

```dockerfile
# GOOD — pinned base image
FROM node:20.12.2-alpine@sha256:bf77dc26e48ea95fca9d1aceb5acfa69d2e546b765ec2abfb25835ec6d2e8ed4
# SHA256 pin = cryptographically immutable
```

**Tag strategy**:
- Application images: use Git SHA (`app:abc1234`) or semantic version (`app:v1.2.3`)
- Base images: use full version + distro (`python:3.12.4-slim`)
- Critical environments: add SHA256 digest pin for immutability

---

### Anti-Pattern 3: Secrets in Version Control (CRITICAL)

**Definition**: Embedding credentials, API keys, or certificates in Dockerfiles, Compose files, K8s manifests, or any file tracked by Git.

**Manifestations**:
```dockerfile
# BAD — FORBIDDEN: hardcoded secret
ENV DATABASE_URL=postgres://user:password123@db:5432/mydb
ENV AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
```

```yaml
# BAD — FORBIDDEN: secret in K8s manifest
apiVersion: v1
kind: Secret
stringData:
  password: SuperSecret123  # Still in Git!
```

**Why it's dangerous**: Secrets in Git are forever. Even if deleted, they remain in Git history. Anyone with repository access has the credentials. Automated scanners (GitHub secret scanning, gitleaks) will flag and potentially revoke exposed credentials.

**Correction**: Externalize all secrets.

```dockerfile
# GOOD — env var reference only
ENV DATABASE_URL=""
# Set at runtime: docker run -e DATABASE_URL=...
```

```yaml
# GOOD — K8s Secret with external reference
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:
  url: ""  # Populated by External Secrets Operator or Vault Agent
```

```yaml
# GOOD — GitHub Actions with OIDC (no static credentials)
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/GitHubActionsRole
    aws-region: us-east-1
# No AWS_ACCESS_KEY_ID in repository secrets
```

---

### Anti-Pattern 4: Metric Drought (HIGH)

**Definition**: Deployment package lacking /metrics endpoint, structured logs, or health checks.

**Manifestations**:
```yaml
# BAD — FORBIDDEN: no observability
spec:
  containers:
    - name: api
      image: app:v1.2.3
      # No livenessProbe
      # No readinessProbe
      # No /metrics
```

**Why it's dangerous**: A system without metrics is invisible. You cannot alert on failures, diagnose performance issues, or understand usage patterns. The first incident becomes the discovery moment for missing observability — at the worst possible time, under time pressure.

**Correction**: Observability minimum set is mandatory.

```yaml
# GOOD — complete observability
spec:
  containers:
    - name: api
      image: app:v1.2.3
      livenessProbe:
        httpGet:
          path: /health/live
          port: 8080
        initialDelaySeconds: 10
        periodSeconds: 30
      readinessProbe:
        httpGet:
          path: /health/ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 10
      ports:
        - containerPort: 8080
          name: http
        - containerPort: 9090
          name: metrics
```

**Business metrics checklist** (5-10 signals):
1. `business_orders_created_total` — order creation rate
2. `business_payment_success_rate` — payment success percentage
3. `business_user_signups_total` — new user registration rate
4. `business_search_latency_seconds` — search response time
5. `business_active_sessions` — concurrent user sessions

---

### Anti-Pattern 5: No Rollback Plan (CRITICAL)

**Definition**: Deployment runbook without a tested rollback procedure.

**Manifestations**:
```markdown
# BAD — FORBIDDEN: no rollback section
## Deployment Runbook
1. Build image
2. Deploy to production
3. Done
```

**Why it's dangerous**: When a deployment fails in production (and it will), the team must improvise recovery under time pressure. Improvised rollbacks often make things worse: partial rollbacks, data inconsistency, extended downtime.

**Correction**: Every runbook has a Rollback section with command, expected output, and verification.

```markdown
## GOOD — complete rollback procedure
### Rollback Procedure

**Command**: `kubectl rollout undo deployment/api --to-revision=42`

**Expected output**:
```
deployment.apps/api rolled back
```

**Verification**:
```bash
kubectl rollout status deployment/api
# Expected: deployment "api" successfully rolled out

curl -s https://api.example.com/health | jq '.version'
# Expected: "1.2.2" (previous version)
```

**If rollback fails**:
1. Check pod status: `kubectl get pods -l app=api`
2. Check events: `kubectl describe deployment/api`
3. Manual rollback: `kubectl set image deployment/api api=app:v1.2.2`
```

---

### Anti-Pattern 6: Single-Stage Dockerfile (MEDIUM)

**Definition**: Dockerfile with a single stage, including build tools and dependencies in the runtime image.

**Manifestations**:
```dockerfile
# BAD — FORBIDDEN: single stage with build tools
FROM node:20.12.2
WORKDIR /app
COPY package*.json ./
RUN npm install  # devDependencies included!
COPY . .
RUN npm run build
CMD ["node", "dist/main.js"]
# Image size: 1.2GB (includes gcc, python, build tools)
```

**Why it's dangerous**: Larger attack surface (more packages = more CVEs), slower deployments, wasted bandwidth and storage.

**Correction**: Multi-stage build with minimal runtime.

```dockerfile
# GOOD — multi-stage
# Stage 1: Build
FROM node:20.12.2-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build && npm prune --production

# Stage 2: Runtime (no build tools)
FROM node:20.12.2-alpine AS runtime
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=build --chown=app:app /app/dist ./dist
COPY --from=build --chown=app:app /app/node_modules ./node_modules
COPY --from=build --chown=app:app /app/package.json ./
USER app
EXPOSE 3000
HEALTHCHECK --interval=30s CMD node -e "require('http').get('http://localhost:3000/health')"
CMD ["node", "dist/main.js"]
# Image size: 180MB (vs 1.2GB)
```

---

### Anti-Pattern 7: Missing Health Checks (HIGH)

**Definition**: Container orchestration without liveness and readiness probes.

**Manifestations**:
```yaml
# BAD — FORBIDDEN: no probes
spec:
  containers:
    - name: api
      image: app:v1.2.3
      # No livenessProbe — Kubernetes won't know if app is dead
      # No readinessProbe — traffic sent before app is ready
```

**Why it's dangerous**: Without livenessProbe, Kubernetes cannot detect a hung process and restart it. Without readinessProbe, traffic is routed to pods that are still starting up, causing 502/503 errors during rolling updates.

**Correction**: Always define both probes with appropriate settings.

```yaml
# GOOD — proper probes
spec:
  containers:
    - name: api
      image: app:v1.2.3
      livenessProbe:
        httpGet:
          path: /health/live
          port: 8080
        initialDelaySeconds: 30  # Allow startup
        periodSeconds: 10
        failureThreshold: 3  # Restart after 30s of failures
      readinessProbe:
        httpGet:
          path: /health/ready
          port: 8080
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 2  # Remove from LB after 10s
```

---

### Anti-Pattern 8: CI/CD Without Security Gates (HIGH)

**Definition**: Pipeline that builds and deploys without vulnerability scanning or secret detection.

**Manifestations**:
```yaml
# BAD — FORBIDDEN: no security gates
jobs:
  deploy:
    steps:
      - run: docker build -t app:latest .
      - run: docker push app:latest
      - run: kubectl set image deployment/app app=app:latest
      # No scan, no secret check, no sign
```

**Why it's dangerous**: Vulnerable images deployed directly to production. Secrets committed to code are deployed before detection. No audit trail of what was deployed.

**Correction**: Security gates at every stage.

```yaml
# GOOD — security gates
jobs:
  build:
    steps:
      - run: docker build -t app:${{ github.sha }} .
      
  scan:
    needs: build
    steps:
      - run: trivy image --exit-code 1 --severity HIGH,CRITICAL app:${{ github.sha }}
      - run: gitleaks detect --source . --verbose
      
  sign:
    needs: scan
    steps:
      - run: cosign sign --key env://COSIGN_PRIVATE_KEY app:${{ github.sha }}
      
  deploy:
    needs: sign
    steps:
      - run: kubectl set image deployment/app app=app:${{ github.sha }}
```
