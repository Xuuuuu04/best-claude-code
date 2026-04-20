# 运维部署工程师 — Output Contract Reference

## Standard Output Format

```
## Deployment Package: [Project Name] — [Environment]

**Deployment Form**: [Docker Compose / Kubernetes + Helm / Serverless]
**Target Environment**: [dev / staging / production]

### Delivered Files
| File | Path | Description |
|------|------|-------------|
| Dockerfile | `docker/Dockerfile` | Multi-stage build, non-root user, health check |
| docker-compose.prod.yml | `docker/docker-compose.prod.yml` | Production orchestration |
| GitHub Actions workflow | `.github/workflows/deploy.yml` | CI/CD pipeline |
| Nginx config | `nginx/nginx.conf` | TLS termination, rate limiting |
| Deployment runbook | `docs/runbook.md` | Step-by-step with verification |

### Security Baseline Confirmation
| Check | Status | Evidence |
|-------|--------|----------|
| Non-root container | PASS | `docker run --rm --entrypoint whoami app:v1.2.3` → `appuser` |
| Explicit version tag | PASS | `node:20.12.2-alpine` (not `:latest`) |
| Secrets externalized | PASS | All credentials in K8s Secrets / Vault |
| Image scan result | PASS | trivy: CRITICAL: 0, HIGH: 2 (documented) |
| TLS configured | PASS | TLSv1.2+, HSTS, OCSP stapling |
| Read-only root FS | PASS | `readOnlyRootFilesystem: true` in K8s |

### Observability Minimum Set
| Component | Status | Details |
|-----------|--------|---------|
| /health endpoint | PASS | `/health/live` (liveness), `/health/ready` (readiness with DB check) |
| /metrics endpoint | PASS | Prometheus format, 8 application metrics |
| Structured JSON logs | PASS | `{"timestamp":"...","level":"INFO","service":"api","trace_id":"abc123"}` |
| Business metrics | PASS | 6 signals: orders, payments, signups, search latency, active sessions, errors |

### Rollback Summary
**Command**: `kubectl rollout undo deployment/api --to-revision=42`

**Verification**:
```bash
kubectl rollout status deployment/api
# Expected: deployment "api" successfully rolled out

curl -s https://api.example.com/health | jq '.version'
# Expected: "1.2.2" (previous version)
```

**If rollback fails**:
1. `kubectl get pods -l app=api` — check pod status
2. `kubectl describe deployment/api` — check events
3. Manual image swap: `kubectl set image deployment/api api=app:v1.2.2`

### Next Steps
- @test-func — verify deployment using runbook steps 1-7
- @security-auditor — review image scan results and secret management
```

## BLOCKED Output Format

```
## Deployment Package: [Project Name] — [Environment]

**Status**: BLOCKED

**Blocked on**: [specific missing item]
**Blocked by**: [@role or user]
**Rationale**: [why this blocks deployment]

**What I have done**: [completed work despite block]
**What I need**: [specific unblock condition]

**Unblock conditions**:
1. [condition 1]
2. [condition 2]
```

## Filled Example — FastAPI + PostgreSQL Deployment

```
## Deployment Package: Payment API — Staging

**Deployment Form**: Docker Compose (staging) / Kubernetes (production)
**Target Environment**: staging

### Delivered Files
| File | Path | Description |
|------|------|-------------|
| Dockerfile | `docker/Dockerfile` | Multi-stage Python 3.12, non-root user |
| docker-compose.staging.yml | `docker/docker-compose.staging.yml` | App + PostgreSQL + Redis |
| CI workflow | `.github/workflows/staging.yml` | lint → test → build → scan → deploy |
| Nginx config | `nginx/staging.conf` | TLSv1.3, HSTS, rate limiting |
| Runbook | `docs/runbook-staging.md` | Deployment and rollback procedures |

### Security Baseline Confirmation
| Check | Status | Evidence |
|-------|--------|----------|
| Non-root container | PASS | `whoami` → `appuser` (UID 1000) |
| Explicit version tag | PASS | `python:3.12.4-slim` |
| Secrets externalized | PASS | `.env.staging` in .gitignore, values in GitHub Secrets |
| Image scan result | PASS | trivy: CRITICAL: 0, HIGH: 1 (openssl CVE-2024-XXXX, patched in base image) |
| TLS configured | PASS | Let's Encrypt certificate, TLSv1.2+ only |

### Observability Minimum Set
| Component | Status | Details |
|-----------|--------|---------|
| /health/live | PASS | HTTP 200, simple process check |
| /health/ready | PASS | HTTP 200 if DB + Redis connected; HTTP 503 otherwise |
| /metrics | PASS | `http_requests_total`, `http_request_duration_seconds`, `db_connections_active` |
| Structured logs | PASS | JSON format with trace_id, no PII |
| Business metrics | PASS | `payment_attempts_total`, `payment_success_rate`, `payment_latency_seconds` |

### Rollback Summary
**Staging**: `docker compose -f docker-compose.staging.yml pull && docker compose up -d`
**Previous image**: `docker tag app:previous app:latest && docker compose up -d`

**Verification**:
```bash
curl -s https://staging-api.example.com/health | jq '.version'
# Expected: "1.2.2"
```

### Next Steps
- @test-func — run smoke tests against staging environment
- @security-auditor — review trivy scan output and secret rotation policy
```
