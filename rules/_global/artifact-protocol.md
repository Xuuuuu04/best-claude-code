# Artifact 交接文件规范

Agent 之间通过 `.claude/artifacts/` 目录中的结构化 Markdown 文件进行交接。此规则定义文件命名、内容结构、生命周期与审查归属。

---

## 目录

所有交接文件位于项目根目录的 `.claude/artifacts/`。此目录默认应加入 `.gitignore`。如团队需要复盘，可选择提交关键 artifact 快照。

---

## 命名规范

### 格式

```text
{type}-{task-id}[-{sequence}].md
```

### Type 枚举

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

### Task ID

形如 `feat-20260423-01` / `bug-20260423-03`。由类型前缀 + 日期 + 当日序号组成。

### Sequence（可选）

多 scope-lock / 多 impl-report 场景使用序号，例如：

- `scope-lock-feat-20260423-01-1.md`
- `impl-report-feat-20260423-01-2.md`

---

## 内容结构

每个 Type 的具体结构在对应 Agent / Skill 定义中规定。通用要求如下：

### 必须有的头部

```markdown
# {Type}: {一句话标题}

**Task ID**: {task-id}[-{seq}]
**生成时间**: {ISO 8601 timestamp}
**产出者**: {agent-name}
**状态**: draft / accepted / rejected / superseded
**关联**: {其他 artifact 路径列表}
```

### 状态字段（支持续传）

| 状态 | 含义 | 何时设 |
|:--|:--|:--|
| `draft` | 刚产出，未经审查 | Agent 写入时 |
| `accepted` | 已通过对应 reviewer/tester 审查 / 用户确认 | 审查通过后由调度器更新 |
| `rejected` | 审查驳回，需要重做 | 审查驳回后由调度器更新 |
| `superseded` | 被后续版本替代 | 新版产出后由调度器更新 |

续传判断示例：

- 只有 `requirements` 且 accepted → 从架构阶段开始
- 有 `architecture` 但无 `scope-lock` → 从范围规划阶段开始
- `scope-lock` accepted 但无 `impl-report` → 从实现阶段开始
- 有 `impl-report` 但无 `review-code` → 从代码审查开始
- 有 `review-code` 但无 `review-security` / `review-functional` → 继续后续门控

### 结构化优于散文

- 用表格、列表、小标题
- 避免长段落
- 代码块要标注语言
- 结论、证据、未覆盖项优先置顶

---

## 生命周期

### 创建
产出 Agent 写入 artifact。

### 消费
下一阶段 Agent 读取 artifact 作为输入。

### 归档（可选）
任务完成后，可移入 `.claude/artifacts/archive/{year-month}/`。

### 清理
调度器可在以下情况清理：
- 同一 task-id 的流程已完成并提交
- 超过保留期（默认 30 天）
- 用户明确要求

---

## 读取与修改

- Agent **可读** 其他 Agent 的 artifact 作为输入
- Agent **不应修改** 其他 Agent 的 artifact
- 如需修订，优先由原角色重产，或产出新版本（如 `-v2`）

例外：调度器可以持续追加 `evolve-log.md`

---

## 敏感信息

artifact 中不得出现：
- 密钥、token、密码
- 完整个人信息（PII）

如涉及敏感信息，使用占位符，例如 `{REDACTED_TOKEN}`、`{USER_PII}`。

---

## 审查视角

对应 reviewer / tester 审查 artifact 时：

- 结构合规（头部字段完整）
- 内容充分（足够给下游使用）
- 精确具体（带路径、行号、证据）
- 无敏感泄露
