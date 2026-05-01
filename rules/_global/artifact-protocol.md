<rule id="artifact-protocol" severity="blocker">
  <rationale>
    Agent 之间通过 <path>.claude/artifacts/</path> 目录中的结构化 Markdown 文件进行交接。此规则定义文件命名、内容结构、生命周期与审查归属。
  </rationale>

  <section id="directory">
    <requirement>
      所有交接文件位于项目根目录的 <path>.claude/artifacts/</path>。此目录默认应加入 <path>.gitignore</path>。如团队需要复盘，可选择提交关键 artifact 快照。
    </requirement>
  </section>

  <section id="naming">
    <subsection id="naming-format">
      <requirement severity="blocker">
        格式：
        <code-block language="text"><![CDATA[{type}-{task-id}[-{sequence}].md]]></code-block>
      </requirement>
    </subsection>

    <subsection id="naming-type-enum">
      <table>
| Type | 产出者 | 用途 |
|:--|:--|:--|
| `requirements` | product-analyst | 需求分析与 Task 拆分 |
| `client-brief` | client | 客户需求整理与售后分类 |
| `creative` | creative | 命名、Slogan、品牌方向提案 |
| `dispatch` | pm | 单跳调度与状态变化记录 |
| `architecture` | architect | 架构设计文档 |
| `scope-lock` | scope-planner | 实现范围锁定（多个） |
| `scope-plan` | scope-planner | scope-lock 执行依赖图与批次规划 |
| `schema` | database-engineer | schema / migration 方案 |
| `ml-report` | ml-engineer | 训练、评估、推理交付报告 |
| `impl-report` | implementer-* | 实现报告 |
| `review-requirements` | requirements-reviewer | 需求审查 |
| `review-architecture` | architecture-reviewer | 架构审查 |
| `review-code` | code-reviewer | 代码审查 |
| `review-security` | security-auditor | 安全审计 |
| `review-functional` | functional-tester | 功能测试报告 |
| `review-visual` | visual-tester | 视觉测试报告 |
| `verdict` | test-lead | 最终质量裁决 |
| `doc` | doc-writer | 文档交付说明 |
| `design` | visual-designer | 设计系统 / 视觉规范摘要 |
| `prompt-governance` | prompt-engineer | 元治理变更记录 |
| `deploy-report` | devops | 部署记录 |
| `incident` | devops | 事故记录 |
| `repo-research` | repo-researcher | 仓库研究报告 |
| `tech-research` | tech-researcher | 技术调研报告 |
| `init-analysis` | repo-researcher | `/bcc-init-project` 初始扫描 |
| `update-analysis` | repo-researcher | `/bcc-update-project` 差异扫描 |
| `evolve-audit` | repo-researcher / tech-researcher | `/bcc-evolve` 系统审计 |
| `evolve-proposals` | 调度器 | `/bcc-evolve` 进化提案 |
| `evolve-log` | 调度器 | 进化历史累积文件 |
| `review-content` | content-reviewer | 文档/创意内容审查 |
| `review-research` | research-reviewer | 技术调研/仓库研究审查 |
| `storyboard` | creative-media-producer | 分镜设计脚本 |
| `media-impl` | creative-media-producer | 媒体实现报告（Remotion 项目结构） |
| `media-render` | creative-media-producer | 渲染输出报告（MP4/GIF/静态图） |
| `bid-proposal` | freelance-bidder | 外包项目报价提案 |
| `career` | career-coach | 就业辅导产出（简历/面试/薪资） |
| `audit-paper-claim` | paper-claim-auditor | L3 论文数字审计 |
| `audit-citation` | citation-auditor | L4 引用审计 |
| `audit-proof` | proof-checker | 定理与证明审计 |
      </table>
    </subsection>

    <subsection id="naming-task-id">
      <requirement>
        形如 <pattern>feat-20260423-01</pattern> / <pattern>bug-20260423-03</pattern>。由类型前缀 + 日期 + 当日序号组成。
      </requirement>
    </subsection>

    <subsection id="naming-sequence">
      <requirement>
        多 scope-lock / 多 impl-report 场景使用序号，例如：
        <list>
          <item><path>scope-lock-feat-20260423-01-1.md</path></item>
          <item><path>impl-report-feat-20260423-01-2.md</path></item>
        </list>
      </requirement>
    </subsection>
  </section>

  <section id="content-structure">
    <requirement>
      每个 Type 的具体结构在对应 Agent / Skill 定义中规定。通用要求如下：
    </requirement>

    <subsection id="content-header">
      <constraint severity="blocker">
        必须有的头部：
        <code-block language="markdown"><![CDATA[
# {Type}: {一句话标题}

**Task ID**: {task-id}[-{seq}]
**生成时间**: {ISO 8601 timestamp}
**产出者**: {agent-name}
**状态**: draft / accepted / rejected / superseded
**关联**: {其他 artifact 路径列表}
        ]]></code-block>
      </constraint>
    </subsection>

    <subsection id="content-status">
      <table>
