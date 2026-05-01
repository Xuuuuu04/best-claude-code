<rule id="reviewer-independence" severity="warning">
  <rationale>
    跨 Agent 审稿的有效性依赖于审稿者独立形成判断。如果执行者预处理、摘要或解释内容后再传给审稿者，审稿者评估的是执行者的 framing 而非实际工作——这重新引入了异构审稿本欲避免的相关盲区。
  </rationale>

  <section id="core-principle">
    <requirement>
      **内容必须以未过滤形式到达审稿者。** 执行者指向文件并设定审稿任务；审稿者独立读取并判断。
    </requirement>
  </section>

  <section id="allowed-content">
    <requirement>
      可以传递给审稿者的内容：
      <list>
        <item>角色/人设 — e.g., "作为资深代码审查员审阅"</item>
        <item>审稿目标 — e.g., "检查安全性漏洞"</item>
        <item>文件路径 — 让审稿者直接读取文件内容</item>
        <item>结构元数据 — e.g., "项目有 5 个核心模块"</item>
        <item>约束条件 — e.g., "Python 3.12, Django 4.2"</item>
      </list>
    </requirement>
  </section>

  <section id="forbidden-content">
    <constraint severity="warning">
      禁止传递给审稿者的内容（视为"主观干扰"）：
      <list>
        <item>执行者对文件内容的摘要或改写</item>
        <item>执行者对结果的解释（e.g., "我认为问题是...", "这说明..."）</item>
        <item>执行者的建议或结论（e.g., "我建议修改...", "可能的原因是..."）</item>
        <item>执行者提取的关键发现或要点</item>
        <item>引导性问题（e.g., "这是否可上线？"）</item>
        <item>之前审稿轮次的反馈（让审稿者从头评估当前状态）</item>
        <item>执行者描述自上次以来的修改（e.g., "我修了 X, Y, Z"）</item>
        <item>断言当前方法优势的陈述</item>
      </list>
    </constraint>
  </section>

  <section id="agent-legion-mapping">
    <requirement>
      Agent Legion 中的具体应用：
      <table>
| 执行者 | 审稿者 | 传递限制 |
|:--|:--|:--|
| implementer-* | code-reviewer | 仅文件路径 + artifact 路径，无实现摘要 |
| implementer-* | security-auditor | 仅文件路径，无安全上下文解释 |
| implementer-* | functional-tester | 仅功能范围和测试命令，无实现说明 |
| implementer-* | visual-tester | 仅 UI 文件路径，无设计意图解释 |
| academic-paper-writer | academic-paper-reviewer | 仅论文文件路径，无写作意图 |
| tech-researcher / repo-researcher | research-reviewer | 仅研究 artifact 路径 |
| doc-writer / creative | content-reviewer | 仅文档 artifact 路径 |
      </table>
    </requirement>
  </section>

  <section id="exceptions">
    <note>
      同一 Agent 内部的多轮自我审查不受此限制——此规则只约束<strong>不同 Agent 之间</strong>的审查传递。
    </note>
  </section>

  <section id="enforcement">
    <requirement>
      审查者发现执行者违反本规则时，应在审查报告中标记 <tag>[一般] reviewer-independence 违规</tag>，累计 ≥3 项视为驳回条件之一。
    </requirement>
  </section>
</rule>
