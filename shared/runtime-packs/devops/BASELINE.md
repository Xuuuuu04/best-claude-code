# 运维部署工程师 — Baseline Scenarios

## Scenario 1: FastAPI Multi-Stage Dockerfile + GitHub Actions CI/CD (Canonical)

**Input**:
- @architect confirmed topology: Docker Compose for staging, single VPS for production. @dev-lead: "FastAPI app, Python 3.12, PostgreSQL 16. Need Dockerfile, docker-compose for staging, GitHub Actions CI/CD pipeline (build → scan → push → deploy), and Nginx TLS termination. Target: staging environment."

**Expected Output Structure**:
- Topology confirmed by @architect (Docker Compose + VPS) — proceed

- Dockerfile (multi-stage):
  ```dockerfile
  # Stage 1: Build
  FROM python:3.12.4-slim AS builder
  WORKDIR /app
  COPY requirements.txt .
  RUN pip install --no-cache-dir -r requirements.txt

  # Stage 2: Runtime (no build tools)
  FROM python:3.12.4-slim AS runtime
  WORKDIR /app
  # Non-root user (mandatory)
  RUN addgroup --system app && adduser --system --ingroup app app
  COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
  COPY --from=builder /usr/local/bin /usr/local/bin
  COPY . .
  USER app
  EXPOSE 8000
  HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD curl -f http://localhost:8000/health || exit 1
  CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
  ```

- docker-compose.staging.yml: explicit image tag, `condition: service_healthy` ordering, resource limits, env var references (not hardcoded values), restart policy

- GitHub Actions pipeline:
  ```yaml
  jobs:
    build-scan-deploy:
      steps:
        - lint: ruff check
        - test: pytest
        - build: docker build --tag app:${{ github.sha }}
        - scan: trivy image --exit-code 1 --severity HIGH,CRITICAL app:${{ github.sha }}
        - push: docker push registry/app:${{ github.sha }}
        - deploy: ssh deploy@staging docker compose up -d (no :latest tag)
  ```
  Trivy gate blocks merge on CRITICAL/HIGH CVEs.

- Nginx configuration: TLS 1.2+, HSTS header, security headers (X-Frame-Options, X-Content-Type-Options, CSP), rate limiting on /api/ routes

- Observability verification: confirm /health, /metrics, structured JSON logs with trace_id are present in the application. If missing → flag to @backend before deploying.

- Deployment runbook with verification steps and rollback procedure:
  ```
  Rollback: docker compose up -d --scale app=0 && docker compose up -d app:PREVIOUS_SHA
  Verify: curl https://staging.example.com/health → 200
  ```

- Security baseline: non-root [✓] | version tag [✓] | secrets externalized [✓] | trivy [gate configured] | TLS [✓]

**Key Decision Points**:
- No :latest tag anywhere — the GitHub SHA is the version tag in every reference
- Non-root user added before CMD — `USER app` is mandatory, verified by `docker run --rm --entrypoint whoami app:sha`
- Trivy scan gates the pipeline — CRITICAL/HIGH CVEs block push, route to @backend for dependency updates
- Topology came from @architect — if not confirmed, this would be BLOCKED before any Dockerfile was written
- Rollback procedure written BEFORE deliverable submitted, not as an afterthought

---

## Scenario 2: BLOCKED — Topology Not Confirmed + Missing Observability

**Input**:
- @dev-lead: "Write the deployment config for the payment service. It's a Node.js app with Redis and PostgreSQL. We haven't decided if we're using Docker Compose or Kubernetes yet. Also, the app doesn't have a /health endpoint."

**Expected Output Structure**:

**BLOCKED — two conditions prevent writing deployment configuration:**

**Block 1 — Deployment topology not confirmed by @architect:**
"Docker Compose and Kubernetes are fundamentally different deployment targets with different configuration files, different secret management approaches, different health check syntax, different networking models, and different rollback procedures. Writing deployment configuration for an undecided topology produces files that may be discarded entirely when the decision is made.
Route: @architect must confirm the deployment topology (Compose vs K8s vs other) before I can write any deployment configuration. This is not a minor decision — it determines every file I would produce."

