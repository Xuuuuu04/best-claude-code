# best-claude-code / Agent Legion — 系统维护指南

> **这是给未来 AI 维护者的文档**。如果你是一个被召唤来升级、调试或扩展这套系统的新会话，没有历史上下文，**先完整读完本文再动手**。本文记录了设计初衷、Claude Code 的关键机制、以及升级这套系统时的纪律。
>
> 本文刻意**不引用具体文件名**，只引用**目录名和机制名**。这样当系统内部文件调整时，本文仍然准确。

---

## 一、这是什么

best-claude-code 是公开项目名；Agent Legion 是内部系统名。它基于 Claude Code 全部扩展机制构建"自适应多 Agent 开发军团"。核心设计理念：

- **默认调度，受控快路径**：主会话负责调度和整合；系统文件和单文件低风险小修可直接完成，复杂实现仍由 Subagent 完成
- **认知模式分工**：Agent 按思维方式划分（分析/设计/实现/对抗/运维），不按技术栈
- **Skill 热插拔**：技术栈差异通过 Skill 预加载切换，而非新建 Agent
- **Rule 按需激活**：编码规范通过 path-specific Rules 在读取匹配文件时自动加载
- **确定性由 Hook 保障**：必须发生的事走 Hook，建议遵守的事走 CLAUDE.md / Rules
- **文件驱动交接**：Agent 间通过 `.claude/artifacts/` 的结构化 Markdown 交接，主会话做总线
- **调度表真源**：用户信号、首调 Agent、artifact、下一跳和并发等级统一写入调度表
- **渐进进化**：Auto Memory + Agent Memory → `/bcc-update-memory` → `/bcc-update-memory` 闭环

---

## 二、为什么这样设计（设计心路）

### 核心洞察：上下文是最稀缺的资源

Claude 的上下文窗口保存对话历史、工具结果、文件内容、CLAUDE.md、Skills、MCP 工具定义等。当上下文接近满时：
- Claude 开始"遗忘"早期指令
- 指令遵循度下降
- 犯错率上升

几乎所有架构决策都在回答一个问题：**如何在有限上下文中最大化信噪比？**

这直接解释了系统的几个选择：
- 为什么 CLAUDE.md 严格控制在 120-150 行（而非百科全书式）
- 为什么 Rules 必须带 `paths` 按需激活
- 为什么要用 Subagent 隔离探索
- 为什么主会话默认不写复杂代码（保持干净的调度上下文）
- 为什么调度表必须成为真源（避免 25 个角色后靠临场感觉路由）

### 核心洞察：模型能力 vs 架构支撑

行业主流做法是用最强模型（Opus 级）去对抗混乱上下文。我们的信念是：**干净上下文 + 结构化约束能让 Sonnet 级模型在单点任务上不输 Opus**。

这解释了为什么 资深系统架构师 产出 scope-lock（精确到文件/函数级），以及为什么每个 实现工程师 接任务时只加载必要的 Skill 和 Rule。弱模型 + 强架构 > 强模型 + 弱架构。

### 核心洞察：指令是概率性的，不是确定性的

CLAUDE.md、Rules、Skills 都是作为上下文文本注入，Claude"尝试遵循但不保证"。需要确定性保证（例如"编辑完必须 lint"）的场合必须用 Hook（外部脚本，保证执行）或托管设置。

### 为什么扩展到 39 个 Agent

早期版本把能力主要压在少数几个 Agent 身上，优点是体系简洁，缺点是容易把不同目标函数混在一起。进一步实战后，真正暴露出来的瓶颈不是 Agent 太少，而是某些职责不该继续合并：

- 旧版“总审查员”同时审需求、架构、代码、功能、视觉，认知切换成本太高
- 旧版“总研究员”同时做仓库探索和外部调研，事实收集和方案比较混在一起
- `资深系统架构师` 同时做技术方案和 scope-lock 生产，设计抽象和执行拆分互相污染

所以当前版本扩展为 39 个角色，但扩展的依据仍然不是“多多益善”，而是三条：

- 核心流水线中的认知冲突必须拆开
- 运行时、交付物和验收标准差异足够大的专项域必须独立成卫星角色
- 主会话自身的调度理解、门控压缩和单模型交付风险必须能被只读反向检查

因此当前拓扑分成两层：

- 核心流水线：`客户需求整理师` / `创意策划师` / `资深需求分析师` / `高级需求审查师` / `调度顾问师` / `项目管理师` / `资深系统架构师` / `资深范围规划师` / `高级架构审查师` / `高级前端工程师` / `高级后端工程师` / `高级移动端工程师` / `高级桌面应用工程师` / `高级代码审查师` / `高级安全审计师` / `高级功能测试师` / `高级视觉测试师` / `质量总监` / `高级运维工程师`
- 专项卫星层：`小程序开发专家` / `资深数据库工程师` / `机器学习工程师` / `文档工程师` / `视觉设计专家` / `Claude Code 工作流与提示词设计大师` / `代码库研究员` / `技术调研专家` / `高级内容审查师` / `高级调研审查师` / `接单报价师` / `就业教练` / `多媒体内容生成师` / `仓颉语言开发专家` / `华为昇腾开发专家` / `学术论文写作专家` / `顶会顶刊审稿专家` / `论文数字审计员` / `引用审计员` / `定理证明审计员`

技术栈差异大部分仍然交给 Skill + Rule 解决；只有当平台运行时、交付物、验收标准或调度风险发生质变时，才提升成独立 Agent。典型例子就是小程序、数据库、ML、最终裁决、元治理和调度顾问。

`调度顾问师` 是只读反向 advisor，不是第二个 PM。它存在的原因是：主会话可能在长上下文中丢失最新用户意图，或让同一模型完成“理解 → 实现 → 审查 → 宣布完成”的闭环。它只输出 `DISPATCH_ADVICE`，用于提醒动态理解漂移、职责混同、质量门控缺口和单模型交付风险；真正推进状态仍由 `项目管理师` 或主会话执行。

它不维护静态 Agent 名单。每次职责判断必须读取 `rules/_global/dispatch-table.md` 和 `agents/*.md` frontmatter；未来新增普通 Agent 时，清晰的 description 就是它的动态知识来源。只有新增“顾问分析维度”时，才需要更新它自己的 prompt。

### 为什么实现工程师有 4 个变体

理想情况是 1 个实现工程师动态加载不同技术栈 Skill。但 Claude Code 的约束是：**Subagent 的 `skills:` 字段是静态的，主会话调度时无法动态指定**。发现这个约束后，我们按"大类认知域"（前端/后端/移动端/桌面端）拆成 4 个变体，每个静态预加载对应的领域 Skill + 实现协议。具体技术栈细节通过 path-specific Rules 自动补充。

---

## 三、Claude Code 机制速查

以下是本系统依赖的 Claude Code 机制。未来升级前务必确认这些机制仍然有效（Claude Code 版本可能变化）。

### 3.1 扩展体系概览

Claude Code 在模型 + 内置工具之上提供一套扩展层：

| 扩展 | 作用 | 加载时机 | 上下文成本 |
|:--|:--|:--|:--|
| **CLAUDE.md** | 每会话持久指令 | 会话开始 | 持续（每请求） |
| **Rules** | 编码规范 | 无条件启动加载；或 paths 匹配文件时加载 | 持续（条件加载为零直到触发） |
| **Skills** | 可调用的知识或工作流 | 启动加载描述；使用时加载完整内容 | 低（描述级） |
| **Subagents** | 隔离上下文的工作者 | 按需生成 | 独立上下文，不污染主会话 |
| **MCP** | 外部服务连接 | 会话开始（Tool Search 仅加载 10%） | 中等 |
| **Hooks** | 生命周期外部脚本 | 事件触发 | 零（除非 hook 注入） |
| **Plugins** | 打包分发单元 | 按 plugin 启用状态 | 取决于内容 |

### 3.2 CLAUDE.md 机制

- **层级加载**：工作目录到根目录路径上所有 CLAUDE.md 累加注入（不是覆盖）
- **@import 语法**：文件内 `@relative/path` 自动展开引用文件内容到上下文（最大 5 跳）
- **HTML 注释剥离**：`<!-- ... -->` 块在注入前剥离，可给人类维护者留笔记不占 token
- **`/compact` 存活**：项目根 CLAUDE.md 在压缩后会重新注入；子目录 CLAUDE.md 只有在读取该目录文件时才再加载
- **200 行建议上限**：超过会明显降低遵循度
- **claudeMdExcludes 设置**：在 monorepo 中跳过不相关团队的 CLAUDE.md
- **路径优先级**（同名覆盖）：托管策略 > 项目 > 用户 > 本地
- 但 CLAUDE.md 本质是**累加**而非覆盖（冲突由 Claude 判断协调）

### 3.3 Skills 机制

**Frontmatter 字段**：

- `name`：唯一标识，决定调用时的 `/<name>`
- `description`：Claude 决定何时使用的依据（描述质量直接影响触发精度）
- `disable-model-invocation: true`：完全从自动调用中隐藏，只能手动 `/<name>` 触发
- `allowed-tools`：限制 Skill 运行中可用的工具（与 Agent 的 `tools` 字段类似）
- `context: fork`：在隔离上下文中运行（类似 Subagent）

**目录约定（关键）**：
- **Skill 目录必须是 `skills/` 的直接子目录**——`~/.claude/skills/<skill-name>/SKILL.md` 或 `.claude/skills/<skill-name>/SKILL.md`
- **不支持二级嵌套**：`skills/_category/<skill-name>/SKILL.md` 不会被发现（本系统早期踩过此坑，导致所有 Skill 和 `/bcc-*` 命令都加载失败）
- 目录名不决定调用名，frontmatter 的 `name` 字段才决定
- 想要分类？用命名前缀（`bcc-*`、`domain-*` 等）代替子目录

