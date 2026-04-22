# Agent Legion — 系统维护指南

> **这是给未来 AI 维护者的文档**。如果你是一个被召唤来升级、调试或扩展这套系统的新会话，没有历史上下文，**先完整读完本文再动手**。本文记录了设计初衷、Claude Code 的关键机制、以及升级这套系统时的纪律。
>
> 本文刻意**不引用具体文件名**，只引用**目录名和机制名**。这样当系统内部文件调整时，本文仍然准确。

---

## 一、这是什么

Agent Legion 是基于 Claude Code 全部扩展机制构建的"自适应多 Agent 开发军团"。核心设计理念：

- **调度-执行分离**：主会话只做调度和整合，所有代码实现由 Subagent 完成
- **认知模式分工**：Agent 按思维方式划分（分析/设计/实现/对抗/运维），不按技术栈
- **Skill 热插拔**：技术栈差异通过 Skill 预加载切换，而非新建 Agent
- **Rule 按需激活**：编码规范通过 path-specific Rules 在读取匹配文件时自动加载
- **确定性由 Hook 保障**：必须发生的事走 Hook，建议遵守的事走 CLAUDE.md / Rules
- **文件驱动交接**：Agent 间通过 `.claude/artifacts/` 的结构化 Markdown 交接，主会话做总线
- **渐进进化**：Auto Memory + Agent Memory → `/bcc-reflect` → `/bcc-evolve` 闭环

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
- 为什么主会话不写代码（保持干净的调度上下文）

### 核心洞察：模型能力 vs 架构支撑

行业主流做法是用最强模型（Opus 级）去对抗混乱上下文。我们的信念是：**干净上下文 + 结构化约束能让 Sonnet 级模型在单点任务上不输 Opus**。

这解释了为什么 architect 产出 scope-lock（精确到文件/函数级），以及为什么每个 implementer 接任务时只加载必要的 Skill 和 Rule。弱模型 + 强架构 > 强模型 + 弱架构。

### 核心洞察：指令是概率性的，不是确定性的

CLAUDE.md、Rules、Skills 都是作为上下文文本注入，Claude"尝试遵循但不保证"。需要确定性保证（例如"编辑完必须 lint"）的场合必须用 Hook（外部脚本，保证执行）或托管设置。

### 为什么 8 个 Agent

人类职业（前端工程师、后端工程师、iOS 工程师）的划分是因为一个人精力有限。Agent 没有这个限制——一个 Agent 加载不同 Skill 就扮演不同技术角色。Agent 数量应按**认知模式**划分，不按技术栈：

- 产品思维（从需求到规格）
- 架构思维（从规格到设计）
- 执行思维（在锁定范围内高质量产出）
- 对抗思维（找别人的错）
- 探索思维（广度搜索和摘要）
- 运维思维（可重复、可回滚、可追踪）

技术栈差异交给 Skill + Rule 解决。

### 为什么 Implementer 有 3 个变体

理想情况是 1 个 Implementer 动态加载不同技术栈 Skill。但 Claude Code 的约束是：**Subagent 的 `skills:` 字段是静态的，主会话调度时无法动态指定**。发现这个约束后，我们按"大类认知域"（前端/后端/移动端）拆成 3 个变体，每个静态预加载对应的领域 Skill + 实现协议。具体技术栈细节通过 path-specific Rules 自动补充。

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
- `skills:` 静态绑定到 Agent 定义，主会话调度时无法动态指定（这是 3 个 Implementer 变体的由来）
- 每次调用生成**新鲜上下文**，不继承父对话的对话历史或调用的 Skill
- 父对话的 CLAUDE.md 和 git 状态会继承；无条件 Rules 大概率也继承
- Path-specific Rules 只有在 Subagent 自己读取匹配文件时才触发

**调用方式**：
- `Agent` 工具调用（模型判断）
- `@agent-<name>` 显式 mention（强制）
- `claude --agent <name>` 将整个会话作为该 Subagent 运行

### 3.5 Rules 机制

- 存放在 `.claude/rules/` 目录（项目级）或 `~/.claude/rules/`（用户级）
- 递归发现所有 `.md` 文件
- **无条件 Rule**：无 `paths` frontmatter，启动时加载
- **条件 Rule**：有 `paths` 数组，仅在 Claude 读取匹配 glob 的文件时加载
- glob 支持：`**/*.ts`、`src/**/*`、`{a,b}`、`?` 等
- 符号链接支持，循环检测

**Rule 不是 Skill 的替代**：Rule 是"项目或语言通用约束"，Skill 是"特定任务的知识或工作流"。两者补充。

### 3.6 Hooks 机制

**事件列表**（按本系统使用）：

- `SessionStart`：会话开始（含 `startup` / `resume` / `clear` / `compact`）
- `PreCompact` / `PostCompact`：压缩前后
- `PreToolUse` / `PostToolUse`：工具使用前后（支持 `matcher` 限定工具名）
- `SubagentStart` / `SubagentStop`：Subagent 生命周期
- `InstructionsLoaded`：每次指令文件加载完成
- 其他还有 `Notification` / `Stop` / `UserPromptSubmit` 等

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
- 思维类 Agent（产品分析师、架构师、质量守卫、运维）→ `user`（跨项目积累）
- 执行类 Agent（implementer、explorer）→ `project`（项目特定）

### 3.8 MCP 机制

- `.mcp.json` 项目级 / `~/.claude/.claude.json` 用户级 / `settings.json` 嵌入
- 服务器类型：`stdio` / `http` / `sse` / `ws`
- **Tool Search**（默认启用）：启动时只加载约 10% 的 MCP 工具定义，其余延迟
- 可靠性陷阱：MCP 连接可能中途静默断开，用 `/mcp` 检查
- 每服务器的上下文成本可以通过 `/mcp` 查询

**Subagent 中使用 MCP**：
- `mcpServers` frontmatter 可以内联定义（此 Agent 专属）或按名引用（共享主会话配置）
- 内联定义避免把该 MCP 暴露给主会话（节省主上下文）

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

运行 `/bcc-evolve`。它会：
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
- **任何配置改动后**：运行 `/bcc-update-project`（如在项目中）或重启会话观察效果
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
5. 如果要动配置，先跑 `/bcc-evolve` 看系统自己认为该改什么
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
- 让 quality-guardian 做代码审查环节没跑 → 流水线纪律破坏

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
6. **人在回路中**：`/bcc-evolve` 的产出必须经人审批，永远不自动生效
7. **保持 CLAUDE.md 干净**：它不是百科全书，是协议
8. **主会话永不写代码**：这是不可违反的铁律
9. **Artifact 是契约**：格式稳定性比丰富性更重要
10. **当直觉说"架构不对"时，停下来重新设计，不要打补丁**

---

## 八、参考

Claude Code 官方文档是最终真理来源。本文基于撰写时的 Claude Code 版本，若机制有变化：
- 先查 Claude Code 官方文档（`/docs` 或 code.claude.com）
- 更新本文相应章节
- 运行 `/bcc-evolve` 评估系统是否需要调整

本文档由 Agent Legion 系统的初版建造者与 Claude Opus 4.7（1M context）合作完成于 2026-04-23。
