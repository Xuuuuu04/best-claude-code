<rule id="assurance-contract" severity="warning">
  <rationale>
    effort（深度/成本）与 assurance（审计严格度）是两个独立维度。
    历史上它们被混淆导致：高 effort 不保证强制审计执行。
    本规则将它们分离，使"草稿级快速迭代"和"交付级严格门控"可独立配置。
  </rationale>

  <section id="two-axes">
    <requirement>
      两轴分离：
      <table>
| 轴 | 控制 | 默认值 |
|:--|:--|:--|
| effort | 深度/成本（Agent 轮数、研究范围） | 继承会话默认值 |
| assurance | 审计严格度 — 静默跳过允许 vs 裁决必须 | 由 effort 推导（见映射表） |
      </table>
      可独立覆盖：<code>— effort: balanced, assurance: submission</code> 表示"正常深度，但每项审计必须发出裁决后最终化"。
    </requirement>
  </section>

  <section id="assurance-levels">
    <subsection id="draft">
      <requirement>
        <definition>draft</definition> — 当前行为，无破坏：
        <list>
          <item>审计仅在内容检测器匹配时运行</item>
          <item>允许静默跳过</item>
          <item>适用于：快速迭代、探索性草稿、内部讨论</item>
        </list>
      </requirement>
    </subsection>

    <subsection id="submission">
      <requirement>
        <definition>submission</definition> — 负载审计：
        <list>
          <item>所有强制审计<strong>必须</strong>发出裁决（六级之一）</item>
          <item>禁止静默跳过</item>
          <item>test-lead 裁决前调用 <cmd>bin/verify-artifacts.sh</cmd>；非零退出阻塞 verdict</item>
          <item>最终 verdict 标记 <code>submission-ready: yes/no</code></item>
          <item>适用于：交付/上线/投稿/客户验收</item>
        </list>
      </requirement>
    </subsection>
  </section>

  <section id="default-mapping">
    <requirement>
      effort → assurance 默认映射：
      <table>
| effort | 隐含 assurance |
|:-------|:---------------|
| lite | draft |
| balanced | draft |
| max | submission |
      </table>
    </requirement>
  </section>

  <section id="verdict-state-machine">
    <requirement>
      每项强制审计必须发出以下六级之一，不得静默跳过：
      <table>
| 裁决 | 含义 | 审计执行？ | submission 阻塞？ |
|:-----|:-----|:----------|:------------------|
| PASS | 全部通过 | 是 | 否 |
| WARN | 发现问题，但非取消资格 | 是 | 否 |
| FAIL | 发现取消资格问题 | 是 | <strong>是</strong> |
| NOT_APPLICABLE | 检测器阴性；无内容可审计 | 是（审计阶段已运行） | 否 |
| BLOCKED | 审计应运行但前提缺失 | 无法完成 | <strong>是</strong> |
| ERROR | 审计调用失败 | 已尝试但出错 | <strong>是</strong> |
      </table>
    </requirement>
    <note>
      <definition>NOT_APPLICABLE</definition> 与静默跳过的区别：前者写入 verdict artifact 证明"已检查，无内容"；后者不留记录，无法区分"已检查无内容"和"遗漏"。
    </note>
  </section>

  <section id="audit-artifact-schema">
    <requirement>
      每项强制审计必须写入 JSON artifact（可附带 Markdown 人类可读版本），至少包含：
      <code-block language="json"><![CDATA[
{
  "audit_skill": "code-reviewer",
  "verdict": "PASS",
  "reason_code": "all_checks_passed",
  "summary": "审查了 5 个文件，无安全问题。",
  "audited_input_hashes": {
    "src/auth.ts": "sha256:a3f8...",
    "src/api.ts": "sha256:b2d1..."
  },
  "generated_at": "2026-05-01T14:23:01Z"
}
      ]]></code-block>
    </requirement>
    <requirement>
      <code>audited_input_hashes</code> — 每项被审计文件的 SHA256。Verifier 重新计算当前文件哈希，不匹配则标记 <code>STALE</code>。
    </requirement>
  </section>

  <section id="subskill-contract">
    <requirement>
      子审计 Skill（code-reviewer、security-auditor 等）遵循"Always Emit, Never Block"合约：
      <list>
        <item>始终发出 verdict artifact，即使检测器阴性或出错</item>
        <item>自身不阻塞父流程 — 仅发出裁决</item>
        <item>阻塞决策集中在单一位置：test-lead 的 assurance 判断 + verify-artifacts.sh</item>
      </list>
    </requirement>
  </section>
</rule>
