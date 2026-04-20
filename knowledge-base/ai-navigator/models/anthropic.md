# Anthropic — 全景知识

> last_updated: 2026-04-18
> 覆盖：Claude 模型矩阵 / 定价 / 上下文 / Agent SDK / Skills / Plugins / Claude Code
> 状态：[部分] 核心事实已模式 A 验证；pricing 已从官方表格提取

---

## 1. 模型矩阵（2026-04-18 快照）

来源：[权威] `https://docs.anthropic.com/en/docs/about-claude/models`（HTML 解析，46 个 claude-* model ID）

### 旗舰 Opus 系列

| 模型 ID | 发布 | 状态 | 主打 |
|---|---|---|---|
| `claude-opus-4-7` | 2026-04 GA | [权威] 当前旗舰 | 软件工程最难任务 / 高分辨率视觉 / 新分词器 / Cyber Verification Program 限流 |
| `claude-opus-4-6` / `claude-opus-4-6-v1` | 2026-Q1 | [权威] | 前代，仍推荐用于多 agent 编排 / 代码库重构 |
| `claude-opus-4-5` / `-20251101` | 2025-11-01 | [权威] | |
| `claude-opus-4-1` / `-20250805` | 2025-08-05 | [权威] | |
| `claude-opus-4` / `-20250514` | 2025-05-14 | [权威] | 老旗舰 |

### Sonnet 系列（主力工作马）

| 模型 ID | 发布 | 状态 | 要点 |
|---|---|---|---|
| `claude-sonnet-4-6` | 2026-Q1 | [权威] | 当前 Sonnet 主版本，**1M token context 在 beta**；free/pro 默认；在 Claude Code 中早测用户 70% 偏好 > 4.5；59% 偏好 > Opus 4.5 |
| `claude-sonnet-4-5` / `-20250929` | 2025-09-29 | [权威] | 此前 frontier coding |
| `claude-sonnet-4` / `-20250514` | 2025-05-14 | [权威] | |
| `claude-sonnet-3-7` | (deprecated) | [权威] | 仍列表 |

### Haiku 系列（低延迟）

| 模型 ID | 发布 | 状态 | 要点 |
|---|---|---|---|
| `claude-haiku-4-5` / `-20251001` | 2025-10-01 | [权威] | 与 5 个月前的 Sonnet 4 持平编码能力，**1/3 成本、2× 速度**；某些任务（computer use）甚至超过 Sonnet 4；ASL-2 安全等级 |
| `claude-haiku-3-5` | | [权威] | |
| `claude-3-haiku` / `-20240307` | 2024-03-07 | [权威] 兼容保留 |

---

## 2. 官方定价（2026-04-18 官方 Pricing 页解析）

来源：[权威] `https://docs.anthropic.com/en/docs/about-claude/pricing`

**列含义**（5 列：基础输入 / 5m-cache-write / 1h-cache-write / cache-read / 输出；均为 $/MTok）

| 模型 | 输入 | 5m 写入 | 1h 写入 | 缓存读 | 输出 |
|---|---|---|---|---|---|
| **Claude Opus 4.7** | $5 | $6.25 | $10 | $0.50 | $25 | *(与 4.6 持平；官方公告确认 input $5, output $25)* |
| **Claude Opus 4.6** | $5 | $6.25 | $10 | $0.50 | $25 |
| Claude Opus 4.5 | $5 | $6.25 | $10 | $0.50 | $25 |
| Claude Opus 4.1 | $15 | $18.75 | $30 | $1.50 | $75 |
| Claude Opus 4 | $15 | $18.75 | $30 | $1.50 | $75 |
| **Claude Sonnet 4.6** | $3 | $3.75 | $6 | $0.30 | $15 |
| Claude Sonnet 4.5 | $3 | $3.75 | $6 | $0.30 | $15 |
| Claude Sonnet 4 | $3 | $3.75 | $6 | $0.30 | $15 |
| **Claude Haiku 4.5** | $1 | $1.25 | $2 | $0.10 | $5 |
| Claude Haiku 3.5 | $0.80 | $1 | $1.6 | $0.08 | $4 |
| Claude Haiku 3 | $0.25 | $0.30 | $0.50 | $0.03 | $1.25 |

关键变化：
- Opus 4.5/4.6/4.7 均为 **$5 输入 / $25 输出**，相比 Opus 4/4.1 的 $15/$75 **降价约 3×**（[权威] 多处证据）
- Sonnet/Haiku 线保持稳定价位
- Data residency：US-only 推理对 Opus 4.7 / 4.6 及以上可用
- Web search：按次 $10/千次（session 内）

