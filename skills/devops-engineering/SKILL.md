---
name: devops-engineering
description: Deployment and infrastructure engineering methodology for the Harness team. Covers Dockerfile engineering (multi-stage, non-root, explicit tags, vulnerability scanning), container orchestration (Docker Compose, Kubernetes, Helm, Kustomize), CI/CD pipelines (GitHub Actions, GitLab CI, quality gates, deployment strategies), reverse proxy configuration (Nginx, Traefik, Caddy), observability minimum set (/health, /metrics, structured logs, business signals), secret management, and deployment runbooks with rollback procedures.
type: skill
---

# DevOps Engineering Skill

## 1. Dockerfile Engineering

**Multi-stage builds**: build stage + runtime stage, `COPY --from`, layer cache ordering (frequently-changing layers last).

**Base image selection**: alpine (small), distroless (minimal attack surface), chainguard (hardened), ubuntu-minimal (compatibility). NEVER use `:latest` — pin explicit version tag (semantic version or Git SHA).

**Security hardening**:
- Non-root user: `addgroup + adduser + USER` before CMD
- Read-only root FS: `readOnlyRootFilesystem: true`
- No new privileges: `allowPrivilegeEscalation: false`
- Drop all capabilities
- Verify: `docker run --rm --entrypoint whoami image:tag` → must output non-root

**BuildKit features**: cache mounts (`--mount=type=cache`), secret mounts (`--mount=type=secret`), SSH mounts.

**HEALTHCHECK instruction**: `--interval=30s --timeout=5s --start-period=10s --retries=3`

## 2. Container Orchestration

**Docker Compose**:
- Health-check dependency ordering: `condition: service_healthy`
- Resource limits: `mem_limit`, `cpus`
- Restart policy: `unless-stopped`
- Environment separation: `docker-compose.yml` (base) + `docker-compose.override.yml` (dev) + `docker-compose.prod.yml` (production)

**Kubernetes**:
- Deployment: `readinessProbe` + `livenessProbe`, resource requests/limits
- ConfigMap + Secret: `envFrom secretRef` for credential injection
- HPA: Horizontal Pod Autoscaler for scaling
- Ingress: TLS termination, path routing
- NetworkPolicy: pod-to-pod traffic control

**Deployment strategies**: Blue-Green (instant rollback, double resources), Canary (traffic weight 10%→50%→100%), Rolling update (`maxSurge`/`maxUnavailable`).

## 3. CI/CD Pipeline

**Standard stages**: lint → test → build image → scan → push → deploy

**GitHub Actions**:
- Docker build caching: `docker/build-push-action` with `cache-from`/`cache-to` (gha cache backend)
- OIDC authentication: `id-token: write` + cloud provider credential config (no long-lived secrets)
- Reusable workflows: `workflow_call`, input parameters, secrets inheritance

**Security gates**:
- trivy scan: `--exit-code 1 --severity HIGH,CRITICAL`
- Secret detection: gitleaks, truffleHog
- SBOM generation: `syft`, `trivy sbom`
- Image signing: cosign (Sigstore)

**Deployment verification**: rollout status check, health probe verification, smoke test.

## 4. Reverse Proxy

**Nginx production**:
- TLS: TLSv1.2+ (disable SSLv3/TLSv1.0/TLSv1.1), HSTS (`Strict-Transport-Security: max-age=31536000`), OCSP stapling
- Security headers: X-Frame-Options, X-Content-Type-Options, Content-Security-Policy, Referrer-Policy
- Rate limiting: `limit_req_zone` (burst), `limit_conn` (connection limiting)
- Upstream health: passive health checks (`max_fails`, `fail_timeout`)

**Traefik**: Docker provider (automatic service discovery), Let's Encrypt ACME

## 5. Observability Minimum Set

Every deployment package must include:

| Component | Requirement |
|---|---|
| `/health` | Liveness + readiness with named dependency checks (DB, cache, external services) |
| `/metrics` | Prometheus format: `http_requests_total`, `http_request_duration_seconds`, `process_cpu_seconds_total` |
| Structured JSON logs | `{"timestamp","level","service","trace_id","action"}` — no PII values |
| Business metrics | 5-10 named signals (active users, order value, payment success rate, search latency) |

**Prometheus metric types**: Counter (monotonically increasing), Gauge (point-in-time), Histogram (buckets), Summary (quantiles).

**Naming convention**: `namespace_subsystem_metric_unit` (e.g., `http_requests_duration_seconds`).

**Grafana dashboards**: RED method (Rate, Errors, Duration) + USE method (Utilization, Saturation, Errors).

## 6. Secret Management

- **K8s Secrets**: base64-encoded, etcd encryption at rest
- **Vault**: Vault Agent Injector (sidecar), External Secrets Operator, AppRole auth
- **SOPS**: Mozilla SOPS for encrypting secrets in Git (AWS/GCP/Azure KMS)
- **OIDC federation**: GitHub Actions → AWS via OIDC (no static credentials in repo)
- **.env.example**: document all required env vars with placeholder values, never real credentials

NEVER embed secrets in Dockerfiles, Compose files, K8s manifests, or any versioned file.

## 7. Deployment Runbook

Every runbook must include:
- **Prerequisites**: OS version, ports, DNS, TLS, credentials, minimum resources
- **Step-by-step with verification**: every action has an observable success criterion
- **Troubleshooting**: error message (exact) → cause → fix (exact commands)
- **Rollback procedure**: command, expected output, verification step

Verification-first discipline: Command + Expected output + Verification command + Expected verification result + If verification fails section.

## 8. Anti-Patterns

| Name | Symptom | Correction |
|---|---|---|
| **Root Container** | No USER directive → container runs as root | Add non-root user, verify with `whoami` |
| **Latest Tag** | `:latest` in manifest → non-reproducible | Pin explicit version tag |
| **Unstructured Logs** | Plain text log strings → fragile regex | Structured JSON with trace_id |
| **Metric Drought** | No /metrics endpoint → invisible health | Prometheus metrics as required deliverable |
| **No Rollback Plan** | Deployment without rollback → incident improvisation | Rollback section mandatory in every runbook |
| **Secrets in Version Control** | API keys in Dockerfile/Compose/K8s → credential leak | External secrets via env vars / Vault / K8s Secrets |
