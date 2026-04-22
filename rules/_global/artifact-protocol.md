# Artifact 交接文件规范

Agent 之间通过 `.claude/artifacts/` 目录中的结构化 Markdown 文件进行交接。此规则定义文件命名、内容结构、生命周期约定。

---

## 目录

所有交接文件位于项目根目录的 `.claude/artifacts/`。此目录应在 `.gitignore` 中（artifact 是过程产物，不进入版本控制）。

但有一个例外：如果团队希望 artifact 可追溯（便于复审、复盘），可以将 `artifacts/` 纳入版本控制，或提交关键的 artifact 快照。

---

## 命名规范

### 格式

```
{type}-{task-id}[-{sequence}].md
```

### Type 枚举

| Type | 产出者 | 用途 |
|:--|:--|:--|
| `requirements` | product-analyst | 需求分析与 Task 拆分 |
| `architecture` | architect | 架构设计文档 |
| `scope-lock` | architect | 实现范围锁定（多个） |
| `impl-report` | implementer-* | 实现报告 |
| `review-requirements` | quality-guardian | 需求审查 |
| `review-architecture` | quality-guardian | 架构审查 |
| `review-code` | quality-guardian | 代码审查 |
| `review-functional` | quality-guardian | 功能测试报告 |
| `review-predeploy` | quality-guardian | 部署前预检 |
| `deploy-report` | devops | 部署记录 |
| `incident` | devops | 事故记录 |
| `init-analysis` | researcher | /bcc-init-project 初始扫描 |
| `update-analysis` | researcher | /bcc-update-project 差异扫描 |
| `evolve-audit` | researcher | /bcc-evolve 系统审计 |
| `evolve-proposals` | 调度器 | /bcc-evolve 进化提案 |
| `evolve-log` | 调度器 | 进化历史累积文件 |

### Task ID

形如 `feat-20260423-01` / `bug-20260423-03`。由 type 前缀 + 日期 + 当日序号组成。

### Sequence（可选）

对多 scope-lock、多 impl-report 的场景：`scope-lock-feat-20260423-01-1.md`、`scope-lock-feat-20260423-01-2.md`。

---

## 内容结构

每个 Type 的具体结构在对应 Agent / Skill 定义中规定。通用要求：

### 必须有的头部

```markdown
# {Type} : {一句话标题}

**Task ID**: {task-id}[-{seq}]
**生成时间**: {ISO 8601 timestamp}
**产出者**: {agent-name}
**关联**: {其他 artifact 路径列表}
```

### 结构化优于散文

- 用表格、列表、小标题
- 避免长段落
- 代码块明确语言（`​```typescript`）

### 可被下一 Agent 高效消化

- 明确的结论、要点
- 关键信息置顶
- 引用具体文件和行号

---

## 生命周期

### 创建
产出 Agent 写入 artifact 文件。

### 消费
下一阶段 Agent 读取 artifact 作为输入。

### 归档（可选）
任务流水线完成后，可将相关 artifact 移入 `.claude/artifacts/archive/{year-month}/` 以便历史查询。

### 清理
调度器在以下情况可清理：
- 同一 task-id 的所有流水线阶段完成且已提交
- 超过保留期（默认 30 天）
- 用户明确清理

清理前建议简报告知用户。

---

## 并发约定

同一时间可能有多个 artifact 存在，对应不同 task-id：

- `feat-20260423-01` 进行中
- `bug-20260422-03` 已完成但未清理
- `feat-20260423-02` 刚开始

调度器管理生命周期，不应在未完成的 task 之间产生引用。

---

## 读取与修改

- Agent **可读** 其他 Agent 的 artifact（作为输入）
- Agent **不应修改** 其他 Agent 的 artifact
- 如需修订，产出新版本（追加 `-v2` 后缀或让原 Agent 重新产出覆盖）

例外：调度器可以在 `evolve-log.md` 这类累积文件上持续追加。

---

## 敏感信息

artifact 可能包含：
- 代码片段（可能含内部 API 路径）
- 需求描述（可能含业务敏感）
- 错误消息（可能含系统信息）

不得在 artifact 中出现：
- 密钥、token、密码
- 完整的个人信息（PII）

如果讨论涉及敏感信息，使用占位符（`{REDACTED_TOKEN}`、`{USER_PII}`）。

---

## 审查视角

quality-guardian 审查 artifact 时：

- 结构合规（头部信息完整）
- 内容充分（能被下一 Agent 使用）
- 精确具体（有文件路径、行号、证据）
- 无敏感泄露
