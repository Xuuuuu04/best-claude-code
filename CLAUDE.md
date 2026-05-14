# 跨项目通用约定

每条规则都对应一个"模型独立做不到的事"。如果某条不再 earn its place,删掉。

## 沟通口味
- 中文回答,代码标识符保持 ASCII
- 默认 teacher output-style(已配置)
- 简单问题直接答;复杂问题先 plan 再做,需要看真实代码状态时优先 plan mode
- 失败要 verbose,成功要 silent —— 没事别打断我

## Task 系统(核心机制)

每个用户独立诉求 → 一个 Task 文件,路径:

```
<project>/.claude/tasks/Task-{YYYY-MM-DD}-{HHMM}-{slug}.md
```

详细 schema 见 `/start-task` skill。常用流程:

1. 用户发新诉求 → 主代理调用 `/start-task` → 增强意图、一句话确认、写文件
2. 工作时主代理在该 Task 文件追加 Execution Log + Decisions
3. 完成时 `/finish-task` 写 Completion + HANDOVER 段
4. 跨会话恢复用 `/continue-task`

判断"新 task vs 当前 task 继续"的标准:**这条新输入能否独立成一个 commit?** 能→新 task;不能→追加当前 task 的 Prompt 段。

## 主代理调度边界

| 情况 | 怎么做 |
|---|---|
| 简单编辑、单次问答 | 主代理直接做,不拆 subagent |
| 探索读取大量文件 | 拆内置 Explore subagent |
| 需要独立判断的 review | 拆 reviewer agent |
| review 不收敛(≥3 轮) | 召唤 judge agent 裁决 |
| 任何 subagent 调用 | 必须先用 `/brief` 写 briefing 文件,绝不让 subagent 自己探索全部上下文 |

> 主代理是首席工程师,不是文员。深度参与判断,只把"重复性/探索性/隔离性"的活外包。

## 提交前纪律(代码项目)
- 必跑项目特定 typecheck / lint —— 命令在项目 CLAUDE.md 的 `## Preflight Commands` 段
- 用 `/preflight` 一键执行
- UI 改动需 playwright 截图对比(用已启用的 playwright MCP)
- 多端项目(web/miniapp/backend 并存)改动 enum/contract 前先跑 `/cross-sync`

## 弱模型时(GLM/Kimi 等)
通用性优先。所有 task / brief / skill 输出已结构化,弱模型按格式填即可,无需额外处理。

## 项目级配置说明

某些项目(漫展、眼科等)的 `.claude/` 里有 `agents/skills/rules/` 等 Legion 时期残留,与本用户级配置共存且互不干扰。优先级:**项目级 > 用户级**。如果项目级有同名组件,听项目级的。

## 文档之间的导航
- Plan 文档(包括本次设计依据): `~/.claude/plans/`
- 当前活跃任务:每个项目自己的 `.claude/tasks/`
- 这份文件本身:`~/.claude/CLAUDE.md` —— 修改前先问"删了会出问题吗?"
