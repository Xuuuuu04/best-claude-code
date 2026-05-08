---
name: bcc-teams
description: Agent Teams 并行协作模式。多个 Teammate 在 Team Lead 指挥下并行工作，适用于大型任务（≥2 独立 scope-lock）。Teammate 各自隔离上下文、通过消息协议协调、共享任务列表和 mailbox。需 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 环境变量启用。
argument-hint: "{任务描述}"
disable-model-invocation: true
---

<skill name="bcc-teams" type="agent-teams-parallel-collaboration">

<overview>
Agent Teams 并行协作模式。多个 Teammate 在 Team Lead 指挥下并行工作，适用于大型任务（≥2 独立 scope-lock）。Teammate 各自隔离上下文、通过消息协议协调、共享任务列表和 mailbox。并发等级 S4（最高）。需 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 环境变量启用。
</overview>

<prerequisites>
<checklist>
  <check id="1" label="环境变量 CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 已设置">
    <fail>→ 拒绝启动，提示用户设置环境变量后重试</fail>
  </check>
  <check id="2" label="项目已有 .claude/CLAUDE.md">
    <fail>→ 先运行 /bcc-init-project</fail>
  </check>
  <check id="3" label="doctor 健康检查通过">
    <cmd>bash ~/.claude/bin/doctor.sh</cmd>
    <fail>→ 先修复 doctor 报告的 FAIL 项</fail>
  </check>
  <check id="4" label="当前分支干净（git status --porcelain 为空或仅含 .claude/ 下文件）">
    <fail>→ 先 commit 或 stash 未提交变更</fail>
  </check>
  <check id="5" label="任务档位 large 且涉及 ≥2 个独立 scope-lock">
    <fail>→ 退回到 /bcc-loop-dev 或自然语言调度</fail>
  </check>
  <check id="6" label="用户已明确同意启用 Agent Teams 模式">
    <fail>→ AskUserQuestion 确认</fail>
  </check>
</checklist>
</prerequisites>

<when-to-use>
<applicable>
  <item>任务档位 large，涉及 ≥2 个独立 scope-lock 区域</item>
  <item>scope-lock 文件白名单无交集</item>
  <item>各子任务可独立实现和验证，无需实时等待其他子任务产出</item>
  <item>典型场景：前后端并行开发、多模块独立功能、多平台同时适配</item>
</applicable>

<not-applicable>
  <item>任务档位 small/medium，子任务间强耦合</item>
  <item>仅涉及单文件或紧密关联的多文件修改</item>
  <item>子任务输出是另一子任务的输入（有依赖链）</item>
  <item>涉及数据库迁移、全局配置修改、生产部署等不可并行操作</item>
  <item>scope-lock 文件白名单有交集</item>
</not-applicable>
</when-to-use>

<core-principles>
<principle id="team-lead-authority">Team Lead（主会话/调度器）负责任务分解、Teammate 分配、冲突检测、回收汇总和最终交付。Teammate 不自行决定跨 scope 事项。</principle>
<principle id="scope-isolation">每个 Teammate 严格限定在自己的 scope-lock 文件白名单内操作。白名单外修改 = scope 越界，立即终止该 Teammate。</principle>
<principle id="message-protocol">Teammate 间通过 SendMessage 通信，Team Lead 通过 Shift+Down 操控。禁止直接读写其他 Teammate 的 artifact。</principle>
<principle id="fail-fast">Teammate 失败时立即报告 Team Lead，不自行重试或降级。Team Lead 决定是重新派遣还是串行回退。</principle>
<principle id="s4-concurrency">并发等级 S4——Teammates 各自隔离上下文，通过消息协调；共享任务列表和 mailbox；文件白名单无交集。</principle>
</core-principles>

<teammate-assignment-strategy>
Teammate 分配依据 <rule-ref>rules/_global/dispatch-table.md</rule-ref> 路由表：

