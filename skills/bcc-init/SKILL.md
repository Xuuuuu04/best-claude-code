---
name: bcc-init
description: 当用户说"/bcc-init"或"迁移到我们的标准"、或当前仓库明确缺少 .claude/tasks/ 目录和项目 CLAUDE.md 时激活 —— 一键把任意仓库的 AI 开发范式迁移为 BCC(Better Claude Code) 标准。不要在用户说"整理代码/整理目录"时误触。
argument-hint: "[目标目录（可选，默认当前项目）]"
---

# /bcc-init

一键把任意仓库升级为 Task-Centric Harness 标准。解决"每个新项目都要手动配一遍"的问题。

## 本次项目状态（动态注入）

!`echo "### 当前目录"; pwd; echo ""; echo "### .claude/ 存在?"; ls -la .claude/ 2>/dev/null | head -5 || echo "(不存在)"; echo ""; echo "### CLAUDE.md 存在?"; ls .claude/CLAUDE.md 2>/dev/null || ls CLAUDE.md 2>/dev/null || echo "(不存在)"; echo ""; echo "### tasks/ 存在?"; ls .claude/tasks/ 2>/dev/null | head -3 || echo "(不存在)"; echo ""; echo "### package.json / go.mod / pom.xml?"; ls package.json go.mod pom.xml pyproject.toml Cargo.toml 2>/dev/null || echo "(未检测到)"`

## 何时调用

- 用户说 `/bcc-init` / "初始化一下" / "迁移到我们的标准" / "整理一下这个项目"
- 主代理发现当前项目没有 `.claude/tasks/` 目录或缺少 CLAUDE.md
- 用户在一个新 clone 的仓库里开始工作

## 不做什么（边界）

- **不覆盖已有的项目级 CLAUDE.md** —— 只补缺失的段
- **不复制用户级 hooks/skills** —— 那些在 `~/.claude/` 已经全局生效
- **不改动业务代码** —— 只动 `.claude/` 目录和项目根配置
- **不做 git init** —— 如果不是 git 仓库，提醒用户先 `git init`

## 执行步骤

### 1. 检测当前状态

检查项目目录下已有什么：

```bash
PROJECT_DIR=$(pwd)
CLAUDE_DIR="$PROJECT_DIR/.claude"

# 检查各组件
HAS_CLAUDE_DIR=$([ -d "$CLAUDE_DIR" ] && echo "yes" || echo "no")
HAS_CLAUDE_MD=$([ -f "$CLAUDE_DIR/CLAUDE.md" ] || [ -f "$PROJECT_DIR/CLAUDE.md" ] && echo "yes" || echo "no")
HAS_TASKS=$([ -d "$CLAUDE_DIR/tasks" ] && echo "yes" || echo "no")
HAS_GITIGNORE=$([ -f "$CLAUDE_DIR/.gitignore" ] && echo "yes" || echo "no")
IS_GIT=$([ -d "$PROJECT_DIR/.git" ] && echo "yes" || echo "no")
```

输出状态摘要：
```
项目状态扫描
============
git 仓库: ✓/✗
.claude/ 目录: ✓/✗
项目 CLAUDE.md: ✓/✗
tasks/ 目录: ✓/✗
.gitignore: ✓/✗
技术栈: [检测结果]
```

### 2. 检测技术栈

自动判断项目用什么语言/框架，决定 Preflight Commands：

```bash
# 检测技术栈
if [ -f "package.json" ]; then
  STACK="node"
  # 进一步判断：有 tsconfig → TypeScript
  [ -f "tsconfig.json" ] && STACK="typescript"
  # 检测框架
  grep -q '"next"' package.json 2>/dev/null && FRAMEWORK="Next.js"
  grep -q '"vue"' package.json 2>/dev/null && FRAMEWORK="Vue"
  grep -q '"react"' package.json 2>/dev/null && FRAMEWORK="React"
elif [ -f "go.mod" ]; then
  STACK="go"
elif [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
  STACK="java"
elif [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  STACK="python"
elif [ -f "Cargo.toml" ]; then
  STACK="rust"
fi
```

根据技术栈生成对应的 Preflight Commands：

| 技术栈 | 默认命令 |
|---|---|
| TypeScript/Node | `npm run typecheck` + `npm run lint` |
| Go | `go vet ./...` + `golangci-lint run` |
| Java/Maven | `mvn compile` |
| Python | `mypy .` + `ruff check .` |
| Rust | `cargo check` + `cargo clippy` |

### 3. 创建目录结构

```bash
mkdir -p "$CLAUDE_DIR/tasks"
mkdir -p "$CLAUDE_DIR/tasks/bcc-briefs"
mkdir -p "$CLAUDE_DIR/tasks/outputs"
mkdir -p "$CLAUDE_DIR/tasks/archive"
```

### 4. 生成项目 CLAUDE.md（如果不存在）

如果项目已有 CLAUDE.md，**不覆盖**，只检查是否缺少关键段（Preflight Commands），缺则补。

如果不存在，生成模板：

