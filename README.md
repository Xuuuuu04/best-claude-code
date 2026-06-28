# best-claude-code

> 极简 Claude Code 用户级配置,基于 **Harness Engineering** 思路。
> **10 Skills · 6 Hooks · 3 Agents · 3 Rules** · **Task-Centric** 架构 · v3.0.0

---

## 这是什么

不是插件集合,不是 agent 农场,是一套**协议**——解决五个模型自己搞不定的问题:

- 跨会话、跨 `/compact`、跨子代理调度时**状态不丢**
- 子代理通信**走文件系统不走消息流**,token 省 10-40 倍
- 对抗性 review **保证收敛**(Writer/Reviewer/Judge 三角 + Acceptance Criteria + Round Cap)
- 专业能力**靠 brief 里的 Activation Persona 动态激活**,不用养一堆专家 agent
- Stop hook **硬拦收尾**(改了一堆没更新 Task 不让停),PostToolUseFailure / UserPromptSubmit **软提示**(连败提示走 `/bcc-debug`、每轮注入工作流路标引导走 skill)——纪律里既有强制也有提醒,各司其职

思路来自 Anthropic 的
[Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
里的 **"Structured Artifacts Over Natural Language"** 原则,
和 Manus 团队的 **"Context as Filesystem"** 架构。

---

## 设计哲学(harness engineer 五原则)

| # | 原则 | 落实在哪 |
|---|---|---|
| 1 | **Earn every component** | 22 个组件,每个对应一件"模型自己做不到的事";没用的砍掉 |
| 2 | **Configuration over capability** | 不等模型变好,用 harness 把当前模型(包括弱模型 GLM/Kimi)托起来 |
| 3 | **Failures become rules** | 纠正过的事变成 skill/hook/rule,不再靠口头说 |
| 4 | **Success is silent, failures are verbose** | 没事不吭声,出问题才喊 |
| 5 | **不重复造轮子** | playwright/context7/frontend-design 已经覆盖够多,新组件绕开 |

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
│(10 个) │    │  (3 个)  │    │  (6 个)  │    │  (3 条)  │    │Servers │
├────────┤    ├──────────┤    ├──────────┤    ├──────────┤    ├────────┤
│bcc-    │    │developer │    │ Session  │    │ honest-  │    │github  │
│ start  │    │          │    │  Start   │    │ communi- │    │repomix │
│ finish │    │ reviewer │    │PreCompact│    │  cation  │    │seq-    │
│ review │    │          │    │ PostTool │    │ git-     │    │thinking│
│ brief  │    │  judge   │    │  Use+Fail│    │  safety  │    └────────┘
│ preflight   └──────────┘    │ Stop     │    │ sensitive│
│ cross-sync        │         └─────┬────┘    │  -files  │
│ debug  │    Brief Pattern         │         └──────────┘
│ tdd    │    + Dev Brief           │
│ init   │    文件系统通信总线       │
│ check  │         │                │
└────────┘    ┌────▼────────────────▼────┐
              │  Task File + Spec        │ ◄── 持久化记忆
              │  + Review History         │     量化评分追踪
              │  <project>/.claude/tasks/ │     跨会话不丢
              └──────────────────────────┘
```

---

## 组件清单

### Skills(10 个,位于 `skills/bcc-<name>/SKILL.md`,统一 `/bcc-` 前缀）

**Task 生命周期(2 个)**
| Skill | 何时调用 | 作用 |
|---|---|---|
| `/bcc-start` | 用户新独立诉求 | 增强意图 + 写 Spec(Requirements + Review Dimensions) + 轻量确认 + 创建 Task 文件 |
| `/bcc-finish` | 任务完成 | 验证 review 分数达标 + 写 Completion(含 Review Score) + 强制 HANDOVER + status: done |

跨会话恢复不需要单独 skill:session-start hook 自动注入 in_progress Task 列表,模型直接 Read 对应文件即可恢复。

**子代理协调(1 个)**
| Skill | 何时调用 | 作用 |
|---|---|---|
| `/bcc-brief` | 调度 subagent 前 | 写 briefing(含 Activation Persona / Development Brief 模板)给子代理读 |

**审查(1 个,v3.0 新增)**
| Skill | 何时调用 | 作用 |
|---|---|---|
| `/bcc-review` | 开发完成后 | 自动生成 review brief → 调度 reviewer → 读评分 → 追加 Review History 到 Task |

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
| `/bcc-check` | 怀疑 harness 有问题时 | 健康检查:jq/hooks 可执行/settings 注册一致性/skills frontmatter(严格 YAML)/rules/版本 |

### Agents(3 个,位于 `agents/<name>.md`)
| Agent | 召唤时机 | 角色 | 工具限制 |
|---|---|---|---|
| `developer` | 正常开发任务 | 执行者,从 development brief 读任务,改代码跑测试,输出结构化 JSON | 完整开发权限(Read/Edit/Write/Bash/Grep/Glob) |
| `reviewer` | 开发完成后(`/bcc-review`) | 对抗性 reviewer,多维度量化评分(0-10),输出评分 JSON | 无 Edit;Bash 限只读;Write 只许 outputs/ |
| `judge` | review 不收敛(≥3 轮) | 独立裁决者,只比对 acceptance criteria | Read + Grep |

### Hooks(6 个事件 hook + 1 个共享库,位于 `hooks/*.sh`)

**上下文连续性(2 个)**
| Hook | 事件 | 作用 |
|---|---|---|
| `session-start.sh` | SessionStart | 扫描 in_progress task,注入 additionalContext + watchPaths;顺手清理过期 state 文件 |
| `precompact.sh` | PreCompact | 压缩前把恢复指引写进 Task 文件(纯 side effect;官方不支持 compact 事件注入上下文,压缩后模型重读文件即恢复) |

**执行纪律(3 个)**
| Hook | 事件 | 作用 |
|---|---|---|
| `posttooluse-guard.sh` | PostToolUse | 文件编辑(Edit/Write 类)成功时累计计数;编辑的是 Task 文件则归零。Bash 成功不计数、只重置连败计数 |
| `posttoolusefailure.sh` | PostToolUseFailure(matcher: Bash) | 命令失败累加连败计数,3 连败注入 `/bcc-debug` |
| `stop-progress-gate.sh` | Stop | 三级拦截:6+ 编辑未更新 Task Log / 有 Spec 但没 review / review 未通过 |

**工作流引导(1 个)**
| Hook | 事件 | 作用 |
|---|---|---|
| `userpromptsubmit-router.sh` | UserPromptSubmit | 每轮注入"工作流路标 + 活跃 task 状态 + review 轮次和分数",引导主代理走对应 skill;不替模型分类,只给状态 + 判据 |

**共享库(1 个)**
| 文件 | 作用 |
|---|---|
| `_common.sh` | jq 检测、state 原子读写(`_load/_save_hook_state`)、review 状态读取(`_task_has_spec/_latest_review_json/_read_review_result`) |

**回归测试**
`hooks/test.sh` — 造 stdin、跑 6 个 hook、断言输出/state(26 个用例,覆盖 #1 无-task 提示 / #3 outputs 不归零 / #4 frontmatter 锚定 等)。改 hook 后跑 `bash hooks/test.sh`,全过 exit 0。

### Rules(3 条,位于 `rules/*.md`)
| Rule | 作用 |
|---|---|
| `honest-communication.md` | 四层中文矫正:行为禁令 + 句法 + 词汇替换 + 进度汇报格式 |
| `git-safety.md` | 禁止 force push / reset --hard / --no-verify 等破坏性操作 |
| `sensitive-files.md` | 禁止读写 .env/credentials/密钥文件,禁止 commit 二进制大文件 |

---

## 四大核心机制

### 1. Task-Centric Persistent File System

每个用户独立诉求 → 一个 Task 文件 → 路径:
```
<project>/.claude/tasks/Task-{YYYY-MM-DD}-{HHMM}-{slug}.md
```

判断"新 task vs 当前 task 继续"的标准:**这条新输入能否独立成一个 commit?**
能 → 新 task;不能 → 追加当前 task 的 Prompt 段。

Task 文件用 YAML frontmatter + Markdown body,包含 10 个段:
`Prompt`(append-only) / `Intent` / `Spec`(Requirements + Review Dimensions) / `Plan` / `Execution Log` /
`Subagent Calls` / `Decisions`(append-only) / `Review History`(量化评分追踪) / `Completion`(含 Review Score) / 嵌入式 `HANDOVER`。

完整 schema 见 `skills/bcc-start/SKILL.md`。

### 2. Briefing Pattern(子代理通信)

调度任何 subagent 之前,**先用 `/bcc-brief` 写一份 briefing 文件**,然后 subagent 的 prompt 只有一句:

```
Agent.prompt = "Read the briefing file at <path>, then execute."
                                (30-50 token)
```

Briefing 文件 7 段:
`Activation Persona` / `Mission` / `Known Facts` / `Files You Need`(精确到行号) /
`Acceptance Criteria` / `Output Format`(JSON schema) / `Constraints` + `Don't`。

Activation Persona 只对 Explore / general-purpose 类 subagent 生效;reviewer / judge 有自己的固定人设。

**Token 效率对照**(估算,基于 brief 体量):
| 模式 | token 消耗 |
|---|---|
| 让 subagent 自己探索 | 5,000-20,000 |
| 用 brief 精准定位 | 200-500(brief) + 30-50(prompt) |
| **杠杆** | **10-40 倍** |

### 3. Developer/Reviewer/Judge 三角(量化 review + 对抗性收敛)

```
主代理(协调者)
    │ 写 Development Brief
    ▼
Developer subagent ──→ dev-result JSON
    │                      │
    │ 读结果,调 /bcc-review │
    ▼                      ▼
Reviewer agent ──→ 多维度评分 JSON (5 维度 0-10 + weighted score)
    │                      │
    │ pass: true → finish  │ pass: false → 新 dev brief 修复
    │                      │
    │       ≥ 3 轮不收敛   ▼
    └─────────→ Judge agent ──→ accept | reject | continue_one_more_round
```

**三个 agent 的权限设计是对称的:**
- developer 有完整开发权限,但不做设计判断(brief 约束行为)
- reviewer 没有 Edit——**不让改代码,逼它好好想**;输出量化评分不是二元 approve/reject
- judge 只有 Read + Grep——比 reviewer 还少,只看 criteria 不看代码细节

reviewer 的评分 JSON 包含: 每维度 score + reasoning + delta(与上轮对比) + actionable_summary(告诉 developer 下一步做什么)。主代理每轮把评分追加到 Task 的 Review History 段,跨 compact/跨会话不丢。

### 4. 执行纪律闭环

```
PostToolUse hook(成功) ──→ Edit/Write/MultiEdit/NotebookEdit → edits_since_task_update++
                            编辑的是 Task 文件本身 → 计数归零(连败计数一并清零)
                            Bash 成功不计数(只读命令占多数),只把连败计数归零

PostToolUseFailure hook(matcher: Bash) ──→ consecutive_bash_failures++
                                            3 连败 → 注入 /bcc-debug 软提示

Stop hook ──→ 模型想收尾时三级检查(v3.0 增强)
              ├─ 6+ 次文件编辑未更新 Task Log → block
              ├─ Task 有 Spec 但没有 review JSON → block("先跑 /bcc-review")
              └─ 最新 review pass: false → block("weighted X, blocking [Y],先修")
```

失败信号来自官方 PostToolUseFailure 事件,不用 exit-code/正则去猜。
state 文件按 session_id 隔离,多会话/agent teams 同项目并行不串号;
用 mktemp + mv 原子写,中断了也不会写出空 JSON。
Task 完成时 `/bcc-finish` 自动把计数器归零。

---

## 文件结构

```
~/.claude/
├── CLAUDE.md                          # 跨项目通用约定
├── README.md                          # 本文件
├── VERSION                            # 语义化版本号(当前 3.0.0)
├── settings.json                      # hooks 注册 + MCP + providers(被 .gitignore)
├── install-hooks.sh                   # 幂等把 hooks 注册进 settings.json(进 git,搬机器跑这个)
├── output-styles/
│   └── teacher.md                     # 教师风格对话
├── skills/                            # 10 个,统一 /bcc- 前缀
│   ├── bcc-start/SKILL.md             # Task 入口,含 Spec 段模板
│   ├── bcc-finish/SKILL.md            # Task 收尾,验证 review 分数
│   ├── bcc-review/SKILL.md            # v3.0 新增:自动 review brief + 调度 + Review History
│   ├── bcc-brief/SKILL.md             # 含 Development Brief 模板 + Activation Persona
│   ├── bcc-tdd/SKILL.md
│   ├── bcc-debug/SKILL.md
│   ├── bcc-preflight/SKILL.md
│   ├── bcc-cross-sync/SKILL.md
│   ├── bcc-init/SKILL.md
│   └── bcc-check/SKILL.md
├── agents/
│   ├── developer.md                   # v3.0 新增:执行者,从 dev brief 改代码跑测试
│   ├── reviewer.md                    # 对抗性 reviewer,多维度量化评分(0-10)
│   └── judge.md                       # 独立裁决者,Read + Grep
├── hooks/                             # 6 个事件 hook + 1 个共享库
│   ├── _common.sh                     # 共享工具函数(jq/state/review 状态读取)
│   ├── session-start.sh               # SessionStart
│   ├── precompact.sh                  # PreCompact(往 Task 文件写恢复指引)
│   ├── posttooluse-guard.sh           # PostToolUse(文件编辑计数,Bash 只重置连败)
│   ├── posttoolusefailure.sh          # PostToolUseFailure(连败计数,3 连败切 /bcc-debug)
│   ├── stop-progress-gate.sh          # Stop(三级拦截:编辑计数 + review 状态)
│   ├── userpromptsubmit-router.sh     # UserPromptSubmit(路标 + review 轮次分数)
│   └── test.sh                        # 6 hook 回归测试
├── rules/                             # 3 条确定性策略
│   ├── honest-communication.md        # 四层中文矫正
│   ├── git-safety.md                  # 破坏性 git 操作围栏
│   └── sensitive-files.md             # 密钥/凭证保护
└── plans/                             # 设计稿(被 .gitignore)
```

每个项目内自动维护:
```
<project>/.claude/tasks/
├── Task-2026-05-15-1030-fix-auth.md   # Task 文件(是否进 git 由各项目 .gitignore 决定)
├── Task-2026-05-15-1420-add-payment.md
├── outputs/                           # brief + subagent 输出,语义命名(被 .gitignore)
│   ├── brief-review-payment.md
│   └── review-payment.json
├── archive/                           # 已完成 task 的归档(被 .gitignore)
└── .hook-state.<session>.json         # hook 计数器,按会话隔离(被 .gitignore)
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

# 4. 注册 hooks(settings.json 被 .gitignore,搬机器/重装必须重跑这步)
bash ~/.claude/install-hooks.sh   # 幂等:把 6 个 hook 写进 settings.json,命令路径自动用 $HOME
# MCP / providers / API keys 仍参考下方模板手工补进 settings.json

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
    "SessionStart": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/session-start.sh" }] }
    ],
    "UserPromptSubmit": [
      { "matcher": "", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/userpromptsubmit-router.sh" }] }
    ],
    "PostToolUse": [
      { "matcher": "Edit|Write|MultiEdit|NotebookEdit|Bash", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/posttooluse-guard.sh" }] }
    ],
    "PostToolUseFailure": [
      { "matcher": "Bash", "hooks": [{ "type": "command", "command": "/Users/<you>/.claude/hooks/posttoolusefailure.sh" }] }
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
A: 可以跟项目 git 走(是否提交由各项目 .gitignore 决定)、自然归档、项目结束 task 历史一起走。跨项目搜索其实很少发生。

**Q: 为什么加了 developer agent 而不是继续主代理写代码?**
A: 主代理写代码时,每轮迭代的 diff/讨论都堆在上下文里,多轮 review 后 token 消耗暴涨。developer subagent 每轮是独立的干净上下文,主代理只看 JSON 结果。简单任务(≤2 文件 ≤30 行)主代理仍直接改(fast path)。

**Q: 为什么 review 要量化评分?**
A: 二元 approve/reject 太模糊——reviewer 说"不通过"但不说差多少、差在哪、修什么能过。量化评分(5 维度 0-10 + 权重 + 阈值)让 developer 一眼知道:哪个维度不达标、分数差多少、修什么能拉分。delta_from_previous 防止改 A 破 B。

**Q: 6 个 hook 分别干嘛?**
A: 三类。**上下文连续性**(2 个):SessionStart 注入活跃 Task + review 状态,PreCompact 压缩前落盘恢复指引。**执行纪律**(3 个):PostToolUse 数编辑(Bash 不计),PostToolUseFailure 数连败(3 连败提示 debug),Stop 三级拦截(编辑计数 + review 缺失 + review 未通过)。**工作流引导**(1 个):UserPromptSubmit 每轮注入路标(活跃 task + review 轮次分数)。共享 `_common.sh`。

**Q: 主代理不会沦为调度员?**
A: CLAUDE.md 里写死了:**主代理是首席工程师,不是码农也不是文员**。设计 + 协调 + 决策自己做,实现和审查外包给 subagent。

**Q: 为什么 subagent 输出一律 JSON?**
A: 弱模型也能填 schema,主代理不用二次理解,可以程序化校验。自由文本意味着多一轮 token + 误读风险。

**Q: 比 Legion 砍了 95%,能力会丢吗?**
A: Legion 265 个组件里,大部分是弥补"模型当时不够强"。Opus 4.7 之后那些变成死重。
真正不可替代的——跨会话记忆、子代理通信、量化 review 收敛、执行纪律——就是这 22 个。

**Q: Rules 和 CLAUDE.md 什么关系?**
A: CLAUDE.md 是摘要(1-2 行/条,每次会话都加载),Rules 是展开版(对照表、案例)。不重复,互补。

---

## Ratchet 观察点(怎么继续改进)

按 harness engineer 精神,每周自问:

1. **主代理写出来的 Activation Persona 够具体吗?** 不是"You are an expert"这种泛泛?
2. **subagent 输出里有没有"我先 Read 了 X、Y、Z..."这种探索性内容?** 有 → brief 没写精准,补行号
3. **有没有反复纠正同一类问题?** ≥3 次 → 该把它转成 hook 或加进 CLAUDE.md
4. **有没有 `/bcc-finish` 时 HANDOVER 写得敷衍?** → 加强 bcc-finish skill 的检查清单
5. **有没有想用某个 persona 但示例库里没有?** → 补进 `bcc-brief` skill 的示例表
6. **PostToolUseFailure 的 3 连败阈值 / Stop gate 的 6 次编辑阈值合不合适?有没有误触发?** → 调阈值,别加启发式
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
