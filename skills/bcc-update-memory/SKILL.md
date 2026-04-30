---
name: bcc-update-memory
description: 更新项目 AutoMemory——汇总本会话所有 Agent 的可复用学习，递归更新所有 CLAUDE.md 的变更日志。当 Memory 积累到临界量时向用户提议架构进化升级（经审批后可拓展 Rule/新增 Skill/升级 Agent）。
argument-hint: "[focus?] (留空全量更新)"
disable-model-invocation: true
---

# Memory 更新与进化引擎

## 阶段 1 — 会话活动审计

### 1.1 从 subagent-events.jsonl 提取

读取 `~/.claude/logs/subagent-events.jsonl`，过滤本 `session_id` 的事件。统计：

- 派遣了哪些 Agent（按 agent_type）
- 每个 Agent 的调用次数
- 各 Agent 的返回 token（IMPL_DONE / REVIEW_PASS / REVIEW_REJECT / TEST_PASS / TEST_BLOCKED / VERDICT_*）
- 驳回和返工次数（REVIEW_REJECT 计数）
- 是否触发 redeliberation（code-reviewer 被同一 scope 调用 ≥2 次且返回 REJECT）

### 1.2 从 cost-log 提取

读取项目 `.claude/logs/cost-log.txt`，统计本会话：
- 总 turns 数
- 各 Agent 的平均 turns（识别 >50 的高摩擦 scope）
- token 消耗分布

### 1.3 从 artifact 提取

扫描 `.claude/artifacts/` 中新产出的文件：
- 哪些 scope-lock 已 accepted
- 哪些 impl-report 已产出
- 最新的 review 和 verdict 结果
- reviewer 质量反馈段（test-lead 是否标记了漏审）

## 阶段 2 — Agent 学习汇总

### 2.1 逐 Agent 追问

对每个本会话中派遣过的 Agent，根据其活动和 token 结果构造追问：

**implementer 类**（收到 IMPL_DONE）：
```
"本轮实现中是否遇到了 scope-lock 不精确的地方（需要额外摸索/猜测）？只答有/没有。"
```
回答有 → 追问具体路径 + 原因 → 写入 agent-memory

**code-reviewer 类**（发出过 REVIEW_REJECT）：
```
"本轮驳回的根因中，是否有跨 scope 通用的模式（如某类字段判断容易出错）？只答有/没有。"
```
回答有 → 追问具体模式 → 写入 agent-memory

**test-lead**（发出过 VERDICT）：
```
"本轮是否有 reviewer 漏审（reviewer PASS 但 tester 发现 [严重]/[一般]≥3）？"
```
回答有 → 记录漏审 reviewer + 漏审项 → 写入 agent-memory

**所有 Agent 通用追问**：
```
"本轮是否产生了跨任务可复用的知识？只答有/没有。"
```
回答有 → "请用 3 句话总结，一句话一条。" → 写入

### 2.2 硬追问（Memory 触发规则）

以下场景**必须追问**，不可跳过：

| 触发条件 | 追问对象 | 追问内容 |
|:--|:--|:--|
| 同一 scope-lock REVIEW_REJECT ≥2 次 | code-reviewer | 驳回根因是否可复用 |
| implementer turns >50 | implementer | 摸索时间是否源于 scope-lock 不精确 |
| 接口字段方向被 reviewer 揪出 | implementer | 是否已内化为检查项 |
| test-lead 判定 reviewer 漏审 | 该 reviewer | 漏审原因，如何防止重复 |

### 2.3 写入路径

按 agent frontmatter 的 `memory` 字段：
- `memory: project` → `$CLAUDE_PROJECT_DIR/.claude/agent-memory/{agent-name}/{short-title}.md`
- `memory: user` → `$HOME/.claude/agent-memory/{agent-name}/{short-title}.md`

每条 ≤30 行。已有重复内容不重复写。先 `mkdir -p` 再写。

## 阶段 3 — AutoMemory 更新

在 `~/.claude/projects/{project-slug}/memory/` 下：
- 读取 `MEMORY.md` 索引
- 按类型（user/feedback/project/reference）分类新条目
- 新条目写入对应主题文件
- 更新 MEMORY.md 索引，确保 ≤200 行

## 阶段 4 — 递归更新所有 CLAUDE.md

### 4.1 识别受影响目录

从 git diff 和 impl-report 中提取本次修改的文件列表，映射到对应的目录 CLAUDE.md。

### 4.2 更新内容

对每个受影响的 CLAUDE.md：
1. **变更日志**：追加 `| {日期} | {变更摘要} | {原因} |`
2. **进度**：更新已完成/未完成/已知问题
3. **文件与符号索引**：新增/删除/重命名的文件和符号
4. **对外 API**：新增/修改/删除的接口

**不覆盖**其他段落。只做增量追加。

### 4.3 根 CLAUDE.md 同步

汇总所有子目录变更到根 CLAUDE.md 的变更日志段。

## 阶段 5 — 项目级 Agent Memory 积累检测

