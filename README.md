<div align="center">

<br>

```
 █████╗  ██████╗ ███████╗███╗   ██╗████████╗    ██╗     ███████╗ ██████╗ ██╗ ██████╗ ███╗   ██╗
██╔══██╗██╔════╝ ██╔════╝████╗  ██║╚══██╔══╝    ██║     ██╔════╝██╔════╝ ██║██╔═══██╗████╗  ██║
███████║██║  ███╗█████╗  ██╔██╗ ██║   ██║       ██║     █████╗  ██║  ███╗██║██║   ██║██╔██╗ ██║
██╔══██║██║   ██║██╔══╝  ██║╚██╗██║   ██║       ██║     ██╔══╝  ██║   ██║██║██║   ██║██║╚██╗██║
██║  ██║╚██████╔╝███████╗██║ ╚████║   ██║       ███████╗███████╗╚██████╔╝██║╚██████╔╝██║ ╚████║
╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚═╝  ╚═══╝   ╚═╝       ╚══════╝╚══════╝ ╚═════╝ ╚═╝ ╚═════╝ ╚═╝  ╚═══╝
```

### The Best Claude Code Template

***把主会话变成指挥官，让 Subagent 军团在隔离上下文中完成一切***

<br>

[![Claude Code](https://img.shields.io/badge/Claude%20Code-v2.1.59+-7c3aed?style=flat-square&logo=anthropic)](https://claude.com/claude-code)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e?style=flat-square)](./LICENSE)
[![Status: v1.0](https://img.shields.io/badge/Status-v1.0-f59e0b?style=flat-square)](#)
[![Chinese First](https://img.shields.io/badge/Language-中文优先-ef4444?style=flat-square)](#)
[![Agents](https://img.shields.io/badge/Agents-8-3b82f6?style=flat-square)](#六个-subagent-角色)
[![Rules](https://img.shields.io/badge/Rules-42-8b5cf6?style=flat-square)](#支持的技术栈)
[![Skills](https://img.shields.io/badge/Skills-19-06b6d4?style=flat-square)](#系统架构)

<br>

**[设计哲学](#设计哲学)** · **[架构](#系统架构)** · **[能做什么](#能做什么)** · **[快速开始](#安装与使用)** · **[维护指南](./LEGION.md)**

<br>

---

<br>

> **一套基于 Claude Code 全部扩展机制构建的自适应多 Agent 开发军团。**
>
> 让中等能力模型在干净的隔离上下文中，单点任务上匹敌甚至超越顶级模型。

</div>

<br>

## 为什么是 Agent Legion

### 核心信念

**干净上下文 + 结构化约束 > 混乱上下文 + 最强模型。**

行业主流做法是扔一个 Opus 级模型到几十 K token 的混乱上下文里硬抗。我们反其道而行：用架构消除混乱本身。在干净的 Subagent 上下文中，一个 Sonnet 级模型在精确 scope 内的单点任务表现可以媲美甚至超越 Opus 在复杂上下文中的表现。

### 核心机制

Agent Legion 把 Claude Code 的七种扩展层全部用上，让它们各司其职：

| 机制 | 职责 | 在本系统的体现 |
|:--|:--|:--|
| **CLAUDE.md** | 调度元协议（始终在线） | 根文件 ~120 行，定义调度器身份和流水线路由 |
| **Skills** | 可调用的知识 / 工作流 | 分三层：调度命令、领域预加载、参考文档 |
| **Subagents** | 隔离上下文的工作者 | 6 核心角色 + 3 Implementer 变体 |
| **Rules** | 编码规范（按需激活） | 全局规则 + 17 种语言 + 13 种框架 + 3 种基础设施 |
| **Hooks** | 确定性保障脚本 | 会话启动注入、压缩前后状态恢复、编辑自动 lint 等 |
| **Memory** | 跨会话持久学习 | Agent 按认知类型分层（思维类 user，执行类 project） |
| **Output Style** | 调度器行为风格 | 自定义 `legion-dispatch` 强制中文、极简、委派纪律 |

---

## 系统架构

```
┌─────────────────────────────────────────────┐
│  用户                                        │
└────────────────┬────────────────────────────┘
                 │ /bcc-new-feature / /bcc-fix-bug / ...
                 ▼
┌─────────────────────────────────────────────┐
│  主会话 = 调度器（Dispatcher）                │
│  CLAUDE.md + Output Style 双重强化其身份     │
│  不写代码，只调度                            │
└─┬──────────────┬──────────┬──────┬──────────┘
  │              │          │      │
  ▼              ▼          ▼      ▼
┌──────┐    ┌──────┐   ┌──────┐ ┌──────┐
│产品  │───▶│架构  │──▶│开发  │ │质量  │ ...
│分析师│    │师    │   │工程师│ │守卫  │
└──────┘    └──────┘   └──────┘ └──────┘
   │            │          │       │
   └────────────┴──────────┴───────┘
                │
                ▼
       .claude/artifacts/
     （结构化文件交接总线）
```

### 六个 Subagent 角色

按**认知模式**而非技术栈划分：

- **product-analyst** — 从模糊需求到精确规格（需求拆分、验收标准、风险识别）
- **architect** — 从规格到技术方案 + 精确的 scope-lock 范围锁定
- **implementer-{frontend,backend,mobile}** — 在 scope-lock 范围内高质量执行
- **quality-guardian** — 对抗性思维守卫质量（需求/架构/代码/测试四类审查）
- **devops** — 构建、部署、CI/CD、发布（可重复、可回滚、可追踪）
- **explorer** — 广度探索只返摘要（保护主会话上下文）

---

## 能做什么

- **新功能开发全流程**：`/bcc-new-feature {需求}` 触发 5 阶段流水线（需求→审查→架构→审查→实现→审查→测试→提交）
- **Bug 修复**：`/bcc-fix-bug {描述}` 走 TDD 简化流水线
- **安全部署**：`/bcc-deploy` 带预检、确认节点、回滚预案
- **跨技术栈项目**：React、Vue、Svelte、Angular、Next、Nuxt、Spring、Django、FastAPI、Rails、Laravel、ASP.NET、iOS、Android、Flutter、微信小程序等主流场景全覆盖
- **项目初始化与持续维护**：`/bcc-init-project` + `/bcc-update-project`
- **系统自我进化**：`/bcc-reflect` 会话总结 + `/bcc-evolve` 将 Memory 固化为 Rules / Skills

---

## 特性总览

### 1. 调度-执行严格分离
主会话上下文永远干净。代码实现、测试、部署都在隔离的 Subagent 上下文中完成，只向主会话返回摘要 artifact。

### 2. Scope-Lock 范围锁定
架构师产出精确到**文件和函数级别**的 scope-lock，包含白名单、禁止事项、接口契约、验证方式、完成标准。即使中等模型也能稳定产出。

### 3. 阶段门控质量
每个阶段的产出必须经 quality-guardian 对抗性审查后才能进入下一阶段。质量是流水线的一部分，不是事后补丁。

### 4. 路径限定 Rules 按需激活
编辑 `.tsx` 自动激活 React 规则；编辑 `.py` 自动激活 Python 规则。不在场的规则零上下文成本。

### 5. 进化飞轮
Auto Memory + Agent Memory 持续积累 → `/bcc-reflect` 结构化学习 → `/bcc-evolve` 提案 → 人工审批 → 固化为永久 Rules/Skills。系统越用越聪明。

### 6. 多模型 Provider 支持
内置多家国内 Claude 兼容协议提供商（GLM、MiniMax、Kimi 等）配置示例，让成本敏感场景也能用上 Agent Legion。

### 7. 中文优先
Output Style 强制中文交互，适合中文开发团队使用。

---

## 安装与使用

### 前置要求

- Claude Code v2.1.59+（支持 Auto Memory、Agent Memory 等特性）
- Git
- （推荐）对应语言的 linter / formatter（ruff / eslint / prettier / gofmt 等）

### 安装

```bash
git clone https://github.com/Xuuuuu04/claude-code-best-template.git ~/.claude
cp ~/.claude/settings.example.json ~/.claude/settings.json
chmod +x ~/.claude/hooks/*.sh
```

### 配置

编辑 `~/.claude/settings.json` 填入自己的 API Key 等配置。本仓库**不包含** Key，你需要自己准备。

### 开始使用

进入任意项目目录运行 `claude`。首次在该项目使用：

```
/bcc-init-project 你的项目简介
```

之后根据需要：

```
/bcc-new-feature  实现用户登录功能，支持邮箱密码和 Google OAuth
/bcc-fix-bug      刷新 token 在并发请求下偶现失败
/bcc-deploy       部署到 staging
/bcc-evolve       （每 1-2 周）让系统基于积累学习进化
```

---

## 目录结构

```
.claude/
├── CLAUDE.md             # 调度元协议（主会话每次看到）
├── LEGION.md             # 维护指南（给未来 AI 维护者）
├── README.md             # 本文件
├── settings.example.json # 配置模板（含占位符）
├── agents/               # 8 个 Subagent 定义
├── skills/
│   ├── _dispatch/        # /bcc-* 命令入口（流水线）
│   ├── _domain/          # Agent 预加载的领域知识
│   └── _reference/       # 可按需查询的参考文档
├── rules/
│   ├── _global/          # 无条件规则
│   ├── _lang/            # 语言规范（path-specific）
│   ├── _framework/       # 框架规范（path-specific）
│   └── _infra/           # 基础设施规范（path-specific）
├── hooks/                # 生命周期脚本
└── output-styles/        # 自定义输出风格
```

---

## 支持的技术栈

**语言** — TypeScript、Python、Java、Swift、Kotlin、Dart、CSS、Go、Rust、C++、C、Ruby、PHP、C#、SQL、Shell、Scala

**框架** — React、Vue、Svelte、Angular、Next.js、Nuxt、Express、NestJS、Spring、Django、FastAPI、Flask、Rails、Laravel、ASP.NET Core、Prisma、Tailwind、微信小程序

**基础设施** — Docker、CI/CD（GitHub Actions/GitLab CI/etc.）、环境配置

覆盖 95% 主流开发场景。其他语言/框架可通过 `/bcc-evolve` 自行扩展。

---

## 设计哲学

### 为什么按认知模式分 Agent 而非按技术栈

人类按职业分（前端工程师、iOS 工程师）是因为人脑精力有限。Agent 没这个限制——一个 Agent 加载不同 Skill 就扮演不同技术角色。应按**根本不同的思维方式**分 Agent（分析、设计、执行、对抗、运维），技术差异交给 Skill/Rule。

### 为什么 Implementer 有三个变体

理想是 1 个 Implementer 动态加载技术栈 Skill。但 Claude Code 的 Subagent `skills:` 字段是**静态绑定**到 Agent 定义文件的，主会话调度时无法动态指定。折中方案：按大类认知域（frontend/backend/mobile）拆 3 个变体，具体技术栈通过 path-specific Rules 自动补充。

### 为什么主会话不写代码

为了保持调度器上下文的绝对干净。一旦主会话开始读代码、编辑文件、跑测试，上下文就会被大量细节污染，后续的调度决策质量会下降。让专业 Agent 在自己的干净上下文中完成工作，只向主会话返回摘要。

### 为什么进化需要人工审批

Claude 自动提炼的 Rule 可能过于严格、过于宽泛、或错误。一条坏 Rule 会持续产生噪音，所以"人在回路"是质量关卡。宁可少进化一条，不要错误地固化一条。

更多设计细节见 [LEGION.md](./LEGION.md)。

---

## 对比其他方案

| 方面 | Agent Legion | 通用 CLAUDE.md 模板 | 静态 Agent 库（如 awesome-claude-agents） |
|:--|:--|:--|:--|
| 调度纪律 | ✅ Output Style + CLAUDE.md 强化 | ❌ 无 | ❌ 无 |
| Agent 拓扑 | ✅ 按认知模式，6 角色可扩展 | N/A | ⚠️ 通常按技术栈，维护成本高 |
| Scope-Lock 机制 | ✅ 架构师产出文件级锁定 | ❌ 无 | ❌ 无 |
| 阶段门控审查 | ✅ 每阶段 quality-guardian | ❌ 无 | ⚠️ 部分方案有 |
| 路径限定 Rules | ✅ 17 语言 + 13 框架 | ❌ 无 | ❌ 无 |
| 自我进化机制 | ✅ Memory + reflect + evolve | ❌ 无 | ❌ 无 |
| 中文支持 | ✅ 原生 | ⚠️ 按模板 | ⚠️ 按模板 |
| Hooks 安全网 | ✅ 完备 | ⚠️ 按需 | ❌ 通常无 |

---

## 贡献

欢迎提交 PR：
- 新语言 / 框架 Rules
- Hook 脚本改进
- Skill 描述优化
- 流水线细节完善

请在 PR 描述中说明：
- 你想解决什么问题
- 改动如何影响现有调度行为
- 是否需要更新 LEGION.md

---

## 致谢

本系统建立在 [Claude Code](https://claude.com/claude-code) 的扩展机制之上，特别感谢 Anthropic 提供的 CLAUDE.md / Skills / Subagents / Rules / Hooks / Memory / Output Styles 这套完整的生态。

初版设计与实现由项目维护者与 Claude Opus 4.7 合作完成。

---

## 许可

MIT
