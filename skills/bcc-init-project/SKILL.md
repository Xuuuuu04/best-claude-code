---
name: bcc-init-project
description: 首次进入新项目时初始化 Claude Code 配置，生成项目级 CLAUDE.md 与知识索引。
disable-model-invocation: true
---

# 项目初始化

`$ARGUMENTS` 是项目简介。此 Skill 为新项目建立 Agent Legion 配置。

## 预备检查

1. 检查 `.claude/` 目录是否存在
2. 如已有 `CLAUDE.md` / 项目级 `.claude/skills/project-knowledge`，询问是否覆盖
3. 若 `$ARGUMENTS` 信息不足，使用 `AskUserQuestion` 补齐项目类型和技术栈

## Phase 1: 仓库扫描

派遣 `repo-researcher`：

```text
任务：扫描项目代码库并产出初始化信息。

请写入 .claude/artifacts/init-analysis.md，包含：
- 项目类型
- 技术栈清单
- 目录结构（前 3 层）
- 核心模块列表
- 入口文件
- API 端点（如适用）
- 构建/测试/lint 命令
- 现有 CI/CD 配置
- 代码风格线索
```

## Phase 2: 用户确认

基于 `init-analysis.md`，确认：
- 项目的一句话描述
- 核心模块与核心铁律
- 是否需要为特定子目录生成子 CLAUDE.md

## Phase 3: 生成配置

### 3.1 根 CLAUDE.md

按 `rules/_global/claudemd-standard.md` 生成项目级 CLAUDE.md。

### 3.2 子目录 CLAUDE.md（可选）

为 `src/api/`、`src/frontend/`、`prisma/` 等独立模块生成简化版约定。

### 3.3 project-knowledge Skill

基于用户级 `project-knowledge-template` 生成项目级 `.claude/skills/project-knowledge/SKILL.md`，记录技术栈、模块关系、API 索引、数据模型概要和变更日志。不得把具体项目知识写回用户级 `~/.claude/skills/`。

### 3.4 基础目录

创建：
- `.claude/artifacts/`
- `.claude/rules/`（如需要）

### 3.5 .gitignore

确保以下路径被忽略：
- `.claude/artifacts/`
- `.claude/backups/`
- `.claude/agent-memory-local/`
- `.claude/instructions-log.txt`
- `CLAUDE.local.md`

## Phase 4: 审查

派遣 `architecture-reviewer`：

```text
任务：审查初始化生成的 CLAUDE.md 与 project-knowledge。
对象：
- CLAUDE.md
- .claude/skills/project-knowledge/SKILL.md
```

## Phase 5: 汇报

汇报创建的文件、识别的技术栈，以及推荐的下一步（首次试用 `/bcc-new-feature` 或 `/bcc-fix-bug`）。