<assignment-matrix>
  <assign signal="Web 前端 / UI 代码实现" teammate="高级前端工程师" scope-prefix="scope-lock-frontend" />
  <assign signal="后端 / API / 服务端逻辑实现" teammate="高级后端工程师" scope-prefix="scope-lock-backend" />
  <assign signal="iOS / Android / Flutter / RN" teammate="高级移动端工程师" scope-prefix="scope-lock-mobile" />
  <assign signal="桌面应用 / Electron / Tauri" teammate="高级桌面应用工程师" scope-prefix="scope-lock-desktop" />
  <assign signal="微信小程序 / uni-app" teammate="小程序开发专家" scope-prefix="scope-lock-miniapp" />
  <assign signal="数据库 schema / 迁移" teammate="资深数据库工程师" scope-prefix="scope-lock-db" />
  <assign signal="训练模型 / 推理服务" teammate="机器学习工程师" scope-prefix="scope-lock-ml" />
</assignment-matrix>

<assignment-rules>
  <rule>每个 scope-lock 恰好分配一个 Teammate</rule>
  <rule>同一 Teammate 可负责多个 scope-lock（如 2 个前端 scope），但必须串行执行</rule>
  <rule>路由不明的子任务 → 派 项目管理师 判定</rule>
  <rule>Teammate 引用 Subagent 定义时，skills 和 mcpServers 不继承——需在项目/用户设置中配置</rule>
</assignment-rules>
</teammate-assignment-strategy>

<message-protocol>
Teammate 间通信协议：

<message-types>
  <msg type="TASK_START" direction="Lead → Teammate" payload="scope-lock 定义、文件白名单、验收标准、依赖 artifact 路径" />
  <msg type="PROGRESS" direction="Teammate → Lead" payload="当前步骤、完成百分比、阻塞项" />
  <msg type="IMPL_DONE" direction="Teammate → Lead" payload="impl-report-* artifact 路径、修改文件列表" />
  <msg type="BLOCKED" direction="Teammate → Lead" payload="阻塞原因、需要的输入/决策、建议方案" />
  <msg type="CROSS_SCOPE_QUERY" direction="Teammate → Lead → Other Teammate" payload="需要确认的接口/契约/共享类型" />
  <msg type="CROSS_SCOPE_REPLY" direction="Other Teammate → Lead → Requester" payload="确认结果、契约定义、类型签名" />
  <msg type="TERMINATE" direction="Lead → Teammate" payload="终止原因（scope 越界/超时/失败）" />
</message-types>

<protocol-rules>
  <rule>Teammate 不直接向其他 Teammate 发消息——所有跨 scope 通信经 Team Lead 中转</rule>
  <rule>CROSS_SCOPE_QUERY 必须包含具体问题，不允许模糊询问</rule>
  <rule>Team Lead 在中转 CROSS_SCOPE_REPLY 时验证回答的完整性和一致性</rule>
  <rule>PROGRESS 消息每完成一个 step 发送一次，不频繁轮询</rule>
  <rule>BLOCKED 消息必须附带建议方案，不允许只报问题不给方案</rule>
</protocol-rules>
</message-protocol>

<phases>

<phase id="1" name="任务分解">

<instructions>

<step id="1.1" title="需求分析">
派 资深需求分析师 → 产出 requirements
<next>→ 高级需求审查师（含对抗性压力测试）</next>
</step>

<step id="1.2" title="架构设计">
派 资深系统架构师 → 产出 architecture
<next>→ 高级架构审查师（含断点分析）</next>
</step>

<step id="1.3" title="范围锁定与并行规划">
派 资深范围规划师 → 产出 scope-lock[] + scope-plan
<requirements>
  <item>每个 scope-lock 必须有独立的文件白名单，白名单间无交集</item>
  <item>scope-plan 必须标注哪些 scope-lock 可并行（同一 Batch）</item>
  <item>标注跨 scope 接口契约（共享类型/API 签名/事件格式）</item>
  <item>标注集成风险点（接口字段类型、状态机边界、同名不同义字段）</item>
</requirements>
</step>

</instructions>

</phase>

<phase id="2" name="团队组建">

<instructions>

<step id="2.1" title="Teammate 分配">
依据 <rule-ref>rules/_global/dispatch-table.md</rule-ref> 路由表，为每个 scope-lock 分配 Teammate：
<procedure>
  <item>读取 scope-plan 中的并行批次</item>
  <item>按 assignment-matrix 匹配 Teammate</item>
  <item>验证每个 Teammate 的文件白名单无交集</item>
  <item>生成 Team Roster：Teammate ID + Agent 角色 + scope-lock + 文件白名单</item>
</procedure>
</step>

