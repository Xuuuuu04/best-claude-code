---
paths:
  - "*.env"
  - "*.env.*"
  - ".env*"
  - "config/**"
  - "**/config.yml"
  - "**/config.yaml"
  - "**/config.json"
  - "**/config.toml"
---

# 环境配置规范

## 环境变量原则

### 什么应该是环境变量

- 数据库连接串
- API Key、Secret
- 第三方服务 URL
- 功能开关（Feature Flag）
- 环境标识（`NODE_ENV`, `ENV`）

### 什么**不**应该是环境变量

- 代码逻辑分支（用代码）
- 大量结构化配置（用配置文件）
- 敏感业务参数（如支付费率——用配置服务）

---

## .env 文件

### 分层

- `.env`：本地默认（不进 git）
- `.env.example`：示例（进 git，值用占位符）
- `.env.local`：个人本地覆盖（不进 git）
- `.env.staging` / `.env.production`：环境特定（**不**进 git）

### gitignore

```
.env
.env.local
.env.*.local
```

### 验证

应用启动时验证必需的环境变量：

```ts
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  NODE_ENV: z.enum(['development', 'staging', 'production']),
  PORT: z.string().regex(/^\d+$/).transform(Number).default('3000'),
});

export const env = envSchema.parse(process.env);
```

缺失必需变量立即失败（fail fast），不要用 undefined 启动。

---

## 敏感信息

### 绝对禁止

- 提交 `.env` 到 git（即使是开发环境）
- 在代码中硬编码任何密钥
- 在日志中输出敏感配置（甚至是打印 `process.env`）
- 在错误消息中包含密钥

### 管理方式

- 本地：`.env` 文件，从密钥管理工具同步
- 生产：Secret 管理服务（Vault / AWS Secrets Manager / Kubernetes Secrets）
- CI：平台 secrets（GitHub Secrets / GitLab Variables）

### 轮换

- 定期轮换（90-180 天）
- 发现泄露**立即**轮换
- 支持多密钥并存（过渡期）

---

## 配置文件

适合结构化、非敏感配置。

### 格式选择

- JSON：通用，不支持注释
- YAML：可读性好，支持注释，但缩进陷阱
- TOML：适合简单键值 + 段落
- INI：简单但表达力弱
- `.js` / `.ts`：动态配置（小心可执行代码）

### 分环境

```
config/
├── default.yaml        # 基础配置
├── development.yaml    # 开发覆盖
├── staging.yaml
└── production.yaml
```

加载时合并：`default` + 环境特定覆盖。

### 不包含敏感值

配置文件**可以**提交到 git，所以**不能**包含密钥。
敏感值用环境变量引用：

```yaml
database:
  host: ${DATABASE_HOST}
  port: ${DATABASE_PORT}
  # 密码从环境变量读取
```

---

## Feature Flag

### 使用场景

- 渐进发布
- A/B 测试
- 紧急关闭问题功能
- 按用户 / 地区启用

### 实现

- 简单：环境变量 / 配置文件
- 中等：数据库 + 缓存
- 高级：LaunchDarkly / Flagsmith / Unleash

### 清理

Feature flag 成功发布后**必须清理**（否则变技术债）。每个 flag 有"过期日期"。

---

## 密钥扫描

### Pre-commit

```bash
# 使用 git-secrets 或 trufflehog
git secrets --install
git secrets --register-aws
git secrets --add-provider -- cat .git-secrets-patterns
```

### CI

每次构建扫描变更：
```yaml
- uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: main
```

### 已泄露的密钥

1. **立即轮换**（假设已被利用）
2. 清除 git 历史（`git filter-repo` / BFG）
3. Force push（经团队同意）
4. 审计访问日志

---

## 12-Factor App

遵循 [12-Factor App](https://12factor.net/) 原则的相关部分：

- **III. Config**：配置从代码分离
- **IV. Backing services**：所有服务（DB、缓存、队列）作为可配置资源
- **V. Build, release, run**：构建、发布、运行三阶段分离
- **XI. Logs**：日志作为事件流，不写文件

---

## 审查要点

`security-auditor` 审查 env 和 config 变更时：

- [ ] 没有密钥硬编码
- [ ] `.env` 没被提交
- [ ] `.env.example` 已更新（有新增变量时）
- [ ] 敏感变量在 CI secrets 配置
- [ ] 启动时验证必需变量
- [ ] 日志不打印敏感配置