---

## 3. 关键能力与近期更新

### Opus 4.7（2026-04 GA；[权威] `https://www.anthropic.com/news/claude-opus-4-7`）

- **软件工程最难任务**显著提升；早测用户可"放心移交最难工作"
- **高分辨率视觉**：图像以更高保真处理（token 消耗更多；用户可下采样）
- **新分词器**：同文本 token 数为前代的 1.0–1.35×，但 effort 控制下净成本更优
- **Cyber Verification Program**：仅限白名单（红队 / vuln research）用户；受 Project Glasswing 约束
- **API 发布**：Claude API、Bedrock、Vertex AI、Microsoft Foundry 全量同步

### Sonnet 4.6（[权威] `https://www.anthropic.com/news/claude-sonnet-4-6`）

- **1M context window**（beta）— 覆盖整个代码库 / 数十篇论文
- Computer Use 显著提升，OSWorld 基准连续 16 个月增长；对 prompt injection 抗性显著增强
- Claude Code：用户偏好 70% vs Sonnet 4.5；vs Opus 4.5 偏好 59%
- **Adaptive thinking + extended thinking + context compaction (beta)** 三模并存
- Excel 插件支持 MCP connectors（S&P / LSEG / Daloopa / PitchBook / Moody's / FactSet）

### Haiku 4.5（2025-10-01，[权威] `https://www.anthropic.com/news/claude-haiku-4-5`）

- 对标 5 月前 Sonnet 4 的编码水平；成本 1/3，速度 2×+
- 适用：chat 助手 / 客服 / pair programming / Claude for Chrome 加速
- ASL-2 安全等级；Haiku 3.5 至 Sonnet 4 的**替身**

### Project Glasswing（2026-04）

- 公开讨论 AI 在网络安全中的风险与收益
- 限制 `Claude Mythos Preview` 的放行；新模型需先经过较弱模型安全测试 cyber safeguards 再放行

### Claude Design（2026-04，Anthropic Labs）

- 新产品：协作生成设计 / 原型 / 幻灯片 / one-pager

---

## 4. SDK & 工具链生态（2026-04-18 最新版本）

来源：[权威] GitHub Releases API

| 项目 | 最新版 | 日期 | 说明 |
|---|---|---|---|
| `anthropic-sdk-python` | **v0.96.0** | 2026-04-16 | 基础 API SDK |
| `claude-agent-sdk-python` | **v0.1.63** | 2026-04-18 | Agent 编排 SDK，v0.1.62 起新增**顶层 `skills` 参数** |
| `claude-code` | **v2.1.114** | 2026-04-18 | 终端 agentic coding CLI，日发版节奏 |
| `claude-code-action` | — | 活跃 | GitHub Action 集成 |
| `anthropics/skills` | — | 2026-04-16 | Agent Skills 公开仓 |
| `anthropics/knowledge-work-plugins` | — | 2026-04-17 | Claude Plugins 官方目录 |

Agent SDK v0.1.60（2026-04-16）关键特性：
- **Subagent transcript helpers**：`list_subagents()` / `get_subagent_messages()` 可读取 subagent 会话链
- **Distributed tracing**：W3C TRACEPARENT/TRACESTATE 贯穿 CLI 子进程（`pip install claude-agent-sdk[otel]`）
- **Cascading session deletion**：删除会话时联动删除 subagent transcript 目录

---

## 5. Claude Skills（新范式）

[权威] `https://docs.anthropic.com/en/docs/agents-and-tools/agent-skills/overview`

- Skills 以"技能包"形式发布，可在 `ClaudeAgentOptions` 顶层 `skills="all"` 或 `skills=[...]` 启用
- 对标：OpenAI Codex Skills Catalog、Google Gemini 的 Built-in Tools
- 公司级：`anthropics/skills` 公开仓已上线

---

## 6. Context 管理

- **1M context window**：Sonnet 4.6 beta；Opus 4.7 [待验证具体是否达 1M；公告未明言]
- **Prompt Caching**：读命中约 10% 原价；5m 与 1h 两种写入时效
- **Context compaction**（beta）：旧上下文自动摘要，延长有效 context

---

## 7. 待验证 / 下轮研究

- [ ] Opus 4.7 具体完整版本号日期后缀（页面只给 `claude-opus-4-7`）
- [ ] `claude-opus-4-7` 与 GPT-5.4、Gemini 3.1 Pro、Grok 4.20 的 SWE-bench Verified 直接对比（官方公告引用 OpenAI 自报数据）
- [ ] Mythos Preview 模型何时转 GA
- [ ] Claude Design 的 API 开放程度
