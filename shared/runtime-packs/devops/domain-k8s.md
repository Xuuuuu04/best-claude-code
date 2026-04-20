---
source: agents/devops.md
copied: 2026-04-21
note: Kubernetes deployment patterns and manifests for DevOps engineer.
---

# DevOps — Kubernetes Domain

## Production Deployment Manifest

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
  labels:
    app: api
    version: "{{ .Values.image.tag }}"
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
        version: "{{ .Values.image.tag }}"
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        runAsGroup: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      containers:
        - name: api
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: Always
          ports:
            - name: http
              containerPort: 8000
              protocol: TCP
            - name: metrics
              containerPort: 9090
              protocol: TCP
          env:
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: db-credentials
                  key: url
            - name: ENV
              value: "{{ .Values.environment }}"
          resources:
            requests:
              cpu: 250m
              memory: 256Mi
            limits:
              cpu: 1000m
              memory: 512Mi
          livenessProbe:
            httpGet:
              path: /health/live
              port: http
            initialDelaySeconds: 30
            periodSeconds: 10
            failureThreshold: 3
          readinessProbe:
            httpGet:
              path: /health/ready
              port: http
            initialDelaySeconds: 5
            periodSeconds: 5
            failureThreshold: 2
          startupProbe:
            httpGet:
              path: /health/ready
              port: http
            initialDelaySeconds: 10
            periodSeconds: 5
            failureThreshold: 30
          securityContext:
            allowPrivilegeEscalation: false
            readOnlyRootFilesystem: true
            capabilities:
              drop:
                - ALL
          volumeMounts:
            - name: tmp
              mountPath: /tmp
            - name: cache
              mountPath: /app/cache
      volumes:
        - name: tmp
          emptyDir: {}
        - name: cache
          emptyDir:
            sizeLimit: 100Mi
---
apiVersion: v1
kind: Service
metadata:
  name: api
  labels:
    app: api
spec:
  type: ClusterIP
  ports:
    - port: 80
      targetPort: http
      protocol: TCP
      name: http
    - port: 9090
      targetPort: metrics
      protocol: TCP
      name: metrics
  selector:
    app: api
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: api
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    nginx.ingress.kubernetes.io/rate-limit: "100"
spec:
  ingressClassName: nginx
  tls:
    - hosts:
        - api.example.com
      secretName: api-tls
  rules:
    - host: api.example.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: api
                port:
                  number: 80
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api
  minReplicas: 3
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
        - type: Percent
          value: 100
          periodSeconds: 60
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
        - type: Percent
          value: 10
          periodSeconds: 60
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: api
spec:
  podSelector:
    matchLabels:
      app: api
  policyTypes:
    - Ingress
    - Egress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              name: ingress-nginx
      ports:
        - protocol: TCP
          port: 8000
  egress:
    - to:
        - podSelector:
            matchLabels:
              app: db
      ports:
        - protocol: TCP
          port: 5432
    - to:
        - podSelector:
            matchLabels:
              app: redis
      ports:
        - protocol: TCP
          port: 6379
```

---

## Probe Configuration Guide

| Probe Type | Purpose | When to Fail | Typical Settings |
|-----------|---------|--------------|------------------|
| `livenessProbe` | Is the container alive? | Restart container | initialDelay: 30s, period: 10s, failureThreshold: 3 |
| `readinessProbe` | Is the container ready for traffic? | Remove from Service | initialDelay: 5s, period: 5s, failureThreshold: 2 |
| `startupProbe` | Has the container finished starting? | Disable other probes until pass | initialDelay: 10s, period: 5s, failureThreshold: 30 |

**Critical**: Do NOT point livenessProbe to a dependency check (e.g., database connectivity). If the database is down, livenessProbe fails → container restarts repeatedly. Use readinessProbe for dependency health.

```yaml
# BAD — livenessProbe checks DB (causes restart loop)
livenessProbe:
  httpGet:
    path: /health/ready  # Includes DB check!

# GOOD — livenessProbe checks only process health
livenessProbe:
  httpGet:
    path: /health/live   # Process-only: "I'm not dead"

# GOOD — readinessProbe checks full stack
readinessProbe:
  httpGet:
    path: /health/ready  # Includes DB, cache checks
```

---

## Secret Management Patterns

### Pattern A: External Secrets Operator (Recommended)

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    kind: ClusterSecretStore
    name: vault-backend
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
    - secretKey: url
      remoteRef:
        key: /prod/database
        property: url
    - secretKey: password
      remoteRef:
        key: /prod/database
        property: password
```

### Pattern B: Sealed Secrets

```bash
# Encrypt secret for GitOps
kubectl create secret generic db-credentials \
  --from-literal=url=postgres://... \
  --dry-run=client -o yaml | \
  kubeseal --controller-namespace=sealed-secrets \
  --controller-name=sealed-secrets \
  --format yaml > sealed-db-credentials.yaml

# Deploy (can be stored in Git safely)
kubectl apply -f sealed-db-credentials.yaml
```

---

## Rollback Procedures

### Kubernetes Rollback

```bash
# View rollout history
kubectl rollout history deployment/api

# Rollback to previous revision
kubectl rollout undo deployment/api

# Rollback to specific revision
kubectl rollout undo deployment/api --to-revision=42

# Verify rollback
kubectl rollout status deployment/api

# Check pod status
kubectl get pods -l app=api

# Verify version
curl -s https://api.example.com/health | jq '.version'
```

### Helm Rollback

```bash
# List releases
helm list

# Rollback to previous revision
helm rollback api 42

# Verify
helm status api
kubectl get pods -l app=api
```

---

## Observability Stack

### Prometheus ServiceMonitor

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: api-metrics
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: api
  endpoints:
    - port: metrics
      path: /metrics
      interval: 30s
      scrapeTimeout: 10s
```

### RED Metrics (Rate, Errors, Duration)

```yaml
# Grafana dashboard JSON snippet for RED
{
  "title": "API RED Metrics",
  "panels": [
    {
      "title": "Rate (req/s)",
      "expr": "sum(rate(http_requests_total[5m]))"
    },
    {
      "title": "Error Rate (%)",
      "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m])) * 100"
    },
    {
      "title": "Duration (p99)",
      "expr": "histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))"
    }
  ]
}
```
