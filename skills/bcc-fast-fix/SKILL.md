---
name: bcc-fast-fix
description: 极速修复模式。Agent 完全不参与——主会话直接读取、修改、验证、交付。仅适用于单文件、≤20 行、无 schema/依赖/接口变更的 trivial/small 级修复。
argument-hint: "<文件路径 + 改动描述>"
disable-model-invocation: true
---

# 极速修复模式

## 准入检查（8 条，全部满足才走此模式）

| # | 条件 | 不满足时 |
|---|------|---------|
| 1 | 仅 1 个文件 | → 退回到自然语言调度（需要 scope-lock） |
| 2 | ≤20 行净增删 | → 同上 |
| 3 | 不涉及 `.prisma`/`migration/`/`package.json`/`tsconfig`/`Dockerfile`/CI 配置/`docker-compose` | → 退回到完整流水线 |
| 4 | 不改变任何函数签名/API endpoint/类型导出/接口契约 | → 同上——接口变更必须走 code-reviewer |
| 5 | 不引入新 import/require/依赖 | → 同上 |
| 6 | 不修改认证/授权/支付/密码逻辑 | → 同上 + 安全审计 |
| 7 | 不涉及数据库查询或 schema | → 同上 + database-engineer |
| 8 | 目标文件不在 `.claude/` 或 `.gitignore` 中 | → 人工确认 |

**任一不满足 → 拒绝走 fast-fix → 按 dispatch-table 走完整流水线。**

## 执行流程

### 1. 预检
- 读目标文件，确认行数 ≤500（过大文件 fast-fix 风险高）
- 检查该文件是否在某个进行中的 scope-lock 白名单中（避免并发修改冲突）
- 检查该文件所在目录是否有 CLAUDE.md（有 → 修完需更新变更日志）

### 2. 修改
- 精确修改，不顺手修其他
- 不确定 → 不猜，退回到完整流水线（用不确定项标记机制）

### 3. 验证（全部通过才交付）

| 验证项 | 命令示例 | 失败处理 |
|--------|---------|---------|
| 相关测试 | `npx jest path/to/file.test.ts --no-coverage` | 修复后重试，最多 2 次 → 仍失败则退回 |
| Lint | `npx eslint path/to/file.ts` 或 `ruff check path/to/file.py` | 必须清零 |
| Typecheck | `npx tsc --noEmit` 或 `mypy path/to/file.py` | 必须通过 |

### 4. CLAUDE.md 更新
如果该文件所在目录有 CLAUDE.md：
- 更新变更日志：`| {日期} | {改动摘要} | bcc-fast-fix |`

### 5. 交付
```
✓ fast-fix 完成
  └ 文件: {路径}
  └ 改动: {一行描述}
  └ 验证: {测试 N passed / lint 0 / typecheck ok / CLAUDE.md 已更新}
```

## 失败处理表

| 情况 | 处理 |
|:--|:--|
| 测试失败（首轮） | 分析原因 → 修复 → 重跑 |
| 测试失败（第 2 次） | 最后一次重试 |
| 测试失败（第 3 次） | 退回到完整流水线——不是 fast-fix 能解决的 |
| Lint 告警 | 必须清零，不清零不交付 |
| Typecheck 失败 | 必须通过，类型错误不能"快速修" |
| 发现修改波及了其他文件 | 立即停止，退回到完整流水线 |
| scope-lock 冲突 | 停止，报告用户——该文件有其他 Agent 正在修改 |

## 禁止

- ❌ 不派任何 Agent
- ❌ 不写 impl-report（太轻量）
- ❌ 不修改白名单外文件
- ❌ 不扩大修改范围
- ❌ 不跳过验证（"这么简单应该没问题"）
- ❌ 不修改 scope-lock-guard 保护的路径
- ❌ 不同时修多个文件（即使"这两个修起来一样简单"）
