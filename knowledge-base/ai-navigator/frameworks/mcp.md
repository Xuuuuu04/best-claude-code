# MCP (Model Context Protocol) — 生态知识

> last_updated: 2026-04-18
> 状态：[权威] 官方 registry 抓取

---

## 1. 核心定位

Anthropic 于 2024-11 提出的**开放协议**：让 LLM / Agent 安全标准化地访问外部数据与工具。

- 官方主页：`https://modelcontextprotocol.io/`
- 规范 spec：`https://spec.modelcontextprotocol.io/`
- Servers registry：`https://github.com/modelcontextprotocol/servers`（2026.1.26 发布，持续活跃）

核心抽象：
- **Prompts**：预置提示模板
- **Resources**：服务端可读取的上下文（文档 / 文件 / DB）
- **Tools**：可调用的动作
- **Sampling**：允许 server 反向请求 LLM 补全

## 2. 官方 Reference Servers（当前）

| Server | 作用 |
|---|---|
| **Everything** | 演示所有 MCP 能力 + 测试 |
| **Fetch** | Web 内容获取 + LLM-friendly 转换 |
| **Filesystem** | 安全文件操作（可配置白名单） |
| **Git** | 读取 / 搜索 / 操作 Git 仓库 |
| **Memory** | 知识图谱型持久化记忆 |
| **Sequential Thinking** | 动态 / 反思式问题解决 |
| **Time** | 时间 / 时区转换 |

### 已归档（servers-archived）

AWS KB Retrieval / Brave Search（被 Brave 官方 server 替代）/ EverArt / GitHub / GitLab / Google Drive / Google Maps / PostgreSQL / Puppeteer / Redis / Sentry / Slack（被 Zencoder 接管）/ SQLite

**信号**：官方将精力收缩到"展示型参考"，具体能力让**厂商官方 server**接管。

## 3. 主流框架支持

### 服务端（构建 MCP server）

| 框架 | 语言 | 说明 |
|---|---|---|
| **FastMCP** | TypeScript / Python | 官方推广的高层框架 |
| **Anubis MCP** | Elixir | 高性能，类 Live View 体验 |
| **ModelFetch** | TypeScript | runtime-agnostic，可部署到任意 TS/JS runtime |
| **FastAPI to MCP auto generator** | Python | 零配置把 FastAPI endpoint 导出为 MCP tools（by Tadata） |
| **Foxy Contexts** | Golang | Go 生态主力 |
| **MCP Declarative Java SDK** | Java | 注解驱动，不依赖 Spring |
| **MCP-Framework** | TypeScript | CLI `mcp create app` 5 分钟起步 |
| **MCP Plexus** | Python | multi-tenant / multi-user + OAuth 2.1 |
| **Higress** | Wasm plugin on Envoy | 企业网关托管 MCP |
| **mcp_sse** | Elixir | SSE 实现 |
| **Foobara MCP Connector** | Ruby | |
| **EasyMCP** | TypeScript | |

### 客户端 / 宿主

- **Claude Code / Claude Desktop**：原生 MCP 客户端
- **Claude in Excel**（2026-04）：add-in 支持 MCP connectors（S&P / LSEG / Daloopa / PitchBook / Moody's / FactSet）
- **Gemini 3 系**：`Grounding with Google Maps` + `Built-in Tools + Function Calling combined`（2026-03-18）[待验证] 具体是否走 MCP 协议
- **Cline / Aider / Cursor**：已有 MCP 接入
- **Grok / xAI**：docs 有 MCP Release Notes 专章（2026）

## 4. 2026 生态进展

### 最新 release

- `modelcontextprotocol/servers` 2026.1.26（官方 monorepo 日历式发布）
- 前序：2026.1.14 / 2025.12.18

### 重大趋势（[已验证]）

1. **协议已被三大模型厂商共同支持**：Anthropic 原生 + Google Gemini 3（Built-in tools + function calling combined）+ xAI（docs MCP 专章）
2. **OpenAI 侧**：Responses API + Remote Tools 走自己的协议，但社区封装 `mcp-proxy` 让 OpenAI 也能消费 MCP [待验证 OpenAI 官方 MCP 支持]
3. **企业级托管**：Higress / Groq 的 Remote Tools & MCP Connectors 开始 SaaS 化
4. **Registry 分化**：官方仓库趋于最小化；社区自发维护"MCP marketplace"（awesome-mcp-servers 等）

## 5. 常见企业 MCP server（生态调研）

社区可用（[待验证] 合规性 / 稳定性，按需审计）：
- GitHub / GitLab / Bitbucket
- Notion / Linear / Jira / ClickUp
- Postgres / MySQL / MongoDB / Snowflake / BigQuery
- AWS / GCP / Azure 各类 SDK 封装
- Slack / Discord / Teams / WeChat / Lark
- Obsidian / Roam / Logseq
- Stripe / Plaid / 支付
- Brave Search / Tavily / Exa（搜索）

## 6. 官方资源

- 主页：`https://modelcontextprotocol.io/`
- SDK：`https://github.com/modelcontextprotocol`（多语言 SDK）
- Servers：`https://github.com/modelcontextprotocol/servers`
- Awesome：社区整理的 `awesome-mcp-servers`（[待验证] 具体 repo）

## 7. 下轮研究

- [ ] OpenAI 是否官方 MCP 客户端支持
- [ ] Gemini 3 Built-in Tools combined 是否符合 MCP spec
- [ ] MCP Plexus 多租户 + OAuth 2.1 在 SaaS 场景的实践
- [ ] 权威 MCP marketplace 与 App Store 化趋势
