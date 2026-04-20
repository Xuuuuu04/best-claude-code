---
source: agents/devops.md
copied: 2026-04-21
note: Docker and containerization deep domain knowledge for DevOps engineer.
---

# DevOps — Docker & Containerization Domain

## Multi-Stage Dockerfile Patterns

### Pattern A: Python/FastAPI Application

```dockerfile
# Stage 1: Builder
FROM python:3.12.4-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y --no-install-recommends gcc libpq-dev
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

# Stage 2: Runtime
FROM python:3.12.4-slim AS runtime
RUN addgroup --system --gid 1000 appgroup && \
    adduser --system --uid 1000 --ingroup appgroup appuser
WORKDIR /app
COPY --from=builder --chown=appuser:appgroup /root/.local /home/appuser/.local
COPY --chown=appuser:appgroup . .
ENV PATH=/home/appuser/.local/bin:$PATH \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
USER appuser
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

### Pattern B: Node.js Application

```dockerfile
# Stage 1: Build
FROM node:20.12.2-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build && npm prune --production

# Stage 2: Runtime
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
```

### Pattern C: Go Application (Minimal)

```dockerfile
# Stage 1: Build
FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o app .

# Stage 2: Runtime (distroless)
FROM gcr.io/distroless/static:nonroot
COPY --from=builder /app/app /app
EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/app"]
```

---

## Image Security Hardening

### Non-Root User Verification

```bash
# Build and verify
docker build -t app:test .
docker run --rm --entrypoint whoami app:test
# Expected: appuser (NOT root)

# Check for root in image history
docker history app:test | grep -i "user\|root"
# Expected: no root references in runtime layers
```

### Distroless vs Alpine vs Slim

| Base Image | Size | Shell | CVE Surface | Use Case |
|-----------|------|-------|-------------|----------|
| `gcr.io/distroless/static` | ~2MB | No | Minimal | Go, Rust static binaries |
| `alpine:latest` | ~5MB | sh | Low | General purpose, musl libc |
| `debian:bookworm-slim` | ~30MB | bash | Medium | Python, Node.js, JVM |
| `chainguard/wolfi-base` | ~10MB | sh | Very Low | Supply-chain verified |

### Image Scanning with Trivy

```bash
# Scan built image
trivy image --exit-code 1 --severity HIGH,CRITICAL app:test

# Generate SBOM
trivy image --format spdx-json --output sbom.json app:test

# Scan Dockerfile itself
trivy config Dockerfile

# CI/CD gate example
trivy image \
  --exit-code 1 \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --vuln-type os,library \
  app:${GITHUB_SHA}
```

### Cosign Image Signing

```bash
# Generate key pair
cosign generate-key-pair

# Sign image after build
cosign sign --key cosign.key app:${GITHUB_SHA}

# Verify signature before deploy
cosign verify --key cosign.pub app:${GITHUB_SHA}

# In CI (keyless with OIDC):
cosign sign --yes app:${GITHUB_SHA}
```

---

## Docker Compose Patterns

### Staging Environment

```yaml
services:
  app:
    image: ghcr.io/org/app:${GITHUB_SHA}
    user: "1000:1000"
    read_only: true
    tmpfs:
      - /tmp:noexec,nosuid,size=100m
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
      start_period: 10s
    deploy:
      resources:
        limits:
          cpus: '1.0'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 128M
    security_opt:
      - no-new-privileges:true
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE

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
    deploy:
      resources:
        limits:
          memory: 256M

  redis:
    image: redis:7.2.4-alpine
    volumes:
      - redisdata:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          memory: 128M

volumes:
  pgdata:
  redisdata:
```

### Security Options Explained

- `read_only: true` — Root filesystem read-only; prevents runtime file modifications
- `tmpfs: /tmp` — Writable temp directory in memory, discarded on container exit
- `security_opt: no-new-privileges` — Prevents privilege escalation via setuid binaries
- `cap_drop: ALL` — Remove all Linux capabilities
- `cap_add: NET_BIND_SERVICE` — Add back only needed capability (bind to ports <1024)
- `user: "1000:1000"` — Explicit UID:GID, avoids username resolution issues

---

## .dockerignore Template

```
# Git
.git
.gitignore

# Documentation
README.md
CHANGELOG.md
docs/

# Tests
tests/
test/
__tests__/
*.test.js
*.spec.js
pytest.ini
conftest.py

# Local environment
.env
.env.*
!.env.example

# Dependencies (installed in image)
node_modules/
vendor/

# Build artifacts (built in image)
dist/
build/
*.egg-info/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# CI/CD configs (not needed in image)
.github/
.gitlab-ci.yml
```
