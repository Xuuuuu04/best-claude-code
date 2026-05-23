#!/bin/bash
# SessionEnd hook: 会话结束时检查所有 in_progress task，
# 通过 systemMessage 提醒用户。SessionEnd 不能阻塞退出。
# 输入: stdin JSON，含 .cwd .reason
# 输出: 标准 JSON（systemMessage）

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')

if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
  exit 0
fi

ACTIVE_FILES=$(grep -l 'status: in_progress' "$CWD/.claude/tasks/"*.md 2>/dev/null || true)

if [ -z "$ACTIVE_FILES" ]; then
  exit 0
fi

COUNT=$(echo "$ACTIVE_FILES" | wc -l | tr -d ' ')

# 构建任务列表
TASK_LIST=""
while IFS= read -r FILE; do
  [ -z "$FILE" ] && continue
  TASK_ID=$(basename "$FILE" .md)
  TITLE=$(grep -m1 '^# ' "$FILE" 2>/dev/null | sed 's/^# //' || echo "(无标题)")
  TASK_LIST="${TASK_LIST}  * ${TASK_ID} — ${TITLE}
"
done <<< "$ACTIVE_FILES"

MSG="会话结束（原因: ${REASON}），有 ${COUNT} 个 Task 仍是 in_progress：

${TASK_LIST}
下次开启会话时，SessionStart hook 会再次提醒。
如果某个 task 已实质完成，下次用 /continue-task → /finish-task 补档。"

jq -n --arg msg "$MSG" \
  '{systemMessage: $msg, hookSpecificOutput: {hookEventName: "SessionEnd"}}'

exit 0
