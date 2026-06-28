# 跨项目通用约定

每条规则都对应一个"模型独立做不到的事"。如果某条不再 earn its place,删掉。

## 沟通纪律（最高优先级规则）
- 中文回答,代码标识符保持 ASCII,像开发者说话不像客服
- 默认 teacher output-style(已配置)
- 简单问题直接答;复杂问题先 plan 再做
- 零谄媚 / 零虚假自信 / 零翻译腔 / 零夸大 / 语言一致 —— 完整禁令和对照表在 `rules/honest-communication.md`,该文件每会话自动加载,以它为准,这里不重复

## Task 系统(核心机制)

每个用户独立诉求 → 一个 Task 文件,路径:

```
<project>/.claude/tasks/Task-{YYYY-MM-DD}-{HHMM}-{slug}.md
```

详细 schema 见 `/bcc-start` skill。常用流程:

1. 用户发新诉求 → 主代理调用 `/bcc-start` → 增强意图、写 Spec(Requirements + Review Dimensions)、一句话确认、写文件
2. 主代理 Plan → 写 development brief → developer subagent 执行(或 fast path 自己改)
3. 开发完成 → `/bcc-review` → reviewer 多维度量化评分 → 追加 Review History 到 Task
4. review 通过 → `/bcc-finish` 写 Completion(含最终 Review Score) + HANDOVER
5. review 未通过 → 写新 dev brief 修复 → 再轮 review(≥3 轮不收敛 → judge)
6. 跨会话恢复:session-start hook 自动注入活跃 Task + review 状态

判断"新 task vs 当前 task 继续"的标准:**这条新输入能否独立成一个 commit?** 能→新 task;不能→追加当前 task 的 Prompt 段。

## 主代理调度边界

| 情况 | 怎么做 |
|---|---|
| 简单编辑(≤2 文件 ≤30 行)、单次问答 | 主代理直接做(fast path),改完仍走 `/bcc-review` |
| 正常开发任务 | 写 development brief → 拆 developer subagent → 读结果 → `/bcc-review` |
| 探索读取大量文件 | 拆内置 Explore subagent |
| 代码改动后(有 Spec 的 Task) | 走 `/bcc-review` 量化评分,通过后才能 finish |
| review 不收敛(≥3 轮) | 召唤 judge agent 裁决 |
| 任何 subagent 调用 | 先想清 brief 内容(persona/criteria/output schema)并落成 brief 放 outputs/ |

**开发模式**: 主代理是协调者+设计者,不亲自写大量代码。读代码定位范围 → 预提取到 development brief → developer subagent 执行 → 主代理读结果 → 调 reviewer 评分。每轮 developer 是独立 subagent,干净上下文,主代理只看 JSON 结果。

**何时算"重大改动" → review 不可跳过(宁可漏不可滥):**
- 改了 hook / 共享库 / 核心控制流
- 删除或重构组件
- 跨 ≥3 文件的一致性改动(enum / contract / 计数)
- 自己改完"感觉干净"但没第二双眼验过的重大改动
- 日常小改(单文件小修、改文案、纯文档)且 Task 无 Spec → 可跳过 review

> 主代理是首席工程师,不是文员也不是码农。设计+协调+决策自己做,实现和审查外包给 subagent。

## 开发纪律(代码项目)

**TDD 默认开启**:实现功能或修 bug 时,默认用 `/bcc-tdd` 流程(红-绿-重构)。用户说"不用测试"时可跳过。
**系统化调试**:遇到 bug 用 `/bcc-debug`,禁止盲猜盲修——先定位根因,再写失败测试,再修。

**提交前检查**:
- 必跑项目特定 typecheck / lint —— 命令在项目 CLAUDE.md 的 `## Preflight Commands` 段
- 用 `/bcc-preflight` 一键执行
- UI 改动需 playwright 截图对比(用已启用的 playwright MCP)
- 多端项目(web/miniapp/backend 并存)改动 enum/contract 前先跑 `/bcc-cross-sync`

**复杂任务先设计**:Plan 超过 5 步时,在动手写代码前先和用户对齐 2-3 个方案和取舍。

## 国产模型时(GLM/DeepSeek/Kimi 等)
通用性优先。所有 task / brief / skill 输出已结构化,按格式填即可。这些模型 coding 已接近 Claude(别再当"弱模型"),选型与适配见 memory `domestic-models`:单厂商按会话切、subagent 继承主代理模型(model 别名档位在自定义 provider 下不生效)。

## 项目级配置说明

某些项目(漫展、眼科等)的 `.claude/` 里有 `agents/skills/rules/` 等 Legion 时期残留,与本用户级配置共存且互不干扰。优先级:**项目级 > 用户级**。如果项目级有同名组件,听项目级的。

## 文档之间的导航
- Plan 文档(包括本次设计依据): `~/.claude/plans/`
- 当前活跃任务:每个项目自己的 `.claude/tasks/`
- Rules(确定性策略): `~/.claude/rules/`(git-safety, sensitive-files, honest-communication）
- 这份文件本身:`~/.claude/CLAUDE.md` —— 修改前先问"删了会出问题吗?"
