<rule id="dotclaude-layout" severity="blocker">
  <rationale>
    **强制规范**。所有 agent 在项目级目录下写文件（artifact / log / state / memory）时必须遵守。v3 新增。
  </rationale>

  <section id="root-directory">
    <constraint severity="blocker">
      根目录只允许以下条目：
      <code-block language="text"><![CDATA[
<project-root>/.claude/
├── artifacts/          # Agent 交接文件（主要产出）
│   └── archive/        # 归档区（按季度打包）
│       └── 2026-Q2/
├── agent-memory/       # Agent 跨任务记忆（per-agent 子目录）
│   └── <agent-name>/
├── logs/               # 所有 *.log / *.jsonl / *.txt 日志
│   └── backups/        # broken / rotated 备份
├── state/              # 运行时锁、状态、PID、session 文件
├── worktrees/          # git worktree 临时目录
├── skills/             # 项目级 skill override（可选）
├── agents/             # 项目级 agent override（可选）
├── rules/              # 项目级 rule override（可选）
├── settings.local.json # 本地设置（Claude Code 管理）
└── CLAUDE.md           # 项目指令（如有）
      ]]></code-block>
    </constraint>
    <constraint severity="blocker">
      **禁止** 在 <path>.claude/</path> 根目录放其他文件。见下方迁移表。
    </constraint>
  </section>

  <section id="file-locations">
    <table>
| 文件 | 错误位置 | 正确位置 |
|:--|:--|:--|
| `cost-log.txt` | `.claude/cost-log.txt` | `.claude/logs/cost-log.txt` |
| `instructions-log.txt` | `.claude/instructions-log.txt` | `.claude/logs/instructions-log.txt` |
| `hook-errors.log` | `.claude/hook-errors.log` | `.claude/logs/hook-errors.log` |
| `cost-log.txt.broken.*` | `.claude/cost-log.txt.broken.*` | `.claude/logs/backups/` |
| `scheduled_tasks.lock` | `.claude/scheduled_tasks.lock` | `.claude/state/scheduled_tasks.lock` |
| `scheduled_tasks.json` | `.claude/scheduled_tasks.json` | `.claude/state/scheduled_tasks.json` |
| `backups/`（散装） | `.claude/backups/` | `.claude/logs/backups/` 或 `.claude/artifacts/archive/` |
    </table>
    <note>
      **向后兼容**：已有项目可延迟整理；新产出必须按新布局。<cmd>bin/tidy-dotclaude.sh</cmd> 提供只读诊断和手动迁移建议。
    </note>
  </section>

  <section id="artifact-naming">
    <subsection id="artifact-naming-format">
      <constraint severity="blocker">
        格式：<code-block language="text"><![CDATA[{type}-{task-id}[-{seq}].md]]></code-block>
      </constraint>
    </subsection>

    <subsection id="artifact-naming-task-id">
      <constraint severity="blocker">
        task-id 格式：<code-block language="text"><![CDATA[{prefix}-{YYYYMMDD}-{NN|slug}]]></code-block>
        <list>
          <item><pattern>prefix</pattern>：<value>feat</value> / <value>bug</value> / <value>hotfix</value> / <value>chore</value> / <value>refactor</value> / <value>migration</value> / <value>deploy</value> / <value>audit</value> / <value>research</value></item>
          <item><pattern>YYYYMMDD</pattern>：8 位日期（绝不允许省略）</item>
          <item><pattern>NN</pattern>：2 位当日序号（<value>01</value>-<value>99</value>）</item>
          <item><pattern>slug</pattern>：可选可读短名（kebab-case，≤ 20 字符）</item>
        </list>
      </constraint>
    </subsection>

    <subsection id="artifact-naming-valid-examples">
      <table>
| 合规 | 说明 |
|:--|:--|
| `feat-20260425-01` | 最简格式 |
| `bug-20260425-03-miniapp-login` | 带 slug |
| `impl-report-feat-20260425-01-2.md` | 第 2 个实现报告 |
| `scope-lock-feat-20260425-01-3.md` | 第 3 个 scope-lock |
| `deploy-report-feat-20260425-01.md` | 部署报告 |
      </table>
    </subsection>

    <subsection id="artifact-naming-invalid-examples">
      <table>
