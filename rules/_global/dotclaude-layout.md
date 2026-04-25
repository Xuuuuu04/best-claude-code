# 项目级 `.claude/` 目录布局规范

**强制规范**。所有 agent 在项目级目录下写文件（artifact / log / state / memory）时必须遵守。v3 新增。

---

## 根目录只允许以下条目

```
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
```

**禁止** 在 `.claude/` 根目录放其他文件。见下方迁移表。

## 常见文件的正确位置

| 文件 | ❌ 错误位置 | ✅ 正确位置 |
|:--|:--|:--|
| `cost-log.txt` | `.claude/cost-log.txt` | `.claude/logs/cost-log.txt` |
| `instructions-log.txt` | `.claude/instructions-log.txt` | `.claude/logs/instructions-log.txt` |
| `hook-errors.log` | `.claude/hook-errors.log` | `.claude/logs/hook-errors.log` |
| `cost-log.txt.broken.*` | `.claude/cost-log.txt.broken.*` | `.claude/logs/backups/` |
| `scheduled_tasks.lock` | `.claude/scheduled_tasks.lock` | `.claude/state/scheduled_tasks.lock` |
| `scheduled_tasks.json` | `.claude/scheduled_tasks.json` | `.claude/state/scheduled_tasks.json` |
| `backups/`（散装） | `.claude/backups/` | `.claude/logs/backups/` 或 `.claude/artifacts/archive/` |

**向后兼容**：已有项目可延迟整理；新产出必须按新布局。`bin/tidy-dotclaude.sh` 提供只读诊断和手动迁移建议。

---

## Artifact 文件命名（硬约束）

### 格式

```
{type}-{task-id}[-{seq}].md
```

### task-id 格式

```
{prefix}-{YYYYMMDD}-{NN|slug}
```

- `prefix`：`feat` / `bug` / `hotfix` / `chore` / `refactor` / `migration` / `deploy` / `audit` / `research`
- `YYYYMMDD`：8 位日期（绝不允许省略）
- `NN`：2 位当日序号（`01`-`99`）
- `slug`：可选可读短名（kebab-case，≤ 20 字符）

### 合规示例

| ✅ 合规 | 说明 |
|:--|:--|
| `feat-20260425-01` | 最简格式 |
| `bug-20260425-03-miniapp-login` | 带 slug |
| `impl-report-feat-20260425-01-2.md` | 第 2 个实现报告 |
| `scope-lock-feat-20260425-01-3.md` | 第 3 个 scope-lock |
| `deploy-report-feat-20260425-01.md` | 部署报告 |

### 违规示例

| ❌ 违规 | 问题 | 应改为 |
|:--|:--|:--|
| `forumkit-11.md` | 无 type 前缀、无日期、无前缀 | `impl-report-feat-20260423-11-forumkit.md` |
| `impl-report-27aba93.md` | commit hash 不能当 task-id | `impl-report-bug-20260424-01-commit27aba93.md` |
| `impl-report-fix-pay-toast.md` | 无日期 | `impl-report-bug-20260425-02-pay-toast.md` |
| `deploy-report-20260424-09-perm-fix.md` | 缺 prefix（未说明是 feat/bug/hotfix） | `deploy-report-hotfix-20260424-09-perm-fix.md` |
| `init-analysis.md` | 无 task-id | `init-analysis-audit-20260425.md` |

### 序号规则

- 同一 task-id 的多个 artifact 用 `-{seq}`，从 `-1` 开始连续不跳号
- 不允许两个文件撞同一 `task-id + seq`
- 超过 9 个 seq 时考虑拆子 task-id（表明单个任务太大）

---

## 归档规则

### 触发归档

以下任一：
- 同一 task-id 完整流水线走完（有 `verdict` 或 `deploy-report` 收尾）
- artifact 产出时间超过 30 天
- 项目里已完成的 sprint / milestone 结束

### 归档动作

```bash
mkdir -p .claude/artifacts/archive/YYYY-Qn
mv .claude/artifacts/*-{task-id}*.md .claude/artifacts/archive/YYYY-Qn/
```

归档后活跃目录应仅保留进行中任务的 artifact。

---

## 索引要求（多 seq 任务）

当一个 task-id 产出 ≥ 3 个 seq 时，**必须**在 `artifacts/` 根建索引文件：

```
index-{task-id}.md
```

内容：
```markdown
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
```

---

## Planning / Roadmap 类文档

Agent 产出推进类文档（整体规划、阶段路线图、多 task 协调）使用 `dispatch` type：

- `dispatch-{YYYYMMDD}-{slug}.md` — pm 或主会话产出
- 不允许用 `roadmap.md` / `plan.md` / `todo.md` 等无规范命名

---

## 审查责任

- **主会话**：派遣 agent 前告知 task-id（可由 intent-classify 建议）
- **每个 agent**：写 artifact 前校验 task-id 合规
- **`bin/validate-artifacts.sh`**：非合规 task-id 输出 `WARNING`；非法 type 前缀输出 `CRITICAL`
- **`bin/tidy-dotclaude.sh`**：只读诊断当前项目布局 + 命名合规率
- **`bin/doctor.sh` §15**：Artifact Schema 校验汇总
