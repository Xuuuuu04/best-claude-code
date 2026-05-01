<rule id="claudemd-standard" severity="blocker">
  <rationale>
    项目中的 CLAUDE.md 文件必须符合以下规范。此规则由 <cmd>/bcc-init-project</cmd> 和 <cmd>/bcc-update-memory</cmd> 生成时遵循，也指导 <agent>architecture-reviewer</agent> 在审查 CLAUDE.md 时的判断。
  </rationale>

  <section id="capacity-limit">
    <constraint severity="blocker">
      总行数 ≤ 200 行
    </constraint>
    <constraint severity="warning">
      推荐 ≤ 150 行
    </constraint>
    <requirement>
      超过 200 行必须拆分到 <path>.claude/rules/</path> 或 <path>.claude/skills/</path>
    </requirement>
    <rationale>
      超过 200 行导致 Claude 在每次请求中背负不必要的上下文，降低指令遵循度。
    </rationale>
  </section>

  <section id="required-blocks">
    <subsection id="block-1-identity">
      <requirement>
        项目身份（3-5 行）—— 项目名称、一句话描述、核心业务。
      </requirement>
    </subsection>
    <subsection id="block-2-tech-stack">
      <requirement>
        技术栈（3-8 行）—— 主要语言、框架、数据库、工具链。**只列名称和版本**，详细内容归 <skill>project-knowledge</skill> Skill。
      </requirement>
    </subsection>
    <subsection id="block-3-build-test-commands">
      <requirement>
        构建/测试命令（5-10 行）—— 完整的 <cmd>npm run build</cmd>、<cmd>npm test</cmd>、<cmd>npm run lint</cmd> 等命令。
      </requirement>
    </subsection>
    <subsection id="block-4-core-modules">
      <requirement>
        核心模块（5-10 行）—— 每个核心模块一行描述。**不要写每个文件**，那是 project-knowledge 的职责。
      </requirement>
    </subsection>
    <subsection id="block-5-core-invariants">
      <requirement>
        核心铁律（5-15 行）—— 绝对不可违反的规则。例如：
        <list>
          <item>"永远不修改 prisma/migrations/"</item>
          <item>"不在代码中硬编码密钥"</item>
          <item>"提交前所有测试必须通过"</item>
        </list>
      </requirement>
    </subsection>
    <subsection id="block-6-agent-dispatch-guide">
      <requirement>
        Agent 调度指引（15-30 行）—— 作为调度器的行为准则，包括：
        <list>
          <item>可用的流水线命令</item>
          <item>Agent 选择规则</item>
          <item>调度原则（何时用 repo-researcher / tech-researcher，何时各层 reviewer/tester 必须审查）</item>
        </list>
      </requirement>
    </subsection>
    <subsection id="block-7-imports">
      <requirement>
        @imports（3-5 行）—— 引用 README、package.json 等关键参考文件。
      </requirement>
    </subsection>
  </section>

  <section id="forbidden-content">
    <constraint severity="blocker">
      以下内容**不应**写入 CLAUDE.md：
      <list>
        <item>详细的 API 文档 → 归入 <skill>project-knowledge</skill> Skill</item>
        <item>代码示例超过 5 行 → 归入对应的 Rule 或 Skill</item>
        <item>频繁变化的进度信息（版本号、当前 sprint 进度）→ 归入 <skill>project-knowledge</skill> Skill</item>
        <item>长篇背景介绍或历史演变</item>
        <item>架构决策记录（ADR）→ 归入 <skill>project-knowledge</skill> Skill</item>
        <item>详细的测试策略 → 归入 <skill>test-strategy</skill> Skill</item>
        <item>冗长的编码规范 → 归入对应的路径限定 Rules</item>
      </list>
    </constraint>
  </section>

  <section id="style-requirements">
    <requirement>
      <list>
        <item>Markdown 标题清晰（## 分区块）</item>
        <item>列表比段落清晰</item>
        <item>命令用 code block 包裹</item>
        <item>避免华丽辞藻和冗余形容词</item>
        <item>不使用 emoji（除非项目文化要求）</item>
      </list>
    </requirement>
  </section>

  <section id="review-points">
    <requirement>
      <agent>architecture-reviewer</agent> 审查 CLAUDE.md 时，除了形式合规，还要检查：
      <checklist>
        <check id="invariants-testable">核心铁律**具体可检验**（"写好代码"不算，"ESLint 必须无警告"算）</check>
        <check id="dispatch-agent-exists">Agent 调度指引**与实际 Agent 定义一致**（引用的 Agent 名称存在）</check>
        <check id="tech-stack-consistent">技术栈声明**与实际代码一致**（项目说用 React 但 package.json 没有）</check>
        <check id="build-commands-runnable">构建命令**可以实际运行**（不是复制模板未更新）</check>
      </checklist>
    </requirement>
  </section>
</rule>