**Rules 机制相反**：Rules 支持递归发现所有子目录，所以 `rules/_lang/python.md`、`rules/_framework/react.md` 这类嵌套是合法的。

**加载机制**：
- 会话开始：所有 Skill 的 name + description 加载到上下文（让 Claude 知道有什么）
- 启用时：完整 `SKILL.md` 加载（按需）
- `disable-model-invocation: true` 的 Skill 连描述都不加载，成本为零直到手动触发

**调用方式**：
- 用户输入 `/<name> {args}`，`$ARGUMENTS` 在 Skill 内部指代用户参数
- 或 Claude 自动调用（如未禁用 model invocation）

**在 Subagent 中的特殊行为**：
- Subagent 的 `skills:` 字段预加载的 Skill 是**启动时全量加载**（不是按需）
- Subagent 不继承主会话的 Skill，必须显式指定
- `disable-model-invocation: true` 的 Skill 不能被预加载（因为预加载来自 model-invocable 池）

#### 3.3.1 BCC 命令设计哲学

BCC（Bootstrapped Command Chain）命令是本系统对 Claude Code Skill 机制的核心应用——以 `bcc-` 前缀的 Skill 封装高频开发工作流，通过 `disable-model-invocation: true` 确保仅在用户显式调用时触发。

**三条设计原则**：

1. **快捷入口**（Quick Entry）：一键触发多步骤复杂流程，降低用户认知负担。例：`/bcc-loop-dev` 一条命令启动全 Agent 团队自动迭代。
2. **流程编排**（Workflow Orchestration）：将分散的多步操作收敛为确定性流程，减少遗漏和歧义。例：`/bcc-deploy` 编排构建→测试→部署→验证全链路。
3. **质量门控**（Quality Gate）：在关键节点强制执行检查，防止低质量产出流入下游。例：`/bcc-doctor` 在部署前扫描系统健康状态。

**命名规范**：`bcc-{action}-{target}` 或 `bcc-{workflow}`
- `bcc-{workflow}`：端到端工作流（`bcc-loop-dev`、`bcc-fast-fix`、`bcc-init-project`）
- `bcc-{action}-{target}`：针对特定目标的操作（`bcc-security-scan`、`bcc-perf-test`、`bcc-deploy`）

**命令矩阵**（v5.1）：

| 命令 | 类型 | 触发场景 |
|:--|:--|:--|
| `/bcc-init-project` | 工作流 | 新项目首次进入 |
| `/bcc-update-memory` | 工作流 | 会话结束、知识沉淀 |
| `/bcc-doctor` | 质量门控 | 定期健康检查、部署前验证 |
| `/bcc-loop-dev` | 工作流 | 自主开发循环 |
| `/bcc-fast-fix` | 工作流 | 极速单点修复 |
| `/bcc-teams` | 工作流 | Agent Teams 并行协作 |
| `/bcc-deploy` | 流程编排 | 一键部署（构建→测试→部署→验证） |
| `/bcc-security-scan` | 质量门控 | 安全扫描（依赖漏洞/代码安全/敏感信息） |
| `/bcc-perf-test` | 质量门控 | 性能测试（瓶颈/内存泄漏/响应时间） |
| `/bcc-refactor` | 流程编排 | 安全重构（分析→拆分→验证→回归） |

**扩展指引**：新增 BCC 命令时，必须遵循以上三条原则之一，且 SKILL.md 必须包含完整操作流程（不依赖 references/），因为 `disable-model-invocation: true` 意味着 Skill 内容在触发时才全量加载。

### 3.4 Subagents 机制

**Frontmatter 核心字段**（按在本系统中使用到的）：

- `name` / `description`：同 Skill
- `tools`：允许列表（省略则继承所有）
- `disallowedTools`：拒绝列表（从继承或允许列表中扣除）
- `model`：`sonnet` / `opus` / `haiku` / `inherit` / 具体 model ID
- `permissionMode`：`default` / `acceptEdits` / `auto` / `dontAsk` / `bypassPermissions` / `plan`
- `skills`：启动时预加载的 Skill 名称数组（全量内容，非按需）
- `mcpServers`：内联或按名引用的 MCP 服务器（可限定到此 agent）
- `hooks`：Agent 生命周期 hook（仅此 agent 有效）
- `memory`：`user` / `project` / `local`（持久记忆目录范围）
- `isolation: worktree`：在临时 git worktree 中运行（隔离副本）
- `effort`：`low` / `medium` / `high` / `xhigh` / `max`（覆盖会话级）
- `background: true`：默认后台运行
- `color`：UI 显示颜色
- `initialPrompt`：作为主会话运行时的首轮自动提示

**Frontmatter 之外**：markdown body 作为 Agent 的系统提示（非 Claude Code 的默认完整系统提示）。

**关键限制**：
- **Subagent 不能生成 Subagent**（hub-and-spoke 拓扑）
- `skills:` 静态绑定到 Agent 定义，主会话调度时无法动态指定（这是 3 个 Implementer 变体的由来）（v5.0 验证：截至 Claude Code v2.1.131，此限制仍然存在。下次验证时机：v5.1 或 Claude Code v2.2 发布时）
- 每次调用生成**新鲜上下文**，不继承父对话的对话历史或调用的 Skill
- 父对话的 CLAUDE.md 和 git 状态会继承；无条件 Rules 大概率也继承
- Path-specific Rules 只有在 Subagent 自己读取匹配文件时才触发

**Session Forking**（v2.1.x 新增）：

主会话可以将当前对话 fork 到并行工作者。与命名 Subagent 的区别：

| 维度 | 命名 Subagent | Fork |
|:--|:--|:--|
| 上下文 | 全新上下文，不继承父对话历史 | 共享父会话上下文快照 |
| 定义方式 | `.claude/agents/*.md` frontmatter | 运行时动态 fork |
| 通信 | 只能返回结果给主会话 | 可观察和操控（observe and steer） |
| 适用场景 | 有明确角色定义的专职任务 | 只读研究、并行探索同一问题的不同假设 |
| Token 成本 | 独立上下文，成本可控 | 共享上下文，fork 数量需控制 |

**Fork 的关键特性**：
- Fork 后的工作者可在后台运行，主会话可观察进度
- 主会话可向 fork 发送消息进行操控（steer）
- Fork 适合只读任务；写入任务仍应使用命名 Subagent（隔离更安全）
- `CLAUDE_CODE_FORK_SUBAGENT=1` 环境变量可在非交互会话中启用 fork

**新 Frontmatter 字段**（v2.1.x 新增/确认）：

- `maxTurns`：最大 agentic 轮数，到达后 subagent 自动停止
- `isolation: worktree`：在临时 git worktree 中运行，自动清理无变更的 worktree
- `effort`：`low` / `medium` / `high` / `xhigh` / `max`，覆盖会话级 effort
- `background: true`：默认后台运行
- `color`：UI 显示颜色
- `initialPrompt`：作为主会话运行时的首轮自动提示
- `memory`：`user` / `project` / `local`，持久记忆目录范围

**Subagent 定义的作用域与优先级**：

| 位置 | 作用域 | 优先级 |
|:--|:--|:--|
| 托管设置 | 组织级 | 1（最高） |
| `--agents` CLI 标志 | 当前会话 | 2 |
| `.claude/agents/` | 当前项目 | 3 |
| `~/.claude/agents/` | 所有项目 | 4 |
| Plugin 的 `agents/` 目录 | 插件启用处 | 5（最低） |

**CLI 动态定义 Subagent**（`--agents` 标志）：

可通过 `--agents` 传入 JSON 在启动时动态定义 subagent，无需写文件：

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer",
    "prompt": "You are a senior code reviewer...",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

支持所有 frontmatter 字段（`description`、`prompt`、`tools`、`disallowedTools`、`model`、`permissionMode`、`mcpServers`、`hooks`、`maxTurns`、`skills`、`initialPrompt`、`memory`、`effort`、`background`、`isolation`、`color`）。

**Plugin Subagent 安全限制**：

来自 Plugin 的 subagent 定义不支持 `hooks`、`mcpServers`、`permissionMode` 字段——这些字段在加载时被忽略。如需这些能力，将 agent 文件复制到 `.claude/agents/` 或 `~/.claude/agents/`。

**调用方式**：
- `Agent` 工具调用（模型判断）
- `@agent-<name>` 显式 mention（强制）
- `claude --agent <name>` 将整个会话作为该 Subagent 运行

**SubagentStop 事件与 Transcript 的对应关系**（实战验证，v2.1.x）：

Claude Code 真实的 `SubagentStop` hook 事件 JSON 字段**非常精简**，只有：

```
session_id, agent_id, agent_type, agent_transcript_path,
hook_event_name, cwd, permission_mode, last_assistant_message,
stop_hook_active, transcript_path
```

**没有** `usage` / `model` / `duration_ms`。这是一个容易误判的点——文档示例常显示"完整字段"但实际事件字段更少。

Token 用量的真相源是 **subagent 自己的 transcript**，路径由 `agent_transcript_path` 指示，格式：

```
~/.claude/projects/<project-slug>/<session_id>/subagents/agent-<agent_id>.jsonl
```

每条记录是一个 turn，`.type` 为 `user` / `assistant` / `tool_use` / `tool_result`。`type: assistant` 的记录包含 `.message.usage`（input/output/cache tokens）和 `.message.model`。

任何需要 subagent 级分析的脚本（成本、耗时、行为审计）都应读 transcript 而非依赖 hook event。

**并发 Subagent 的状态追踪**：

Claude Code 支持多 subagent 并发（`Agent` 工具可以一次发起多个调用）。任何"当前活跃状态"的追踪文件**必须按 `agent_id` 命名空间化**，例如：

