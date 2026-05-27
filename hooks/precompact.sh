#!/bin/bash
# PreCompact hook: 压缩前在活跃 Task 文件追加标记
source "$(dirname "$0")/_common.sh"

_init_hook
_require_tasks_dir
_find_active_tasks

[ "$ACTIVE_COUNT" -eq 0 ] && exit 0

TIMESTAMP=$(date "+%H:%M")

while IFS= read -r FILE; do
  [ -n "$FILE" ] && echo "- $TIMESTAMP [PreCompact] 上下文即将压缩，自动落档" >> "$FILE"
done <<< "$ACTIVE_FILES"

FILE_LIST=$(echo "$ACTIVE_FILES" | sed 's/^/  - /' | tr '\n' '|' | sed 's/|/\\n/g')

jq -n --arg ctx "[PreCompact] 已在 ${ACTIVE_COUNT} 个活跃 task 文件追加压缩标记。压缩后请优先重读：\n${FILE_LIST}" \
  '{hookSpecificOutput: {hookEventName: "PreCompact", additionalContext: $ctx}}'
