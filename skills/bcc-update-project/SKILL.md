---
name: bcc-update-project
description: 扫描代码库当前状态，更新项目级 CLAUDE.md 索引和 project-knowledge Skill。
argument-hint: "[focus?: structure | dependencies | conventions]"
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

## Phase 1.5：CLAUDE.md ↔ 代码一致性扫描（v3.5 必走）

来自漫展项目实测（memory `platform-header-default-mismatch`）——CLAUDE.md 写"X-Platform 默认 'web'"但代码 `request.ts:68` 实际是 `'applet'`，文档与代码不一致后续 Agent 全部被误导。

派遣 `repo-researcher` 做对账扫描：

```text
任务：CLAUDE.md ↔ 代码一致性核查。

读取项目根 CLAUDE.md 和所有 `.claude/CLAUDE.md` / `.claude/skills/project-knowledge/SKILL.md`。
对其中每条**具体技术声明**做反查：

要核对的声明类型（不限于）：
1. 默认值声明（"X-Platform 默认 'web'"）→ grep 实际配置文件
2. 端口声明（"开发端口 3000"）→ 查 vite.config / package.json scripts
3. 路径声明（"API 在 src/api/"）→ ls 验证
4. 命令声明（"npm run dev 启动"）→ 查 package.json scripts
5. 字段声明（"用户表有 status 字段"）→ grep schema.prisma 或 migrations
6. 依赖声明（"用 Zod 校验"）→ grep package.json dependencies

对每条不一致写入：
- CLAUDE.md 第 N 行原文
- 实际代码 file:line
- 严重程度（误导级 / 轻微）

写入 .claude/artifacts/update-consistency-{YYYYMMDD}.md。
```

**判据**：发现 ≥1 条"误导级"不一致 → bcc-update-project 必修 CLAUDE.md，**禁止**只做新增不做修正。

## Phase 2: 生成更新

基于 `update-analysis.md` + `update-consistency-*.md` 更新：
- 项目级 `.claude/skills/project-knowledge/SKILL.md`
- 根 `CLAUDE.md`（只更新精练索引，不写详细 API）
- **修正所有"误导级"不一致**（这是必做项，不是 nice-to-have）

## Phase 3: 审查

派遣 `architecture-reviewer`：

```text
任务：审查更新后的 CLAUDE.md 与 project-knowledge。
重点：
- CLAUDE.md 是否仍 <200 行
- 信息是否与实际项目一致（对照 update-consistency 报告复核）
- 是否遗漏重大变化
- **修正后是否解决了所有"误导级"不一致**
```

## Phase 4: 汇报

汇报识别的变化、已更新文件、以及是否建议运行 `/bcc-evolve`。