```
/tmp/claude-legion-active-{session_id}-{agent_id}
```

读取时用 glob 收集所有活跃实例；`SubagentStop` 清理**只删自己的** agent_id 对应文件。否则只能追踪到"最后启动的那一个"。

### 3.5 Rules 机制

- 存放在 `.claude/rules/` 目录（项目级）或 `~/.claude/rules/`（用户级）
- 递归发现所有 `.md` 文件
- **无条件 Rule**：无 `paths` frontmatter，启动时加载
- **条件 Rule**：有 `paths` 数组，仅在 Claude 读取匹配 glob 的文件时加载
- glob 支持：`**/*.ts`、`src/**/*`、`{a,b}`、`?` 等
- 符号链接支持，循环检测

**Rule 不是 Skill 的替代**：Rule 是"项目或语言通用约束"，Skill 是"特定任务的知识或工作流"。两者补充。

### 3.6 Hooks 机制

**事件列表**（完整，含 v2.1.x 新增）：

| 事件 | 触发时机 | matcher 支持 | 本系统使用 |
|:--|:--|:--|:--|
| `SessionStart` | 会话开始或恢复 | `startup` / `resume` / `clear` / `compact` | ✅ |
| `Setup` | `--init-only` / `--init` / `--maintenance` 启动 | `init` / `maintenance` | — |
| `UserPromptSubmit` | 用户提交 prompt | 不支持 | ✅ |
| `UserPromptExpansion` | 命令展开为 prompt 前 | 命令名 | — |
| `PreToolUse` | 工具调用执行前 | 工具名 | ✅ |
| `PermissionRequest` | 权限对话框出现 | 工具名 | ✅ |
| `PermissionDenied` | 工具调用被 auto mode 拒绝 | 工具名 | — |
| `PostToolUse` | 工具调用成功后 | 工具名 | ✅ |
| `PostToolUseFailure` | 工具调用失败后 | 工具名 | 🆕 |
| `PostToolBatch` | 并行工具调用批次完成后 | 不支持 | 🆕 |
| `Notification` | Claude Code 发送通知 | 通知类型 | — |
| `SubagentStart` | Subagent 生成 | agent type | ✅ |
| `SubagentStop` | Subagent 完成 | agent type | ✅ |
| `TaskCreated` | 任务被创建（Agent Teams） | 不支持 | 🆕 |
| `TaskCompleted` | 任务被标记完成（Agent Teams） | 不支持 | 🆕 |
| `Stop` | Claude 完成响应 | 不支持 | ✅ |
| `StopFailure` | 因 API 错误终止 | 错误类型 | 🆕 |
| `TeammateIdle` | Agent Teams 队友即将空闲 | 不支持 | 🆕 |
| `InstructionsLoaded` | CLAUDE.md / Rule 文件加载 | 加载原因 | ✅ |
| `ConfigChange` | 配置文件变更 | 配置来源 | — |
| `CwdChanged` | 工作目录变更 | 不支持 | 🆕 |
| `FileChanged` | 监视文件在磁盘上变更 | 字面文件名 | 🆕 |
| `WorktreeCreate` | Worktree 被创建 | — | — |
| `WorktreeRemove` | Worktree 被移除 | — | — |
| `PreCompact` | 上下文压缩前 | `manual` / `auto` | ✅ |
| `PostCompact` | 上下文压缩后 | `manual` / `auto` | ✅ |
| `Elicitation` | MCP 服务器请求用户输入 | MCP 服务器名 | — |
| `ElicitationResult` | 用户响应 MCP 请求后 | MCP 服务器名 | — |
| `SessionEnd` | 会话终止 | 终止原因 | — |

**Hook 条目结构**：

```json
{
  "matcher": "工具名或 |-分隔的多个",
  "hooks": [
    {
      "type": "command",
      "command": "shell 命令",
      "if": "可选的命令级条件，如 Bash(pattern)",
      "timeout": 30,
      "async": true,
      "statusMessage": "显示给用户的状态"
    }
  ]
}
```

**输入**：Claude Code 通过 stdin 传入 JSON（含 `session_id`、`tool_input`、`tool_response` 等）。

**输出控制**：
- 退出码 0：正常
- 退出码 2：阻止（把 stderr 作为错误反馈给 Claude）
- stdout 输出 JSON `{"hookSpecificOutput": {...}}` 可以注入 `additionalContext`、`permissionDecision` 等

**重要陷阱**：
- `if` 字段的 `Bash(pattern)` 语法中，`$HOME` 等环境变量会被展开，展开后的模式如果太宽会误伤正常命令（本系统早期踩过此坑）
- 条件匹配倾向宽松，设置 `if` 条件要尽量精确
- `async: true` 时 hook 不阻塞 Claude，但也无法通过退出码阻止操作

**Hook 类型扩展**（v2.1.x 新增）：

除传统 `type: "command"` 外，Claude Code 现支持三种新 hook 类型：

| 类型 | 配置 | 适用场景 |
|:--|:--|:--|
| `command` | `"type": "command", "command": "shell 命令"` | 确定性逻辑、文件操作、数值比较 |
| `prompt` | `"type": "prompt", "prompt": "判断指令"` | 需要语义理解的决策（如分类、意图判断） |
| `agent` | `"type": "agent"` | 需要完整 agentic 能力的复杂判断（可使用工具） |
| `http` | `"type": "http", "url": "https://..."` | 调用外部 API / webhook |

**Prompt-based Hooks**：

用 Claude 模型做语义判断，替代 bash 关键词正则。配置格式：

```json
{
  "type": "prompt",
  "prompt": "判断用户 prompt 是否缺少关键信息。如果请求明确且完整，返回 {\"decision\": \"allow\"}。如果缺少必要信息（如文件路径、错误日志、验收标准），返回 {\"decision\": \"block\", \"reason\": \"缺少: ...\"}。"
}
```

- 输入：与 command hook 相同的 JSON（通过 stdin 传入事件上下文）
- 输出：JSON `{"decision": "allow|block", "reason": "..."}`
- 优势：语义理解远优于关键词正则，误判率显著降低
- 限制：每次调用消耗 token；延迟高于 bash；不适合纯数值比较
- 适用：clarification-gate 类语义判断（替代当前 bash 方案）

**Agent-based Hooks**：

生成完整 subagent 做复杂判断，可使用工具（Read/Grep 等）。配置格式：

```json
{
  "type": "agent"
}
```

- Agent 的系统提示由 hook 事件上下文自动构建
- 可使用 Read/Grep 等工具做深入分析
- 适合需要代码库上下文的复杂决策
- 成本最高（完整 agentic 循环）

**HTTP Hooks**：

向外部 URL 发送 POST 请求，请求体为 hook 事件 JSON。配置格式：

```json
{
  "type": "http",
  "url": "https://your-server.com/hook"
}
```

- 适合集成外部系统（通知、审计、CI 触发）
- 响应格式与 command hook stdout 相同

**Async Hooks**（后台执行）：

所有类型的 hook 都支持 `async: true`，在后台执行不阻塞 Claude：

```json
{
  "type": "command",
  "command": "run-tests.sh",
  "async": true,
  "statusMessage": "Running tests..."
}
```

- 适用：测试运行、通知发送、日志记录等不需要即时反馈的场景
- 限制：async hook 无法通过退出码阻止操作

**新事件的 JSON Input Schema 速查**：

`PostToolUseFailure`：
```json
{"tool_name": "Bash", "tool_input": {...}, "error": "错误信息"}
```

`TaskCreated` / `TaskCompleted`（Agent Teams）：
```json
{"task_id": "...", "task_title": "...", "agent_name": "..."}
```

`FileChanged`：
```json
{"filename": "改变的文件路径", "change_type": "modified|created|deleted"}
```
- matcher 字段指定要监视的文件名（字面量，`|` 分隔），如 `".envrc|.env"`
- 不遵循常规 matcher 规则（不支持正则）

`CwdChanged`：
```json
{"cwd": "新工作目录路径"}
```

`TeammateIdle`：
```json
{"teammate_name": "...", "task_id": "..."}
```
- 退出码 2 可发送反馈并让 teammate 继续工作

`StopFailure`：
```json
{"error_type": "rate_limit|authentication_failed|billing_error|server_error|max_output_tokens|unknown"}
```
- 输出和退出码被忽略（仅用于日志记录）

**本系统的 Hook 集中网关**：所有 hook 都通过 `hooks/_lib/run-with-logging.sh` 包装执行。该 wrapper 会：

1. 日志化：stderr 捕获 + 异常退出写入 `hook-errors.log`
2. Profile 门控（v2 新增）：source `hooks/_lib/hook-flags.sh`，读取 `CLAUDE_HOOK_PROFILE`（`minimal|standard|strict`，默认 `standard`）与 `CLAUDE_DISABLED_HOOKS`（逗号分隔黑名单）。禁用时消费 stdin、立即 exit 0，不污染真 hook 的 stdin pipe

每个 hook 的最低 profile 在 `hook-flags.sh` 的 `_HOOK_MIN_PROFILE` 数组声明（灵感来自 ECC `scripts/lib/hook-flags.js`，实现独立）。新增 hook 必须登记，否则 `bin/doctor.sh` §14 会报漂移。单元测试见 `bin/test-hook-flags.sh`。

**Profile 分档原则**：
- `minimal`：只放行生命周期必需（`session-start` / `pre-compact` / `post-compact` / `subagent-start-mark`）
- `standard`（默认）：minimal + 审计/安全/质量（`scope-lock-guard` / `artifact-write-guard` / `post-edit-lint` / `subagent-stop-log` / `instructions-audit`）
- `strict`：预留更强约束档位，当前等价 `standard`

### 3.7 Memory 机制

