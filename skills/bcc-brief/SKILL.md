---
name: bcc-brief
description: 主代理调度 subagent 之前,把 briefing 内容(persona / known facts / files / acceptance criteria / output schema)想清楚并落成一份 brief 文件,让 subagent 的 prompt 只有一句"读这份 brief",不用自己探索全部上下文。这是 harness 省 token 的关键。
argument-hint: "[subagent 类型] [目的简述]"
effort: high
---

# /bcc-brief

调 subagent 不塞一大段 prompt,改成指向一份 briefing 文件。

## 何时调用

**拆 subagent 前,先把 brief 内容想清楚**(Activation Persona / Known Facts / Files / Acceptance Criteria / Output schema)——这是省 token、防 subagent 乱探索的关键。适用:
- 内置 Explore 做大量探索
- reviewer agent 做 review
- judge agent 做裁决
- 项目级或 plugin 提供的任何自定义 subagent

唯一例外:prompt 本身只有 1-2 句具体指令(例"读 src/foo.ts:50,告诉我函数参数有哪些")—— 这种轻量 query 不需要 brief。

## 执行步骤

### 1. 定位 outputs 目录

```bash
OUT_DIR="$(pwd)/.claude/tasks/outputs"
mkdir -p "$OUT_DIR"
```

brief 和 subagent 的输出**都放这里**。不用单独的 `bcc-briefs/` 目录,也不用算 call 编号——实战(跨多个真实项目)证明那套形式没人遵守,语义命名更好认。

### 2. 生成 brief 文件名(语义命名)

`brief-<topic>.md`,topic 用 2-4 个词点明主题:
- `brief-explore-auth-flow.md`
- `brief-review-payment.md`
- `brief-audit-r3-backend.md`(多轮时带轮次)

跟实战里 `review-r7`、`audit-C1` 的风格一致,见名知意,不用回头查"call-3 到底是干嘛的"。

### 3. 按模板写 brief

```markdown
# Brief: <一句话目标,英文>

**Task**: <task id>
**For**: <subagent 类型,例 Explore / reviewer / judge / playwright>
**Created**: <时间戳>

## Activation Persona(必填,3-5 行)
⚠️ 仅影响 Explore / general-purpose 类 subagent。reviewer / judge 有固定 persona（见 agents/reviewer.md、agents/judge.md），不受此处影响。

You ARE a <具体角色,带技术栈或视角>.
You are paranoid about <2-3 个本领域最容易翻车的点>.
You do NOT <本领域常见反模式,1-2 条>.

## Mission
<1-2 句话明确告诉 subagent 它的唯一目标。不要绕弯,不要废话。>

## Known Facts(主代理已知,subagent 不需要重新发现)
- <事实 1,例:auth 入口在 src/auth/index.ts>
- <事实 2,例:token expiry 设置在 .env 的 AUTH_TOKEN_TTL,当前 3600s>
- <事实 3>

## Files You Need(直接 Read 这些,不要 Glob/Grep 探索)
- <path:start-end>,例 src/auth/refreshToken.ts:1-80
- <path:start-end>,例 src/auth/__tests__/refresh.test.ts:整文件
- <path>,例 docs/auth-flow.md

(可选)## Files You Can Touch If Needed(允许范围)
- <subagent 如果要 Edit,只能动这些>

## Acceptance Criteria
- [ ] <可验证标准 1>
- [ ] <可验证标准 2>
- [ ] <可验证标准 3>

## Output Format
输出严格的 JSON,写入 outputs/ 下与 brief 同主题的文件,例 `outputs/review-payment.json`。

Schema:
\`\`\`json
{
  "status": "success" | "partial" | "failed",
  "findings": [<根据 subagent 类型定>],
  "next_recommendation": "<给主代理的建议,1-2 句>"
}
\`\`\`

## Constraints
- <硬约束,例:不能改 API contract>
- <例:不能写 .env / .git / .claude/>

## Don't(本任务的反例)
- <例:不要扩大改动范围到 src/auth/index.ts 之外的文件>
- <例:不要重新探索整个 src/,我已经定位好了>
```

### 4. 调用 subagent

用 Agent 工具调用 subagent,prompt 仅包含一句:

```
Read the briefing file at <brief 文件绝对路径>, then execute. Write your output to the path specified in the brief.
```

子代理类型选对:
- 大量探索 → `Explore` (内置)
- code review → `reviewer` (本仓库自定义)
- 裁决 → `judge` (本仓库自定义)
- 一般执行 / 实现代码 → `general-purpose` (内置)

模型选择（省成本加速度）:
- 机械性实现（清晰 spec、1-2 个文件）→ 用 `haiku`
- 多文件集成、模式匹配 → 用 `sonnet`
- 架构设计、review、裁决 → 用 `opus`

