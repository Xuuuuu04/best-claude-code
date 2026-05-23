#!/bin/bash
# PreCompact hook: 上下文压缩前在活跃 Task 文件追加一笔,
# 防止用户最痛的"上下文炸了忘交接"。
# 输入: stdin JSON，含 .cwd
# 输出: 标准 JSON（hookSpecificOutput.additionalContext）

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
  exit 0
fi

ACTIVE_FILES=$(grep -l 'status: in_progress' "$CWD/.claude/tasks/"*.md 2>/dev/null || true)

if [ -z "$ACTIVE_FILES" ]; then
  exit 0
fi

TIMESTAMP=$(date "+%H:%M")
COUNT=$(echo "$ACTIVE_FILES" | wc -l | tr -d ' ')

# 在每个活跃 task 文件追加一行
while IFS= read -r FILE; do
  [ -n "$FILE" ] && echo "- $TIMESTAMP [PreCompact] 上下文即将压缩，自动落档" >> "$FILE"
done <<< "$ACTIVE_FILES"

# 收集文件路径
FILE_LIST=$(echo "$ACTIVE_FILES" | sed 's/^/  - /' | tr '\n' '|' | sed 's/|/\\n/g')

# 输出标准 JSON
jq -n --arg ctx "[PreCompact] 已在 ${COUNT} 个活跃 task 文件追加压缩标记。压缩后请优先重读：\n${FILE_LIST}" \
  '{hookSpecificOutput: {hookEventName: "PreCompact", additionalContext: $ctx}}'

exit 0