**两套系统**：
- **CLAUDE.md**：你写的指令（静态）
- **Auto Memory**：Claude 自己积累的笔记（动态）

**Auto Memory**：
- 目录：`~/.claude/projects/<project>/memory/`
- 入口：`MEMORY.md`（前 200 行或 25KB 在会话开始时加载）
- 主题文件：按需读取
- 跨 worktree 共享（同 repo）

**Agent Memory**（Subagent 的持久记忆）：
- 通过 `memory` frontmatter 启用
- 范围：`user` / `project` / `local`
- 路径：`~/.claude/agent-memory/<agent-name>/`（user）或 `.claude/agent-memory/<agent-name>/`（project）
- 工作方式：Agent 系统提示自动注入内存目录的 `MEMORY.md` 开头部分 + 读写工具开启

**本系统的 Memory 分层策略**：
- 方法论、表达和治理型 Agent（`客户需求整理师`、`创意策划师`、`视觉设计专家`、`Claude Code 工作流与提示词设计大师`）→ `user`（跨项目偏好与方法可复利）
- 项目状态与交付型 Agent（`项目管理师`、`资深需求分析师`、`高级需求审查师`、`资深系统架构师`、`资深范围规划师`、`高级架构审查师`、`实现工程师-*`、`小程序开发专家`、`资深数据库工程师`、`机器学习工程师`、`高级代码审查师`、`高级安全审计师`、`高级功能测试师`、`高级视觉测试师`、`质量总监`、`文档工程师`、`高级运维工程师`）→ `project`
- 事实采样型 Agent（`代码库研究员`、`技术调研专家`）→ `project`，避免把单仓库 / 单次调研噪声带到别的场景

**项目知识隔离硬规则**：具体项目的 `project-knowledge` 只能存在于该项目 `.claude/skills/project-knowledge/`，用户级 `~/.claude/skills/` 只能保留模板或生成器。

### 3.8 MCP 机制

- `.mcp.json` 项目级 / `~/.claude/.claude.json` 用户级 / `settings.json` 嵌入
- 服务器类型：`stdio` / `http` / `sse` / `ws`
- **Tool Search**（默认启用）：启动时只加载约 10% 的 MCP 工具定义，其余延迟
- 可靠性陷阱：MCP 连接可能中途静默断开，用 `/mcp` 检查
- 每服务器的上下文成本可以通过 `/mcp` 查询

**Subagent 中使用 MCP**：
- `mcpServers` frontmatter 可以内联定义（此 Agent 专属）或按名引用（共享主会话配置）
- 内联定义避免把该 MCP 暴露给主会话（节省主上下文）

**本系统默认启用的 MCP（用户级）**：

| MCP | 角色协同 | 零配置？ |
|:--|:--|:--|
| `github` | 高级运维工程师 的 PR/release 流程、代码库研究员 查历史 PR、流水线自动化 | 需填 PAT |
| `fetch` | 技术调研专家 做外部技术调研（比 WebFetch 更全：POST、header、md 转换） | 是 |
| `time` | artifact 时间戳一致性、跨时区协作 | 是 |
| `sequential-thinking` | 资深系统架构师 做复杂架构设计时的多步推理脚手架 | 是 |

**通过 Plugin（不是 MCP）启用的能力**：
- `playwright` — UI 自动化和视觉测试（高级视觉测试师 提供截图证据）
- `context7` — 第三方库文档按需获取
- LSP 组（typescript / pyright / jdtls）— 精确符号导航

插件和 MCP 二选一：某能力若已通过 Plugin 启用（如 Playwright），就不要再装对应 MCP——会重复加载、污染上下文。

### 3.9 Plugins 机制

- Plugin 是 Skills + Hooks + Subagents + MCP 的打包单元
- Plugin Skill 是命名空间的：`/<plugin>:<skill>`
- 通过 Marketplace（如 `anthropics/claude-plugins-official`）分发
- 本系统通过 `enabledPlugins` 启用若干 LSP 插件（typescript-lsp、pyright-lsp 等）给 Agent 提供精确符号导航

### 3.10 Output Style 机制

- 路径：`~/.claude/output-styles/<name>.md`
- Frontmatter：`name` + `description`
- Body：自定义系统提示（**完全替换** Claude Code 默认系统提示的行为风格部分）
- 在 `settings.json` 中 `outputStyle: "<name>"` 设为默认
- 内置风格：`default` / `explanatory` / `learning`

本系统的自定义 style（`legion-dispatch`）强制调度器身份和中文、极简响应。

### 3.11 Settings.json 结构速查

主要字段：
- `env`：环境变量
- `permissions.allow` / `permissions.defaultMode`
- `enabledPlugins` / `extraKnownMarketplaces`
- `mcpServers`
- `hooks`：见上文
- `outputStyle`
- `language`：界面语言
- `effortLevel`
- `providers`：第三方 API 提供商（本系统配了多个国产兼容 Claude 协议的提供商）
- `agent`：默认以某 Subagent 身份运行主会话
- `claudeMdExcludes`
- `autoMemoryEnabled` / `autoMemoryDirectory`

---

### 3.13 Agent Teams 机制

**状态**：实验性功能（需 `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 环境变量启用），v2.1.32+ 可用。

Agent Teams 让多个 Claude Code 实例作为团队协作。一个会话充当 Team Lead，协调工作、分配任务、综合结果。Teammates 独立工作，各有自己的上下文窗口，可直接互相通信。

**与 Subagent 的核心区别**：

| 维度 | Subagent | Agent Teams |
|:--|:--|:--|
| 上下文 | 独立上下文，结果返回主会话 | 独立上下文，完全独立 |
| 通信 | 只能向主会话报告 | Teammates 可直接互发消息 |
| 协调 | 主会话管理所有工作 | 共享任务列表，自协调 |
| 适用 | 只需结果的聚焦任务 | 需要讨论和协作的复杂工作 |
| Token 成本 | 较低（结果摘要返回） | 较高（每个 teammate 是独立 Claude 实例） |

**架构组件**：

| 组件 | 角色 |
|:--|:--|
| Team Lead | 主 Claude Code 会话，创建团队、spawn teammates、协调工作 |
| Teammates | 独立 Claude Code 实例，各自处理分配的任务 |
| Task List | 共享工作列表，teammates 认领和完成 |
| Mailbox | Agent 间消息通信系统 |

**关键特性**：
- Teammates 可引用 Subagent 定义（复用 `tools`、`model`，定义体追加到 teammate 系统提示）
- 但 `skills` 和 `mcpServers` frontmatter 在作为 teammate 运行时不生效——teammates 从项目/用户设置加载
- 任务声明依赖关系，被依赖任务完成后自动解锁
- 任务认领使用文件锁防止竞态条件
- 支持 in-process（Shift+Down 切换）和 split-pane（tmux/iTerm2）两种显示模式
- Teammate 可被要求 plan approval（先规划再实现）

**存储位置**：
- 团队配置：`~/.claude/teams/{team-name}/config.json`
- 任务列表：`~/.claude/tasks/{team-name}/`

**本系统集成策略**：
- 大型任务（large 档 + ≥2 独立 scope-lock）可选用 Agent Teams 模式
- 小型任务保持 Subagent 模式
- 并发安全约束仍由 dispatch-table 的 S0-S3 等级控制
- 新增 S4 并发等级：Agent Teams 并行协作（Teammates 各自隔离，通过消息协调）

**已知限制**：
- 仍为实验性功能，API 可能变化
- 会话恢复支持有限
- 任务协调可能出现竞态
- 关闭行为需要手动清理

### 3.14 Channels 机制

**状态**：研究预览（v2.1.80+），需 claude.ai 登录，不支持 Console/API key 认证。

Channels 让 MCP 服务器将事件推送到运行中的 Claude Code 会话，使 Claude 能在用户离开终端时响应外部事件。

**核心概念**：
- Channel 是一个 MCP 服务器插件，推送事件到会话
- 事件只在会话打开时到达
- 支持双向通信：Claude 读取事件并通过同一 channel 回复
- 通过 `--channels` 标志启用

**预置 Channel 插件**：
- Telegram：通过 Bot 推送消息
- Discord：通过 Bot DM 推送
- iMessage：读取本地 Messages 数据库（仅 macOS）

**安全模型**：
- 每个 channel 维护 sender allowlist
- Telegram/Discord 通过 pairing 机制验证
- iMessage 自聊自动放行，其他联系人需手动添加
- `channelsEnabled` 托管设置控制组织级开关
- `allowedChannelPlugins` 限制可用插件

**自定义 Channel**：
- 按 Channels reference 协议构建 MCP 服务器
- 声明 channel capability
- 实现通知事件和回复工具
- 开发测试用 `--dangerously-load-development-channels`

**本系统集成策略**：
- CI 结果推送 → 高级功能测试师 自动调整测试策略
- PR 事件 → 高级代码审查师 自动启动 code-review
- 监控告警 → 高级运维工程师 自动响应
- Channel 触发的 DispatchTicket 自动创建

### 3.15 Routines / 定时任务机制

Claude Code 提供三种定时/周期任务机制：

| 机制 | 运行位置 | 需要机器开机 | 需要打开会话 | 访问本地文件 |
|:--|:--|:--|:--|:--|
| Cloud Routines | Anthropic 云 | 否 | 否 | 否（fresh clone） |
| Desktop 定时任务 | 本机 | 是 | 否 | 是 |
| `/loop` | 本机 | 是 | 是 | 是 |

**Desktop 定时任务**：
- 在 Claude Code Desktop 的 Routines 页面创建
- 支持 Manual / Hourly / Daily / Weekdays / Weekly 预设
- 每个任务有独立的权限模式
- 支持 worktree 隔离
- 错过运行时最多补跑一次（7 天内最近一次）
- 存储位置：`~/.claude/scheduled-tasks/<task-name>/SKILL.md`

**Cloud Routines**：
- 在 Anthropic 托管基础设施上运行
- 支持定时 / API 调用 / GitHub 事件触发
- 即使计算机关闭也能运行
- 通过 `/schedule` CLI 命令管理

**`/loop` 会话内调度**：
- 在当前会话内设置周期性任务
- 最短间隔 1 分钟
- 会话关闭后失效（`--resume` 可恢复未过期任务）

**本系统集成策略**：
- 每日 doctor 检查 → Desktop 定时任务
- 每周安全审计 → Cloud Routine
- 代码审查轮询 → `/loop` 会话内
- Routines 与 `/bcc-*` 命令映射：`/bcc-doctor` → 每日定时、`/bcc-update-memory` → 每周定时

### 3.16 Structured Outputs 机制

**状态**：仅 Agent SDK 可用（Python / TypeScript），**不可用于常规 Claude Code Subagent**。

Structured Outputs 让 Agent 返回验证过的 JSON 而非自由文本。通过 JSON Schema / Zod / Pydantic 定义输出格式，SDK 自动验证并在不匹配时重试。

**配置方式**（Agent SDK）：

```typescript
import { query } from "@anthropic-ai/claude-agent-sdk";

