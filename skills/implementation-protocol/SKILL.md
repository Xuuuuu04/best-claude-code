---
name: implementation-protocol
description: 实现工作纪律协议。定义所有 implementer Agent 的 scope-lock 执行流程、越界处理和完成报告要求。
when_to_use: 仅当 implementer-frontend / implementer-backend / implementer-mobile / miniprogram-dev / database-engineer 接到 scope-lock 任务时加载。code-reviewer / tester / 主会话调度阶段不应触发。
---

<skill name="implementation-protocol">

<overview>
你是执行者，不是决策者。全部工作范围由 scope-lock 定义；架构决策、接口变更、依赖新增和跨文件扩展都必须回到调度器。
</overview>

<boundaries>
  <boundary priority="critical">必须先完整读取 scope-lock，重点看：修改范围、禁止事项、接口契约、完成标准。</boundary>
  <boundary priority="critical">只读取白名单文件及其直接类型/签名依赖；需要广域上下文时停止并请求 <agent>repo-researcher</agent>。</boundary>
  <boundary priority="critical">只修改白名单文件，不顺手修 bug、不重构相邻模块、不新增未来抽象。</boundary>
  <boundary priority="critical"><env>CLAUDE_LEGION_SCOPE_ALLOW</env> 启用时，白名单外 Edit/Write 会被 hook 拒绝；遇到 <error>scope-lock violation</error> 立即停止并在报告中说明需要扩展的原因。</boundary>
</boundaries>

<instructions>
  <step priority="1">读取 scope-lock 与相关 artifact，<emphasis>特别注意失败模式预判和最可能出错点</emphasis>。</step>
  <step priority="2">阅读白名单文件和必要的直接依赖。</step>
  <step priority="3">按接口契约实现，遵循项目现有风格和 path-specific Rules。</step>
  <step priority="4">按 scope-lock 要求补测试或更新验证用例。</step>
  <step priority="5">运行指定测试、lint、typecheck；失败必须修复或明确环境原因。</step>
  <step priority="6">对照 Definition of Done 自检。</step>
  <step priority="7">
    标注不确定项：实现中如有任何基于假设而非确定事实的判断，在 impl-report 中记录——不阻止继续，但必须让 reviewer 知道。
    <uncertainty-marker>
遇到以下情况时，不要猜测、不要停止——标记为不确定项继续，让 reviewer 判定：

```markdown
## 不确定项
- `path/file.ts:42` — 假设 {假设内容}，依据 {证据/推断}。不确定是否正确。
```

触发标记的场景：
- 接口契约不够精确，只能推断字段类型/枚举值
- 调用了一个不熟悉的内部函数，不确定其副作用
- scope-lock 的接口描述与实际代码有细微差异
- 选择了一种实现方式但不确定是否与项目约定一致

不确定项不是"我写错了"——是"我写了，但 reviewer 请重点关注这里"。
    </uncertainty-marker>
  </step>
  <step priority="8">写入 <artifact>impl-report-{task-id}-{n}.md</artifact>。</step>
</instructions>

<stop-conditions>
  <condition priority="critical">scope-lock 自相矛盾或缺关键文件。</condition>
  <condition priority="critical">需要改白名单外文件才能完成 → 产出结构化扩展请求（见下），不写自然语言长报告。</condition>
  <condition priority="critical">发现可立即利用的安全漏洞、数据损坏风险或合规风险。</condition>
  <condition priority="critical">测试/构建环境缺失导致无法验证。</condition>
</stop-conditions>

<scope-expansion-template>
当发现必须修改白名单外文件时，产出 <artifact>scope-expand-{task-id}-{seq}.md</artifact>：

```markdown
# Scope 扩展请求：{task-id}-{seq}

## 需扩展的文件
- `path/file.ts` — 原因：{白名单内文件必须 import/调用/修改它才能完成}

## 不扩展的后果
- {不扩展的话，当前 scope 能做到哪一步？哪些完成标准无法满足？}

## 建议
- [ ] 扩展当前 scope-lock（加文件）
- [ ] 拆新 scope-lock（独立实现）
- [ ] 调度器判断
```