<step id="2.2" title="契约对齐">
在 Teammates 启动前，Team Lead 确认跨 scope 接口契约：
<procedure>
  <item>提取所有 scope-lock 间的共享类型定义</item>
  <item>确认 API 签名（请求/响应字段、枚举值方向）</item>
  <item>将契约写入共享 artifact 供 Teammates 引用</item>
  <item>接口字段对账按 <rule-ref>rules/_global/dispatch-table.md#field-reconciliation</rule-ref> 执行</item>
</procedure>
</step>

<step id="2.3" title="并行安全声明">
输出并发声明：
<code-block language="text"><![CDATA[
Agent Teams 并行批次：Batch {n}
对象：{Teammate-1} / {Teammate-2} / ...
依据：scope-lock 白名单无交集；无依赖关系；输出 artifact 不冲突
回收：全部 Teammates idle → Lead 汇总 → 进入 高级代码审查师
风险：共享环境 {无 / 有，处理方式}
]]></code-block>
</step>

</instructions>

</phase>

<phase id="3" name="并行执行">

<instructions>

<step id="3.1" title="启动 Teammates">
对同一 Batch 内的所有 Teammates 并行发送 TASK_START：
<procedure>
  <item>每个 Teammate 收到：scope-lock 定义 + 文件白名单 + 验收标准 + 共享契约 artifact</item>
  <item>Team Lead 监控 PROGRESS 消息</item>
  <item>TeammateIdle hook 可发送反馈让 teammate 继续工作（exit code 2）</item>
</procedure>
</step>

<step id="3.2" title="跨 scope 通信处理">
当收到 CROSS_SCOPE_QUERY 时：
<procedure>
  <item>Team Lead 验证查询的合理性（是否真的需要跨 scope 信息）</item>
  <item>转发给目标 Teammate 或直接从共享契约 artifact 回答</item>
  <item>记录所有跨 scope 通信到 mailbox</item>
</procedure>
</step>

<step id="3.3" title="IMPL_DONE 回收">
每个 Teammate 完成后发送 IMPL_DONE：
<procedure>
  <item>Team Lead 验证产出文件是否在白名单内</item>
  <item>验证 artifact 路径唯一且无冲突</item>
  <item>收集所有 IMPL_DONE 后进入下一阶段</item>
</procedure>
</step>

</instructions>

</phase>

<phase id="4" name="集成">

<instructions>

<step id="4.1" title="代码审查">
串行派 高级代码审查师，对每个 Teammate 的产出逐一审查：
<procedure>
  <item>审查维度含：跨 scope 接口一致性、白名单合规性、契约对账</item>
  <item>接口字段对账按 <rule-ref>rules/_global/dispatch-table.md#field-reconciliation</rule-ref> 执行</item>
</procedure>
<branch>
  <case condition="REVIEW_REJECT">→ 退回对应 Teammate 修复（max 3 轮 redeliberation）</case>
  <case condition="REVIEW_PASS">→ 继续</case>
</branch>
</step>

<step id="4.2" title="安全审计">
<condition>如涉后端/认证/支付/数据库</condition>：派 高级安全审计师（OWASP + 7 维业务逻辑攻击）
</step>

<step id="4.3" title="跨 scope 一致性检查">
<condition>scope-lock ≥ 3</condition>：派 质量总监 含跨 scope 接口契约交叉比对
<checklist>
  <check>共享类型定义是否一致</check>
  <check>API 签名（字段名/类型/枚举方向）是否对齐</check>
  <check>事件格式是否匹配</check>
  <check>同名不同义字段是否已区分</check>
</checklist>
</step>

</instructions>

</phase>

<phase id="5" name="验证">

<instructions>

<step id="5.1" title="功能测试">
派 高级功能测试师（验收 + 边界 + 回归 + 跨 scope 集成测试）
</step>

<step id="5.2" title="视觉测试">
<condition>如涉 UI</condition>：派 高级视觉测试师（5 状态截图证据）
</step>

<step id="5.3" title="最终裁决">
质量总监 汇总 functional + visual + security + 跨 scope 一致性 + reviewer 质量反馈
<verdict-branch>
  <case condition="VERDICT_PASS">→ git commit + push → 交付</case>
  <case condition="VERDICT_CONDITIONAL">→ 人工确认</case>
  <case condition="VERDICT_BLOCKED">→ 回到 Phase 1 修复</case>
