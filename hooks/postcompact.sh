#!/bin/bash
# PostCompact hook: 压缩完成后，重新注入活跃 Task 的关键上下文，
# 防止主代理压缩后"失忆"——不知道自己在做什么 task。
# 输入: stdin JSON，含 .cwd
# 输出: 标准 JSON（hookSpecificOutput.additionalContext）

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
  exit 0
fi

ACTIVE_FILE=$(grep -l 'status: in_progress' "$CWD/.claude/tasks/"*.md 2>/dev/null | head -1 || true)

if [ -z "$ACTIVE_FILE" ]; then
  jq -n '{hookSpecificOutput: {hookEventName: "PostCompact", additionalContext: "[PostCompact] 压缩已完成。当前无活跃 Task。"}}'
  exit 0
fi

TASK_ID=$(basename "$ACTIVE_FILE" .md)
TITLE=$(grep -m1 '^# ' "$ACTIVE_FILE" 2>/dev/null | sed 's/^# //' || echo "(无标题)")

# 提取最近 5 行 Execution Log
LAST_LOGS=$(grep -E '^- [0-9]{2}:[0-9]{2} ' "$ACTIVE_FILE" 2>/dev/null | tail -5 || true)

# 提取 Plan 段（到下一个 ## 之前，最多 8 行）
PLAN=$(sed -n '/^## Plan$/,/^## /{/^## Plan$/d;/^## /d;p}' "$ACTIVE_FILE" 2>/dev/null | head -8 || true)

CONTEXT="[PostCompact] 压缩已完成。当前活跃 Task：
- 文件: ${ACTIVE_FILE}
- ID: ${TASK_ID}
- 标题: ${TITLE}

Plan:
${PLAN}

最近进展:
${LAST_LOGS}

请重读 Task 文件以恢复完整上下文，然后继续执行。"

jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "PostCompact", additionalContext: $ctx}}'

exit 0
