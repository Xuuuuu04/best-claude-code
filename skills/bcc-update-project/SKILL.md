---
name: bcc-update-project
description: 扫描代码库当前状态，更新项目级 CLAUDE.md 索引和 project-knowledge Skill。
disable-model-invocation: true
---

# 项目知识更新

此 Skill 刷新项目状态快照。它应在隔离上下文中运行，避免污染主会话。

## 模式判定

### 系统仓库模式（meta-mode）

若当前仓库就是 Agent Legion 自身：
- 检查 README 徽章数字与实际统计
- 检查 CLAUDE.md 命令表与 `skills/bcc-*` 是否一致
- 检查 LEGION.md 是否引用已移除概念
- 汇总近期 git 变更

此模式不派 reviewer，只可选运行 `bash ~/.claude/bin/doctor.sh`。

### 标准项目模式

要求项目级 `.claude/skills/project-knowledge/SKILL.md` 存在；若不存在，提示先运行 `/bcc-init-project`。

## Phase 1: 扫描

派遣 `repo-researcher`：

```text
任务：扫描代码库当前状态并对比现有 project-knowledge。

请写入 .claude/artifacts/update-analysis.md：
- 技术栈变化
- 模块变化
- API 变化
- 数据模型变化
- 近 20 条 git commit 摘要
- 现有 project-knowledge 中已过时的内容
```

## Phase 2: 生成更新

基于 `update-analysis.md` 更新：
- 项目级 `.claude/skills/project-knowledge/SKILL.md`
- 根 `CLAUDE.md`（只更新精练索引，不写详细 API）

## Phase 3: 审查

派遣 `architecture-reviewer`：

```text
任务：审查更新后的 CLAUDE.md 与 project-knowledge。
重点：
- CLAUDE.md 是否仍 <200 行
- 信息是否与实际项目一致
- 是否遗漏重大变化
```

## Phase 4: 汇报

汇报识别的变化、已更新文件、以及是否建议运行 `/bcc-evolve`。