```markdown
# [项目名]

## 项目概况
[一句话描述这个项目做什么]

技术栈: [自动检测结果]
主要语言: [自动检测结果]

## Preflight Commands（被 /bcc-preflight skill 读取）

提交前必跑，顺序执行，任一失败即停：
- [根据技术栈生成的命令]

## 项目结构
[让主代理填，或者用 tree 生成骨架]

## 开发约定
[项目特有的约定，如分支策略、commit 格式等]
```

**跟用户确认一次**再写入：
```
生成了项目 CLAUDE.md 模板，技术栈检测为 TypeScript + React。
Preflight 命令是 npm run typecheck + npm run lint，对吗？
```

### 5. 生成项目级 .gitignore（.claude/ 内）

如果 `$CLAUDE_DIR/.gitignore` 不存在，生成：

```gitignore
# Task 运行时状态（不进版本库）
tasks/bcc-briefs/
tasks/outputs/
tasks/archive/
tasks/.hook-state.json

# 会话临时文件
*.jsonl
*.tmp
```

如果已存在，检查是否包含上面这些关键规则，缺则补。

### 6. 检测并处理已有的 AI 开发残留

扫描项目中可能存在的其他 AI 工具配置：

```bash
# 常见 AI 工具残留
[ -f ".cursorrules" ] && echo "发现 Cursor 配置"
[ -f ".aider.conf.yml" ] && echo "发现 Aider 配置"
[ -d ".github/copilot" ] && echo "发现 Copilot 配置"
[ -f ".clinerules" ] && echo "发现 Cline 配置"
[ -f ".windsurfrules" ] && echo "发现 Windsurf 配置"
[ -f "codex.md" ] && echo "发现 Codex 配置"
```

如果发现其他工具的规则文件：
- **不删除** —— 那是用户可能还在用的
- 提醒用户：
  ```
  发现 .cursorrules，里面有些约定可能值得迁移到 CLAUDE.md。
  要我读一下看看有没有可以吸收的？
  ```

### 7. 验证 Harness 全局组件

确认用户级 `~/.claude/` 的关键组件都在位：

```bash
echo "全局 Harness 检查："
[ -f ~/.claude/CLAUDE.md ] && echo "  ✓ CLAUDE.md" || echo "  ✗ CLAUDE.md 缺失"
[ -d ~/.claude/hooks ] && echo "  ✓ hooks/ ($(ls ~/.claude/hooks/*.sh 2>/dev/null | wc -l | tr -d ' ') 个)" || echo "  ✗ hooks/ 缺失"
[ -d ~/.claude/skills ] && echo "  ✓ skills/ ($(ls -d ~/.claude/skills/*/ 2>/dev/null | wc -l | tr -d ' ') 个)" || echo "  ✗ skills/ 缺失"
[ -d ~/.claude/rules ] && echo "  ✓ rules/ ($(ls ~/.claude/rules/*.md 2>/dev/null | wc -l | tr -d ' ') 个)" || echo "  ✗ rules/ 缺失"
```

如果全局组件有缺失，报告而不是自动修复（全局配置不在项目里动）。

### 8. 输出最终报告

```
BCC 初始化完成
==============

新建：
  ✓ .claude/tasks/ 目录结构（tasks/bcc-briefs/outputs/archive）
  ✓ .claude/CLAUDE.md（技术栈：TypeScript + React）
  ✓ .claude/.gitignore

已有（保留）：
  - .cursorrules（建议迁移后删除）

全局 Harness 状态：
  ✓ 6 个 hooks 已注册
  ✓ 9 个 skills 可用
  ✓ 3 条 rules 生效

Preflight 命令：
  1. npm run typecheck
  2. npm run lint

下一步：
  1. 看看生成的 CLAUDE.md，补充项目概况和开发约定
  2. 开始工作时说你要做什么，我会自动开 Task
```

## 已有项目的增量升级

如果项目已经有 `.claude/` 但版本旧（比如 Legion 残留），做增量升级：

1. **保留** 所有 Task 文件（历史记录）
2. **保留** 项目级 CLAUDE.md 的业务内容
3. **补齐** 缺失的目录结构（briefs/outputs/archive）
4. **补齐** 缺失的 Preflight Commands 段
5. **清理** 明确的残留（如 `state/clarification-pending-*.json`）
6. 输出变更清单让用户确认

## 多端项目处理

如果检测到项目有多个子目录各有自己的 package.json / go.mod：

```
检测到多端项目结构：
  web/ (TypeScript + React)
  miniapp/ (TypeScript)
  backend/ (Go)

建议在 CLAUDE.md 加 Cross-end Shared 段（供 /bcc-cross-sync 使用）。
要现在加吗？
```

## 反例（别这样做）

- 不覆盖用户已有的 CLAUDE.md 内容
- 不删除其他 AI 工具的配置文件
- 不在项目级复制全局 hooks/skills（它们已经通过 `~/.claude/` 全局生效）
- 不自动 commit —— 初始化完让用户看一眼再决定
- 不在非 git 仓库里强行初始化 —— 先提醒 `git init`