调度器凭此模板 30 秒可判断，无需读长报告。
</scope-expansion-template>

<targeted-revision mode="定向修订模式（驳回重做时）">
  <trigger>
当实现被 code-reviewer 驳回且满足以下条件时，进入定向修订模式而非全面重做：
    <condition>scope-lock 涉及文件数 ≥ 3</condition>
    <condition>review-code 的严重/一般问题集中在 ≤ 2 个文件</condition>
  </trigger>
  <behavior>
    <step priority="1">只读取有问题的文件 + review-code 中的审查意见</step>
    <step priority="2">仅修改问题文件，不改动其他白名单文件</step>
    <step priority="3">产出修订报告 <artifact>impl-report-{task-id}-{seq}_r{M}.md</artifact>（M 为修订轮次），格式精简：</step>
  </behavior>
  <revision-report-template>
```markdown
# 修订报告：{task-id}-{seq}（第 M 轮）

## 修改文件
- `path/file.ts:{行号}` → 修改描述

## 问题修复对照
| 审查意见 | 修复措施 |
|---------|---------|
| {严重/一般 问题摘要} | {具体修改} |
```
  </revision-report-template>
  <post-condition>不必重新跑所有测试，只跑受影响文件的测试 + scope-lock 验证命令</post-condition>
  <non-trigger>
    <case>严重问题涉及 scope-lock 白名单中 &gt;2 个文件 → 需全面重做</case>
    <case>问题涉及架构层面的契约变更 → 退回架构师，不走修订模式</case>
    <case>这是首轮实现（非驳回重做） → 走正常执行流程</case>
  </non-trigger>
</targeted-revision>

<report-requirements>
报告必须包含：修改文件、对应 scope-lock、验证命令与结果、未完成项、遗留问题。不要写长篇背景或解释代码细节。
</report-requirements>

<memory-protocol>
任务完成后，在返回前做一次自检：<emphasis>本次有没有产生跨任务可复用的事实？</emphasis> 如有任一条命中，必须写入 agent memory：

<memory-triggers>
  <trigger category="用户/团队偏好">如"该项目中文 commit message"、"不用 class component"、"禁用 any"</trigger>
  <trigger category="项目约束">如"生产 DB 不能 restart"、"某 API 有速率限制 X"、"某文件必须过 lint"</trigger>
  <trigger category="反模式">如"该命令需 sudo 但本项目 sudo 环境复杂"、"某库在本项目版本组合下有已知 bug"</trigger>
  <trigger category="失败教训">导致返工的根因</trigger>
</memory-triggers>

<write-path>
```
# 项目级 agent（frontmatter memory: project）
$CLAUDE_PROJECT_DIR/.claude/agent-memory/<your-agent-name>/<short-title>.md

# 用户级 agent（frontmatter memory: user）
$HOME/.claude/agent-memory/<your-agent-name>/<short-title>.md
```
</write-path>

<format-rule>3 句话能说清。超过 3 句的事实拆成多条。不确定是否值得记的一律不写。记住：负向不记、具体到单任务不记、重复已有 memory 不记。先 <cmd>mkdir -p</cmd> 目录再 Write，单个 memory 文件 ≤ 30 行。</format-rule>
</memory-protocol>

<references>
  <reference path="references/full-protocol.md" purpose="完整错误处理、测试、scope 合规细则"/>
  <reference path="references/engineering-discipline.md" purpose="10 条工程纪律（读回验证 / non-atomic 错误处理 / edit source 不 edit artifact / diagnose before fix / persist till done / 并行工具调用 / AGENTS.md / 不 destructive git）。综合自 Anthropic Word/Excel/PowerPoint agent + Codex + Jules 公开行为协议（已 attribution）。"/>
</references>

</skill>