</verdict-branch>
</step>

</instructions>

</phase>

</phases>

<error-handling>

<teammate-failure>
当 Teammate 失败时的处理策略：

<failure-matrix>
  <case condition="Teammate 超时（无 PROGRESS 消息超过预期 2 倍时间）" action="Team Lead 发送 TERMINATE → 评估是否重新派遣同一 Agent 或换 Agent → 如无法恢复，该 scope 退回串行模式" />
  <case condition="Teammate 报 BLOCKED" action="Team Lead 评估阻塞原因 → 如可解决则提供输入 → 如需其他 Teammate 产出则等待 → 如无法解决则该 scope 退回串行模式" />
  <case condition="Teammate scope 越界（修改白名单外文件）" action="立即 TERMINATE → git checkout 恢复白名单外文件 → 该 scope 重新派遣" />
  <case condition="Teammate 产出 artifact 路径冲突" action="后完成的 Teammate TERMINATE → 调整 artifact 路径 → 重新派遣" />
  <case condition="连续 2 个 Teammate 在同一 scope 失败" action="暂停 Agent Teams 模式 → 退回到 /bcc-loop-dev 串行处理该 scope" />
  <case condition="Batch 内超过半数 Teammate 失败" action="暂停整个 Agent Teams 模式 → 退回到 /bcc-loop-dev → 报告用户系统性问题" />
</failure-matrix>
</teammate-failure>

<recovery-strategy>
<degradation>
  <stage level="单 Teammate 降级">失败 Teammate 的 scope 改为串行，其他 Teammate 继续</stage>
  <stage level="Batch 降级">当前 Batch 全部串行重跑</stage>
  <stage level="模式降级">退回到 /bcc-loop-dev，所有剩余 scope 串行处理</stage>
</degradation>

<rule>降级决策由 Team Lead 做出，不自动降级。每次降级需向用户汇报原因和影响。</rule>
</recovery-strategy>

</error-handling>

<safety-constraints>
<constraint severity="blocker">
  <item>Teammates 引用 Subagent 定义时，skills 和 mcpServers 不继承——需在项目/用户设置中配置</item>
  <item>并发安全仍由 dispatch-table S0-S4 等级控制</item>
  <item>Team Lead 负责文件冲突检测和回收顺序</item>
  <item>TeammateIdle hook 可发送反馈让 teammate 继续工作（exit code 2）</item>
  <item>涉及数据库迁移、生产部署、全局配置修改 → 必须串行，不得并行</item>
  <item>同一文件、同一目录生成物、同一测试数据库、同一浏览器 session → 禁止分配给不同 Teammate</item>
  <item>安全漏洞发现 → 立即暂停所有 Teammates，等用户决策</item>
</constraint>
</safety-constraints>

<thresholds>

<safety-valves>
  <valve condition="同一 scope-lock 迭代 ≥5 轮仍未 PASS" action="暂停，报告用户——scope 可能有根本缺陷" />
  <valve condition="连续 3 个 Teammate 均失败" action="暂停 Agent Teams 模式，退回 /bcc-loop-dev" />
  <valve condition="总 Teammate 派遣次数 ≥50" action="暂停，汇报进度+消耗，请用户确认继续" />
  <valve condition="质量总监 连续 2 次 CONDITIONAL PASS" action="视为 PASS（条件已足够轻微）" />
  <valve condition="安全漏洞发现" action="立即暂停所有 Teammates，等用户决策" />
</safety-valves>

</thresholds>

<progress-report>
每个 Batch 完成后：
<template>
[teams] Batch {n}/{total} 完成
  Teammates: {成功数}/{总数}
  git: {commit hash} — {commit message}
  消耗: {本次派遣数} 派遣 / {累计} 累计
  跨 scope 通信: {查询数} queries / {阻塞数} blocked
</template>
每 10 次 Teammate 派遣汇报 token 消耗。
</progress-report>

<resume>
中断后可通过描述续跑。bcc-teams 自动扫描 artifact 状态，跳过已 accepted 的 scope，从断点继续。续跑时重新评估 Teammate 分配——如之前有 Teammate 失败，优先串行补完。
</resume>

<output>
Git commits + artifact 文件（由 Teammates 和审查 Agent 产出）。
</output>

</skill>