统计：
- Auto Memory MEMORY.md 行数
- `.claude/agent-memory/` 下文件总数
- 距上次进化天数
- 同一 pattern 的 memory 条目数（模糊匹配关键词）

| 条件 | 阈值 | 含义 |
|:--|:--|:--|
| MEMORY.md ≥ 180 行 | 接近上限 | 需固化 |
| agent-memory 文件 ≥ 15 | 积累显著 | 可能存在通用模式 |
| 距上次 evolve ≥ 14 天 | 时间驱动 | 定期审查 |
| 同一 pattern ≥ 3 条 | 模式成熟 | 可固化为 Rule |

**触发任一条件 → 进入阶段 6。**

## 阶段 6 — 进化升级引擎

### 6.1 系统理解前置（强制执行）

**在提议任何升级前，必须完整阅读：**

| 文件 | 为什么 |
|:--|:--|
| `~/.claude/CLAUDE.md` | 调度元协议——所有决策的根 |
| `~/.claude/LEGION.md` | 系统维护指南——设计哲学和机制速查 |
| `~/.claude/output-styles/legion-dispatch.md` | 调度器行为协议——档位自判/token 协议/再审议触发 |
| `~/.claude/rules/_global/dispatch-table.md` | 调度真源——路由规则/并发等级/门控条件/问题分级 |
| `~/.claude/rules/_global/artifact-protocol.md` | Artifact 命名与生命周期 |
| `~/.claude/rules/_global/dotclaude-layout.md` | .claude 目录布局规范 |
| `~/.claude/rules/_global/skill-architecture-standard.md` | Skill 架构规范 |
| `~/.claude/rules/_global/external-skill-source-policy.md` | 外部素材引入策略 |
| `~/.claude/rules/_global/hook-scripts-pattern.md` | Hook 脚本规范 |
| `~/.claude/agents/` | 全部 25 个 Agent 定义（至少读与拟议升级相关的） |
| `~/.claude/hooks/` | 全部 Hook 脚本 + `_lib/` |
| `~/.claude/settings.json` | 当前配置 |
| `~/.claude/skills/` | 全部 Skill（至少读相关分类） |

**不完成此步骤 → 不得提议任何升级。** 不深入理解全系统的人无权改动它。

### 6.2 模式分析

交叉比对 Memory 条目，识别：
- 反复出现的 failure pattern → 候选 Rule
- 反复出现的知识缺口 → 候选 Skill
- 反复出现的认知盲区 → 候选 Agent 升级
- 反复出现的调度失误 → 候选 dispatch-table 优化

### 6.3 生成进化提案

```markdown
# 进化提案：{日期}

## 数据依据
- 本次会话 Agent 派遣 {N} 次，驳回 {M} 次，redeliberation {R} 次
- cost-log 显示平均 turns {avg}，最高 {max}
- 新积累 agent-memory {K} 条

## 检测到的模式
1. {模式} — 出现 {N} 次 — 来源 {memory 路径}
2. ...

## 建议升级（逐项审批）

### 提案 1：{类型 — Rule / Skill / Agent 升级 / dispatch-table}
- **当前问题**：{描述 + 证据}
- **建议方案**：{具体改动 + 文件路径}
- **与现有设计的兼容性**：{是否冲突/补充/替代哪个现有机制}
- **影响范围**：{哪些 Agent/Skill/流水线受影响}
- **回退方式**：{git revert 或手动回退步骤}
- **风险**：{低/中/高 — 具体原因}
```

**用户未 approve 的提案绝不执行。**

### 6.4 可提议的升级范围

| 类型 | 条件 | 限制 |
|:--|:--|:--|
| 新增/修改 Rule | ≥2 条相似 memory | 必须有 paths frontmatter；验证不误触发 |
| 修改 Skill | ≥3 条相关 feedback | 保持 SKILL.md ≤500 行；长内容进 references |
| 新 Skill | ≥3 次同一类问题未被现有 Skill 覆盖 | 遵守 skill-architecture-standard |
| Agent 升级（改 prompt/tools/skills） | 基于明确的认知缺口 | 不改变 Agent 的核心认知模式 |
| 新增 Agent | 基于现有 25 Agent 无法覆盖的认知模式 | **极高门槛**：必须证明旧角色无法覆盖、非按技术栈加人 |
| dispatch-table 优化 | 基于调度失误的 pattern | 不破坏现有门控条件 |

### 6.5 执行与验证

对批准的提案：
1. 执行修改
2. 运行 `bash ~/.claude/bin/doctor.sh`（至少 §1/§2/§3/§17）
3. 如有新 hook → 在 `hook-flags.sh` 登记
4. 如有新 Agent → 在相应 Skill 的 `when_to_use` 中引用
5. 更新 `LEGION.md` 进化历史
6. 向用户报告执行结果

## 阶段 7 — 收尾

- `bash ~/.claude/bin/doctor.sh` 全系统健康检查
- 检查 CLAUDE.md 行数（项目根 + 系统全局均 ≤200）
- 归档超 30 天的 artifact
- 清理 agent-memory 中重复条目
