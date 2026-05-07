---
name: bcc-update-memory
description: 更新项目 AutoMemory——汇总本会话所有 Agent 的可复用学习，递归更新所有 CLAUDE.md 的变更日志。当 Memory 积累到临界量时向用户提议架构进化升级（经审批后可拓展 Rule/新增 Skill/升级 Agent）。
argument-hint: "[focus?] (留空全量更新)"
disable-model-invocation: true
---

<skill name="bcc-update-memory" type="memory-evolution">

<overview>
更新项目 AutoMemory——汇总本会话所有 Agent 的可复用学习，递归更新所有 CLAUDE.md 的变更日志。当 Memory 积累到临界量时向用户提议架构进化升级，经审批后可拓展 Rule/新增 Skill/升级 Agent。
</overview>

<phases>

<phase id="1" name="会话活动审计">

<instructions>

<step id="1.1" title="从 subagent-events.jsonl 提取">
读取 <file>~/.claude/logs/subagent-events.jsonl</file>，过滤本 session_id 的事件。统计：
<stats>
  <stat key="派遣了哪些 Agent">按 agent_type</stat>
  <stat key="每个 Agent 的调用次数" />
  <stat key="各 Agent 的返回 token">IMPL_DONE / REVIEW_PASS / REVIEW_REJECT / TEST_PASS / TEST_BLOCKED / VERDICT_*</stat>
  <stat key="驳回和返工次数">REVIEW_REJECT 计数</stat>
  <stat key="是否触发 redeliberation">高级代码审查师 被同一 scope 调用 ≥2 次且返回 REJECT</stat>
</stats>
</step>

<step id="1.2" title="从 cost-log 提取">
读取项目 <file>.claude/logs/cost-log.txt</file>，统计本会话：
<stats>
  <stat key="总 turns 数" />
  <stat key="各 Agent 的平均 turns">识别 &gt;50 的高摩擦 scope</stat>
  <stat key="token 消耗分布" />
</stats>
</step>

<step id="1.3" title="从 artifact 提取">
扫描 <dir>.claude/artifacts/</dir> 中新产出的文件：
<stats>
  <stat key="哪些 scope-lock 已 accepted" />
  <stat key="哪些 impl-report 已产出" />
  <stat key="最新的 review 和 verdict 结果" />
  <stat key="reviewer 质量反馈段">质量总监 是否标记了漏审</stat>
</stats>
</step>

</instructions>

</phase>

<phase id="2" name="Agent 学习汇总">

<instructions>

<step id="2.1" title="逐 Agent 追问">
对每个本会话中派遣过的 Agent，根据其活动和 token 结果构造追问：

<question-template target="实现工程师" trigger="收到 IMPL_DONE">
"本轮实现中是否遇到了 scope-lock 不精确的地方（需要额外摸索/猜测）？只答有/没有。"
<follow-up condition="回答有">追问具体路径 + 原因 → 写入 agent-memory</follow-up>
</question-template>

<question-template target="高级代码审查师" trigger="发出过 REVIEW_REJECT">
"本轮驳回的根因中，是否有跨 scope 通用的模式（如某类字段判断容易出错）？只答有/没有。"
<follow-up condition="回答有">追问具体模式 → 写入 agent-memory</follow-up>
</question-template>

<question-template target="质量总监" trigger="发出过 VERDICT">
"本轮是否有 reviewer 漏审（reviewer PASS 但 tester 发现 [严重]/[一般]≥3）？"
<follow-up condition="回答有">记录漏审 reviewer + 漏审项 → 写入 agent-memory</follow-up>
</question-template>

<question-template target="all" trigger="通用追问">
"本轮是否产生了跨任务可复用的知识？只答有/没有。"
<follow-up condition="回答有">"请用 3 句话总结，一句话一条。" → 写入</follow-up>
</question-template>

</step>

<step id="2.2" title="硬追问（Memory 触发规则）">
以下场景<em>必须追问</em>，不可跳过：

<triggers>
  <trigger condition="同一 scope-lock REVIEW_REJECT ≥2 次" target="高级代码审查师" question="驳回根因是否可复用" />
  <trigger condition="实现工程师 turns >50" target="实现工程师" question="摸索时间是否源于 scope-lock 不精确" />
  <trigger condition="接口字段方向被 reviewer 揪出" target="实现工程师" question="是否已内化为检查项" />
  <trigger condition="质量总监 判定 reviewer 漏审" target="该 reviewer" question="漏审原因，如何防止重复" />