> ⚠️ 上面这套档位（haiku/sonnet/opus）只在 Anthropic Claude 模式下成立。
> 主代理若跑在自定义 provider（国产模型 GLM/DeepSeek/Kimi 等）上，这些别名在 subagent 的解析
> 是 Claude Code 未文档化的行为——subagent 很可能直接继承主代理模型，而不是按档位换。
> 单厂商场景下这其实合理：subagent 用同一家同一模型即可。要省成本用轻量档，靠会话级手动 /model，
> 别指望 brief 里写 model 别名生效。（2026-05 查证，CC 机制若变需复核）

### 4b. 实现类 brief 的两阶段 Review（吸收自 Superpowers SDD）

当 brief 的 For 字段是 `implementer`（实现代码任务）时，实现者完成后追加两轮独立 review：

**第一轮：Spec 合规 Review**
- 调度 reviewer subagent，对比 brief 的 Acceptance Criteria 和实际代码
- 重点检查：有没有漏做的？有没有多做的？有没有理解偏差？
- **不信任实现者的自述**——独立读代码验证

**第二轮：代码质量 Review**
- 只有 Spec 合规通过后才做
- 检查：命名、可读性、测试质量、文件职责是否清晰
- 调度方式：写新 brief（For: reviewer），或直接用内置 reviewer agent

**实现者状态协议**——实现类 subagent 的 output JSON 的 status 字段扩展：
- `DONE` — 正常完成，进入 review
- `DONE_WITH_CONCERNS` — 完成但有疑虑（主代理先读 concerns 再决定是否 review）
- `NEEDS_CONTEXT` — 缺信息，主代理补充后重新 dispatch
- `BLOCKED` — 做不了。主代理判断：补上下文？换更强模型？拆小任务？升级给用户？

**绝不忽略 BLOCKED/NEEDS_CONTEXT。** 如果实现者说卡住了，一定有东西要改。

### 5. (可选) 在 Task 文件记一笔

想保留可追溯性,就在 Subagent Calls 段追加一行——**非强制**,`outputs/` 里的文件本身就是记录:

```markdown
## Subagent Calls
- <topic> (<subagent 类型>): <一句话摘要>, output: outputs/<topic>.json
```

### 6. 读 subagent 输出

subagent 完成后,主代理:
1. Read `outputs/<topic>.json`
2. 验证 status 是否 success
3. 发现重要决策点,追加一行到 Task 的 Decisions 段

## Activation Persona 写作指南(零成本激活专业视角)

不养专业 agent,每次写 brief 时**动态注入身份**就够了。
模型知识面够宽,缺的是"用什么视角想问题"的指引。

### 写作骨架(3-5 行,必填)

```
You ARE a <具体角色,带技术栈或视角>.
You are paranoid about <2-3 个本领域最容易翻车的点>.
You do NOT <本领域常见反模式,1-2 条>.
```

关键要素:
- **具体到技术栈**:不写 "frontend engineer",写 "senior Vue 3 + Pinia engineer"
- **paranoid 段落点出"翻车点"**:不是泛泛说"质量",而是该领域的具体陷阱
- **do NOT 段落点出"反模式"**:防止模型退回到平庸做法

### Persona 示例(按项目技术栈调整)

| 任务类型 | persona 骨架 |
|---|---|
| **Vue 3 前端** | ...paranoid about reactivity pitfalls, computed side effects. Do NOT mix Options/Composition API. |
| **FastAPI 后端** | ...paranoid about Pydantic blind spots, async leaks. Do NOT skip validation or bare `except`. |
| **安全审计** | ...paranoid about injection, authn/authz bypass, secrets in code. Do NOT accept "framework handles it". |
| **DevOps** | ...paranoid about image bloat, secret leaks in env. Do NOT use `:latest` in production. |

选 persona:**"找真人做这件事,找哪种专家?"** 答案就是 persona。同一 task 多次调用可换 persona。

Persona 反例:泛泛写 "an expert"、paranoid 段空洞、超 5 行、和 Mission 矛盾。

## 关键纪律

- **brief 内容应该浓缩但完整**:大概 30-80 行 markdown 是合适区间。如果超过 100 行,说明 mission 不够聚焦,应该拆成多个 brief。
- **Files You Need 必须精确**:写到行号最好。这是省 token 的关键。
- **Output Format 必须有 schema**:JSON 字段名固定。这是省 round-trip 的关键。
- **Acceptance Criteria 必须可验证**:不要写"代码质量好",写"通过 typecheck"。
- **Activation Persona 必填**:每个 brief 都要有这一段,不是可选。这是零成本激活专业能力的关键。

## 反例(别这样做)

- ❌ Mission 写"帮我看一下 auth" —— 太模糊
- ❌ Files You Need 写"src/auth/" —— 让 subagent 自己探索,等于没省 token
- ❌ Output Format 写"输出你的发现" —— 没 schema,主代理还得二次解析
- ❌ Acceptance Criteria 写"满足要求" —— 不可验证
- ❌ 同一个 task 反复发同样的 brief —— review 不收敛时召唤 judge,不是再发一次 brief

## token 效率

brief 精准定位(几百 token)比让 subagent 自己探索(几千到几万 token)省得多。subagent 输出里出现"我先 Read 了 X、Y、Z..."说明 brief 不够精准,该补行号。
