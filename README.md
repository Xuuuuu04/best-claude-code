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

***把主会话变成默认指挥官，让 Subagent 军团处理复杂任务，在快路径中直接完成小修***

<br>

[![Claude Code](https://img.shields.io/badge/Claude%20Code-v2.1.59+-7c3aed?style=flat-square&logo=anthropic)](https://claude.com/claude-code)
[![License: MIT](https://img.shields.io/badge/License-MIT-22c55e?style=flat-square)](./LICENSE)
[![Status: v4.3](https://img.shields.io/badge/Status-v4.3-f59e0b?style=flat-square)](#)
[![Chinese First](https://img.shields.io/badge/Language-中文优先-ef4444?style=flat-square)](#)
[![Agents](https://img.shields.io/badge/Agents-32-3b82f6?style=flat-square)](#二十九-subagent-角色)
[![Rules](https://img.shields.io/badge/Rules-48-8b5cf6?style=flat-square)](#支持的技术栈)
[![Skills](https://img.shields.io/badge/Skills-45-06b6d4?style=flat-square)](#系统架构)

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
| **Skills** | 可调用的知识 / 工作流 | 45 个，分三类：系统运维命令（disable-model-invocation）、领域协议（Agent 预加载）、参考文档 |
| **Subagents** | 隔离上下文的工作者 | 32 个专职角色，覆盖需求/设计/研究/实现/审查/测试/验收/部署/元治理/论文/仓颉/昇腾 |
| **Rules** | 编码规范与调度真源（按需激活） | 全局规则 + 调度表 + 18 种语言 + 18 种框架 + 3 种基础设施 |
| **Hooks** | 确定性保障脚本 | 会话启动注入、压缩前后状态恢复、编辑自动 lint 等 |
| **Memory** | 跨会话持久学习 | Agent 按认知类型分层（思维类 user，执行类 project） |
| **Output Style** | 调度器行为风格 | 自定义 `legion-dispatch` 强制中文、极简、委派纪律 |

---

## 系统架构

```
┌─────────────────────────────────────────────┐
│  用户                                        │
└────────────────┬────────────────────────────┘
                 │ 自然语言描述任务（v3.4 自然语言优先）
                 ▼
┌───────────────────────────────────────────────┐
│  主会话 = 调度器（Dispatcher）                  │
│  CLAUDE.md + Output Style 双重强化其身份       │
│  默认不写复杂代码；仅在受控快路径直做小修       │
└─┬─────────────────────────────────────────────┘
  │
  ▼
┌────────────┐   ┌────────────────────┐   ┌────────────────────┐
│需求与调度链 │──▶│设计与范围规划链      │──▶│实现与专项域链        │
│client      │   │architect           │   │implementer-*       │
│creative    │   │scope-planner       │   │miniprogram-dev     │
│product-    │   │architecture-review │   │database-engineer   │
│analyst     │   └────────────────────┘   │ml-engineer         │
│pm          │                             │devops              │
│requirements│                             └──────┬─────────────┘
│reviewer    │                                    │
└──────┬─────┘                                    ▼
       │                              ┌────────────────────────┐
       └─────────────────────────────▶│审查 / 文档 / 验收链      │
                                      │code-reviewer          │
                                      │security-auditor       │
                                      │functional-tester      │
                                      │visual-tester          │
                                      │test-lead              │
                                      │doc-writer             │
                                      │visual-designer        │
                                      │prompt-engineer        │
                                      └─────────┬─────────────┘
                                                ▼
                                     .claude/artifacts/
                                   （结构化文件交接总线）
```

### 二十五个 Subagent 角色

按**认知模式**而非技术栈划分：

- **client** — 客户原话、售后反馈、提案需求的工程化整理
- **creative** — 命名、Slogan、品牌调性和概念级视觉方向
- **product-analyst** — 从模糊需求到精确规格（需求拆分、验收标准、风险识别）
- **requirements-reviewer** — 只审需求文档是否完整、可测、可进入设计阶段
- **pm** — 多阶段任务的状态机、单跳调度、返工升级
- **architect** — 只做技术方案、模块边界、ADR 和关键权衡
- **scope-planner** — 把需求和架构压缩成文件级 `scope-lock` 与依赖图
- **architecture-reviewer** — 专审架构方案与 scope-lock 是否自洽、可实施
- **repo-researcher** — 只做仓库内定位、代码考古、依赖关系和历史追溯
- **tech-researcher** — 只做外部文档、第三方能力、兼容性和选型调研
- **implementer-{frontend,backend,mobile}** — 在 scope-lock 范围内高质量执行
- **miniprogram-dev** — 微信小程序 / uni-app / 小程序生态专项实现
- **database-engineer** — schema、迁移、索引和数据层兼容性
- **ml-engineer** — 训练、评估、推理部署和 ML 失败分析
- **code-reviewer** — 只审 diff、契约一致性、异常处理、测试覆盖和可维护性
- **security-auditor** — 只审权限、安全边界、依赖风险和上线前隐患
- **functional-tester** — 只做功能验证、主路径回归和边界场景测试
- **visual-tester** — 只做 UI 证据采集、视觉回归和交互可用性检查
- **test-lead** — 汇总功能 / 视觉 / 安全证据后的最终放行裁决
- **doc-writer** — API 文档、部署说明、交付文档、阶段报告
- **visual-designer** — design tokens、组件规范、布局与视觉系统
- **prompt-engineer** — Agent、Rule、Style 和元治理协议维护
- **devops** — 构建、部署、CI/CD、发布（可重复、可回滚、可追踪）

---

## 能做什么

- **自然语言驱动开发**：直接说"实现用户登录功能"即可触发完整门控流水线（需求→架构→scope→实现→审查→安全→测试→裁决），无需显式命令
- **顶会论文撰写与审稿**：学术论文写作专家 + 顶会审稿专家形成撰写-审查闭环，对标 NeurIPS/CVPR/ACL 标准
- **仓颉语言开发**：华为仓颉语言专属开发专家，完整类型系统/并发/FFI 知识
- **昇腾 NPU 开发**：CANN 工具链/Ascend C 算子/模型部署/鸿蒙端侧推理
- **Claude Code 工作流定制**：提示词设计大师可为任意场景快速设计 Agent/Skill/流水线
- **跨技术栈项目**：React、Vue、Next、Spring、Django、Flutter、微信小程序、仓颉、昇腾等全覆盖
- **项目初始化**：`/bcc-init-project` 深度递归探索 + 逐目录生成 CLAUDE.md
- **系统进化**：`/bcc-update-memory` 自动汇总学习 → 检测临界 → 提议架构升级

---

## 特性总览

### 1. 默认调度，受控快路径
主会话上下文尽量保持干净。复杂实现、测试、部署优先交给隔离的 Subagent 完成；系统文件和单文件低风险小修允许主会话直接完成。

### 2. Scope-Lock 范围锁定
架构师只负责设计，`scope-planner` 专职产出精确到**文件和函数级别**的 scope-lock，包含白名单、禁止事项、接口契约、验证方式、完成标准。这样把“设计正确”和“拆分精确”两种认知任务分离开来。

### 3. 阶段门控质量
需求、架构、代码、安全、功能、视觉各自有专职 reviewer / tester，避免一个“总审查员”同时切换多种判断标准。质量是流水线的一部分，不是事后补丁。

### 3.1 最终裁决与专项域
`test-lead` 负责最终放行；数据库、小程序、ML、文档、设计、提示词治理分别有专职角色，不再把高差异场景硬塞给通用 implementer。

### 3.2 调度表与安全并发
`rules/_global/dispatch-table.md` 是路由真源，定义“用户信号 → Agent → artifact → 下一跳 → 并发等级”。允许并发，但必须满足白名单无交集、输出 artifact 不冲突、依赖图同 Batch、共享环境不污染。

### 4. 路径限定 Rules 按需激活
编辑 `.tsx` 自动激活 React 规则；编辑 `.py` 自动激活 Python 规则。不在场的规则零上下文成本。

### 5. 进化飞轮
Auto Memory + Agent Memory 持续积累 → `/bcc-update-memory` 自动汇总 → 临界检测 → 人工审批 → 固化为永久 Rules/Skills。系统越用越聪明。

### 6. 多模型 Provider 支持
内置多家国内 Claude 兼容协议提供商（GLM、MiniMax、Kimi 等）配置示例，让成本敏感场景也能用上 Agent Legion。

### 7. 中文优先
Output Style 强制中文交互，适合中文开发团队使用。

### 8. 自适应推理强度（v3.2 新增）
7 个高决策风险 Agent（`test-lead` / `architect` / `architecture-reviewer` / `code-reviewer` / `security-auditor` / `scope-planner` / `prompt-engineer`）通过 `effort` frontmatter 配置 4.7 自适应推理强度（`high` / `xhigh`），其余 Agent 继承会话默认值。

### 9. PermissionRequest 自动批准（v3.2 新增）
`ExitPlanMode` 权限请求由专用 hook 自动批准，消除 plan mode 完成后的确认摩擦。其他权限请求不受影响。

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

之后直接自然语言描述任务即可：

```
实现用户登录功能，支持邮箱密码和 Google OAuth
刷新 token 在并发请求下偶现失败
帮我写一篇 CVPR 论文初稿
```

或使用显式命令：

```
/bcc-loop-dev 实现完整的用户管理系统
/bcc-fast-fix src/auth.ts 第 42 行 typo
/bcc-update-memory  （每 1-2 周）进化系统
/bcc-doctor          每周健康检查
```

---

## 目录结构

```
.claude/
├── CLAUDE.md             # 调度元协议（主会话每次看到）
├── LEGION.md             # 维护指南（给未来 AI 维护者）
├── README.md             # 本文件
├── settings.example.json # 配置模板（含占位符）
├── agents/               # 25 个专职 Subagent 定义
├── skills/               # 所有 Skill 扁平存放（Claude Code 要求直接子目录）
│   ├── bcc-*/            # /bcc-* 命令入口（流水线，disable-model-invocation）
│   ├── {domain}/         # Agent 预加载的领域知识
│   └── {reference}/      # 可按需查询的参考文档
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

**语言（18）** — TypeScript、Python、Java、Swift、Kotlin、Dart、CSS、Go、Rust、C++、C、Ruby、PHP、C#、SQL、Shell、Scala、LaTeX

**框架（18）** — React、Vue、Svelte、Angular、Next.js、Nuxt、Express、NestJS、Spring、Django、FastAPI、Flask、Rails、Laravel、ASP.NET Core、Tailwind、Prisma、微信小程序

**基础设施** — Docker、CI/CD（GitHub Actions/GitLab CI/etc.）、环境配置

覆盖 95% 主流开发场景。其他语言/框架可通过 `/bcc-update-memory` 自行扩展。

---

## 设计哲学

### 为什么按认知模式分 Agent 而非按技术栈

人类按职业分（前端工程师、iOS 工程师）是因为人脑精力有限。Agent 没这个限制——一个 Agent 加载不同 Skill 就扮演不同技术角色。应按**根本不同的思维方式**分 Agent（分析、设计、执行、对抗、运维），技术差异交给 Skill/Rule。

### 为什么 Implementer 有三个变体

理想是 1 个 Implementer 动态加载技术栈 Skill。但 Claude Code 的 Subagent `skills:` 字段是**静态绑定**到 Agent 定义文件的，主会话调度时无法动态指定。折中方案：按大类认知域（frontend/backend/mobile）拆 3 个变体，具体技术栈通过 path-specific Rules 自动补充。

### 为什么主会话默认不写复杂代码

为了保持调度器上下文尽可能干净。一旦主会话长期沉入大量实现细节，后续调度决策质量会下降。让专业 Agent 在自己的干净上下文中完成复杂工作，只向主会话返回摘要；但对系统文件和单文件小修，主会话直做的开销更低。

### 为什么进化需要人工审批

Claude 自动提炼的 Rule 可能过于严格、过于宽泛、或错误。一条坏 Rule 会持续产生噪音，所以"人在回路"是质量关卡。宁可少进化一条，不要错误地固化一条。

更多设计细节见 [LEGION.md](./LEGION.md)。

---

## 对比其他方案

| 方面 | Agent Legion | 通用 CLAUDE.md 模板 | 静态 Agent 库（如 awesome-claude-agents） |
|:--|:--|:--|:--|
| 调度纪律 | ✅ Output Style + CLAUDE.md 强化 | ❌ 无 | ❌ 无 |
| Agent 拓扑 | ✅ 核心流水线 + 专项卫星层，共 25 角色 | N/A | ⚠️ 通常按技术栈，维护成本高 |
| Scope-Lock 机制 | ✅ `scope-planner` 产出文件级锁定 | ❌ 无 | ❌ 无 |
| 阶段门控审查 | ✅ reviewer/tester 专职链 | ❌ 无 | ⚠️ 部分方案有 |
| 路径限定 Rules | ✅ 17 语言 + 18 框架 | ❌ 无 | ❌ 无 |
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