const schema = {
  type: "object",
  properties: {
    token: { type: "string" },
    artifact_path: { type: "string" },
    issue_counts: {
      type: "object",
      properties: {
        severe: { type: "number" },
        general: { type: "number" },
        minor: { type: "number" }
      }
    }
  },
  required: ["token", "artifact_path"]
};

for await (const message of query({
  prompt: "...",
  options: {
    outputFormat: { type: "json_schema", schema }
  }
})) {
  if (message.type === "result" && message.structured_output) {
    console.log(message.structured_output);
  }
}
```

**对本系统的影响**：
- 当前 17 个核心 Agent 的返回 token 协议（`IMPL_DONE:` / `REVIEW_PASS:` 等）仍需保持自由文本格式
- 未来若 Claude Code 将 Structured Outputs 扩展到常规 Subagent，可升级为 JSON Schema 验证的返回格式
- 当前替代方案：在 Subagent 系统提示中严格定义返回格式（如 `IMPL_DONE:...` / `REVIEW_PASS:...` token 协议），由 hook 脚本用 jq 或正则解析。v5.0 验证：Structured Outputs 不适用于常规 Subagent，Agent 返回 token 协议保持自由文本格式不变。

---

### 3.11.5 Artifact Schema（v2 新增）

Artifact 从"文字规范"升级为"机读可验证规范"。校验器 `bin/validate-artifacts.sh` 对 `.claude/artifacts/*.md` 做三层检查：

| 级别 | 含义 | 样例 |
|:--|:--|:--|
| `CRITICAL` | 结构性错误，必须修 | frontmatter type 与文件名前缀不一致；status 非法值；scope-lock 缺白名单段；verdict 缺最终结论 |
| `WARNING` | 兼容性问题，建议修 | 老 artifact 缺 frontmatter；缺 status 字段；文件名前缀不在 type 枚举 |
| `PASS` | 完整合规 | frontmatter 齐、专项段落齐 |

**设计决策**：校验器用 bash + awk 实现，不引入 YAML parser；老 artifact 缺 frontmatter 只报 WARNING 不阻塞。`bin/doctor.sh` §15 会汇总。

**专项校验**：
- `scope-lock-*.md`：必须包含 `## 改动白名单` / `## 白名单` / `## Scope` 之一
- `verdict-*.md`：文件中必须出现 `PASS` / `CONDITIONAL PASS` / `BLOCKED` 之一

### 3.11.6 Router 分层（v3 新增·核心升级）

**背景**：Anthropic 官方承认多 agent 系统常被用错（[engineering blog](https://www.anthropic.com/engineering/multi-agent-research-system)）——简单任务用多 agent 反而浪费 token（15×）且结果未必更好。当前版本把"什么任务走什么路径"交给模型按完整语义自判，hook 只负责确定性拦截和提醒。

#### 双 hook 链

用户每次发消息，`UserPromptSubmit` 事件触发两个 hook 串行执行：

```
用户 prompt
  ↓
clarification-gate.sh → 若请求明确缺关键信息且无文件/错误日志 → decision:"block" 追问
  ↓
review-gate.sh        → 若本 session 有未 review 的 实现工程师 改动 → 注入 [REVIEW-PENDING]
  ↓
主会话自判 tier + 读取提示 → 按 output-styles/legion-dispatch.md 的映射表调度
```

#### 5 档分类标准

| tier | 信号 | 调度动作 |
|:--|:--|:--|
| `trivial` | 短 + 问号 / "好的"/"谢谢" | 主会话直接回，不派 subagent |
| `small` | 有文件路径 + 长度 < 300 + "改一下"等轻动词 | 快路径或单 实现工程师 |
| `medium` | 跨文件 / 功能级 / 清楚需求 | 必经 高级代码审查师 |
| `large` | "新功能/重构/迁移/部署" 等结构性动词 | 完整流水线 + 全门控 |
| `unclear` | "客户说/感觉/帮我看看"+ 无文件引用 + 长度 < 400 | 被 clarification-gate 拦截 |

#### 设计取舍（都踩过官方坑才这么设计）

- **hook 合并到 UserPromptSubmit**：`Stop` 事件不支持 `additionalContext`，用 `UserPromptSubmit` 在下一轮注入提示是唯一可行路径
- **clarification-gate 保守触发**：文件路径 / 错误日志 / 长 prompt（>500 字符）/ bypass 关键词 → 放行；避免骚扰
- **review-gate 只提醒不 block**：快路径改动本来就可以跳 review（small 档），强 block 会骚扰
- **档位模型自判**：关键词正则看不懂语境，当前只保留确定性 hook，不再用 bash 分类器注入 tier
- **降档受限**：output-style 允许升档（medium→large）不允许降档（除非用户明确说"小修就行"）

#### review-gate.sh

- **触发点**: UserPromptSubmit（clarification-gate → review-gate）
- **数据源**: `~/.claude/logs/subagent-events.jsonl`，按 session_id 过滤
- **Pending 公式**: `modify_count - reviewer_count`（modify = 实现工程师-*/小程序开发专家/资深数据库工程师/机器学习工程师/高级运维工程师 完成数）
- **行为**: 纯 advisory，注入 `[REVIEW-PENDING]` 标记，不 block
- **忽略方式**: 忽略标记即可；small 档任务本就可以跳 review
- **日志**: `~/.claude/logs/review-gate.jsonl`，每条含 session_id/modify/reviewer/pending

### 3.12 系统健康信号（经验性指标）

以下经验性指标来自实战数据观察。`/bcc-doctor` 和未来 `/bcc-update-memory` 可以用作判断依据。

#### 3.12.1 Prompt Cache 健康比例

在 Claude Code + Agent Legion 架构下，健康的 subagent 会话应有：

```
cache_read_tokens ≈ input_tokens × 10~20
```

**原理**：每个 Subagent 的 CLAUDE.md + Skills + system prompt 在每轮 turn 都重新发送。Prompt cache 识别重复前缀，以 1/10 价格读取。Cache 生效时这个比例会自然拉高到 10-20×。

**判读**：
- **≥10×**：cache 正常工作
- **5~10×**：cache 部分生效，可能 session 短或前缀变化频繁
- **<5×**：cache 几乎没工作——检查 provider 是否支持 prompt cache，或前缀（system prompt / CLAUDE.md）是否在 session 内被频繁修改

#### 3.12.2 Turn 数作为 Scope-Lock 质量信号

正常 实现工程师 完成一个**精确**的 scope-lock 应该在 **10-30 turns** 内。

**判读**：
- **≤30 turns**：正常
- **30-60 turns**：偏多，可能 scope 偏大或有反复
- **>60 turns**：scope-lock 不够精确，agent 在反复摸索"到底该改什么"——归因到 资深系统架构师 的产出质量，而非 agent 本身

**实战观察**：建造期内某项目 8 次 subagent 调用产出 365 turns（平均 46/次），说明早期 scope-lock 设计不够收敛。

**处置**：
- 单次实现如果 实现工程师 自己发现 turn 数 >50 还没收尾，应主动停下汇报，让 资深系统架构师 重新拆 scope
- `/bcc-update-memory` 审计时可把"高 turn 数"作为寻找系统性问题的起点

#### 3.12.3 成本异常排查路径

当 `bin/cost-summary.sh` 显示某项目成本明显高于同类项目时，按序检查：

1. **Turn 数**：`cost-log.txt` 列中 `turns` 平均值是否 >40？→ scope 问题
2. **Cache 比例**：cache_rd / input 是否 <5×？→ prompt cache 未生效
3. **调用次数**：单次流水线是否触发了过多 subagent？→ 可能误用了完整流水线在应该 `/bcc-fast-fix` 的任务上

## 四、系统的目录层面概览

（**不引用具体文件名**，仅层级和职责）

```
~/.claude/
├── CLAUDE.md                # 调度元协议
├── LEGION.md                # 本文
├── settings.json            # 配置 + hooks
├── agents/                  # Subagent 定义
├── skills/                  # 所有 Skill 扁平存放（Claude Code 发现规则要求）
│   │                        # 按命名前缀区分角色：
│   ├── bcc-*/               # 调度命令（disable-model-invocation:true）
│   ├── {domain-name}/       # 领域知识（Agent 预加载使用）
│   └── {reference-name}/    # 参考资料（模型可自动调用）
├── rules/
│   ├── _global/             # 无条件规则（启动加载）
│   ├── _lang/               # 语言规范（path-specific）
│   ├── _framework/          # 框架规范（path-specific）
│   └── _infra/              # 基础设施规范（path-specific）
├── hooks/                   # Hook 脚本
├── output-styles/           # 自定义输出风格
├── artifacts/               # Agent 间交接文件（运行时）
├── backups/                 # PreCompact 快照
├── agent-memory/            # 项目级 Agent Memory
└── logs/                    # Hook 产生的事件日志
```

