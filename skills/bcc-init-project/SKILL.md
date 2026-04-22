---
name: bcc-init-project
description: 首次进入新项目时初始化 Claude Code 配置。生成 CLAUDE.md、各子目录 CLAUDE.md、项目知识 Skill。
disable-model-invocation: true
---

# 项目初始化

`$ARGUMENTS` 是项目简介（用户可选传入，如"一个全栈 Web 应用，React + Node.js + PostgreSQL"）。

此 Skill 用于**首次**为项目建立 Agent Legion 配置。已有配置的项目请使用 `/bcc-update-project`。

---

## 预备检查

1. 检查 `.claude/` 目录是否存在
2. 如已有 `CLAUDE.md` 或 `.claude/agents/` 等配置，警告用户并询问是否覆盖
3. 使用 `AskUserQuestion` 确认项目类型和技术栈（如 $ARGUMENTS 未提供足够信息）

---

## Phase 1: 分析代码库

派遣 researcher 做全面扫描：

```
任务：扫描项目代码库，产出初始化所需的信息。

请输出以下内容到 .claude/artifacts/init-analysis.md：
1. 项目类型（Web / 移动 / CLI / 库 / 多体）
2. 技术栈清单
   - 主要语言及版本
   - 框架（React/Vue/Express/Spring 等）
   - 数据库
   - 测试框架
   - 构建工具
3. 目录结构（前 3 层）
4. 核心模块列表（每个模块一行描述）
5. 入口文件（main/index/app）
6. 对外 API 端点清单（如适用）
7. 构建/测试/lint 命令（从 package.json/Makefile/pom.xml 等提取）
8. 已有的 CI/CD 配置（.github/workflows, .gitlab-ci.yml 等）
9. 代码风格线索（已有 .eslintrc, .prettierrc, pyproject.toml 等）
```

---

## Phase 2: 用户确认

向用户展示 researcher 的分析结果，使用 AskUserQuestion 确认：

- 项目的一句话描述（用于 CLAUDE.md）
- 哪些是核心模块（需要写入 CLAUDE.md 模块概要）
- 是否需要创建特定子目录的 CLAUDE.md（如 `src/api/CLAUDE.md`）
- 是否存在"核心铁律"（如"永不修改 legacy/"）

---

## Phase 3: 生成配置

### 3.1 根 CLAUDE.md

基于分析结果 + 用户确认，按 `rules/_global/claudemd-standard.md` 规范生成根 CLAUDE.md。

结构：
1. 项目身份
2. 技术栈
3. 构建/测试命令
4. 核心模块
5. 核心铁律
6. Agent 调度指引（从本 Skill 的内置模板引用）
7. @imports（README.md、package.json 等）

### 3.2 子目录 CLAUDE.md（可选）

对于 `src/api/`、`src/frontend/`、`prisma/` 等有独立约定的目录，生成简化版子 CLAUDE.md：

```markdown
# {模块名}

{模块职责 1-2 句话}

## 约定
- {模块内的特定规则}

## 接口
{模块对外暴露的主要接口}
```

### 3.3 project-knowledge Skill

生成 `.claude/skills/_domain/project-knowledge/SKILL.md`：

```markdown
---
name: project-knowledge
description: 项目全局知识库，包含模块关系、API 索引、技术栈详情和迭代进度
---

# 项目知识库

> 此文件由 /bcc-update-project 命令维护。手动编辑仅应用于修正，结构性更新请运行 /bcc-update-project。
> 首次生成：{timestamp}

## 技术栈详情
{从 init-analysis 提取}

## 模块依赖关系
```
{目录树 + 依赖关系}
```

## API 端点索引
| 路径 | 方法 | 描述 | 认证 |
|:--|:--|:--|:--|
{如适用}

## 数据模型概要
{如有 DB，列出核心表/集合}

## 当前迭代进度
- {基于 git 近期提交推测或留空待用户填写}

## 变更日志
- {timestamp}: 项目初始化
```

### 3.4 基础 artifacts 目录

```bash
mkdir -p .claude/artifacts
```

### 3.5 .gitignore 更新（如需）

确认以下路径在 .gitignore 中：
```
.claude/artifacts/
.claude/backups/
.claude/agent-memory-local/
CLAUDE.local.md
```

---

## Phase 4: 验证

派遣 quality-guardian 审查生成的配置：

```
审查类型：architecture-review
审查对象：CLAUDE.md、.claude/skills/_domain/project-knowledge/SKILL.md

请验证：
- CLAUDE.md 符合 rules/_global/claudemd-standard.md 规范
- project-knowledge 内容完整
- 行数不超过 200（CLAUDE.md）
```

如审查不通过，根据反馈修订。

---

## Phase 5: 向用户汇报

```markdown
## 项目初始化完成：{项目名}

**创建的文件**:
- CLAUDE.md（{N} 行）
- .claude/skills/_domain/project-knowledge/SKILL.md
- {列出其他创建的文件}

**技术栈识别**:
- 语言：{...}
- 框架：{...}
- 数据库：{...}

**推荐的下一步**:
1. 人工检查 CLAUDE.md 中的"核心铁律"是否完整
2. 根据项目实际情况补充 `.claude/rules/` 下的特定规范
3. 首次使用 `/bcc-new-feature` 或 `/bcc-fix-bug` 流水线尝试 Agent Legion

如需更新项目状态，随时运行 `/bcc-update-project`。
```

---

## 注意事项

- 初始化不激活 Agent 定义——Agent 定义在 `~/.claude/agents/` 是全局的，无需重复创建
- 不生成不必要的文件：如果项目简单（如单文件脚本），不需要子目录 CLAUDE.md
- 用户已有自定义 Rules 时，不覆盖——只添加项目级规则到 `.claude/rules/`
