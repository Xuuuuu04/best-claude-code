---
paths:
  - ".github/workflows/**"
  - ".gitlab-ci.yml"
  - ".circleci/**"
  - "Jenkinsfile*"
  - "azure-pipelines*.yml"
---

# CI/CD 配置规范

## 流水线结构

每个 PR / 推送触发的典型流水线：

```
1. Checkout
2. Setup（语言运行时、缓存）
3. Install deps（用 lock 文件）
4. Lint
5. Type check
6. Unit tests
7. Build
8. Integration tests
9. Security scan
10. （main / tag）Deploy
```

每步失败**立即终止**（`fail-fast: true`）。

## 性能

### 缓存

- 依赖缓存：`node_modules`、`pip cache`、`~/.gradle`
- 构建缓存：turbo、bazel 远程缓存
- Docker layer cache：`cache-from` / `cache-to`

### 并行

- 独立任务并行（lint / test / build）
- Test 矩阵：按文件或模块分片

### 超时

每个 job 和 step 都应有超时（防止僵死）：
```yaml
jobs:
  test:
    timeout-minutes: 10
```

## 密钥管理

### 绝对禁止

- 在 workflow 文件中硬编码密钥
- 在日志中打印密钥（即使脱敏）
- 在分叉 PR 中暴露密钥（GitHub Actions 默认阻止，确认设置）

### 正确做法

- 使用平台 secrets（GitHub Secrets、GitLab Variables）
- 最小权限：每个 secret 只给需要它的 job
- 定期轮换
- 审计日志：谁访问过

## 权限

### GitHub Actions

```yaml
permissions:
  contents: read   # 默认
  pull-requests: write  # 仅在需要时
  packages: write
```

默认最小权限，按需扩展。

### GITHUB_TOKEN

使用后自动过期。避免使用 PAT（Personal Access Token）除非必要。

## 触发条件

### 合理范围

- PR 触发：开发分支
- Push 触发：`main` / `develop`
- Tag 触发：release
- Schedule：定时任务（nightly build、依赖扫描）

### 避免

- `on: [push]` 不限定分支（触发过多）
- 路径过滤缺失（非相关变更触发流水线）

## 部署

### 环境分层

```yaml
environments:
  staging:
    url: https://staging.example.com
  production:
    url: https://example.com
    # 必需审批
```

Production 环境必须：
- 手动审批
- 限制谁能部署
- 强制 PR review 状态

### 部署脚本

- 幂等（重复执行安全）
- 日志结构化
- 失败时提供明确错误

## 缓存中毒防护

```yaml
cache:
  paths: ...
  key: ${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
```

lock 文件变化时缓存失效，避免使用过期依赖。

## 矩阵测试

```yaml
strategy:
  matrix:
    node-version: [18, 20]
    os: [ubuntu-latest, macos-latest]
```

不过度（笛卡尔积爆炸）。

## 通知

- 主分支失败：立即通知
- PR 失败：仅通知作者
- 非紧急（依赖更新失败）：异步通知

## 日志与产物

- 保留期：30 天（默认）
- 测试报告 / 覆盖率 / 构建产物作为 artifact 上传
- 敏感信息**不**进日志

## 安全扫描

- 依赖扫描：Dependabot / Renovate
- SAST：CodeQL / Semgrep
- 容器扫描：Trivy / Snyk
- Secret 扫描：pre-commit + CI 二次验证

扫描失败的阈值：严重漏洞阻断发布，警告级的不阻断但记录。

## 复用

- Reusable workflow / composite action 复用逻辑
- 参数化而非复制粘贴
- 版本固定（使用 SHA 或 tag）

```yaml
uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
```

使用 SHA 比 tag 更安全（tag 可被移动）。

## 本地验证

- 使用 `act`（GitHub）或 `gitlab-runner exec`（GitLab）本地运行 workflow
- 大变更先在 branch 验证，再合入 main
