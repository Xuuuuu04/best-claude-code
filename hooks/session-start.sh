#!/bin/bash
# session-start.sh
# 目的：在会话启动时注入项目最新状态
# 触发：SessionStart hook（startup | resume | clear | compact）
#
# 设计原则：hook 失败不能阻塞 Claude Code。所有可能失败的命令都 || true，
# 并且不使用 set -e（防止新仓库无 commit 时 git log 退出 128 炸掉整个脚本）。

set -uo pipefail

INPUT="$(cat || true)"

# 取出触发源（可选）
SOURCE="$(echo "$INPUT" | jq -r '.source // "startup"' 2>/dev/null || echo "startup")"

# 收集 git 状态（容错处理：新仓库、无 commits、非 git 目录都不报错）
GIT_BRANCH=""
GIT_STATUS=""
RECENT_COMMITS=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_BRANCH="$(git branch --show-current 2>/dev/null || echo "")"
  GIT_STATUS="$(git status --short 2>/dev/null | head -15 || true)"
  # git log 在无 commit 的新仓库上退出 128，用 || 吞掉
  RECENT_COMMITS="$(git log --oneline -5 2>/dev/null || true)"
fi

# 收集进行中的 artifact（如目录存在）
PENDING_ARTIFACTS=""
if [ -d ".claude/artifacts" ]; then
  PENDING_ARTIFACTS="$(ls .claude/artifacts/*.md 2>/dev/null | head -10 | sed 's|^|- |' || true)"
fi

# 组装注入文本
CONTEXT=""
if [ -n "$GIT_BRANCH" ]; then
  CONTEXT+="## 当前项目状态\n"
  CONTEXT+="- 分支: ${GIT_BRANCH}\n"
  if [ -n "$GIT_STATUS" ]; then
    CONTEXT+="\n### 未提交改动\n\`\`\`\n${GIT_STATUS}\n\`\`\`\n"
  fi
  if [ -n "$RECENT_COMMITS" ]; then
    CONTEXT+="\n### 最近提交\n\`\`\`\n${RECENT_COMMITS}\n\`\`\`\n"
  else
    CONTEXT+="\n_（新仓库，尚无提交）_\n"
  fi
fi

if [ -n "$PENDING_ARTIFACTS" ]; then
  CONTEXT+="\n### 进行中的交接文件\n${PENDING_ARTIFACTS}\n"
fi

# 如无有效上下文，不注入
if [ -z "$CONTEXT" ]; then
  exit 0
fi

# 输出 JSON，供 Claude 注入为 additionalContext（jq 失败也不炸）
jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}' 2>/dev/null || true

# ── 机会性日志轮转（~10% 会话概率触发，通常 no-op）──────────────────────────
if [ -x "$HOME/.claude/bin/rotate-logs.sh" ] && [ $((RANDOM % 10)) -eq 0 ]; then
  bash "$HOME/.claude/bin/rotate-logs.sh" >/dev/null 2>&1 || true
fi

exit 0
