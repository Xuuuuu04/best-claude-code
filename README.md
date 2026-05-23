# best-claude-code

> 一份基于 **Harness Engineering** 精神的极简 Claude Code 用户级配置。
> **13 个组件** · 精简自之前 Legion 时代的 **265 个组件**(95.1% 精简) · **Task-Centric** 架构。

---

## 这是什么

这不是一个"插件集合"或"agent 农场",而是一套**协议设计**:

- 让 Claude Code 在跨会话、跨 `/compact`、跨子代理调度的过程中,**核心状态不丢失**
- 让子代理之间的通信**从消息流改为文件系统**(token 消耗降 10-40 倍)
- 让对抗性 review **保证收敛**(Writer/Reviewer/Judge 三角 + Acceptance Criteria + Round Cap)
- 让 Opus 4.7 的专业能力**通过 brief 里的 Activation Persona 动态激活**,而不需要常驻一堆专家 agent

设计依据是 Anthropic 自己发布的
[Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
论文里的 **"Structured Artifacts Over Natural Language"** 原则,
以及 Manus 团队提出的 **"Context as Filesystem"** 架构。

---

## 设计哲学(harness engineer 五原则)

| # | 原则 | 落实在哪 |
|---|---|---|
| 1 | **Earn every component** | 13 个组件,每个都对应一个"模型独立做不到的事";不达标的不要 |
| 2 | **Configuration over capability** | 不等模型变好,用 harness 把当下的模型(以及弱模型 GLM/Kimi)举起来 |
| 3 | **Failures become rules** | 每次纠正都转化为 skill/hook 条款,不是一次性沟通 |
| 4 | **Success is silent, failures are verbose** | 成功无声,只在失败/风险时打断用户 |
| 5 | **不重复造轮子** | playwright/context7/frontend-design 三个官方插件已覆盖大量能力,新组件避开 |

---

## 核心架构图

```
                          ┌──────────────────────┐
                          │ ~/.claude/CLAUDE.md  │  跨项目"始终如此"规则(56 行)
                          └──────────┬───────────┘
                                     │
        ┌────────────────────────────┼────────────────────────────┐
        ▼                            ▼                            ▼
  ┌──────────┐               ┌──────────────┐              ┌──────────┐
  │  Skills  │               │    Agents    │              │  Hooks   │
  │ (6 个)   │               │   (2 个)     │              │ (4 个)   │
  ├──────────┤               ├──────────────┤              ├──────────┤
  │start-task│               │   reviewer   │              │PreCompact│
  │continue- │  ┐         ┌─ │     judge    │              │SessionStt│
  │   task   │  │  Brief  │                                │SessionEnd│
  │finish-   │  │ Pattern │   ↓ 通过 brief 文件通信                  │
  │   task   │  ┤ 文件系统├─ ┌──────────────┐                       │
  │  brief   │  │  通信   │  │ Task File    │ ◄── 持久化记忆,跨会话 │
  │preflight │  │  总线   │  │ <project>/   │     不丢                │
  │cross-sync│  │         │  │ .claude/     │                          │
  └──────────┘  ┘         └─ │   tasks/     │                          │
                              └──────────────┘                          │
                                     ▲                                  │
                                     │                                  │
                                     └─── hooks 在压缩/进出时维护 ──────┘
```

---

## 组件清单(全 12 个)

### 用户级 CLAUDE.md(1 个)
| 文件 | 作用 |
|---|---|
| `CLAUDE.md` | 跨项目"始终如此"规则:沟通口味、Task 系统索引、调度边界、提交纪律 |

### Skills(6 个,位于 `skills/<name>/SKILL.md`)
| Skill | 何时调用 | 作用 |
|---|---|---|
| `/start-task` | 用户新独立诉求 | 增强意图 + 轻量确认 + 创建 Task 文件 |
| `/continue-task` | 跨会话恢复 | grep in_progress task,用户选一个 load |
| `/finish-task` | 任务完成 | 写 Completion + 强制写 HANDOVER + 改 status: done |
| `/brief` | 调度 subagent 前 | 写 task-specific briefing(含 Activation Persona)给子代理读 |
| `/preflight` | 提交代码前 | 读项目 CLAUDE.md 的 Preflight Commands 顺序执行 |
| `/cross-sync` | 多端项目改动后 | 检查 web/miniapp/backend 间 enum/contract 一致性 |

### Agents(2 个,位于 `agents/<name>.md`)
| Agent | 召唤时机 | 角色 |
|---|---|---|
| `reviewer` | 重大代码改动后 | 对抗性 reviewer,工具收窄到只读,输出严格 JSON |
| `judge` | review 不收敛(≥3 轮) | 独立裁决者,只比对 acceptance criteria,输出 accept/reject/continue |

### Hooks（4 个，位于 `hooks/*.sh`，输出标准 JSON）
| Hook | 事件 | 作用 |
|---|---|---|
| `precompact.sh` | PreCompact | 压缩前在活跃 Task 文件追加标记，输出 additionalContext 提示重读 |
| `postcompact.sh` | PostCompact | 压缩后重新注入活跃 Task 的关键状态（ID/标题/Plan/最近进展），防止主代理"失忆" |
| `session-start.sh` | SessionStart | 进入会话时扫描本项目 in_progress task，注入 additionalContext + watchPaths |
| `session-end.sh` | SessionEnd | 退出前通过 systemMessage 提醒未 finish 的 task |

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

完整 schema 见 `skills/start-task/SKILL.md`。

### 2. Briefing Pattern(子代理通信)

主代理在调度任何 subagent 之前,**必须用 `/brief` 生成 task-specific briefing 文件**,然后:

```
Agent.prompt = "Read the briefing file at <path>, then execute."
                                (仅 30-50 token)
```

Briefing 文件含 7 段:
`Activation Persona` / `Mission` / `Known Facts` / `Files You Need`(行号级) /
`Acceptance Criteria` / `Output Format`(强制 JSON schema) / `Constraints` + `Don't`。

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

### 加成:Activation Persona(零成本激活专业能力)

`/brief` 模板里**必填** Activation Persona 段,主代理动态填:

```
You ARE a senior <技术栈/视角> engineer.
You are paranoid about <2-3 个本领域最容易翻车的点>.
You do NOT <本领域常见反模式>.
```

`brief` skill 自带 11 个 persona 示例库(Vue 3 / uni-app / Next.js / FastAPI /
Spring Boot / PostgreSQL / 安全 / 性能 / Docker / Playwright / 文档审查),
覆盖绝大多数技术栈。**不需要常驻专业 agent,身份激活的效果就足够**。

---

## 文件结构

```
~/.claude/
├── CLAUDE.md                          # 跨项目通用约定(56 行)
├── README.md                          # 本文件
├── settings.json                      # 含 hooks 注册 + 3 个国内 provider(被 .gitignore)
├── output-styles/
│   └── teacher.md                     # 教师风格对话(保留)
├── skills/
│   ├── start-task/SKILL.md
│   ├── continue-task/SKILL.md
│   ├── finish-task/SKILL.md
│   ├── brief/SKILL.md                 # 含 Activation Persona 示例库
│   ├── preflight/SKILL.md
│   └── cross-sync/SKILL.md
├── agents/
│   ├── reviewer.md
│   └── judge.md
├── hooks/
│   ├── precompact.sh                  # chmod +x, 输出标准 JSON
│   ├── postcompact.sh                 # chmod +x, 压缩后恢复 Task 上下文
│   ├── session-start.sh               # chmod +x, 跨平台兼容
│   └── session-end.sh                 # chmod +x, systemMessage 输出
└── plans/                             # 设计稿(被 .gitignore,本地保留)
    └── unified-floating-crane.md
```

每个项目内自动维护:
```
<project>/.claude/tasks/
├── Task-2026-05-15-1030-fix-auth.md
├── Task-2026-05-15-1420-add-payment.md
├── briefs/                            # 主代理写的 task-specific briefing
│   └── Task-xxx-call-1-explore.md
└── outputs/                           # subagent 返回的 JSON
    └── Task-xxx-call-1.json
```

---

## 快速开始(在新机器/新账号复用)

```bash
# 1. clone 到位
git clone git@github.com:Xuuuuu04/best-claude-code.git ~/.claude

# 2. 准备 settings.json(被 ignore,需手工创建)
cp settings.example.json settings.json  # 如果有 example;否则参考下方模板
# 编辑 settings.json,填入你的 API keys / 启用的 plugins

# 3. 确认 hooks 可执行
chmod +x ~/.claude/hooks/*.sh

# 4. 重启 Claude Code 让 hooks 生效

# 5. 在某个项目里试跑
cd ~/path/to/your-project
claude
# 给一句正常的工作指令,Claude 会自动调用 /start-task 开 Task 文件
```

最小 `settings.json` 模板(供参考):
```json
{
  "permissions": { "defaultMode": "default" },
  "outputStyle": "teacher",
  "language": "Chinese",
  "hooks": {
    "PreCompact": [{ "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/precompact.sh" }] }],
    "SessionStart": [{ "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/session-start.sh" }] }],
    "SessionEnd": [{ "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/session-end.sh" }] }]
  }
}
```

---

## 设计权衡 / FAQ

**Q: 为什么 Task 文件放项目级,不放用户级?**
A: 跟 git 走、自然归档、项目结束 task 历史一起走。跨项目搜索其实很少发生。

**Q: 为什么不预设"前端专家""后端专家"agent?**
A: Opus 4.7 知识广度已经够,需要的是**身份激活**而不是知识灌输。
所以用 `/brief` 里的 Activation Persona **动态注入**,零维护成本,无限技术栈适配。
只有"横跨技术栈的质量维度"(如安全、性能)才考虑后续加专业 agent —— 按 ratchet 原则,撞到痛点再加。

**Q: 为什么 hook 只有 4 个?**
A: 这 4 个都解决"上下文连续性"这**一个核心痛点**（进-压缩前-压缩后-出，四个时间点）。
所有 hook 输出标准 JSON（`hookSpecificOutput.additionalContext`），跨平台兼容。
其他场景（自动截图、拦截敏感操作）是另外的痛点，没痛到强制就不装。

**Q: 主代理为什么不沦为"调度员/打字员"?**
A: CLAUDE.md 的"调度边界"段明确写了:**主代理是首席工程师**,深度参与判断,
只外包"重复性 / 探索性 / 隔离性"的活给 subagent。

**Q: 为什么所有 subagent 输出强制 JSON?**
A: 弱模型友好 + 主代理解析快 + schema 可程序化验证。free-form 输出每次都要主代理重读理解,等于又一轮 token + 误解风险。

**Q: 这套和 Legion 比,精简到这种程度,会不会丢失能力?**
A: Legion 的 265 组件里,大部分是"模型独立能做但当时模型还不够强"的弥补。
Opus 4.7 之后,大部分组件变成 "load-bearing for nothing",应该被拆掉。
真正不可替代的 5%(跨会话记忆 + 子代理通信总线 + review 收敛机制)就是这 13 个组件。

---

## Ratchet 观察点(怎么继续改进)

按 harness engineer 精神,每周自问:

1. **主代理写出来的 Activation Persona 够具体吗?** 不是"You are an expert"这种泛泛?
2. **subagent 输出里有没有"我先 Read 了 X、Y、Z..."这种探索性内容?** 有 → brief 没写精准,补行号
3. **有没有反复纠正同一类问题?** ≥3 次 → 该把它转成 hook 或加进 CLAUDE.md
4. **有没有 `/finish-task` 时 HANDOVER 写得敷衍?** → 加强 finish-task skill 的检查清单
5. **有没有想用某个 persona 但示例库里没有?** → 补进 `brief` skill 的示例表

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
