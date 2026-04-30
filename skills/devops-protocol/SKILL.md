---
name: devops-protocol
description: 运维工作协议。覆盖构建、部署、CI/CD、发布、回滚、监控的方法论。
when_to_use: 仅当 devops Agent 处理构建 / 部署 / CI/CD 配置 / 发布 / 回滚 / 事故响应任务时加载。日常代码实现、本地调试、文档撰写不应触发。
---

# 运维工作协议

## 核心原则

1. **可重复**：任何部署能再次执行得到相同结果（Infrastructure as Code）
2. **可回滚**：任何变更有明确的回退路径
3. **可追踪**：每次变更有记录、时间戳、触发原因

## 构建

### 构建产物要求

- **确定性**：相同源码 + 相同依赖 → 相同产物
- **可追溯**：产物带版本号、git commit hash、构建时间
- **最小化**：不包含开发依赖、不含源码 map（除非明确需要）
- **可验证**：产物完整性校验（checksum）

### 构建时机

- 本地开发：`npm run dev` / `cargo run` 等开发模式
- 预览/测试：`npm run build:staging`
- 生产：CI/CD 触发，**不手动构建产线**

### 缓存策略

- 依赖缓存（node_modules、pip cache）加速 CI
- 增量构建（turbo、nx、bazel）加速本地
- 但生产构建应 clean build 确保无状态污染

## CI/CD

### 流水线结构

```
┌─ Checkout
├─ Install deps (cached)
├─ Lint
├─ Type check
├─ Unit tests
├─ Build
├─ Integration tests
├─ Security scan
├─ (仅 main) Deploy staging
├─ (仅 tag) Deploy production
```

每个阶段失败应快速终止整个流水线。

### 测试矩阵

- 多 Node / Python / 等语言版本（如项目声明支持多版本）
- 多 OS（如有跨平台需求）
- 代价：矩阵维度乘积不要超过实际价值

### 密钥管理

- 不在 workflow 文件中硬编码密钥
- 使用 CI 平台的 secrets（GitHub Secrets / GitLab Variables）
- 最小权限：每个 secret 只给需要它的 job

## 版本管理

### SemVer

- **MAJOR**：破坏性变更
- **MINOR**：向后兼容的新功能
- **PATCH**：向后兼容的 bug 修复

对于应用（而非库），版本号也可以是日期（`2026.04.23`）或自增（`v127`）。

### Git Tag

```bash
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3
```

### Changelog

遵循 [Keep a Changelog](https://keepachangelog.com/) 格式：

```markdown
## [1.2.3] - 2026-04-23
### Added
- 新功能 X
### Changed
- 修改 Y 行为
### Fixed
- 修复 Z bug
### Security
- 升级依赖解决 CVE-xxx
```

## 监控与告警

### 基础监控

- 系统：CPU、内存、磁盘、网络
- 应用：请求延迟、错误率、流量、饱和度
- 业务：关键业务指标

### 告警原则

- **可操作**：每条告警对应明确的处理动作
- **可诊断**：告警信息包含上下文（时间、值、趋势、相关服务）
- **无噪音**：避免告警疲劳（已知问题自动静默）
- **分级**：紧急 vs 重要 vs 信息

### SLO / SLI

- 定义 SLO（服务等级目标）：如"99.9% 请求 < 200ms"
- SLI 监控：实际达成率
- Error Budget：超标时冻结变更，专注稳定性

## 安全运维

### 依赖管理

- 定期扫描（`npm audit`、`pip-audit`、Dependabot）
- 关键 CVE 立即处理
- 锁定版本（lock file 提交）
- 镜像扫描（Trivy / Snyk）

### 密钥轮换

- 定期轮换（90 天 / 180 天）
- 泄露立即轮换
- 使用 secret 管理服务

### 审计

- 关键操作记录日志（谁、什么时候、做了什么）
- 日志保留满足合规
- 异常访问告警

## 长参考

按需读取以下 supporting files：

- `references/deploy-patterns.md` — 部署策略（蓝绿/金丝雀/滚动）、健康检查、文件传输 md5 校验、双产物编译
- `references/rollback-emergency.md` — 回滚（代码/DB/部分）、应急响应流程、不可逆操作铁律