---

## 五、如何升级这套系统

### 5.1 日常进化

运行 `/bcc-update-memory`。它会：
1. 审计 Memory 和现有配置
2. 提出改进提案（新 Rule / 新 Skill / 合并 / 清理）
3. 等待用户审批
4. 执行批准的变更

绝大多数升级应通过此机制进行——它是被设计来自我改进的。

### 5.2 手动升级场景

何时需要手动介入：

- **新增 Agent 角色**：识别出一种**全新的认知模式**需求（警告：不要轻易加，几年一次；按技术栈加 Agent 几乎总是错的）
- **新增技术栈支持**：通常只需增加一个 `_lang/` 或 `_framework/` 下的 Rule
- **Claude Code 升级**：新版本可能引入新 Hook 事件、新 Skill 字段等——需要阅读更新日志并同步到本文档
- **修复系统本身的 Bug**：如 Hook 误拦截、Skill 描述不触发——直接改对应文件

### 5.3 升级纪律

- **改 Hook 前先测试**：Hook 太宽松可能拦截正常操作；测试时在非关键会话尝试
- **改 Agent 定义要考虑向后兼容**：有进行中的 artifact 引用该 Agent 时，结构变化会破坏
- **改 Skill 描述要谨慎**：描述决定触发精度，改得太模糊或太严都会影响
- **Rule 的 `paths` 要精确**：太宽的 paths 导致规则到处触发污染上下文；太窄导致该管的地方不管
- **任何配置改动后**：运行 `/bcc-update-memory`（如在项目中）或重启会话观察效果
- **改 CLAUDE.md**：记住 200 行上限，过量会降低遵循度
- **settings.json 改动**：JSON 语法错误会让 Claude Code 不启动——改完立即验证

### 5.4 危险操作清单

这些改动会有连锁影响，特别小心：

- 修改 `agents/` 下的 Agent 身份（产品分析师改成别的认知模式）
- 修改 `skills/bcc-*/` 下的流水线顺序（会改变 artifact 依赖关系）
- 修改 `_global/artifact-protocol.md` 里的命名规则（所有 Agent 依赖此约定）
- 删除 Hook 脚本却未删除 settings.json 中的引用（启动报错）
- 改 Agent Memory 路径（已有 Memory 会被孤立）

### 5.5 新会话继承场景

如果新 AI 会话要维护本系统但缺乏上下文：

1. **先读本文**（完整读完）
2. 再读根 CLAUDE.md 了解调度协议
3. 浏览 `agents/` 下的 Agent 定义理解团队分工
4. 浏览 `skills/bcc-*/` 下的流水线理解工作流
5. 如果要动配置，先跑 `/bcc-update-memory` 看系统自己认为该改什么
6. 手动改动遵循上文的"升级纪律"

---

## 六、常见问题与陷阱

### 6.1 "我改了 Rule 但 Claude 没遵循"

检查：
- `paths` glob 是否真的匹配目标文件？用 `ls **/*` 验证
- Rule 是否被加载？查看 `~/.claude/logs/instructions-loaded.jsonl`（由 `instructions-audit.sh` hook 产生）
- Rule 文本是否足够具体？"优化代码"式描述 Claude 无法验证

### 6.2 "Skill 应该触发但没触发"

- Skill 的 `description` 是否精准描述了使用场景？
- Skill 是否被 `disable-model-invocation: true` 隐藏了？（如果是，必须手动调用）
- 是否存在描述重叠的多个 Skill 让 Claude 选错？考虑合并或明确差异

### 6.3 "Hook 误拦截正常命令"

- `if` 字段的 glob 模式过宽（常见于使用 `$HOME*` 这类环境变量）
- 改得更精确，如 `Bash(rm -rf /)` 比 `Bash(rm -rf /*)` 更安全
- 或移除 `if`，改用 `matcher` + 在 hook 脚本内部判断

### 6.4 "Subagent 报告完但结果错误"

- Subagent 可能没加载正确的 Skill（检查 `skills:` 字段）
- scope-lock 描述不够精确，导致自由发挥
- `高级代码审查师` 或对应 tester 没跑 → 流水线纪律破坏

### 6.5 "主会话自己写代码了"

- Output Style 未生效（检查 settings.json 的 `outputStyle`）
- CLAUDE.md 的调度纪律被压缩遗忘 → 检查 PostCompact hook
- 用户急切任务时 Claude 可能"图快"自己动手 → 在对话中强调派遣

### 6.6 "上下文满了"

- 主会话累积了太多 Subagent 的详细输出 → 让 Subagent 产出摘要式 artifact，主会话只读路径
- CLAUDE.md 过长 → 修剪到 200 行以内
- MCP 工具过多 → 断开不用的服务器

---

## 七、设计原则（给将来做重大决策的自己）

1. **一个能自我改进的简单系统，永远优于一个不能进化的复杂系统**
2. **宁可漏掉一条 Rule，不要错误地固化一条**（错误 Rule 会持续产生噪音）
3. **具体优于笼统**（"使用 2 空格缩进" > "正确格式化代码"）
4. **确定性需求用 Hook，概率性建议用 Rule/Skill**
5. **Agent 数量增长谨慎**，Skill + Rule 增长自然
6. **人在回路中**：`/bcc-update-memory` 的产出必须经人审批，永远不自动生效
7. **保持 CLAUDE.md 干净**：它不是百科全书，是协议
8. **Skill 主文件保持短协议**：长资料放 `references/`，用 eval 验证触发和 owner，而不是靠目录数量证明能力
9. **硬约束优先于口头约束**：scope-lock、artifact-only、Skill owner、eval 元数据都应由 Hook/Doctor 校验
8. **主会话默认不写复杂代码**：快路径只限系统文件和单文件低风险小修
9. **Artifact 是契约**：格式稳定性比丰富性更重要
10. **当直觉说"架构不对"时，停下来重新设计，不要打补丁**

---

## 七续、v3.x 进化历史

本节是历史记录，数字按当时版本保留；当前运行口径以 `CLAUDE.md` / `README.md` / `bin/doctor.sh` 为准。

### v3.1.3（2026-04-23，首次 evolve）

- 47 个 Skill 全部加 `when_to_use` frontmatter，解决自动触发误匹配
- 47 条 Rule 补齐 `paths` frontmatter（`_lang/17` + `_framework/17` + `_global/9` + `_infra/3`）
- `UserPromptSubmit` 三级 hook 链落地（intent-classify / clarification-gate / review-gate），Router 正式投产
- 接口字段对账 few-shot 写入调度表（`dispatch-table.md`），封堵枚举方向翻转 bug
- 5 个高优先 references 完成实质内容填充（implementation-protocol / 高级视觉测试师 / 高级安全审计师 / agent-guardrails-protocol / failure-taxonomy）
- `bin/skill-audit.sh` 新增，可自检 Skill 描述覆盖率
- Artifact Schema 校验器 `bin/validate-artifacts.sh` 落地，`bin/doctor.sh` §15 汇总

### v3.2（2026-04-27）

#### 1. 4.7 自适应推理 effort 配置

7 个高决策风险 Agent 加 `effort` frontmatter，覆盖会话级默认值：

| Agent | effort | 理由 |
|:--|:--|:--|
| `质量总监` | xhigh | 最终放行裁决，错误代价最高 |
| `资深系统架构师` | high | 架构方案影响后续所有 scope-lock |
| `高级架构审查师` | high | 审查架构方案 |
| `高级代码审查师` | high | 代码审查深度直接影响上线质量 |
| `高级安全审计师` | high | 安全漏洞漏审代价不可逆 |
| `资深范围规划师` | high | scope 不精确导致 实现工程师 反复（§3.12.2） |
| `Claude Code 工作流与提示词设计大师` | high | 元治理变更影响全系统 |

其余 18 个 Agent 继承会话默认值（通常 `medium`）。

**何时升级**：若某 Agent 在实战中频繁出现"漏项"或"误判"，且 turn 数正常（scope 无问题），可考虑将其 effort 上调。

#### 2. 13 个 bcc-* Skill argument-hint

所有 `bcc-*` 流水线 Skill 补充 argument-hint，格式：
- `<必填参数>`：尖括号，用户必须提供
- `[可选参数?]`：方括号 + 问号，可省略

与现有 `bcc-route` 示例风格一致。目的：Claude Code CLI 可在输入时展示提示，降低用户遗漏参数的概率。

#### 3. 9 个 references 实质内容填充（+1106 行）

| Reference | 新增主要内容 |
|:--|:--|
| `frontend-design` | A11y 量化基线（WCAG 2.1 AA）、具体反例代码 |
| `docx-workflow` | Word/DOCX 12 类保真陷阱（style inheritance / Track Changes / comment ID 等） |
| `pdf-workflow` | OCR 置信度判断、表单字段处理 |
| `xlsx-workflow` | Show Your Work 原则（每个数都是公式）、颜色编码规范 |
| `pptx-workflow` | slide master 配齐 5 项、字号 floor、AI slop 避免清单 |
| `mcp-workflow` | MCP 连接可靠性陷阱、Tool Search 机制、Subagent 中内联 MCP |
| `webapp-workflow` | 跨文件引用规范、前后端接口字段对账 |

**为什么填充 references 而非直接写 Skill 主文件**：主 `SKILL.md` 应作为短协议（导航 + 核心约束），长资料通过 `references/` 按需加载，遵循 §3.3 Skill 上下文预算原则。

#### 4. PermissionRequest 自动批准 ExitPlanMode