| 违规 | 问题 | 应改为 |
|:--|:--|:--|
| `forumkit-11.md` | 无 type 前缀、无日期、无前缀 | `impl-report-feat-20260423-11-forumkit.md` |
| `impl-report-27aba93.md` | commit hash 不能当 task-id | `impl-report-bug-20260424-01-commit27aba93.md` |
| `impl-report-fix-pay-toast.md` | 无日期 | `impl-report-bug-20260425-02-pay-toast.md` |
| `deploy-report-20260424-09-perm-fix.md` | 缺 prefix（未说明是 feat/bug/hotfix） | `deploy-report-hotfix-20260424-09-perm-fix.md` |
| `init-analysis.md` | 无 task-id | `init-analysis-audit-20260425.md` |
      </table>
    </subsection>

    <subsection id="artifact-naming-seq-rules">
      <constraint severity="blocker">
        <list>
          <item>同一 task-id 的多个 artifact 用 <pattern>-{seq}</pattern>，从 <value>-1</value> 开始连续不跳号</item>
          <item>不允许两个文件撞同一 <pattern>task-id + seq</pattern></item>
          <item>超过 9 个 seq 时考虑拆子 task-id（表明单个任务太大）</item>
        </list>
      </constraint>
    </subsection>
  </section>

  <section id="archive-rules">
    <subsection id="archive-triggers">
      <requirement>
        触发归档，以下任一：
        <list>
          <item>同一 task-id 完整流水线走完（有 <status>verdict</status> 或 <status>deploy-report</status> 收尾）</item>
          <item>artifact 产出时间超过 30 天</item>
          <item>项目里已完成的 sprint / milestone 结束</item>
        </list>
      </requirement>
    </subsection>

    <subsection id="archive-action">
      <requirement>
        <code-block language="bash"><![CDATA[
mkdir -p .claude/artifacts/archive/YYYY-Qn
mv .claude/artifacts/*-{task-id}*.md .claude/artifacts/archive/YYYY-Qn/
        ]]></code-block>
        归档后活跃目录应仅保留进行中任务的 artifact。
      </requirement>
    </subsection>
  </section>

  <section id="index-requirements">
    <constraint severity="blocker">
      当一个 task-id 产出 ≥ 3 个 seq 时，**必须**在 <path>artifacts/</path> 根建索引文件：
      <code-block language="text"><![CDATA[index-{task-id}.md]]></code-block>
      内容：
      <code-block language="markdown"><![CDATA[
# Index: {task-id}

**范围**：一句话描述
**状态**：进行中 / 已归档
**起始**：2026-04-25
**负责 agent**：xxx

## artifact 列表
- `requirements-{task-id}.md` — 需求
- `architecture-{task-id}.md` — 架构
- `scope-lock-{task-id}-1.md` - `-5.md` — 5 个子 scope
- `impl-report-{task-id}-1.md` - `-5.md` — 5 个实现报告
- `review-code-{task-id}.md` — 代码审查
- `verdict-{task-id}.md` — 最终裁决
      ]]></code-block>
    </constraint>
  </section>

  <section id="planning-docs">
    <requirement>
      Agent 产出推进类文档（整体规划、阶段路线图、多 task 协调）使用 <type>dispatch</type> type：
      <list>
        <item><pattern>dispatch-{YYYYMMDD}-{slug}.md</pattern> — 项目管理师 或主会话产出</item>
        <item>不允许用 <path>roadmap.md</path> / <path>plan.md</path> / <path>todo.md</path> 等无规范命名</item>
      </list>
    </requirement>
  </section>

  <section id="monorepo">
    <requirement>
      子项目级 artifact 使用嵌套目录：
      <code-block language="text"><![CDATA[
.claude/artifacts/
├── {service-a}/           # 子项目 A
│   ├── scope-lock-*.md
│   └── impl-report-*.md
├── {service-b}/           # 子项目 B
│   └── ...
└── shared/                # 跨子项目
    └── architecture-*.md
      ]]></code-block>
      <list>
        <item>scope-lock 白名单路径必须含子项目前缀，如 <path>packages/web/src/...</path></item>
        <item><cmd>bcc-init-project</cmd> 检测到 monorepo 时会询问整体 vs 分子项目初始化</item>
        <item>跨子项目任务由 <agent>资深需求分析师</agent> 拆分子项目边界，<agent>资深系统架构师</agent> 做跨模块设计</item>
      </list>
    </requirement>
  </section>

  <section id="review-responsibility">
    <requirement>
      <list>
        <item><role>主会话</role>：派遣 agent 前告知 task-id（由模型按当前任务自判）</item>
        <item><role>每个 agent</role>：写 artifact 前校验 task-id 合规</item>
        <item><cmd>bin/validate-artifacts.sh</cmd>：非合规 task-id 输出 <token>WARNING</token>；非法 type 前缀输出 <token>CRITICAL</token></item>
        <item><cmd>bin/tidy-dotclaude.sh</cmd>：只读诊断当前项目布局 + 命名合规率</item>
        <item><cmd>bin/doctor.sh</cmd> §15：Artifact Schema 校验汇总</item>
      </list>
    </requirement>
  </section>
</rule>
