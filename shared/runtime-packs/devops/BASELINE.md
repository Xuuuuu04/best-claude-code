# 运维部署工程师 — Baseline Scenarios

## Scenario 1: FastAPI Multi-Stage Dockerfile + GitHub Actions CI/CD (Canonical)

**Input**:
- @architect confirmed topology: Docker Compose for staging, K8s for production
- @dev-lead: "FastAPI app, Python 3.12, PostgreSQL 16, Redis 7. Need Dockerfile, docker-compose for staging, GitHub Actions CI/CD pipeline (build → scan → push → deploy), and Nginx TLS termination. Target: staging environment."

**Expected Output Structure**:
- Topology confirmed by @architect — proceed

- Dockerfile (multi-stage):
  ```dockerfile
  # Stage 1: Build
  FROM python:3.12.4-slim AS builder
  WORKDIR /app
  RUN apt-get update && apt-get install -y --no-install-recommends gcc
  COPY requirements.txt .
  RUN pip install --user --no-cache-dir -r requirements.txt
  
  # Stage 2: Runtime
  FROM python:3.12.4-slim AS runtime
  RUN addgroup --system --gid 1000 appgroup && \
      adduser --system --uid 1000 --ingroup appgroup appuser
  WORKDIR /app
  COPY --from=builder --chown=appuser:appgroup /root/.local /home/appuser/.local
  COPY --chown=appuser:appgroup . .
  ENV PATH=/home/appuser/.local/bin:$PATH
  USER appuser
  EXPOSE 8000
  HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
  CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
  ```

- docker-compose.staging.yml:
  ```yaml
  services:
    app:
      image: ghcr.io/org/app:${GITHUB_SHA}
      user: "1000:1000"
      read_only: true
      depends_on:
        db:
          condition: service_healthy
        redis:
          condition: service_healthy
      environment:
        DATABASE_URL: ${DATABASE_URL}
        REDIS_URL: ${REDIS_URL}
      healthcheck:
        test: ["CMD", "python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"]
        interval: 30s
        timeout: 10s
        retries: 3
      deploy:
        resources:
          limits:
            cpus: '1.0'
            memory: 512M
    db:
      image: postgres:16.2-alpine
      environment:
        POSTGRES_DB: app_staging
        POSTGRES_USER: ${DB_USER}
        POSTGRES_PASSWORD: ${DB_PASSWORD}
      volumes:
        - pgdata:/var/lib/postgresql/data
      healthcheck:
        test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d app_staging"]
        interval: 10s
        timeout: 5s
        retries: 5
    redis:
      image: redis:7.2.4-alpine
      volumes:
        - redisdata:/data
      healthcheck:
        test: ["CMD", "redis-cli", "ping"]
        interval: 10s
        timeout: 5s
        retries: 5
  
  volumes:
    pgdata:
    redisdata:
  ```

- GitHub Actions pipeline:
  ```yaml
  name: CI/CD
  on:
    push:
      branches: [main]
  
  jobs:
    lint-test:
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - run: pip install ruff pytest
        - run: ruff check .
        - run: pytest
    
    build-scan:
      needs: lint-test
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: docker/build-push-action@v5
          with:
            context: .
            push: false
            tags: app:${{ github.sha }}
            cache-from: type=gha
            cache-to: type=gha,mode=max
        - uses: aquasecurity/trivy-action@master
          with:
            image-ref: app:${{ github.sha }}
            exit-code: 1
            severity: HIGH,CRITICAL
    
    deploy-staging:
      needs: build-scan
      runs-on: ubuntu-latest
      steps:
        - uses: actions/checkout@v4
        - uses: docker/build-push-action@v5
          with:
            context: .
            push: true
            tags: ghcr.io/org/app:${{ github.sha }}
        - run: |
            ssh deploy@staging "cd /opt/app && \
              GITHUB_SHA=${{ github.sha }} docker compose -f docker-compose.staging.yml up -d"
        - run: |
            ssh deploy@staging "curl -sf http://localhost:8000/health/ready || exit 1"
  ```

- Nginx configuration:
  ```nginx
  server {
      listen 443 ssl http2;
      server_name staging-api.example.com;
      
      ssl_certificate /etc/letsencrypt/live/staging-api.example.com/fullchain.pem;
      ssl_certificate_key /etc/letsencrypt/live/staging-api.example.com/privkey.pem;
      ssl_protocols TLSv1.2 TLSv1.3;
      ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;
      ssl_prefer_server_ciphers off;
      add_header Strict-Transport-Security "max-age=63072000" always;
      
      location / {
          proxy_pass http://app:8000;
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Request-Id $request_id;
          
          limit_req zone=api burst=20 nodelay;
      }
  }
  ```