</triggers>

</step>

<step id="2.3" title="写入路径">
按 agent frontmatter 的 memory 字段：
<write-rules>
  <rule memory="project">→ $CLAUDE_PROJECT_DIR/.claude/agent-memory/{agent-name}/{short-title}.md</rule>
  <rule memory="user">→ $HOME/.claude/agent-memory/{agent-name}/{short-title}.md</rule>
</write-rules>
每条 ≤30 行。已有重复内容不重复写。先 mkdir -p 再写。
</step>

</instructions>

</phase>

<phase id="3" name="AutoMemory 更新">

<instructions>

<step id="3.1" title="索引更新">
在 <dir>~/.claude/projects/{project-slug}/memory/</dir> 下：
<procedure>
  <item order="1">读取 MEMORY.md 索引</item>
  <item order="2">按类型（user/feedback/project/reference）分类新条目</item>
  <item order="3">新条目写入对应主题文件</item>
  <item order="4">更新 MEMORY.md 索引，确保 ≤200 行</item>
</procedure>
</step>

</instructions>

</phase>

<phase id="4" name="递归更新所有 CLAUDE.md">

<instructions>

<step id="4.1" title="识别受影响目录">
从 git diff 和 impl-report 中提取本次修改的文件列表，映射到对应的目录 CLAUDE.md。
</step>

<step id="4.2" title="增量更新内容">
对每个受影响的 CLAUDE.md，<em>只做增量追加，不覆盖</em>其他段落：
<update-fields>
  <field name="变更日志">追加 | {日期} | {变更摘要} | {原因} |</field>
  <field name="进度">更新已完成/未完成/已知问题</field>
  <field name="文件与符号索引">新增/删除/重命名的文件和符号</field>
  <field name="对外 API">新增/修改/删除的接口</field>
</update-fields>
</step>

<step id="4.3" title="根 CLAUDE.md 同步">
汇总所有子目录变更到根 CLAUDE.md 的变更日志段。
</step>

</instructions>

</phase>

<phase id="5" name="项目级 Agent Memory 积累检测">

<instructions>

<step id="5.1" title="阈值统计">
统计以下指标：

<thresholds>
  <threshold metric="MEMORY.md 行数" limit="≥ 180" implication="接近上限，需固化" />
  <threshold metric="agent-memory 文件数" limit="≥ 15" implication="积累显著，可能存在通用模式" />
  <threshold metric="距上次 evolve 天数" limit="≥ 14" implication="时间驱动，定期审查" />
  <threshold metric="同一 pattern 条数" limit="≥ 3" implication="模式成熟，可固化为 Rule" />
</thresholds>

<gating>触发任一条件 → 进入阶段 6。</gating>

</step>

</instructions>

</phase>

<phase id="6" name="进化升级引擎">

<instructions>

<step id="6.1" title="系统理解前置（强制执行）">
<mandatory-note>在提议任何升级前，必须完整阅读以下文件。不完成此步骤 → 不得提议任何升级。不深入理解全系统的人无权改动它。</mandatory-note>

<reading-list>
  <file path="~/.claude/CLAUDE.md" reason="调度元协议——所有决策的根" />
  <file path="~/.claude/LEGION.md" reason="系统维护指南——设计哲学和机制速查" />
  <file path="~/.claude/output-styles/legion-dispatch.md" reason="调度器行为协议——档位自判/token 协议/再审议触发" />
  <file path="~/.claude/rules/_global/dispatch-table.md" reason="调度真源——路由规则/并发等级/门控条件/问题分级" />
  <file path="~/.claude/rules/_global/artifact-protocol.md" reason="Artifact 命名与生命周期" />
  <file path="~/.claude/rules/_global/dotclaude-layout.md" reason=".claude 目录布局规范" />
  <file path="~/.claude/rules/_global/skill-architecture-standard.md" reason="Skill 架构规范" />
  <file path="~/.claude/rules/_global/external-skill-source-policy.md" reason="外部素材引入策略" />
  <file path="~/.claude/rules/_global/hook-scripts-pattern.md" reason="Hook 脚本规范" />
  <file path="~/.claude/agents/" reason="全部 25 个 Agent 定义（至少读与拟议升级相关的）" />
  <file path="~/.claude/hooks/" reason="全部 Hook 脚本 + _lib/" />
  <file path="~/.claude/settings.json" reason="当前配置" />
  <file path="~/.claude/skills/" reason="全部 Skill（至少读相关分类）" />
