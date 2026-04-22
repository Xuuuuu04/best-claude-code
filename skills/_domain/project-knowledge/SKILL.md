---
name: project-knowledge
description: 当前项目的全局知识库，包含模块关系、API 索引、技术栈详情和迭代进度。由 /bcc-init-project 初始化，由 /bcc-update-project 持续维护。
---

# 项目知识库

> 这是一个**模板**。首次使用 Agent Legion 时，运行 `/bcc-init-project` 会将此模板个性化为具体项目的知识库。
> 后续 `/bcc-update-project` 会根据代码库变化自动刷新各区块。
>
> **最后更新**: （待 /bcc-init-project 生成时填充）

---

## 项目身份

- **名称**: {项目名}
- **一句话描述**: {项目做什么}
- **业务领域**: {电商 / SaaS / 工具 / 游戏 / 教育 / 其他}
- **当前阶段**: {MVP / Beta / 生产 / 成熟期}

---

## 技术栈详情

### 语言 & 运行时
- **主语言**: {Node.js 20 / Python 3.12 / Java 21 / Go 1.22 / ...}
- **次要语言**: {Shell / SQL / ...}

### 框架
- **Web 框架**: {Express / FastAPI / Spring Boot / ...}
- **前端框架**: {React 18 / Vue 3 / ...}
- **ORM / 数据访问**: {Prisma / SQLAlchemy / ...}

### 数据存储
- **主数据库**: {PostgreSQL 15 / MySQL 8 / MongoDB / ...}
- **缓存**: {Redis 7 / Memcached / ...}
- **搜索**: {Elasticsearch / Meilisearch / ...}
- **对象存储**: {S3 / OSS / ...}

### 测试
- **单元测试**: {Vitest / Jest / pytest / ...}
- **E2E**: {Playwright / Cypress / ...}
- **覆盖率工具**: {c8 / coverage.py / ...}

### 构建与部署
- **构建工具**: {Vite / Webpack / Turbopack / Gradle / ...}
- **包管理**: {pnpm / npm / yarn / poetry / ...}
- **容器化**: {Docker / 无}
- **编排**: {Kubernetes / Docker Compose / ECS / ...}
- **CI/CD**: {GitHub Actions / GitLab CI / ...}

---

## 模块依赖关系

```
src/
├── auth/        → 依赖 db/, utils/crypto
├── api/         → 依赖 auth/, db/, services/
├── services/    → 依赖 db/, external/
├── db/          → 独立，Prisma schema
├── utils/       → 独立
└── frontend/
    ├── components/ → 依赖 hooks/, utils/
    ├── hooks/      → 依赖 api-client/
    ├── pages/      → 依赖 components/, hooks/
    └── api-client/ → 依赖 后端 API
```

### 模块详细说明

#### `src/auth/`
- **职责**: 用户认证与授权
- **主要导出**: `authenticate()`, `authorize()`, `refreshToken()`
- **依赖**: `db/`, `utils/crypto`
- **注意事项**: Token 刷新存在历史竞态条件，使用分布式锁保护

#### `src/api/`
- **职责**: REST API 端点定义与路由
- **主要导出**: 各路由模块
- **依赖**: `auth/`, `db/`, `services/`
- **注意事项**: 所有端点必须经过认证中间件（除 `/auth/login`、`/health`）

_（其他模块类似）_

---

## API 端点索引

| 路径 | 方法 | 描述 | 认证 | 限流 |
|:--|:--|:--|:--|:--|
| /api/auth/login | POST | 用户登录 | 否 | 10/min |
| /api/auth/refresh | POST | Token 刷新 | Refresh Token | 30/min |
| /api/auth/logout | POST | 用户登出 | 是 | - |
| /api/users | GET | 用户列表 | 是（admin） | 60/min |
| /api/users/:id | GET | 获取用户 | 是 | 60/min |
| ...（/bcc-update-project 会自动扫描更新此表） | | | | |

### 已废弃端点
| 路径 | 废弃时间 | 替代 |
|:--|:--|:--|
| /api/v0/... | 2026-03 | /api/v1/... |

---

## 数据模型概要

### 核心实体
- **User**: 用户基本信息、认证凭证
- **Session**: 登录会话、token
- **Permission**: 角色-权限映射（RBAC）
- ...

### 关键关系
- User 1:N Session
- User M:N Role（through UserRole）
- Role M:N Permission（through RolePermission）

### Schema 文件
- 主 schema: `prisma/schema.prisma` / `alembic/versions/...`
- migration 目录: `prisma/migrations/`

---

## 架构决策记录（ADR）

### ADR-001: 认证方案选择 JWT
- **决策时间**: 2025-12-15
- **选项**: Session / JWT / OAuth
- **选择**: JWT（短期 access + 长期 refresh）
- **理由**: 无状态、易扩展、支持移动端
- **代价**: 撤销 token 复杂（需要黑名单）

### ADR-002: 前端状态管理
- **决策时间**: 2026-01-10
- **选项**: Redux / Zustand / 无全局状态
- **选择**: Zustand
- **理由**: 简单、TypeScript 友好、社区活跃
- **代价**: 团队需要适应新范式

_（/bcc-update-project 会追加新 ADR）_

---

## 当前迭代进度

### 已完成
- [x] v1.0: 基础认证和用户管理
- [x] v1.1: 权限系统 RBAC
- [x] v1.2: 订单模块 MVP

### 进行中
- [ ] v1.3: 通知系统（预计 2026-05）
  - 进度: 需求分析完成，架构设计中

### 计划中
- [ ] v1.4: 报表功能（预计 2026-06）
- [ ] v2.0: 多租户支持（预计 2026-08）

---

## 变更日志

_（最近 20 条，/bcc-update-project 追加）_

- **2026-04-23**: 项目知识库初始化
- **2026-04-20**: 完成权限系统 RBAC 实现（v1.1 发布）
- **2026-04-18**: 修复 token 刷新竞态条件
- ...

---

## 已知问题和技术债

- [ ] `src/legacy/` 目录包含历史代码，计划在 v2.0 前清理
- [ ] 测试覆盖率不足（当前 62%，目标 80%）
- [ ] API 错误响应格式历史上不统一，新代码遵循统一格式

---

## 关键约定

- 错误响应格式: `{ error: { code: string, message: string } }`
- 日期格式: ISO 8601
- 分页: 游标分页，参数 `cursor` + `limit`
- 时区: 后端统一 UTC，前端根据用户时区展示

---

## 外部服务依赖

- **支付**: Stripe
- **邮件**: SendGrid
- **短信**: Twilio
- **对象存储**: AWS S3 (us-west-2)
- **监控**: Datadog

_（如 API Key 需要在 .env 中配置，参考 .env.example）_

---

## 使用说明

- 此文件**不应手动编辑结构**——运行 `/bcc-update-project` 刷新
- 手动编辑仅用于修正 /bcc-update-project 自动生成的错误
- Agent（product-analyst, architect）会自动阅读此文件以了解项目全局
