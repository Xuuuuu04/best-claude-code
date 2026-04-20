# OpenClaw / Agent Harness 生态知识库

> 状态：[部分] 核心事实已模式 A 验证（2026-04-18）
> 创建日期：2026-04-18
> 最后更新：2026-04-18

---

## 术语澄清

**OpenClaw** 是 2026 年 AI Agent 生态中广泛使用的术语，指代一类"Agent 基础设施/框架"概念。

数据源：[已验证] GitHub 搜索 "openclaw" 返回 160K+ stars 的 `everything-claude-code` 项目描述中明确使用 "OpenClaw" 术语，以及大量相关项目（zeroclaw, nanoclaw, OpenHarness, ClawTeam 等）

## 核心项目矩阵

| 项目 | Stars | 说明 | 来源 |
|------|-------|------|------|
| `everything-claude-code` | 160K | Agent harness 性能优化系统：skills, instincts, memory, security | [权威] GitHub |
| `zeroclaw` | 30K | 快速、小型、全自主 AI 个人助理基础设施，跨平台 | [权威] GitHub |
| `nanoclaw` | 27K | 容器化安全运行的轻量 OpenClaw 替代方案 | [权威] GitHub |
| `OpenHarness` | 10K | 内置个人 Agent Ohmo 的开放 Agent Harness | [权威] GitHub |
| `ClawTeam` | 5K | Agent 群体智能，一键全自动化 | [权威] GitHub |
| `OpenClaw-RL` | 5K | 通过对话训练任何 Agent | [权威] GitHub |
| `MetaClaw` | 3K | 对话即进化，Agent 自我学习 | [权威] GitHub |
| `edict` | 15K | 三省六部制多 Agent 编排系统（9 个专业 Agent） | [权威] GitHub |
| `Clawith` | 3K | OpenClaw for Teams | [权威] GitHub |

## 关键概念：Skills（技能）

**Agent Skills** 是 OpenClaw 生态的核心抽象：

- [权威] `sickn33/antigravity-awesome-skills`：1,400+ 可安装 Agentic skills，支持 Claude Code / Cursor / Codex CLI / Gemini CLI
- [权威] `graphify`：AI 编码助手 skill（Claude Code, Codex, Cursor 等）
- [权威] `caveman`：Claude Code skill，通过"洞穴人"说话风格减少 65% token
- [权威] `last30days-skill`：跨 Reddit/X/YouTube/HN/Polymarket 研究任何话题
- [权威] `planning-with-files`：Manus 风格持久化 markdown 规划

## NVIDIA 生态集成

- [权威] `NVIDIA/NemoClaw`：在 NVIDIA OpenShell 中安全运行 OpenClaw，托管推理
- [权威] NVIDIA 官方支持 OpenClaw 生态的模型优化（NVFP4 压缩）

## 与 Claude Code / Codex 的关系

OpenClaw 生态与 Claude Code、OpenAI Codex 形成互补：

| 维度 | Claude Code | Codex | OpenClaw 生态 |
|------|-------------|-------|---------------|
| 定位 | Anthropic 官方终端 Agent | OpenAI 官方编码 Agent | 开放 Agent 基础设施 |
| 可扩展性 | Skills 系统 | Skills Catalog | 1,400+ 社区 skills |
| 多模型 | 仅 Claude | 仅 OpenAI | 多模型支持 |
| 开源 | 闭源 | 闭源 | 开源生态 |

## 相关术语

| 术语 | 说明 |
|------|------|
| **Harness** | Agent 运行框架/编排系统 |
| **Skill** | 可安装的 Agent 能力模块 |
| **Instinct** | Agent 的预设行为模式 |
| **OpenClaw** | 开放 Agent 基础设施总称 |
| **ZeroClaw** | 极简部署的 OpenClaw 变体 |
| **NanoClaw** | 容器化安全运行的轻量版本 |

## 下一轮研究重点

- [ ] OpenClaw 是否有官方组织/标准规范
- [ ] Skills 格式的标准化程度
- [ ] OpenClaw 与 MCP（Model Context Protocol）的关系
- [ ] OpenClaw 与 LangChain/LangGraph 的竞合关系

---

*2026-04-18 模式 A 验证：OpenClaw 是 2026 年 Agent 基础设施领域的事实标准术语，围绕它形成了庞大的开源技能生态（1,400+ skills），与 Claude Code/Codex 形成互补。*