新 hook `permissionrequest-exit-plan-allow.sh`：

- 触发事件：`PermissionRequest`，matcher 限定 `ExitPlanMode`
- 效果：plan mode 完成后自动批准退出，无需人工确认
- wrapper：走 `run-with-logging.sh`，在 `hook-flags.sh` 登记为 `minimal` profile
- 不影响其他 PermissionRequest（write / execute / deploy 等仍需确认）

**设计决策**：`ExitPlanMode` 本身无破坏性（仅切换模式，不执行操作），人工确认是纯摩擦，用 hook 自动批准属于"确定性需求用 Hook"原则的典型应用（§七设计原则 4）。

#### 5. CLAUDE.md HTML 注释维护备注

利用 CLAUDE.md 的 HTML 注释剥离机制（`<!-- -->` 在注入时被移除），在 CLAUDE.md 中加入维护者备注，不占运行时 token。

### v3.3（2026-04-28）

#### 1. 4 个 Agent 补 skills 预加载

- `高级前端工程师` 新增 `frontend-design-protocol` skill（视觉设计基线）
- `高级后端工程师` 新增 `db-patterns` skill（数据库设计模式）
- `小程序开发专家` 新增 `mobile-development` skill（移动端领域知识）
- `机器学习工程师` 新增 `db-patterns` skill

#### 2. 2 条高频 Rule 深化反例代码

- `dispatch-table.md` 接口字段对账段落增加"同名不同义"和"阈值中间态"两个实战反例
- 来自漫展项目 `payType` 跨 endpoint 类型不同、`orderStatus >= 2` 漏掉中间态的真实 bug

### v3.4（2026-04-28）

#### 1. Hook 信号降级为参考

`intent-classify.sh` 输出从指令性 `[LEGION-INTENT]` 改为参考性 `[LEGION-INTENT-HINT]`，`output-styles/legion-dispatch.md` 新增"何时信任 hook、何时忽略"决策表。Hook 是关键词正则，看不懂语境——AI 的语义判断永远比 hook 准确。

#### 2. 自然语言优先

用户用自然语言描述任务时，主会话内化流水线步骤推进，不必显式调用 `/bcc-*` skill。`/bcc-*` 降级为显式入口（用户主动打时才完整执行）。

#### 3. intent-classify.sh 保守化

- Large 信号拆 high/mid 两档，单个 mid 信号不再直接判 large
- Trivial 阈值放宽到 200 字节，覆盖更多中文口语化咨询
- 元对话锚词（"还有吗"/"建议嘛"/"怎么看"）优先于 large 关键词

### v3.5（2026-04-28）

#### 1. 跨项目实战驱动进化

漫展项目、眼科项目、lumi 项目的实战反馈固化为系统改进：
- 接口字段对账升级为 medium 以上 mandatory（含 few-shot 反例）
- 用户态信号（"返工"/"客户不满"/"终极摸排"）触发强制完整门控
- 资深范围规划师 单 batch 上限 6 个 scope-lock，总数 > 8 必须拆 task

#### 2. 资深范围规划师 续传安全

scope-plan 必须在每个 batch 后明确中断重启策略，impl-report 必须每个 scope 单独写入。

#### 3. 高级前端工程师 软约束新增

- 不在组件内写 `console.log`（生产泄露风险）
- 不硬编码像素值（用 design token / CSS 变量）
- 不忽略 TypeScript `any` 类型断言

### v3.6（2026-04-29）

#### 1. 全 25 Agent effort + isolation + maxTurns 全配置

每个 Agent 的 frontmatter 补齐三项运行时配置：
- `effort`：继承会话默认值或显式指定（7 个高风险 agent 用 `high`/`xhigh`）
- `isolation: worktree`：按需启用（当前因接单工作区多非 git repo 暂禁）
- `maxTurns`：按角色复杂度设定（实现工程师 150、reviewer 100、researcher 60 等）

#### 2. settings.json 配置清理

providers 配置规范化，清理冗余字段。

### v3.7（2026-04-29）

#### 1. 模型重分布

25 个 Agent 的模型分配重新规划：
- 13 个用 Opus：决策/审查/架构/安全/元治理类（高推理需求）
- 12 个用 Sonnet：实现/研究/文档/测试执行类（高执行效率）
- 利用 Sonnet 独立池，避免与 Opus 抢占配额

### v3.8（2026-04-30）

#### 1. 全系统审计修复

基于对 25 agents / 47 skills / 47 rules / 15 hooks 的全面交叉审计：
- **Hook 路径合规**：3 个 hook 脚本输出路径修正到 `.claude/logs/`（instructions-audit、pre-compact、subagent-stop-log）
- **数字纠正**：CLAUDE.md hook 数量 8→15、README 框架数 17→18（补 Prisma）、版本号统一 v3.8
- **孤儿 Skill 接入**：`api-guide` 补入 资深系统架构师 / 高级后端工程师 / 高级代码审查师 引用
- **CLAUDE.md 补全**：追加 `/bcc-resume` 命令
- **调度纪律去重**：CLAUDE.md 调度纪律段落精简，移除与 dispatch-table 重复的并发等级/门控条件详述
- **门控强制条件**：dispatch-table 新增门控强制条件段落（高级安全审计师 / 高级功能测试师 / 质量总监 / 高级视觉测试师 的强制触发条件）

### v3.9（2026-05-01）

#### 1. 入口分类改革：bash 分类器退场，模型自判

- **删除** `intent-classify.sh`（169 行 bash）：关键词正则是语义盲，v3.1/v3.4 两次修误判证明
- `output-styles/legion-dispatch.md` 新增"任务档位自判"框架：模型基于完整语义自主判断 trivial/small/medium/large/unclear
- `settings.json` UserPromptSubmit 链从 3 个 hook 精简为 2 个（clarification-gate + review-gate）
- `hook-flags.sh` 移除 intent-classify 登记
- `statusline.sh` 档位显示改为 `◈ auto`（无 intent-classify 日志时）
- `bin/doctor.sh` §17 Router Health 适配
- `/bcc-route` 标记为已退役

#### 2. 返回 token 协议（吸收 Cangjie Harness 设计）

- 17 个核心 Agent 定义新增"返回协议"段落：固定格式 token（`IMPL_DONE:/REVIEW_PASS:/REVIEW_REJECT:` 等）
- 调度器凭 token 路由，无需读产出文件内容
- `CLAUDE.md` 新增"上下文读取权限表"：10 种 artifact 分类明确哪些可读、哪些只凭 token

#### 3. 三级问题分级统一

- `dispatch-table.md` 新增统一标准：严重（Blocker）/ 一般（Issue）/ 轻微（Nit）
- 通过条件：无严重 AND 一般 < 3
- 7 个 reviewer/tester Agent 同步更新，弃用旧的 Critical/Warning 标签

#### 4. 再审议协议 Skill

- 新建 `skills/redeliberation-protocol/SKILL.md`：Agent 可自动触发（model-invocable）
- A（实现工程师）→ B（高级代码审查师）→ judge（质量总监）迭代闭环
- 触发条件：同一 scope-lock 被驳回 ≥2 次，max 3 轮

#### 5. 增量修改模式

- `implementation-protocol` 新增"定向修订模式"：驳回问题集中 ≤2 文件时仅修改问题文件
- 产出修订报告而非全新 impl-report，不重跑全部测试

#### 6. 数字对齐

- Skill 47→48（新增 redeliberation-protocol）
- Hook 15→14（删除 intent-classify）
- README/CLAUDE.md 全系统数字同步

### v3.9.1（2026-05-01，同日紧后续）

#### 1. api-guide 可达性修复

- 去掉 `disable-model-invocation: true`：此前虽被 资深系统架构师/高级后端工程师/高级代码审查师 的 `skills:` 引用，但因该标志无法被预加载（model-invocable 池不可达），实际从未生效。`when_to_use` 仍限制触发场景。

#### 2. 全 Agent 返回 token 覆盖

- `客户需求整理师`、`创意策划师`、`项目管理师`、`Claude Code 工作流与提示词设计大师` 补返回协议
- `代码库研究员`、`技术调研专家` 补 `RESEARCH_DONE` token
- `文档工程师` 补 `DOC_DONE` + 产出审查提示
- `视觉设计专家` 补 `DESIGN_DONE` + 产出验证提示

#### 3. 三级问题分级全覆盖

- `高级功能测试师`、`高级视觉测试师` 补统一三级分级表
- `质量总监` 裁决速查表：依据收到的 token 直接裁决，无需读文件
- `高级功能测试师` token 精确化：`TEST_BLOCKED` 追加 `:env` 标记区分环境阻塞 vs 功能阻塞

#### 4. 再审议穷尽升级 + 并行批次部分失败恢复

- `redeliberation-protocol`：3 轮后不直接上报用户，先派 项目管理师 做根因分析
- `资深范围规划师`：scope-plan 模板新增并行批次部分失败恢复策略

#### 5. 高级运维工程师-protocol 拆 references

- 主 SKILL.md：343 → 147 行
- 新增 `references/deploy-patterns.md`（126 行）+ `references/rollback-emergency.md`（71 行）

#### 6. Memory 触发机制改革

- 从"Agent 自觉"改为"调度器主动追问"：每次流水线 verdict 后追问参与 Agent 是否有可复用知识
- 3 个硬触发场景：驳回 ≥2 次 / turns >50 / 接口字段被揪出

#### 7. Skill 边界澄清 + scope-lock 前置校验

- `visual-design-protocol` 与 `design-system-protocol` 互斥声明
- `资深范围规划师` 质量标准新增文件存在性前置校验

#### 8. 一致性清扫

