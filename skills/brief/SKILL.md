---
name: brief
description: 主代理在调度 subagent 之前生成 task-specific briefing 文件,让 subagent 收到的 prompt 仅有几十 token,避免 subagent 自己探索全部上下文带来的 token 浪费(实测可省 10-40 倍)。这是整个 harness 的 token 效率核心。
---

# /brief

把"调度 subagent"这件事从"塞一大段 prompt"变成"指向一份 briefing 文件"。

## 何时调用

**任何要拆 subagent 的场景都必须先 /brief**,包括:
- 调用内置 Explore subagent 做大量探索
- 调用 reviewer agent 做 review
- 调用 judge agent 做裁决
- 调用项目级或 plugin 提供的任何自定义 subagent

唯一例外:主代理对 subagent 的 prompt 本身就只有 1-2 句具体指令(例如"读 src/foo.ts 第 50 行,告诉我函数参数有哪些")—— 这种轻量 query 不需要 brief。

## 执行步骤

### 1. 定位当前 Task 和 brief 编号

```bash
TASK_ID=<当前活跃 task id>
BRIEFS_DIR="$(pwd)/.claude/tasks/briefs"
mkdir -p "$BRIEFS_DIR"

# 计算本次是第几次 call
N=$(ls "$BRIEFS_DIR"/${TASK_ID}-* 2>/dev/null | wc -l | tr -d ' ')
N=$((N + 1))
```

### 2. 生成 brief 文件名

`{TASK_ID}-call-{N}-{purpose}.md`,例如:
- `Task-2026-05-15-1030-fix-auth-call-1-explore.md`
- `Task-2026-05-15-1030-fix-auth-call-2-review.md`

### 3. 按模板写 brief

```markdown
# Brief: <一句话目标,英文>

**Task**: <task id>
**Call**: #N
**For**: <subagent 类型,例 Explore / reviewer / judge / playwright>
**Created**: <时间戳>

## Activation Persona(必填,3-5 行)
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
输出严格的 JSON,写入: `<project>/.claude/tasks/outputs/{TASK_ID}-call-{N}.json`

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
- 一般执行 → `general-purpose` (内置)

### 5. 在 Task 文件中追加一笔

```markdown
## Subagent Calls

