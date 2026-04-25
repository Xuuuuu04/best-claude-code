---
name: bcc-evolve
description: 系统进化引擎。分析 Auto Memory 和 Agent Memory，将经验固化为 Rules、Skills 或 Agent 改进。
disable-model-invocation: true
---

# 系统进化

这是 Agent Legion 的进化飞轮：**观察 → 反思 → 提案 → 审批 → 执行**。

## Phase 1: 审计

### 1.1 `repo-researcher`

读取并分析：
- `~/.claude/projects/*/memory/*`
- `~/.claude/agent-memory/*`
- `~/.claude/agents/*.md`
- `~/.claude/skills/**/*.md`
- `~/.claude/rules/**/*.md`
- `~/.claude/CLAUDE.md`

产出 `.claude/artifacts/evolve-audit-{timestamp}.md`。

### 1.2 `tech-researcher`（按需）

若某轮进化涉及外部 Claude Code 机制变化、第三方工具升级、最佳实践更新，补充外部调研证据。

## Phase 2: 分析

调度器识别四类机会：
- 反复出现的纠正 → 新 Rule
- 频繁重复的工作流 → 新 Workflow Skill
- 知识积累达到阈值 → 新 Knowledge Skill
- 冗余/冲突 → 合并或删除

## Phase 3: 生成提案

写入 `.claude/artifacts/evolve-proposals-{timestamp}.md`，每条提案都附 Memory 证据和风险。

## Phase 4: 用户审批

逐条 AskUserQuestion，请求批准 / 拒绝 / 修改后批准。

## Phase 5: 执行

对批准项：
- 创建/修改 Rule、Skill、Agent 定义
- 清理已固化的 Memory
- 追加 `evolve-log.md`

## Phase 6: 汇报

汇报：
- 批准执行的提案数
- 新增 Rule / Skill / Agent 改动
- Memory 瘦身效果
- 下次进化建议时间
