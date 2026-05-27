#!/bin/bash
# SessionEnd hook: 会话结束时提醒未完成 task + 提取本次决策写入 pending-learnings
source "$(dirname "$0")/_common.sh"

_init_hook
_require_tasks_dir

REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')

_find_active_tasks

[ "$ACTIVE_COUNT" -eq 0 ] && exit 0

TASK_LIST=""
DECISIONS=""
while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue
  TID=$(_task_id "$FILE")
  TITLE=$(_task_title "$FILE")
  TASK_LIST="${TASK_LIST}  * ${TID} — ${TITLE}
"
  # 提取 Decisions 段内容（非空行）
  TASK_DECISIONS=$(sed -n '/^## Decisions$/,/^## /{/^## Decisions$/d;/^## /d;/^$/d;p}' "$FILE" 2>/dev/null || true)
  if [ -n "$TASK_DECISIONS" ]; then
    DECISIONS="${DECISIONS}
### ${TID}
${TASK_DECISIONS}
"
  fi
done <<< "$ACTIVE_FILES"

# 如果有 Decisions，写入 pending-learnings 供下次 SessionStart 提醒处理
if [ -n "$DECISIONS" ]; then
  LEARNINGS_FILE="$CWD/.claude/pending-learnings.md"
  TIMESTAMP=$(date "+%Y-%m-%d %H:%M")
  cat > "$LEARNINGS_FILE" << LEARNINGS_EOF
# Pending Learnings (extracted ${TIMESTAMP})

以下决策从本次会话的 Task 文件中自动提取。
请评估哪些值得写入 memory（feedback/project 类型），哪些是一次性决策可以丢弃。

${DECISIONS}
LEARNINGS_EOF
fi

MSG="会话结束（原因: ${REASON}），有 ${ACTIVE_COUNT} 个 Task 仍是 in_progress：

${TASK_LIST}
下次开启会话时，SessionStart hook 会再次提醒。
如果某个 task 已实质完成，下次用 /bcc-continue → /bcc-finish 补档。"

jq -n --arg msg "$MSG" \
  '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "SessionEnd"}}'
