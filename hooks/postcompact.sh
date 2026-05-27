#!/bin/bash
# PostCompact hook: 压缩完成后重新注入所有活跃 Task 的关键上下文
source "$(dirname "$0")/_common.sh"

_init_hook
_require_tasks_dir
_find_active_tasks

if [ "$ACTIVE_COUNT" -eq 0 ]; then
  jq -n '{hookSpecificOutput: {hookEventName: "PostCompact", additionalContext: "[PostCompact] 压缩已完成。当前无活跃 Task。"}}'
  exit 0
fi

CONTEXT="[PostCompact] 压缩已完成。当前有 ${ACTIVE_COUNT} 个活跃 Task："

while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue
  TID=$(_task_id "$FILE")
  TITLE=$(_task_title "$FILE")
  LAST_LOGS=$(grep -E '^- [0-9]{2}:[0-9]{2} ' "$FILE" 2>/dev/null | tail -5 || true)
  PLAN=$(sed -n '/^## Plan$/,/^## /{/^## Plan$/d;/^## /d;p}' "$FILE" 2>/dev/null | head -8 || true)

  CONTEXT="${CONTEXT}

--- ${TID} ---
文件: ${FILE}
标题: ${TITLE}
Plan:
${PLAN}
最近进展:
${LAST_LOGS}"
done <<< "$ACTIVE_FILES"

CONTEXT="${CONTEXT}

请重读 Task 文件以恢复完整上下文，然后继续执行。"

jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "PostCompact", additionalContext: $ctx}}'
