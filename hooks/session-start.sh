#!/bin/bash
# session-start.sh
# 目的：在会话启动时注入项目最新状态
# 触发：SessionStart hook（startup | resume | clear | compact）

set -euo pipefail

INPUT=$(cat)

# 取出触发源（如需区分不同处理）
SOURCE=$(echo "$INPUT" | jq -r '.source // "startup"' 2>/dev/null || echo "startup")

# 收集 git 状态（如果当前是 git 仓库）
GIT_BRANCH=""
GIT_STATUS=""
RECENT_COMMITS=""
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  GIT_STATUS=$(git status --short 2>/dev/null | head -15)
  RECENT_COMMITS=$(git log --oneline -5 2>/dev/null)
fi

# 收集进行中的 artifact（如目录存在）
PENDING_ARTIFACTS=""
if [ -d ".claude/artifacts" ]; then
  PENDING_ARTIFACTS=$(ls .claude/artifacts/*.md 2>/dev/null | head -10 | sed 's|^|- |')
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
  fi
fi

if [ -n "$PENDING_ARTIFACTS" ]; then
  CONTEXT+="\n### 进行中的交接文件\n${PENDING_ARTIFACTS}\n"
fi

# 如无有效上下文，不注入
if [ -z "$CONTEXT" ]; then
  exit 0
fi

# 输出 JSON，供 Claude 注入为 additionalContext
jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: $ctx
  }
}'
