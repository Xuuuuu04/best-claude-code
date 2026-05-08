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
| `requirements` | 资深需求分析师 | 需求分析与 Task 拆分 |
| `client-brief` | 客户需求整理师 | 客户需求整理与售后分类 |
| `创意策划师` | 创意策划师 | 命名、Slogan、品牌方向提案 |
| `dispatch` | 项目管理师 | 单跳调度与状态变化记录 |
| `dispatch-ticket` | 调度器 | 当前任务的机读调度票据、风险、自适应质量门控 |
| `architecture` | 资深系统架构师 | 架构设计文档 |
| `scope-lock` | 资深范围规划师 | 实现范围锁定（多个） |
| `scope-plan` | 资深范围规划师 | scope-lock 执行依赖图与批次规划 |
| `schema` | 资深数据库工程师 | schema / migration 方案 |
| `ml-report` | 机器学习工程师 | 训练、评估、推理交付报告 |
| `impl-report` | 实现工程师-* | 实现报告 |
| `review-requirements` | 高级需求审查师 | 需求审查 |
| `review-architecture` | 高级架构审查师 | 架构审查 |
| `review-code` | 高级代码审查师 | 代码审查 |
| `review-security` | 高级安全审计师 | 安全审计 |
| `review-functional` | 高级功能测试师 | 功能测试报告 |
| `review-visual` | 高级视觉测试师 | 视觉测试报告 |
| `verdict` | 质量总监 | 最终质量裁决 |
| `doc` | 文档工程师 | 文档交付说明 |
| `design` | 视觉设计专家 | 设计系统 / 视觉规范摘要 |
| `prompt-governance` | Claude Code 工作流与提示词设计大师 | 元治理变更记录 |
| `deploy-report` | 高级运维工程师 | 部署记录 |
| `incident` | 高级运维工程师 | 事故记录 |
| `repo-research` | 代码库研究员 | 仓库研究报告 |
| `tech-research` | 技术调研专家 | 技术调研报告 |
| `init-analysis` | 代码库研究员 | `/bcc-init-project` 初始扫描 |
| `update-analysis` | 代码库研究员 | `/bcc-update-project` 差异扫描 |
| `evolve-audit` | 代码库研究员 / 技术调研专家 | `/bcc-evolve` 系统审计 |
| `evolve-proposals` | 调度器 | `/bcc-evolve` 进化提案 |
| `evolve-log` | 调度器 | 进化历史累积文件 |
| `review-content` | 高级内容审查师 | 文档/创意内容审查 |
| `review-research` | 高级调研审查师 | 技术调研/仓库研究审查 |
| `storyboard` | 多媒体内容生成师 | 分镜设计脚本 |
| `media-impl` | 多媒体内容生成师 | 媒体实现报告（Remotion 项目结构） |
| `media-render` | 多媒体内容生成师 | 渲染输出报告（MP4/GIF/静态图） |
| `bid-proposal` | 接单报价师 | 外包项目报价提案 |
| `career` | 就业教练 | 就业辅导产出（简历/面试/薪资） |
| `audit-paper-claim` | 论文数字审计员 | L3 论文数字审计 |
| `audit-citation` | 引用审计员 | L4 引用审计 |
| `audit-proof` | 定理证明审计员 | 定理与证明审计 |
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

  <section id="agent-teams-artifacts">
    <requirement severity="warning">
      Agent Teams 产出 artifact 规则（实验性）：

      <list>
        <item>Teammates 产出的 artifact 遵循相同命名规范，但 agent 字段记录 teammate 名称</item>
        <item>TaskCreated / TaskCompleted hook 自动同步 DispatchTicket 状态到 legion-session.json 的 teams.tasks 数组</item>
        <item>Team Lead 汇总时需检查所有 Teammates 的 artifact 完整性</item>
        <item>跨 Teammate 的 artifact 引用需通过 Team Lead 协调（Teammates 不直接共享文件系统写入）</item>
        <item>Agent Teams 模式下的 DispatchTicket 需包含 teams 字段：{team_name, teammates: [{name, scope, status}]}</item>
      </list>
    </requirement>
  </section>
</rule>