### Call #N (HH:MM): <purpose>
- Brief: `.claude/tasks/briefs/{TASK_ID}-call-{N}-{purpose}.md`
- Subagent type: <Explore|reviewer|judge|...>
- Output: `.claude/tasks/outputs/{TASK_ID}-call-{N}.json`
- 摘要: <subagent 返回后,主代理填一两行精华>
```

### 6. 读 subagent 输出

subagent 完成后,主代理:
1. Read `.claude/tasks/outputs/{TASK_ID}-call-{N}.json`
2. 验证 status 是否 success
3. 在 Task 文件的 Subagent Calls 段补上"摘要"行
4. 如果发现重要决策点,追加一行到 Decisions 段

## Activation Persona 写作指南(零成本激活专业视角)

这是这个 harness 里"专业能力激活"的核心机制 —— 不维护一堆专业 agent,而是每次写 brief 时
**动态注入身份**。Opus 4.7 知识广度足够,需要的只是"用什么视角思考"的明确指引。

### 写作骨架(3-5 行,必填)

```
You ARE a <具体角色,带技术栈或视角>.
You are paranoid about <2-3 个本领域最容易翻车的点>.
You do NOT <本领域常见反模式,1-2 条>.
```

关键要素:
- **具体到技术栈**:不写 "frontend engineer",写 "senior Vue 3 + Pinia engineer"
- **paranoid 段落点出"翻车点"**:不是泛泛说"质量",而是该领域的具体陷阱
- **do NOT 段落点出"反模式"**:防止 Opus 退回到平庸做法

### Persona 示例库(覆盖你的常用项目类型)

| 任务类型 | persona 草稿 |
|---|---|
| **Vue 3 + Pinia 前端** | You ARE a senior Vue 3 + Pinia engineer. You are paranoid about reactivity pitfalls (losing reactivity when destructuring refs, watching wrong dependency, computed side effects). You do NOT mix Options API into Composition API code, and do NOT use Vuex patterns. |
| **uni-app 小程序** | You ARE a senior uni-app + WeChat MiniProgram engineer. You are paranoid about platform-conditional code (`#ifdef MP-WEIXIN`), small-screen rendering, and miniprogram-specific API differences. You do NOT assume web-only DOM APIs are available. |
| **Next.js 全栈** | You ARE a senior Next.js 15 App Router engineer. You are paranoid about Server vs Client component boundaries, hydration mismatches, and server action security. You do NOT mix `use client` boundaries carelessly or expose secrets through props. |
| **FastAPI 后端** | You ARE a senior FastAPI engineer. You are paranoid about request validation gaps (Pydantic blind spots), async leaks (sync I/O in async path), and dependency injection mistakes. You do NOT skip request body validation or use bare `except`. |
| **Spring Boot 后端** | You ARE a senior Spring Boot + JPA engineer. You are paranoid about N+1 queries, transaction boundary leaks (`@Transactional` scope), and lazy loading pitfalls outside session. You do NOT use field injection or skip `@Transactional` on multi-step writes. |
| **PostgreSQL/MySQL DBA 视角** | You ARE a senior PostgreSQL DBA. You are paranoid about missing indexes on FK columns, lock contention from long transactions, and unbounded result sets. You do NOT write queries without EXPLAIN-thinking first. |
| **安全审计(横跨技术栈)** | You ARE a senior security auditor. You are paranoid about injection (SQL/XSS/cmd), authn/authz bypass, secrets in code, and unsafe deserialization. You do NOT accept "the framework handles it" without verification. |
| **性能分析(横跨技术栈)** | You ARE a senior performance engineer. You are paranoid about N+1 patterns, sync I/O in hot paths, large in-memory objects, unbounded loops, and missing caching layers. You do NOT optimize without measuring first. |
| **Docker/DevOps** | You ARE a senior DevOps engineer. You are paranoid about image layer bloat, secret leaks in env, and stateful containers without volumes. You do NOT use `:latest` tags in production and do NOT run containers as root. |
| **Playwright E2E** | You ARE a senior QA automation engineer. You are paranoid about flaky selectors (relying on auto-generated class names), race conditions (no `waitFor`), and tests that only cover the happy path. You do NOT use `sleep()` instead of `waitFor`. |
| **论文/文档审查** | You ARE a meticulous editor with a research background. You are paranoid about unsourced claims, terminology drift, and logical jumps between paragraphs. You do NOT let "可能" or "或许" without specifics pass through. |

### 选 persona 的判断方法

读完 Mission 后问自己:**"如果我现在要找真人做这件事,我会找哪种专家?"** 答案就是 persona。

- 修一个 Vue 组件 bug → Vue 3 expert
- 加一个 API 端点 → 后端 expert(看技术栈)
- 跑前端性能优化 → performance engineer
- 检查代码里有没有 SQL 注入 → security auditor
- 同一个任务可能需要多次调用,每次 persona 可以不同(第一次用 "developer" 实现,第二次用 "security auditor" 审查)

### 反例(persona 写错的样子)

- ❌ "You are an expert" —— 泛泛,没激活
- ❌ "You are a Vue expert who is paranoid about everything" —— paranoid 段空洞
- ❌ "You are a coder" —— 不具体到技术栈
- ❌ Persona 段超过 5 行 —— 太长稀释 mission 注意力
- ❌ Persona 和 Mission 矛盾(persona 是 reviewer,mission 是让它写代码)

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

## token 效率对照

- 让 subagent 自己探索:**5,000-20,000 token**
- 用 brief 精准定位:**200-500 token**(brief 本身) + **30-50 token**(subagent prompt)
- 杠杆:**10-40 倍**

如果你发现 subagent 输出里有"我先 Read 了 X、Y、Z 文件..."这种探索性内容,说明 brief 没写够精准 —— 下次补行号、补 Known Facts。
