# CLAUDE.md 内容规范

项目中的 CLAUDE.md 文件必须符合以下规范。此规则由 `/bcc-init-project` 和 `/bcc-update-project` 生成时遵循，也指导 quality-guardian 在审查 CLAUDE.md 时的判断。

---

## 容量限制

- **总行数 ≤ 200 行**
- **推荐 ≤ 150 行**
- 超过 200 行必须拆分到 `.claude/rules/` 或 `.claude/skills/`

理由：超过 200 行导致 Claude 在每次请求中背负不必要的上下文，降低指令遵循度。

---

## 必须包含的区块（按顺序）

### 1. 项目身份（3-5 行）
项目名称、一句话描述、核心业务。

### 2. 技术栈（3-8 行）
主要语言、框架、数据库、工具链。**只列名称和版本**，详细内容归 `project-knowledge` Skill。

### 3. 构建/测试命令（5-10 行）
完整的 `npm run build`、`npm test`、`npm run lint` 等命令。

### 4. 核心模块（5-10 行）
每个核心模块一行描述。**不要写每个文件**，那是 project-knowledge 的职责。

### 5. 核心铁律（5-15 行）
绝对不可违反的规则。例如：
- "永远不修改 prisma/migrations/"
- "不在代码中硬编码密钥"
- "提交前所有测试必须通过"

### 6. Agent 调度指引（15-30 行）
作为调度器的行为准则，包括：
- 可用的流水线命令
- Agent 选择规则
- 调度原则（何时用 Explorer、何时 quality-guardian 必须审查）

### 7. @imports（3-5 行）
引用 README、package.json 等关键参考文件。

---

## 禁止包含的内容

以下内容**不应**写入 CLAUDE.md：

- 详细的 API 文档 → 归入 `project-knowledge` Skill
- 代码示例超过 5 行 → 归入对应的 Rule 或 Skill
- 频繁变化的进度信息（版本号、当前 sprint 进度）→ 归入 `project-knowledge` Skill
- 长篇背景介绍或历史演变
- 架构决策记录（ADR）→ 归入 `project-knowledge` Skill
- 详细的测试策略 → 归入 `test-strategy` Skill
- 冗长的编码规范 → 归入对应的路径限定 Rules

---

## 风格要求

- Markdown 标题清晰（## 分区块）
- 列表比段落清晰
- 命令用 code block 包裹
- 避免华丽辞藻和冗余形容词
- 不使用 emoji（除非项目文化要求）

---

## 审查要点

quality-guardian 审查 CLAUDE.md 时，除了形式合规，还要检查：

- 核心铁律**具体可检验**（"写好代码"不算，"ESLint 必须无警告"算）
- Agent 调度指引**与实际 Agent 定义一致**（引用的 Agent 名称存在）
- 技术栈声明**与实际代码一致**（项目说用 React 但 package.json 没有）
- 构建命令**可以实际运行**（不是复制模板未更新）