</reading-list>
</step>

<step id="6.2" title="模式分析">
交叉比对 Memory 条目，识别：
<analysis-targets>
  <target>反复出现的 failure pattern → 候选 Rule</target>
  <target>反复出现的知识缺口 → 候选 Skill</target>
  <target>反复出现的认知盲区 → 候选 Agent 升级</target>
  <target>反复出现的调度失误 → 候选 dispatch-table 优化</target>
</analysis-targets>
</step>

<step id="6.3" title="生成进化提案">
<template-output format="markdown">

# 进化提案：{日期}

## 数据依据
- 本次会话 Agent 派遣 {N} 次，驳回 {M} 次，redeliberation {R} 次
- cost-log 显示平均 turns {avg}，最高 {max}
- 新积累 agent-memory {K} 条

## 检测到的模式
1. {模式} — 出现 {N} 次 — 来源 {memory 路径}
2. ...

## 建议升级（逐项审批）

### 提案 1：{类型 — Rule / Skill / Agent 升级 / dispatch-table}
- **当前问题**：{描述 + 证据}
- **建议方案**：{具体改动 + 文件路径}
- **与现有设计的兼容性**：{是否冲突/补充/替代哪个现有机制}
- **影响范围**：{哪些 Agent/Skill/流水线受影响}
- **回退方式**：{git revert 或手动回退步骤}
- **风险**：{低/中/高 — 具体原因}

</template-output>

<mandatory-note>用户未 approve 的提案绝不执行。</mandatory-note>
</step>

<step id="6.4" title="可提议的升级范围">
<upgrade-scope>
  <scope type="新增/修改 Rule" condition="≥2 条相似 memory" constraint="必须有 paths frontmatter；验证不误触发" />
  <scope type="修改 Skill" condition="≥3 条相关 feedback" constraint="保持 SKILL.md ≤500 行；长内容进 references" />
  <scope type="新 Skill" condition="≥3 次同一类问题未被现有 Skill 覆盖" constraint="遵守 skill-architecture-standard" />
  <scope type="Agent 升级（改 prompt/tools/skills）" condition="基于明确的认知缺口" constraint="不改变 Agent 的核心认知模式" />
  <scope type="新增 Agent" condition="基于现有 39 Agent 无法覆盖的认知模式" constraint="极高门槛：必须证明旧角色无法覆盖、非按技术栈加人" />
  <scope type="dispatch-table 优化" condition="基于调度失误的 pattern" constraint="不破坏现有门控条件" />
</upgrade-scope>
</step>

<step id="6.5" title="执行与验证">
对批准的提案：
<procedure>
  <item order="1">执行修改</item>
  <item order="2">运行 <cmd>bash ~/.claude/bin/doctor.sh</cmd>（至少 §1/§2/§3/§17）</item>
  <item order="3">如有新 hook → 在 hook-flags.sh 登记</item>
  <item order="4">如有新 Agent → 在相应 Skill 的 when_to_use 中引用</item>
  <item order="5">更新 LEGION.md 进化历史</item>
  <item order="6">向用户报告执行结果</item>
</procedure>
</step>

</instructions>

</phase>

<phase id="7" name="收尾">

<instructions>

<step id="7.1" title="最终检查">
<procedure>
  <item>运行 <cmd>bash ~/.claude/bin/doctor.sh</cmd> 全系统健康检查</item>
  <item>检查 CLAUDE.md 行数（项目根 + 系统全局均 ≤200）</item>
  <item>归档超 30 天的 artifact</item>
  <item>清理 agent-memory 中重复条目</item>
</procedure>
</step>

</instructions>

</phase>

</phases>

<output>
产出/更新文件：
<artifact-list>
  <artifact>~/.claude/projects/{project-slug}/memory/MEMORY.md（索引更新）</artifact>
  <artifact>~/.claude/projects/{project-slug}/memory/ 下对应主题文件</artifact>
  <artifact>$CLAUDE_PROJECT_DIR/.claude/agent-memory/{agent-name}/*.md（新 memory）</artifact>
  <artifact>各受影响目录 CLAUDE.md（变更日志增量）</artifact>
  <artifact>进化提案（如触发）</artifact>
</artifact-list>
</output>

</skill>
