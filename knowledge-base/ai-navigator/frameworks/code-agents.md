# Code Agents 对比 — Claude Code / Cursor / Codex / Cline / Aider / Windsurf

> last_updated: 2026-04-18

---

## 1. 主流代码 Agent（2026-04-18 版本）

| 工具 | 最新版 | 日期 | 载体 | 模型绑定 |
|---|---|---|---|---|
| **Claude Code** | v2.1.114 | 2026-04-18 | 终端 CLI | Claude（默认 Sonnet 4.6） |
| **OpenAI Codex** | rust-v0.122.0-alpha.10 | 2026-04-18 | Rust CLI | OpenAI（默认 gpt-5.4/codex） |
| **Cline** | v3.79.0 | 2026-04-16 | VS Code ext | 任意 |
| **Aider** | v0.86.0 | 2025-08-09 | CLI | 任意 |
| **Cursor** | — | — | IDE 分叉 | 多 provider |
| **Windsurf (Codeium)** | — | — | IDE 分叉 | 多 provider |

### 节奏观察

- **Claude Code 与 OpenAI Codex 均日发版**（2.1.110 → 114 在 4 天内）— 双方都在极速迭代
- Cline 月度级
- Aider 2025-08 后 **8 个月未发版** — [待验证] 维护状态 / 是否 fork

---

## 2. Claude Code v2.x 要点

- 每次新版均通过 `claude-agent-sdk-python` 同步 bundle（v0.1.63 bundle CLI 2.1.114）
- 2026-04-15 左右引入：
  - Skills 顶层配置（SDK v0.1.62）
  - Subagent transcript 可读取（SDK v0.1.60）
  - Distributed tracing via OTel（SDK v0.1.60）
  - Session 级 cascading deletion
- 配合官方 Plugins 仓（`anthropics/knowledge-work-plugins`，2026-04-17）
- 官方 GitHub Action：`claude-code-action` 持续活跃

## 3. OpenAI Codex v0.122 alpha 要点

- Rust 实现（不是 Python），性能 / 启动速度领先
- alpha.8/9/10 日发版节奏（2026-04-17~18）
- 与 `openai-agents-python` SandboxAgent 呼应 — 本质上 Codex 是 Sandbox workspace 的消费者
- **Skills Catalog for Codex**（2026-04）对标 Claude Skills

## 4. Cline v3.79（2026-04-16）

- VS Code extension 形态（UI 交互 > 纯 CLI）
- 任意 provider；深度支持 MCP
- 推出 **Compound agent pattern**（[待验证] 细节）

## 5. 行业对比维度

| 维度 | Claude Code | Codex | Cline | Aider |
|---|---|---|---|---|
| 载体 | Terminal | Terminal | VS Code | Terminal |
| 默认模型 | Sonnet 4.6 | gpt-5.4-codex | 用户选 | 用户选 |
| Skills/Plugins | ✅ 官方 | ✅ Catalog | MCP | ❌ |
| Multi-agent | ✅ Subagent | ✅ via SDK | ✅ | ❌ |
| MCP client | ✅ | [待验证] | ✅ | [待验证] |
| Sandbox | ✅ workspace | ✅ sandbox | — | git worktree |
| GitHub Action | ✅ 官方 | — | — | — |
| 开源 | ❌（二进制） | ✅（Rust） | ✅ | ✅ |

## 6. 最新 GitHub 热榜 Agent 项目（2026-Q2）

[权威] 行业观察（industry-watch/2026-Q2.md）

| 项目 | Stars | 说明 |
|---|---|---|
| `everything-claude-code` | 160K | Agent harness 性能优化 |
| `karpathy/autoresearch` | 74K | 单 GPU 自动研究 Agent |
| `nanobot` | 40K | 超轻量个人 AI Agent |
| `CLI-Anything` | 31K | 让所有软件 Agent-Native |
| `oh-my-claudecode` | 30K | Claude Code 多 Agent 编排 |
| `zeroclaw` | 30K | 全自主 AI 个人助理 |
| `OpenClaw-RL` | 5K | 对话式 Agent 训练 |

**结论**：Claude Code 生态最繁荣，社区作品远超 Codex 侧；但 Codex 的 Rust CLI + OpenAI Sandbox 正在快速追赶。

## 7. 下轮研究

- [ ] Cursor 2.x 最新版本号
- [ ] Windsurf Wave 系列最新
- [ ] Aider 维护状态（8 个月无发版是否分叉）
- [ ] `everything-claude-code` 的"harness 优化"细节
- [ ] SWE-bench Verified 新榜单：Claude / Codex / Cline agent-level 对比
