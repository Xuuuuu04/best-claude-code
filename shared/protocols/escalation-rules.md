---
name: escalation-rules
description: 升级处理规则 v1.1
protocol: true
---

<harness-protocol>
  <section id="overview">
    <title>升级处理规则 v1.1</title>
    <content>
<p>当 Agent 遇到超出自身职责范围的问题时，必须通过升级机制将问题传递给能处理它的角色，而不是自行决策或忽略。</p>
    </content>
  </section>

  <section id="tech-escalation">
    <title>技术实现升级路径</title>
    <content>
<p>后端开发师/前端开发师/机器学习工程师 → 开发组长 → 架构师</p>
<p>触发条件：开发 Agent 在实现过程中发现技术方案有缺陷或不可行，或者需要引入新的架构模式。</p>
<p>升级方式：开发 Agent 返回 BLOCKED 状态，阻塞说明中写明技术问题的具体描述。</p>
    </content>
  </section>

  <section id="requirement-escalation">
    <title>需求升级路径</title>
    <content>
<p>开发组长/测试总监师 → 项目管理师 → 客户沟通师 → 人工（用户本人）</p>
<p>触发条件：需求描述有歧义导致无法确定正确的实现方向，或测试中发现需求本身存在矛盾。</p>
<p>升级方式：返回 BLOCKED 状态，说明需求层面的具体问题。</p>
    </content>
  </section>

  <section id="domain-escalation">
    <title>领域知识升级路径</title>
    <content>
<p>开发组长/机器学习工程师 → 深度研究员 → 人工（用户本人）</p>
<p>触发条件：当前 Task 依赖特定领域知识（学术方法、法律法规、行业规则）且团队中没有现成结论。</p>
<p>升级方式：返回 BLOCKED 状态，说明缺的领域知识方向，建议调用 深度研究员。</p>
    </content>
  </section>

  <section id="creative-escalation">
    <title>创意方向升级路径</title>
    <content>
<p>客户沟通师/项目管理师/前端开发师 → 创意策划师 → 人工（用户本人）</p>
<p>触发条件：产品需要命名、Slogan、文案方向，品牌调性等创意决策，但客户和现有材料都没给明确口径。</p>
<p>升级方式：返回 BLOCKED 状态，说明需要什么类型的创意输出，建议调用 创意策划师。</p>
    </content>
  </section>

  <section id="quality-escalation">
    <title>质量升级路径</title>
    <content>
<p>代码审计师 → 开发组长（如果是方案层面的问题）
功能测试师 → 测试总监师 → 项目管理师（如果是反复修复仍无法通过的问题）</p>
<p>触发条件：同一个 Task 连续 3 轮审查或测试未通过。</p>
<p>升级方式：测试总监师在判定中建议项目管理师重新评估该 Task 的技术方案。</p>
    </content>
  </section>

  <section id="cost-escalation">
    <title>成本升级路径</title>
    <content>
<p>任何 Agent → 项目管理师 → 人工（用户本人）</p>
<p>触发条件：发现任务的实际工作量远超预估，或需要引入额外的付费服务/API/算力。</p>
<p>升级方式：返回 BLOCKED 状态，说明成本影响。</p>
    </content>
  </section>

  <section id="data-escalation">
    <title>数据升级路径</title>
    <content>
<p>机器学习工程师 → 项目管理师 → 客户沟通师 → 人工</p>
<p>触发条件：训练需要更多数据、标注质量不够、或数据合规性存疑。</p>
<p>升级方式：返回 BLOCKED 状态，写明缺的数据类型、规模和来源建议。</p>
    </content>
  </section>

  <section id="iron-rules">
    <title>升级的铁律</title>
    <content>
<ol>
<li>Agent 绝不能在升级应该发生的时候选择"将就着做"。一个有疑问的技术方案如果被强行实现，后果是代码审查发现问题 → 打回 → 修复 → 再审查，反而浪费更多成本。</li>
<li>升级时必须提供充足的上下文，不能只说"方案有问题"，必须说"方案第 3 点要求使用 WebSocket，但目标服务器不支持长连接，建议改为 SSE 或轮询"。</li>
<li>被升级到的 Agent 必须在处理完后把结论写回 Task 文件，让原始 Agent 在重新启动时能看到解决方案。</li>
<li>升级路径不能跳跃。例如后端开发师不能直接升级到架构师，必须先经过开发组长或项目管理师的判断。</li>
</ol>
    </content>
  </section>
</harness-protocol>
