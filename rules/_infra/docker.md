---
paths:
  - "Dockerfile*"
  - "**/Dockerfile*"
  - "docker-compose*.yml"
  - "docker-compose*.yaml"
  - ".dockerignore"
---

# Docker / 容器化规范

## Dockerfile 设计

### 多阶段构建（推荐）

```dockerfile
# Build stage
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build

# Runtime stage
FROM node:20-alpine
WORKDIR /app
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
USER node
CMD ["node", "dist/index.js"]
```

### 基础镜像

- 优先 slim / alpine（体积小）
- 注意 alpine 的 musl libc 兼容性（某些原生模块不兼容）
- 固定版本（`node:20.11.1-alpine3.19`），不用 `:latest`

### 层缓存优化

- 先 copy 依赖文件并安装（利用缓存）
- 后 copy 源码
- 不常变的指令放前面

### 安全

- **不以 root 运行**：`USER node` / `USER nobody`
- 不 COPY 密钥（用运行时注入）
- `.dockerignore` 排除 `.env`、`.git`、`node_modules`、logs
- 使用官方或可信来源的基础镜像
- 定期扫描漏洞（Trivy / Snyk）

### 健康检查

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

### 最终镜像体积

目标 <200MB（Node/Python 项目），<100MB（Go/Rust 静态链接）。

---

## docker-compose

### 版本

使用 `version: '3.9'` 或更高（或省略，因为新版 Compose 不需要）。

### 服务命名

- 全小写
- 描述性名称（`postgres`, `redis`, `api`）

### 网络隔离

```yaml
services:
  api:
    networks:
      - internal
  postgres:
    networks:
      - internal    # 不暴露到 public
networks:
  internal:
    driver: bridge
```

### 数据持久化

- 命名 volume（`postgres_data`）而非匿名
- 关键数据挂载到宿主持久化目录
- 备份 volume（定期）

### 环境变量

- 敏感值用 `.env` 文件（不进 git）
- `env_file: .env` 而非在 compose 中写明文

### 依赖关系

```yaml
services:
  api:
    depends_on:
      postgres:
        condition: service_healthy
```

`depends_on` 只保证启动顺序，不保证服务就绪——配合 healthcheck。

### 资源限制

```yaml
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M
```

---

## 命令与运行

### 禁止

- `docker run --privileged`（除非明确需要）
- 挂载 `/var/run/docker.sock`（高风险）
- `network_mode: host`（除非明确需要）

### 推荐

- 命令参数化：`CMD ["node", "index.js"]`（exec 形式，接收信号）
- 信号处理：应用正确处理 SIGTERM（graceful shutdown）

---

## 镜像管理

- Registry：使用私有 registry 或云服务（ECR / GCR / ACR）
- 标签策略：
  - `latest`：最新稳定（不推荐生产依赖）
  - `v1.2.3`：明确版本
  - `sha-abc123`：git commit
- 生产部署用**不可变 tag**（版本号 / commit hash），不用 `latest`

---

## 开发 vs 生产

开发 compose 和生产镜像可能不同：
- 开发：volume mount 源码、热重载、dev 依赖
- 生产：多阶段构建、最小镜像、只 prod 依赖

避免一份 Dockerfile 既服务开发又服务生产（要么两套，要么构建参数区分）。