| 状态 | 含义 | 何时设 |
|:--|:--|:--|
| `draft` | 刚产出，未经审查 | Agent 写入时 |
| `accepted` | 已通过对应 reviewer/tester 审查 / 用户确认 | 审查通过后由调度器更新 |
| `rejected` | 审查驳回，需要重做 | 审查驳回后由调度器更新 |
| `superseded` | 被后续版本替代 | 新版产出后由调度器更新 |
      </table>

      <note>
        续传判断示例：
        <list>
          <item>只有 <status>requirements</status> 且 accepted → 从架构阶段开始</item>
          <item>有 <status>architecture</status> 但无 <status>scope-lock</status> → 从范围规划阶段开始</item>
          <item><status>scope-lock</status> accepted 但无 <status>impl-report</status> → 从实现阶段开始</item>
          <item>有 <status>impl-report</status> 但无 <status>review-code</status> → 从代码审查开始</item>
          <item>有 <status>review-code</status> 但无 <status>review-security</status> / <status>review-functional</status> → 继续后续门控</item>
        </list>
      </note>
    </subsection>

    <subsection id="content-structured-over-prose">
      <requirement>
        <list>
          <item>用表格、列表、小标题</item>
          <item>避免长段落</item>
          <item>代码块要标注语言</item>
          <item>结论、证据、未覆盖项优先置顶</item>
        </list>
      </requirement>
    </subsection>
  </section>

  <section id="lifecycle">
    <subsection id="lifecycle-create">
      <requirement>产出 Agent 写入 artifact。</requirement>
    </subsection>
    <subsection id="lifecycle-consume">
      <requirement>下一阶段 Agent 读取 artifact 作为输入。</requirement>
    </subsection>
    <subsection id="lifecycle-archive">
      <requirement>任务完成后，可移入 <path>.claude/artifacts/archive/{year-month}/</path>。</requirement>
    </subsection>
    <subsection id="lifecycle-cleanup">
      <requirement>
        调度器可在以下情况清理：
        <list>
          <item>同一 task-id 的流程已完成并提交</item>
          <item>超过保留期（默认 30 天）</item>
          <item>用户明确要求</item>
        </list>
      </requirement>
    </subsection>
  </section>

  <section id="versioning">
    <subsection id="versioning-timestamped">
      <requirement>
        覆盖写入 artifact 时，使用 timestamped 文件名 + fixed-name 最新副本双写：
        <list>
          <item>写入 timestamped 文件：<pattern>{FILENAME}_{YYYYMMDD_HHmmss}.md</pattern>（秒级精度）</item>
          <item>复制相同内容到 fixed-name 文件：<pattern>{FILENAME}.md</pattern>（覆盖上一版）</item>
          <item>下游 Agent 始终读取 fixed-name 文件</item>
          <item>永不删除 timestamped 文件 — 它们是永久历史</item>
        </list>
      </requirement>
    </subsection>

    <subsection id="versioning-not-timestamped">
      <requirement>
        以下文件<strong>不</strong>需要 timestamped 版本：
        <list>
          <item>Append-only 文件：<pattern>findings.md</pattern>、<pattern>MANIFEST.md</pattern></item>
          <item>Per-round 文件：已有 seq 编号的 artifact（如 <pattern>scope-lock-feat-20260425-01-1.md</pattern>）</item>
          <item>Dashboard 类：<pattern>CLAUDE.md</pattern></item>
        </list>
      </requirement>
    </subsection>

    <subsection id="versioning-stale-state">
      <requirement>
        读取状态文件（如 <pattern>REVIEW_STATE.json</pattern>）前检查修改时间：
        <list>
          <item>默认过期阈值：<strong>24 小时</strong></item>
          <item>超过阈值则提示用户："⚠️ 状态文件 {filename} 已 {N} 小时未更新。继续此状态，还是重新开始？"</item>
          <item>用户选择重新开始时，写 timestamped 归档副本后清空状态</item>
        </list>
      </requirement>
    </subsection>
  </section>

  <section id="read-write">
    <list>
      <item>Agent **可读** 其他 Agent 的 artifact 作为输入</item>
      <item>Agent **不应修改** 其他 Agent 的 artifact</item>
      <item>如需修订，优先由原角色重产，或产出新版本（如 <pattern>-v2</pattern>）</item>
    </list>
    <note>例外：调度器可以持续追加 <path>evolve-log.md</path></note>
  </section>

  <section id="sensitive-info">
    <constraint severity="blocker">
      artifact 中不得出现：
      <list>
        <item>密钥、token、密码</item>
        <item>完整个人信息（PII）</item>
      </list>
      如涉及敏感信息，使用占位符，例如 <token>{REDACTED_TOKEN}</token>、<token>{USER_PII}</token>。
    </constraint>
  </section>

  <section id="review-perspective">
    <requirement>
      对应 reviewer / tester 审查 artifact 时：
      <checklist>
        <check id="review-structure">结构合规（头部字段完整）</check>
        <check id="review-content">内容充分（足够给下游使用）</check>
        <check id="review-precision">精确具体（带路径、行号、证据）</check>
        <check id="review-no-leak">无敏感泄露</check>
      </checklist>
    </requirement>
  </section>
</rule>
