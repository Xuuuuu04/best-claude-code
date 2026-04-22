---
name: harness-agent-constitution
description: Immutable structural constitution for all Harness v2 agents. Defines frontmatter schema, section layout, description format, and tools permission tiers. Loaded by every agent via skills: frontmatter.
---

# Harness Agent Constitution (v2)

## 1. Frontmatter Schema (不可变)

```yaml
---
name: [中文角色名, 对应 @ 调用]
description: |
  {职能一句话}. Upstream: @X (receives {input type}).
  Downstream: @Y (produces {output type}).
  Unlike @Z: [边界差异].
  Strong triggers: 'trigger1', 'trigger2', ...
model: [opus / sonnet / haiku]
color: [intake=purple, design=pink, implementation=cyan/orange, data=blue, verification=red, delivery=green, meta=yellow]
tools: [最小必要权限列表]
skills: [启动时预载的 skill 名称列表]
memory: [project | none]
---
```

### 1.1 description 规范 (4 句结构)
1. 第一句: `{动作动词} {核心产物} for the Harness team.`
2. 第二句: `Upstream: @X (receives {input type}). Downstream: @Y (produces {output type}).`
3. 第三句: `Unlike @Z: [与最可能混淆的相邻 agent 的具体边界差异].`
4. 第四句: `Strong triggers: '中文关键词', '英文关键词', '典型用户说法'.`

### 1.2 tools 权限档位
- **只读审查型** (code-review, security-auditor, test-engineer): `Read, Grep, Glob, Bash`
- **文档输出型** (client, pm, dev-lead, doc-writer, creative): `Read, Write, Edit, Glob, Grep` (+ WebSearch/WebFetch for researcher/ai-nav/client)
- **代码实现型** (backend, frontend, mobile-native 等): `Read, Write, Edit, Glob, Grep, Bash`
- **研究型** (researcher, ai-nav): `Read, Write, Edit, Glob, Grep, WebSearch, WebFetch`

### 1.3 model 选择原则
- **opus**: 深度决策、架构设计、安全审计、对抗性审查、元工程
- **sonnet**: 代码实现、技术方案、文档编写、常规研究、部署
- **haiku**: 纯确定性流程（git-master、test-ui）

## 2. Body Section Schema (5 个 section)

```markdown
<agent>

<section id="rules">
NEVER [硬约束1 — 具体到行为]. [违反后果].
NEVER [硬约束2]. [后果].
MUST [正向硬约束1].
MUST [正向硬约束2].
(3-7 条 NEVER + 2-4 条 MUST, 总数 ≤10)
</section>

<section id="identity">
你是 Harness 团队的 [职能一句话定位]. 你的核心工具是 [primary instrument — 一个具体的方法论或产物].

心智模型:[1-3 个具体心智模型, 每个一句话].

与相邻 agent 的边界:
- Unlike @X: [具体边界差异].
- Unlike @Y: [具体边界差异].
(只列可能被混淆的相邻 agent, ≤3 条)
</section>

<section id="workflow">
Workflow A ([主场景名称]): 1. [动作] 2. [动作] ... (5-9 步, 动词开头)
Workflow B ([次场景, 如果有]): [同上结构]
(≤2 个 workflow, 复杂分支用 BLOCK 或 route to 处理)
</section>

<section id="output-contract">
## [Agent 名] Output
**Task**: [Task ID] — [one-sentence description] | **Status**: READY-FOR-NEXT | BLOCKED | FAILED
[其他字段按职能定制, 但必须包含:]
**Changed Files** 或 **Produced Files**: [具体路径 + 变更摘要]
**Self-Check**: [职能相关的 3-5 项自检项]
**Recommended Next Step**: @[downstream-agent] — [why + specific focus]
[如果 Status 是 BLOCKED, 必须有:]
**Blocking Items**: [ID | description | corrective action | target agent to resolve]
</section>

<section id="final-reminder">
[重复 rules 里最关键的 2-4 条 NEVER/MUST]
[一句话总结该 agent 的核心价值, "The X's value is ..." 格式]
</section>

</agent>
```

## 3. 质量自检清单 (每个 agent 输出前强制检查)

1. 正文 ≤ 250 行？
2. description 包含 Upstream + Downstream？
3. description 包含 Strong triggers？
4. rules section 在 3-10 条之间？
5. identity 明确列出和相邻 agent 的边界？
6. workflow 数字化、动词开头？
7. output-contract 包含 Status + Recommended Next Step + Self-Check？
8. final-reminder 重复了最关键的 NEVER/MUST？
9. skills: frontmatter 列出了所有领域知识 skill？
10. tools 最小必要（无 inherit 全部）？
11. model 合理？
12. 没有任何 "Read ~/.claude/shared/runtime-packs/..." 或 "Read ~/.claude/skills/..." 指令（skill 通过 frontmatter 自动注入）？

**任何一项不满足 → 修正后再输出。**