- Observability verification:
  - /health/live: HTTP 200 `{ "status": "alive" }`
  - /health/ready: HTTP 200 `{ "status": "ready", "checks": { "database": "ok", "redis": "ok" } }`
  - /metrics: Prometheus format with `http_requests_total`, `http_request_duration_seconds_bucket`
  - Logs: JSON with trace_id extracted from X-Request-Id header

- Runbook with rollback:
  ```
  Rollback: ssh deploy@staging "cd /opt/app && docker compose pull && docker compose up -d"
  Verify: curl https://staging-api.example.com/health | jq '.version' → "1.2.2"
  ```

- Security baseline: non-root [✓] | version tag [✓] | secrets externalized [✓] | trivy [CRITICAL:0 HIGH:1] | TLS [✓]

**Key Decision Points**:
- No :latest tag anywhere — GitHub SHA is the version tag
- Non-root user verified with `docker run --rm --entrypoint whoami`
- Trivy scan gates the pipeline — CRITICAL/HIGH CVEs block push
- `read_only: true` in Compose for additional security
- Health check dependencies ensure DB and Redis are ready before app starts

---

## Scenario 2: BLOCKED — Topology Not Confirmed + Missing Observability

**Input**:
- @dev-lead: "Write the deployment config for the payment service. It's a Node.js app with Redis and PostgreSQL. We haven't decided if we're using Docker Compose or Kubernetes yet. Also, the app doesn't have a /health endpoint."

**Expected Output Structure**:

**BLOCKED — two conditions prevent writing deployment configuration:**

**Block 1 — Deployment topology not confirmed by @architect:**
"Docker Compose and Kubernetes are fundamentally different deployment targets with different configuration files, different secret management approaches, different health check syntax, different networking models, and different rollback procedures. Writing deployment configuration for an undecided topology produces files that may be discarded entirely when the decision is made.
Route: @architect must confirm the deployment topology (Compose vs K8s vs other) before I can write any deployment configuration."

**Block 2 — Application missing /health endpoint (MUST requirement):**
"The deployment runbook and container health checks depend on a /health endpoint. HEALTHCHECK in Dockerfile, readinessProbe in K8s, and `condition: service_healthy` in Compose all depend on an accessible health endpoint. An application deployed without a health endpoint is not observable.
Route: @backend must implement the /health endpoint before the deployment package is delivered. Requirements: HTTP 200 with `{ 'status': 'ok', 'timestamp': '...' }` and HTTP 503 when any critical dependency is unhealthy."

**Status**: BLOCKED on two items
**Unblock conditions**:
1. @architect confirms deployment topology
2. @backend implements /health endpoint

---

## Scenario 3: Production Incident Response — CVE in Base Image + Non-Root Fix

**Input**:
- Security audit finding: "Production container runs as root. Trivy found CVE-2024-7348 (CRITICAL) in postgresql-client 16.3. Both must be fixed before next release."

**Expected Output Structure**:

**Fix 1 — Non-Root User**

Current violation:
```dockerfile
FROM python:3.12.4-slim
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
# No USER directive — runs as root
```

Fix:
```dockerfile
FROM python:3.12.4-slim
RUN addgroup --system app && adduser --system --ingroup app app
COPY --chown=app:app . .
USER app
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

Verification:
```bash
docker build -t app:fix-nonroot .
docker run --rm --entrypoint whoami app:fix-nonroot
# Expected: app (not root)
```

**Fix 2 — CVE in postgresql-client**

Diagnosis: `postgresql-client` in base image for migration execution.

Option A (Preferred): Remove from runtime image, use separate migration job:
```dockerfile
# Runtime image — no postgresql-client
FROM python:3.12.4-slim AS runtime
# ... app only ...

# Separate migration job
FROM python:3.12.4-slim AS migrate
RUN apt-get update && apt-get install -y postgresql-client-16
COPY migrations/ ./migrations/
CMD ["sh", "-c", "psql $DATABASE_URL < migrations/latest.sql"]
```

Option B: Bump to patched version:
```dockerfile
FROM python:3.12.4-slim
RUN apt-get update && apt-get install -y postgresql-client-16=16.4-1
```

Verification:
```bash
trivy image --exit-code 1 --severity CRITICAL app:fix-cve
# Expected: CVE-2024-7348 no longer present
```

**Deployment impact**:
- Non-root fix may cause permission errors — test in staging first
- Migration job separation requires @devops coordination for job execution
- Rollback procedure updated to reference new image SHAs