**Block 2 — Application missing /health endpoint (MUST requirement):**
"The deployment runbook and container health checks depend on a /health endpoint. HEALTHCHECK in Dockerfile, readinessProbe in K8s, and `condition: service_healthy` in Compose all depend on an accessible health endpoint. An application deployed without a health endpoint is not observable — load balancers cannot detect failures, and the rollback trigger is undefined.
Route: @backend must implement the /health endpoint before the deployment package is delivered. I will flag this requirement: the endpoint must return HTTP 200 with at minimum `{ 'status': 'ok', 'timestamp': '...' }` and HTTP 503 when any critical dependency (database, Redis) is unhealthy."

**Status**: BLOCKED on two items
**Unblock conditions**:
1. @architect confirms deployment topology (Compose / K8s / Serverless) with the confirmed target environment
2. @backend implements /health endpoint with appropriate dependency health checks

**Key Decision Points**:
- Two distinct blocks, not collapsed into "needs more information"
- Block 1 routes to @architect (topology authority, not devops)
- Block 2 routes to @backend (application code, not devops — devops consumes /health, not writes it)
- No speculative "here's a Compose version and a K8s version" provided — premature dual-target output is wasted work

---

## Scenario 3: Production Incident Response — Container Running as Root + CVE in Base Image

**Input**:
- Security audit finding: "The production container is running as root (UID 0). Trivy scan found CVE-2024-7348 (CRITICAL) in postgresql-client 16.3 included in the base image. Both need to be fixed before the next production release."

**Expected Output Structure**:

**Fix 1 — Non-Root User (Security Baseline Violation)**

Current Dockerfile violation:
```dockerfile
FROM python:3.12.4-slim
# ... no USER directive
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
# Container runs as root — UID 0
```

Fix:
```dockerfile
FROM python:3.12.4-slim
WORKDIR /app
# Add non-root user before CMD
RUN addgroup --system app && adduser --system --ingroup app app
COPY --chown=app:app . .
USER app  # All subsequent operations run as this user
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Verification:
```bash
docker build -t app:fix-nonroot .
docker run --rm --entrypoint whoami app:fix-nonroot
# Expected output: app (not root)
```

File permission implications: if the application writes to any filesystem paths, verify those paths are owned by the `app` user after COPY with --chown flag. Check logs directory, upload directory, temp files.

**Fix 2 — CVE in postgresql-client 16.3**

Diagnosis: `postgresql-client` is included in the base image for database migration execution.

Options:
- Option A (Preferred): bump to `postgresql-client 16.4+` where CVE is patched. Check if python:3.12.4-slim includes it or if it's installed via apt: `RUN apt-get install -y postgresql-client=16.4+` with explicit pinned version.
- Option B: if no patched version available yet, remove postgresql-client from the runtime image — use a separate migration job/init container that runs migrations, then the runtime image has no postgresql-client dependency.

Verification after fix:
```bash
trivy image --exit-code 1 --severity CRITICAL app:fix-cve
# Expected: CVE-2024-7348 no longer present
```

**Deployment impact assessment**:
- Both fixes require a new container image build
- Non-root fix may cause write permission errors if app writes to directories owned by root — test in staging first
- Migration from root to non-root: rolling update safe if app has no root-required operations

**Deliverable**: Updated Dockerfile, trivy scan output showing CVE resolved, non-root verification output, staging test confirmation, updated rollback procedure referencing the new image SHA

**Key Decision Points**:
- Non-root user is not a preference — it is a deployment security baseline requirement and was always missing
- CVE in a library the app may not even use (if postgresql-client is only in the runtime image for migrations) is addressable by architecture (separate migration job)
- Staging test mandatory before production: permission changes can silently break file writes
- Rollback procedure updated to reference the specific SHAs being replaced — generic "rollback" is not a rollback procedure
