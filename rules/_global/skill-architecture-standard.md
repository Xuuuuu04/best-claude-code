---
name: skill-architecture-standard
description: Skill 目录结构、frontmatter、长度上限和 progressive disclosure 规范。所有 Skill 创建/审查时遵守。
type: meta-rule
scope: global
applies-to: skills/**/SKILL.md
---

<rule id="skill-architecture-standard" severity="blocker">
  <section id="official-compatibility">
    <constraint severity="blocker">
      <list>
        <item>每个 Skill 必须是一个目录，入口文件为 <path>SKILL.md</path>。</item>
        <item><path>SKILL.md</path> 必须包含 YAML frontmatter，至少写 <field>name</field> 与 <field>description</field>。</item>
        <item><field>description</field> 前置触发条件，必要时补 <field>when_to_use</field>，两者合计保持精确，避免泛化触发。</item>
        <item>长参考、模板、示例和脚本放到 supporting files，如 <path>references/</path>、<path>examples/</path>、<path>scripts/</path>。</item>
        <item>主 <path>SKILL.md</path> 应作为导航和短协议，避免超过 500 行。</item>
      </list>
    </constraint>
  </section>

  <section id="naming-conventions">
    <table>
| 后缀 | 含义 | 适用场景 |
|:--|:--|:--|
| `*-protocol` | 流程协议 | reviewer / tester 的审查流程 |
| `*-checklist` | 检查清单 | 合并进对应 protocol 的 `references/` |
| `*-patterns` | 知识参考 | 设计 / 架构类 agent 的模式库 |
| `*-development` | 领域知识 | 实现工程师 的技术栈知识 |
| `*-intake` | 输入整理 | intake 类 agent 的整理方法 |
| `bcc-*` | 调度命令 | 主会话流水线入口（disable-model-invocation） |
    </table>
  </section>

  <section id="legion-constraints">
    <constraint severity="blocker">
      Agent Legion 约束：
      <list>
        <item>用户级 Skill 不得包含具体项目事实；项目事实写入项目级 <path>.claude/skills/project-knowledge/</path>。</item>
        <item>文件类 Skill 必须包含验证步骤和输出路径汇报要求。</item>
        <item>审查类 Skill 必须区分 <token>BLOCKED</token> / <token>FAILED</token> / <token>WARNING</token> / <token>PASS</token>。</item>
        <item>外部泄漏 prompt 只能转化为结构模式，不得复制原文。</item>
        <item>新 Skill 接入 Agent 前，先检查预加载行数预算；默认通过自动触发优于无差别预加载。</item>
      </list>
    </constraint>
  </section>
</rule>
