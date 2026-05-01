---
paths:
  - "Dockerfile*"
  - "**/Dockerfile*"
  - "docker-compose*.yml"
  - "docker-compose*.yaml"
  - ".dockerignore"
---

# Docker / 容器化规范

<rule name="dockerfile-design">
  <requirement>使用多阶段构建，分离 build 和 runtime 阶段以减小最终镜像体积。</requirement>

  <example type="good">
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
  </example>

  <rule name="base-image">
    <requirement>优先使用 slim / alpine 变体以减小体积。</requirement>
    <requirement>固定精确版本（如 node:20.11.1-alpine3.19），禁止使用 :latest 标签。</requirement>
    <constraint severity="warning">注意 alpine 的 musl libc 兼容性——某些原生模块不兼容。</constraint>
  </rule>

  <rule name="layer-caching">
    <requirement>先 COPY 依赖描述文件并安装，利用 Docker 层缓存。</requirement>
    <requirement>后 COPY 源码。不常变的指令放在前面。</requirement>
  </rule>

  <rule name="security">
    <constraint severity="blocker">不以 root 运行——必须使用 USER node 或 USER nobody。</constraint>
    <constraint severity="blocker">不 COPY 密钥到镜像内，使用运行时注入。</constraint>
    <requirement>.dockerignore 排除 .env、.git、node_modules、logs。</requirement>
    <requirement>使用官方或可信来源的基础镜像。</requirement>
    <requirement>定期使用 Trivy / Snyk 扫描镜像漏洞。</requirement>
  </rule>

  <rule name="healthcheck">
    <requirement>为运行时镜像配置 HEALTHCHECK。</requirement>
    <example type="good">
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
    </example>
  </rule>

  <rule name="image-size">
    <constraint severity="blocker">最终镜像体积目标：Node/Python 项目 &lt;200MB，Go/Rust 静态链接 &lt;100MB。</constraint>
  </rule>
</rule>

<rule name="docker-compose">
  <rule name="version">
    <requirement>使用 version: '3.9' 或更高，或省略（新版 Compose 不再需要 version 字段）。</requirement>
  </rule>

  <rule name="service-naming">
    <requirement>服务名全小写，使用描述性名称（如 postgres、redis、api）。</requirement>
  </rule>

  <rule name="network-isolation">
    <requirement>为服务创建内部网络，数据库等服务不暴露到 public 网络。</requirement>
    <example type="good">
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
    </example>
  </rule>

  <rule name="data-persistence">
    <requirement>使用命名 volume（如 postgres_data），禁止匿名 volume。</requirement>
    <requirement>关键数据挂载到宿主持久化目录。</requirement>
    <requirement>定期备份 volume。</requirement>
  </rule>

  <rule name="environment-variables">
    <constraint severity="blocker">敏感值使用 .env 文件（不进 git），禁止在 compose 文件中写明文。</constraint>
    <requirement>通过 env_file: .env 引用环境变量文件。</requirement>
  </rule>

  <rule name="dependencies">
    <requirement>使用 depends_on 声明启动顺序，配合 healthcheck 的 condition: service_healthy 确保服务就绪。</requirement>
    <constraint severity="warning">depends_on 只保证启动顺序，不保证服务真正就绪——必须配合 healthcheck。</constraint>
    <example type="good">
services:
  api:
    depends_on:
      postgres:
        condition: service_healthy
    </example>
  </rule>

  <rule name="resource-limits">
    <requirement>为每个服务声明 CPU 和内存限制。</requirement>
    <example type="good">
deploy:
  resources:
    limits:
      cpus: '1.0'
      memory: 512M
    </example>
  </rule>
</rule>

<rule name="commands-and-runtime">
  <rule name="prohibitions">
    <constraint severity="blocker">禁止 docker run --privileged，除非明确需要且经安全审计。</constraint>
    <constraint severity="blocker">禁止挂载 /var/run/docker.sock 到容器（高风险）。</constraint>
    <constraint severity="blocker">禁止 network_mode: host，除非明确需要且经评估。</constraint>
  </rule>

  <rule name="recommendations">
    <requirement>CMD 使用 exec 形式（CMD ["node", "index.js"]），以正确接收操作系统信号。</requirement>
    <requirement>应用必须正确处理 SIGTERM，实现 graceful shutdown。</requirement>
  </rule>
</rule>

<rule name="image-management">
  <requirement>使用私有 registry 或云服务（ECR / GCR / ACR）存储镜像。</requirement>
  <requirement>标签策略：latest 用于最新稳定（不推荐生产依赖）；v1.2.3 用于明确版本；sha-abc123 用于 git commit。</requirement>
  <constraint severity="blocker">生产部署必须使用不可变 tag（版本号或 commit hash），禁止使用 latest。</constraint>
</rule>

<rule name="dev-vs-production">
  <requirement>开发环境和生产环境的容器配置必须区分：开发使用 volume mount 源码 + 热重载 + dev 依赖；生产使用多阶段构建 + 最小镜像 + 仅 prod 依赖。</requirement>
  <constraint severity="warning">避免一份 Dockerfile 同时服务开发和生产——要么维护两套，要么用构建参数区分。</constraint>
</rule>
