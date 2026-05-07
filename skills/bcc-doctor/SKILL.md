---
name: bcc-doctor
description: Agent Legion 系统健康检查。扫描配置合法性、hook 可执行性、Agent/Skill/Rule 一致性、Memory 容量、artifact 堆积、日志大小、近期错误。建议每周跑一次。
argument-hint: "[--strict | --quick | <section?>]"
disable-model-invocation: true
---

<skill name="bcc-doctor" type="system-diagnostics">

<overview>
Agent Legion 系统健康检查。扫描配置合法性、hook 可执行性、Agent/Skill/Rule 一致性、Memory 容量、artifact 堆积、日志大小、近期错误。整个过程由一个 bash 脚本完成，不派遣任何 subagent——诊断必须是确定性的。
</overview>

<execution>
<primary-cmd>bash ~/.claude/bin/doctor.sh</primary-cmd>
</execution>

<phases>

<phase id="1" name="执行与报告解读">

<instructions>

<step id="1.1" title="执行诊断脚本">
直接运行 bash 脚本，无需人工干预。
</step>

<step id="1.2" title="解读 10 章节报告">
输出分为 10 个章节：

<section-summary>
  <section id="1" name="Configuration">settings.json 合法性、CLAUDE.md 行数</section>
  <section id="2" name="Hooks">脚本可执行、bash 语法、是否有危险的 set -e 陷阱</section>
  <section id="3" name="Agents">每个 Agent 定义的 frontmatter 合规性</section>
  <section id="4" name="Skills">扁平结构检查（不允许嵌套）+ description 长度</section>
  <section id="5" name="Rules">调用 validate-rules.sh（检查死 glob、重复名）</section>
  <section id="6" name="Memory">Auto Memory 和 Agent Memory 容量接近 200 行告警</section>
  <section id="7" name="Artifacts">当前项目堆积的 artifact 数量和过期项</section>
  <section id="8" name="Logs">所有日志文件大小，超阈值提示轮转</section>
  <section id="9" name="Recent Hook Errors">近期 hook 失败事件摘要</section>
  <section id="10" name="MCP">服务器数量 + PAT 占位符检查</section>
</section-summary>

</step>

</instructions>

</phase>

</phases>

<thresholds>

<triggers>
当以下情况时运行 doctor：
<item>每周一次定期体检</item>
<item>系统行为异常时（比如某个 Rule 不生效）</item>
<item>配置大改后（新增 Agent / Skill / Rule）</item>
<item>升级 Claude Code 版本后</item>
</triggers>

<exit-codes>
<code value="0">全部健康 或 仅警告</code>
<code value="1">有失败项（FAIL），需要立即修复</code>
</exit-codes>

</thresholds>

<related-tools>
<tool cmd="bash ~/.claude/bin/validate-rules.sh" desc="详细 Rule 检查" />
<tool cmd="bash ~/.claude/bin/cost-summary.sh" desc="成本汇总" />
<tool cmd="bash ~/.claude/bin/rotate-logs.sh" desc="日志轮转" />
</related-tools>

<output>
诊断报告（stdout），无文件产出。
</output>

</skill>
