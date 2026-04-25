---
name: bcc-deploy
description: 部署流水线。用于发布、上线、打 tag 和回滚。
disable-model-invocation: true
---

# 部署流水线

`$ARGUMENTS` 可包含目标环境和版本号。

调度真源：`rules/_global/dispatch-table.md`。部署、回滚、打 tag 和生产验证属于 `S0` 高风险链路，禁止并发。

## Phase 1: 部署前检查

### 1.1 调度器自检

- `git status` 工作树必须干净
- 最近提交记录清晰
- 不存在未完成的 feature/bug artifact

### 1.2 最终门控

派遣 `functional-tester`：
- 运行完整测试套件
- 验证关键用户路径

如涉及后端、配置、依赖、部署脚本、环境变量，再派遣 `security-auditor` 做最终安全审计。

### 1.3 生产前裁决

production 或客户交付环境部署前，必须派遣 `test-lead` 汇总功能与安全证据，产出 `verdict-{task-id}.md`。`BLOCKED` 或缺关键证据时不得部署。

## Phase 2: 部署执行

派遣 `devops`：

```text
任务：执行部署。
环境：{staging / production}
预检：
- review-functional-*.md
- review-security-*.md（如适用）
- verdict-*.md（production / 客户交付环境必需）

要求：
1. 记录当前版本用于回滚
2. 执行构建与部署
3. 做健康检查
4. 失败则立即回滚
5. 写 deploy-report
```

任何不可逆操作前必须 AskUserQuestion 确认。

## Phase 3: 部署后验证

- 用户人工验证关键路径
- 如有可见 UI 变更，可追加 `visual-tester` 做生产验证
- 观察监控 15 分钟
- production 部署后派遣 `test-lead` 基于部署报告、smoke test 和视觉证据做最终放行记录

## Phase 4: 发布记录

- 由 `devops` 打 tag（production 必须二次确认）
- 更新 CHANGELOG（如项目维护）
- 发送发布通知（如配置了通知通道）

## Phase 5: 汇报

向用户汇报版本、环境、健康检查、人工验证和回滚命令。