- 4 个 hook（artifact-write-guard、post-compact、session-start、scope-lock-guard）：`jq -n` → `jq -c -n`
- 5 个 实现工程师 Agent worktree 注释升级为完整因果说明
- Hook 15→14（删除 intent-classify），Skill 47→48（新增 redeliberation-protocol），全局数字对齐

### 低频 Agent 标注

以下 Agent 在 dispatch-table 中有明确信号但实际触发频率极低，维护成本为沉没成本。不删除（符合设计哲学），但不应在调度优化中投入精力：

- `客户需求整理师`：依赖客户聊天记录/售后反馈等原始数据，企业项目少见
- `创意策划师`：命名/Slogan 场景，仅在品牌建设阶段用到

### v5.0（2026-05-08）

#### Claude Code 新机制集成
- §3.4 Subagents 新增 Session Forking、新 Frontmatter 字段（maxTurns/isolation:worktree/effort/background/color/initialPrompt/memory）、CLI 动态定义（--agents）、作用域优先级、Plugin 安全限制
- §3.6 Hooks 事件列表从 7 项扩展到 29 项完整表格，新增 PostToolUseFailure/PostToolBatch/TaskCreated/TaskCompleted/FileChanged/CwdChanged/StopFailure/TeammateIdle 等
- §3.6 新增 Hook 类型扩展：Prompt-based / Agent-based / HTTP hooks + 新事件 JSON Input Schema 速查
- 新增 §3.13 Agent Teams 机制速查（实验性，需 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1）
- 新增 §3.14 Channels 机制速查（研究预览，v2.1.80+）
- 新增 §3.15 Routines / 定时任务机制速查（Desktop/Cloud/loop 三种模式）
- 新增 §3.16 Structured Outputs 机制速查（仅 SDK 可用，常规 Subagent 不适用）

#### Hook 安全网升级
- 新增 `task-created-sync.sh`：TaskCreated hook 自动同步 Agent Teams 任务创建到 legion-session.json
- 新增 `task-completed-sync.sh`：TaskCompleted hook 自动同步任务完成状态和 evidence
- 新增 `artifact-file-changed.sh`：FileChanged hook 实时校验 artifact 写入合规性
- 新增 `tool-failure-capture.sh`：PostToolUseFailure 专用 hook 替代旧版 PostToolUse matcher 方案
- clarification-gate 升级方案（Prompt-based hook）记录在 hooks/UPGRADE-NOTES.md
- hook-flags.sh 登记新 hook（profile: standard），Hook 计数 17→20

#### 调度真源扩展
- dispatch-table.md 新增 S4 并发等级（Agent Teams 并行协作）
- 新增 Agent Teams 路由条目和并发模板
- 新增 Channels 触发路由（CI/PR/告警 → Agent 自动调度）
- 新增 Routines 定时任务调度表

#### Agent 矩阵评估
- Subagent skills 动态绑定：v5.0 验证截至 v2.1.131 仍不支持，4 个实现工程师变体保留
- Structured Outputs：仅 Agent SDK 可用，常规 Subagent 返回 token 协议保持自由文本格式

#### Statusline 与 DispatchTicket 闭环增强
- statusline.sh 新增 Agent Teams badge（⬡ 团队 指示器）
- statusline-contract.md 新增 Agent Teams 状态显示要求
- artifact-protocol.md 新增 Agent Teams 产出规则

#### 文档对齐
- CLAUDE.md 更新至 v5.0：Hook 计数 17→20、S4 并发等级、/bcc-teams 命令
- README.md 版本徽章 v4.7→v5.0、Hooks 17+3→20+3
- 当前规模：39 Agents / 58 Skills / 53 Rules / 20 Hooks + 3 `_lib`

### v4.7（2026-05-04）

#### 项目公开命名与 README 升级
- GitHub 仓库从 `claude-code-best-template` 重命名为 `best-claude-code`
- README 全面重写：新增复杂架构图、状态机、序列图、质量矩阵、Agent/Skill/Rule/Hook/治理闭环、多语言技术栈和发布说明
- 文档统一区分：`best-claude-code` 是公开项目名，`Agent Legion` 是内部系统名

#### Statusline 与 DispatchTicket 闭环升级
- `statusline.sh` 改为真正两行：第 1 行只显示 LEGION / 活跃代理 / 模型 / 权限，第 2 行显示任务 / 阶段 / 风险 / 门控 / 理解 / 迭代 / 确认 / 上下文 / 时间
- Subagent 活跃状态从 TSV 升级为 JSON：`session_id / agent_id / agent_type / started_at`
- `SubagentStop` 清理策略升级：优先按 `agent_id` 精确删除；不匹配时按同 session + agent_type 删除最老匹配项
- statusline 自动忽略并清理明显陈旧的 active 文件，避免已结束代理继续占位
- `stop-quality-gate` 增加最终确认容错：若主会话过早写成 `phase=done` 且 `final_confirmation=asked/required`，hook 自动回退到 `needs_user`，避免用户尚未看到确认问题就先看到 hook error
- 新增 `bin/validate-dispatch-ticket.sh`，校验 `phase / gate_status / understanding / iteration / final_confirmation` 合法组合
- 最终确认入口闭环：`phase=needs_user` 且 `final_confirmation=required/asked` 时，用户下一条回复必须先分类为 `accepted / continue_requested / specified_check`
- 新增 3 条发布治理 Rule：`release-version-consistency` / `runtime-state-git-hygiene` / `statusline-contract`
- 新增 `release-checklist` Skill，固化发布前版本一致性、Git hygiene、doctor/rule/hook 验证和 push 后 HEAD 对齐
- 新增 `调度顾问师`：只读反向自检动态理解、职责边界、对抗质量门控和单模型交付风险
- 全部 Agent description 统一覆盖“我是谁 / 能做什么 / 何时调用 / 和谁不同 / 完成后接谁”，降低主会话路由误判
- 公开文档统一到 v4.7；当前规模：39 Agents / 58 Skills / 53 Rules / 17 Hooks + 3 `_lib`（v5.0 升级至 20 Hooks）

### v4.0–v4.6（2026-05-01）

#### v4.0 命令体系重构 + 全链路对抗审查 + AgentLoop 深度强化
- 14→5 bcc 命令精简（自然语言优先完整落地）
- bcc-init-project / bcc-update-memory / bcc-loop-dev / bcc-fast-fix 全面重写
- 入口分类改革：删除 intent-classify.sh，模型自判替代
- 全 Agent 返回 token 协议（25→29 全覆盖）
- 全链路对抗审查：7 层（需求→架构→scope→代码→安全→跨scope→漏审反馈）
- 再审议协议 + 增量修改 + 定向修订 + 不确定项标记
- Claude Code 工作流与提示词设计大师 升级为 Claude Code 工作流与提示词设计大师

#### v4.1 中文 Agent 重命名 + 昇腾/仓颉/论文专家
- 25 Agent 中文职能名重命名 + 全局引用同步
- 华为昇腾专家 Skill（2883 文件本地化）
- 仓颉语言专家 Skill（415 文件本地化）
- 学术论文写作专家 + 顶会顶刊审稿专家 Agent（5 维学术审计）
- LaTeX Rule 新增

#### v4.2 全 Agent XML 标签结构化
- 29/29 Agent 全部深度 XML 内容级标签化
- scope-lock 模板 XML 化（`<task> <constraints> <premortem> <interface>` 等）
- 4 个新增 Agent（仓颉开发/昇腾开发/论文写作/论文审稿）

#### v4.3 文档本地化 + LaTeX Rule + 论文 Skill 升级
- 仓颉/昇腾文档全量本地化（415+2883 文件）
- academic-paper Skill 升级（5 维审计 + LaTeX 自动激活）
- Rules 48 条（+LaTeX）

#### v4.4 全系统 XML 深度结构化
- 29 Agent 全部深度内容级 XML（`<step priority="N">` `<constraint severity="blocker">` 等）
- 48 Rule 全量 XML 结构化（`<example type="good|bad">` `<convention>` 等）
- 42 Skill 全量 XML 结构化（`<knowledge domain="">` `<checklist>` 等）
- output-style 深度 XML 重写（`<thinking_protocol>` `<tier_assessment>` 等）
- bcc-update-memory 新增 README/级联索引/交叉引用更新
- Anthropic 官方 XML 标签最佳实践（+23% 准确率）全系统落地
- ai-terminal-manager effortLevel 修复 + 智枢.app 构建

### 维护节奏建议

| 节奏 | 操作 | 目的 |
|:--|:--|:--|
| 每周 | `/bcc-doctor` | 检查 hook 漂移、artifact 命名违规、Rule paths 误匹配 |
| 每 1-2 周 | `/bcc-update-memory` | 把 Memory 积累固化为 Rule/Skill |
| 每个 Claude Code 大版本 | 读 CHANGELOG，更新 §三 | 确认扩展机制未变化 |
| 有新技术栈需求 | 新增 `_lang/` 或 `_framework/` Rule | 通常不需要新 Agent |
| 有新认知模式缺口 | 谨慎评估是否新增 Agent | 几年一次，轻易不加 |

---

## 八、参考

外部 Prompt/Skill 素材分级使用：官方文档与官方开源 Skill 可作为实现参考；普通开源仓库需检查许可证和质量；泄漏/复刻提示词仓库只能用于结构研究，不得逐字复制到 Agent/Skill/Rule。

Claude Code 官方文档是最终真理来源。本文基于撰写时的 Claude Code 版本，若机制有变化：
- 先查 Claude Code 官方文档（`/docs` 或 code.claude.com）
- 更新本文相应章节
- 运行 `/bcc-update-memory` 评估系统是否需要调整

本文档由 Agent Legion 系统的初版建造者与 Claude Opus 4.7（1M context）合作完成于 2026-04-23。
v3.2 章节由 文档工程师 subagent 补充于 2026-04-27。
