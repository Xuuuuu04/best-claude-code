# best-claude-code

> 一份基于 **Harness Engineering** 精神的极简 Claude Code 用户级配置。
> **10 Skills · 6 Hooks · 2 Agents · 3 Rules** · **Task-Centric** 架构 · v2.1.0

---

## 这是什么

这不是一个"插件集合"或"agent 农场",而是一套**协议设计**:

- 让 Claude Code 在跨会话、跨 `/compact`、跨子代理调度的过程中,**核心状态不丢失**
- 让子代理之间的通信**从消息流改为文件系统**(token 消耗降 10-40 倍)
- 让对抗性 review **保证收敛**(Writer/Reviewer/Judge 三角 + Acceptance Criteria + Round Cap)
- 让 Opus 4.7 的专业能力**通过 brief 里的 Activation Persona 动态激活**,而不需要常驻一堆专家 agent
- 用 PostToolUse / Stop hook **强制执行纪律**,防止模型跑偏不更新 Task、盲猜不调试

设计依据是 Anthropic 自己发布的
[Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
论文里的 **"Structured Artifacts Over Natural Language"** 原则,
以及 Manus 团队提出的 **"Context as Filesystem"** 架构。

---

## 设计哲学(harness engineer 五原则)

| # | 原则 | 落实在哪 |
|---|---|---|
| 1 | **Earn every component** | 21 个组件,每个都对应一个"模型独立做不到的事";不达标的不要 |
| 2 | **Configuration over capability** | 不等模型变好,用 harness 把当下的模型(以及弱模型 GLM/Kimi)举起来 |
| 3 | **Failures become rules** | 每次纠正都转化为 skill/hook/rule 条款,不是一次性沟通 |
| 4 | **Success is silent, failures are verbose** | 成功无声,只在失败/风险时打断用户 |
| 5 | **不重复造轮子** | playwright/context7/frontend-design 三个官方插件已覆盖大量能力,新组件避开 |

---

## 核心架构图

```
                        ┌───────────────────────┐
                        │  ~/.claude/CLAUDE.md  │  跨项目通用约定
                        └───────────┬───────────┘
                                    │
    ┌───────────────┬───────────────┼───────────────┬───────────────┐
    ▼               ▼               ▼               ▼               ▼
┌────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌────────┐
│ Skills │    │  Agents  │    │  Hooks   │    │  Rules   │    │ MCP    │
│ (10个) │    │  (2 个)  │    │  (6 个)  │    │  (3 条)  │    │Servers │
├────────┤    ├──────────┤    ├──────────┤    ├──────────┤    ├────────┤
│bcc-    │    │ reviewer │    │ Session  │    │ honest-  │    │github  │
│ start  │    │          │    │  Start   │    │ communi- │    │repomix │
│ continue    │  judge   │    │  End     │    │  cation  │    │seq-    │
│ finish │    └──────────┘    │ Pre/Post │    │ git-     │    │thinking│
│ brief  │         │          │ Compact  │    │  safety  │    └────────┘
│ preflight  Brief │          │ PostTool │    │ sensitive│
│ cross-sync Pattern          │  Use     │    │  -files  │
│ debug  │    文件系统         │ Stop     │    └──────────┘
│ tdd    │    通信总线         └─────┬────┘
│ init   │         │                │
│ check  │    ┌────▼────────────────▼────┐
└────────┘    │      Task File           │ ◄── 持久化记忆
              │  <project>/.claude/tasks/ │     跨会话不丢
              └──────────────────────────┘
```

---

## 组件清单

### Skills(10 个,位于 `skills/bcc-<name>/SKILL.md`,统一 `/bcc-` 前缀）

**Task 生命周期(3 个)**
| Skill | 何时调用 | 作用 |
|---|---|---|
| `/bcc-start` | 用户新独立诉求 | 增强意图 + 轻量确认 + 创建 Task 文件 |
| `/bcc-continue` | 跨会话恢复 | grep in_progress task,用户选一个 load |
| `/bcc-finish` | 任务完成 | 写 Completion + 强制 HANDOVER + status: done + 重置 hook state |

**子代理协调(1 个)**
| Skill | 何时调用 | 作用 |
|---|---|---|
| `/bcc-brief` | 调度 subagent 前 | 写 task-specific briefing(含 Activation Persona)给子代理读 |

**开发纪律(3 个)**
| Skill | 何时调用 | 作用 |
|---|---|---|
| `/bcc-tdd` | 实现功能或 root cause 已定位后修 bug | 强制 Red-Green-Refactor 循环 |
| `/bcc-debug` | 遇到 bug,需要系统化定位 | 禁止盲猜,强制 reproduce → isolate → root cause → fix |
| `/bcc-preflight` | 提交代码前 | 读项目 CLAUDE.md 的 Preflight Commands 顺序执行 |

**项目管理(2 个)**
| Skill | 何时调用 | 作用 |
|---|---|---|
| `/bcc-cross-sync` | 多端项目改动 enum/contract 后 | 检查 web/miniapp/backend 间一致性 |
| `/bcc-init` | 新仓库首次使用 BCC | 一键创建 .claude/tasks/ + 项目 CLAUDE.md + .gitignore |

**运维(1 个)**
| Skill | 何时调用 | 作用 |
|---|---|---|
| `/bcc-check` | 怀疑 harness 有问题时 | 7 项健康检查:jq/hooks/settings/skills/rules/version |

### Agents(2 个,位于 `agents/<name>.md`)
| Agent | 召唤时机 | 角色 |
|---|---|---|
| `reviewer` | 重大代码改动后 | 对抗性 reviewer,工具收窄到只读,输出严格 JSON |
| `judge` | review 不收敛(≥3 轮) | 独立裁决者,只比对 acceptance criteria,输出 accept/reject/continue |

### Hooks(6 个事件 hook + 1 个共享库,位于 `hooks/*.sh`)

**上下文连续性(4 个)**
| Hook | 事件 | 作用 |
|---|---|---|
| `session-start.sh` | SessionStart | 扫描 in_progress task,注入 additionalContext + watchPaths |
| `session-end.sh` | SessionEnd | 通过 systemMessage 提醒未 finish 的 task |
| `precompact.sh` | PreCompact | 压缩前在 Task 文件追加标记,输出 additionalContext |
| `postcompact.sh` | PostCompact | 压缩后重新注入 Task 关键状态,防止"失忆" |

**执行纪律(2 个)**
| Hook | 事件 | 作用 |
|---|---|---|
| `posttooluse-guard.sh` | PostToolUse | 追踪编辑计数 + Bash 失败检测(3 连败注入 `/bcc-debug`) |
| `stop-progress-gate.sh` | Stop | 6+ 次操作未更新 Task Execution Log 时阻止收尾 |

**共享库(1 个)**
| 文件 | 作用 |
|---|---|
| `_common.sh` | jq 检测、state 文件原子读写、`_reset_hook_state()` 工具函数 |

### Rules(3 条,位于 `rules/*.md`)
| Rule | 作用 |
|---|---|
| `honest-communication.md` | 四层中文矫正:行为禁令 + 句法 + 词汇替换 + 进度汇报格式 |
| `git-safety.md` | 禁止 force push / reset --hard / --no-verify 等破坏性操作 |
| `sensitive-files.md` | 禁止读写 .env/credentials/密钥文件,禁止 commit 二进制大文件 |

---

## 三大核心机制

### 1. Task-Centric Persistent File System

每个用户独立诉求 → 一个 Task 文件 → 路径:
```
<project>/.claude/tasks/Task-{YYYY-MM-DD}-{HHMM}-{slug}.md
```

判断"新 task vs 当前 task 继续"的标准:**这条新输入能否独立成一个 commit?**
能 → 新 task;不能 → 追加当前 task 的 Prompt 段。

Task 文件用 YAML frontmatter + Markdown body,包含 8 个段:
`Prompt`(append-only) / `Intent` / `Plan` / `Execution Log` /
`Subagent Calls` / `Decisions`(append-only) / `Completion` / 嵌入式 `HANDOVER`。

完整 schema 见 `skills/bcc-start/SKILL.md`。

### 2. Briefing Pattern(子代理通信)

主代理在调度任何 subagent 之前,**必须用 `/bcc-brief` 生成 task-specific briefing 文件**,然后:

```
Agent.prompt = "Read the briefing file at <path>, then execute."
                                (仅 30-50 token)
```

Briefing 文件含 7 段:
`Activation Persona` / `Mission` / `Known Facts` / `Files You Need`(行号级) /
`Acceptance Criteria` / `Output Format`(强制 JSON schema) / `Constraints` + `Don't`。

Activation Persona 仅影响 Explore / general-purpose 类 subagent;reviewer / judge 有固定 persona。

**Token 效率对照**(实测):
| 模式 | token 消耗 |
|---|---|
| 让 subagent 自己探索 | 5,000-20,000 |
| 用 brief 精准定位 | 200-500(brief) + 30-50(prompt) |
| **杠杆** | **10-40 倍** |

### 3. Writer/Reviewer/Judge 三角(对抗性 review 保证收敛)

```
Writer(主代理) ──→ Reviewer agent ──→ 主代理决定下一步
                       │
        ≥ 3 轮不收敛   ▼
                  Judge agent ──→ accept | reject | continue_one_more_round
                                  (后者每个 task 最多用 1 次)
```

为什么 reviewer 只能 Read + Grep,不能 Edit:**工具限制反向激活角色思考**。
能 Edit 的话,reviewer 会"顺手改一下",失去 reviewer 视角。

### 4. 执行纪律闭环(v2.1.0 新增)

```
PostToolUse hook ──→ 每次工具调用后计数
                     ├─ Edit 操作 → edits_since_task_update++
                     └─ Bash 失败 → consecutive_bash_failures++
                                    3 连败 → 注入 /bcc-debug 提示

Stop hook ──→ 模型想收尾时检查
              └─ 6+ 操作未更新 Task Log → 阻止,注入提醒
```

state 文件用 mktemp + mv 原子写入,防止中断导致空 JSON。
Task 完成时 `/bcc-finish` 自动重置计数器。

---

## 文件结构

```
~/.claude/
├── CLAUDE.md                          # 跨项目通用约定
├── README.md                          # 本文件
├── VERSION                            # 语义化版本号(当前 2.1.0)
├── settings.json                      # hooks 注册 + MCP + providers(被 .gitignore)
├── output-styles/
│   └── teacher.md                     # 教师风格对话
├── skills/                            # 10 个,统一 /bcc- 前缀
│   ├── bcc-start/SKILL.md
│   ├── bcc-continue/SKILL.md
│   ├── bcc-finish/SKILL.md
│   ├── bcc-brief/SKILL.md             # 含 Activation Persona 示例库(11 个)
│   ├── bcc-tdd/SKILL.md
│   ├── bcc-debug/SKILL.md
│   ├── bcc-preflight/SKILL.md
│   ├── bcc-cross-sync/SKILL.md
│   ├── bcc-init/SKILL.md
│   └── bcc-check/SKILL.md
├── agents/
│   ├── reviewer.md                    # 对抗性 reviewer,只读工具
│   └── judge.md                       # 独立裁决者,只读工具
├── hooks/                             # 6 个事件 hook + 1 个共享库
│   ├── _common.sh                     # 共享工具函数(jq 检测/原子写入/state 重置)
│   ├── session-start.sh               # SessionStart
│   ├── session-end.sh                 # SessionEnd
│   ├── precompact.sh                  # PreCompact
│   ├── postcompact.sh                 # PostCompact
│   ├── posttooluse-guard.sh           # PostToolUse(编辑计数 + 失败检测)
│   └── stop-progress-gate.sh          # Stop(Task Log 更新检查)
├── rules/                             # 3 条确定性策略
│   ├── honest-communication.md        # 四层中文矫正
│   ├── git-safety.md                  # 破坏性 git 操作围栏
│   └── sensitive-files.md             # 密钥/凭证保护
└── plans/                             # 设计稿(被 .gitignore)
```

每个项目内自动维护:
```
<project>/.claude/tasks/
├── Task-2026-05-15-1030-fix-auth.md   # Task 文件(进 git)
├── Task-2026-05-15-1420-add-payment.md
├── bcc-briefs/                        # briefing 文件(被 .gitignore)
│   └── Task-xxx-call-1-explore.md
├── outputs/                           # subagent 输出(被 .gitignore)
│   └── Task-xxx-call-1.json
├── archive/                           # 已完成 task 的 brief/output(被 .gitignore)
└── .hook-state.json                   # hook 计数器(被 .gitignore)
```

---

## 快速开始(在新机器/新账号复用)

```bash
# 1. clone 到位
git clone git@github.com:Xuuuuu04/best-claude-code.git ~/.claude

# 2. 确认 hooks 可执行
chmod +x ~/.claude/hooks/*.sh

# 3. 确认 jq 已安装(hooks 依赖)
jq --version || brew install jq  # macOS
# jq --version || sudo apt install jq  # Linux

# 4. 创建 settings.json(被 .gitignore,需手工创建)
# 参考下方模板,填入你的路径和 API keys

# 5. 重启 Claude Code 让 hooks 生效

# 6. 在某个项目里试跑
cd ~/path/to/your-project
claude
# 给一句正常的工作指令,Claude 会自动调用 /bcc-start 开 Task 文件
# 首次使用可跑 /bcc-init 一键初始化项目结构
```

`settings.json` 模板(6 个 hook 全注册):
```json
{
  "permissions": { "defaultMode": "default" },
  "outputStyle": "teacher",
  "language": "Chinese",
  "hooks": {
    "PreCompact": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/precompact.sh" }] }
    ],
    "PostCompact": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/postcompact.sh" }] }
    ],
    "SessionStart": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/session-start.sh" }] }
    ],
    "SessionEnd": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/session-end.sh" }] }
    ],
    "PostToolUse": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/posttooluse-guard.sh" }] }
    ],
    "Stop": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/stop-progress-gate.sh" }] }
    ]
  },
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github@2025.4.8"],
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "${GITHUB_PAT}" }
    },
    "repomix": {
      "command": "npx",
      "args": ["-y", "repomix@1.14.1", "--mcp"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking@2025.12.18"]
    }
  }
}
```

---

## 设计权衡 / FAQ

**Q: 为什么 Task 文件放项目级,不放用户级?**
A: 跟 git 走、自然归档、项目结束 task 历史一起走。跨项目搜索其实很少发生。

**Q: 为什么不预设"前端专家""后端专家"agent?**
A: Opus 4.7 知识广度已经够,需要的是**身份激活**而不是知识灌输。
所以用 `/bcc-brief` 里的 Activation Persona **动态注入**,零维护成本,无限技术栈适配。
只有"横跨技术栈的质量维度"(如安全、性能)才考虑后续加专业 agent —— 按 ratchet 原则,撞到痛点再加。

**Q: 6 个 hook 分别解决什么?**
A: 分两类。**上下文连续性**(4 个):进入/退出会话 + 压缩前后,确保 Task 状态不丢。**执行纪律**(2 个):PostToolUse 追踪编辑和失败,Stop 阻止不更新 Task Log 就收尾。所有 hook 输出标准 JSON,共享 `_common.sh` 工具库。

**Q: 主代理为什么不沦为"调度员/打字员"?**
A: CLAUDE.md 的"调度边界"段明确写了:**主代理是首席工程师**,深度参与判断,
只外包"重复性 / 探索性 / 隔离性"的活给 subagent。

**Q: 为什么所有 subagent 输出强制 JSON?**
A: 弱模型友好 + 主代理解析快 + schema 可程序化验证。free-form 输出每次都要主代理重读理解,等于又一轮 token + 误解风险。

**Q: 这套和 Legion 比,精简到这种程度,会不会丢失能力?**
A: Legion 的 265 组件里,大部分是"模型独立能做但当时模型还不够强"的弥补。
Opus 4.7 之后,大部分组件变成 "load-bearing for nothing",应该被拆掉。
真正不可替代的核心(跨会话记忆 + 子代理通信总线 + review 收敛 + 执行纪律)就是这 21 个组件。

**Q: Rules 和 CLAUDE.md 里的规则是什么关系?**
A: CLAUDE.md 是摘要(每条 1-2 行,模型每次都读到),Rules 是详细展开(before/after 对照表、具体案例)。两者不重复但互补。

---

## Ratchet 观察点(怎么继续改进)

按 harness engineer 精神,每周自问:

1. **主代理写出来的 Activation Persona 够具体吗?** 不是"You are an expert"这种泛泛?
2. **subagent 输出里有没有"我先 Read 了 X、Y、Z..."这种探索性内容?** 有 → brief 没写精准,补行号
3. **有没有反复纠正同一类问题?** ≥3 次 → 该把它转成 hook 或加进 CLAUDE.md
4. **有没有 `/bcc-finish` 时 HANDOVER 写得敷衍?** → 加强 bcc-finish skill 的检查清单
5. **有没有想用某个 persona 但示例库里没有?** → 补进 `bcc-brief` skill 的示例表
6. **posttooluse-guard 有没有误报/漏报?** → 调整失败检测正则或阈值
7. **honest-communication 规则有没有被模型忽略?** → 精简或拆分

**核心准则:不靠预判,靠观察。撞墙了才加规则,加了之后看它是否真的挣到位置。**

---

## 参考资料

- [Effective Harnesses for Long-Running Agents — Anthropic](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Harness Design for Long-Running Application Development — Anthropic](https://www.anthropic.com/engineering/harness-design-long-running-apps)
- [Agent Harness Engineering — Addy Osmani](https://addyosmani.com/blog/agent-harness-engineering/)
- [Multi-Agent Debate Convergence with Judge Agents (arXiv 2510.12697)](https://arxiv.org/pdf/2510.12697)
- [Claude Code Sub-agents 官方文档](https://code.claude.com/docs/en/sub-agents)
- [Claude Code Hooks 官方文档](https://code.claude.com/docs/en/hooks)

---

## License

MIT(仅本仓库的配置文件、文档与脚本;不含被 .gitignore 的 settings.json 中的密钥)。

---

## 维护原则一条

> **删除规则比新增规则需要更多勇气。如果某条规则不再 earn its place,删掉它。**
> Harness 是活的系统,不是档案馆。
