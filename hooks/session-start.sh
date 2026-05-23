#!/bin/bash
# SessionStart hook: 会话开始时扫描当前项目的 in_progress task，
# 提示主代理是否恢复某个未完成任务。
# 输入: stdin JSON，含 .cwd .source
# 输出: 标准 JSON（hookSpecificOutput.additionalContext + watchPaths）

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
  exit 0
fi

ACTIVE_FILES=$(grep -l 'status: in_progress' "$CWD/.claude/tasks/"*.md 2>/dev/null || true)

if [ -z "$ACTIVE_FILES" ]; then
  exit 0
fi

COUNT=$(echo "$ACTIVE_FILES" | wc -l | tr -d ' ')

# 跨平台 stat 排序：macOS 用 -f，Linux 用 -c
if [[ "$OSTYPE" == "darwin"* ]]; then
  SORTED_FILES=$(echo "$ACTIVE_FILES" | xargs -I {} stat -f "%m %N" {} 2>/dev/null | sort -rn | head -5)
else
  SORTED_FILES=$(echo "$ACTIVE_FILES" | xargs -I {} stat -c "%Y %n" {} 2>/dev/null | sort -rn | head -5)
fi

# 构建任务列表文本
TASK_LIST=""
while IFS= read -r LINE; do
  [ -z "$LINE" ] && continue
  FILE=$(echo "$LINE" | sed 's/^[0-9]* //')
  [ -z "$FILE" ] || [ ! -f "$FILE" ] && continue
  TASK_ID=$(basename "$FILE" .md)
  TITLE=$(grep -m1 '^# ' "$FILE" 2>/dev/null | sed 's/^# //' || echo "(无标题)")
  STARTED=$(grep -m1 '^started:' "$FILE" 2>/dev/null | sed 's/^started: //' || echo "unknown")
  LAST_LOG=$(grep -E '^- [0-9]{2}:[0-9]{2} ' "$FILE" 2>/dev/null | tail -1 | sed 's/^- //' || true)

  TASK_LIST="${TASK_LIST}  * ${TASK_ID}
    标题: ${TITLE}
    开始: ${STARTED}
"
  [ -n "$LAST_LOG" ] && TASK_LIST="${TASK_LIST}    最近: ${LAST_LOG}
"
  TASK_LIST="${TASK_LIST}
"
done <<< "$SORTED_FILES"

CONTEXT="检测到 ${COUNT} 个进行中的 Task（本项目）：

${TASK_LIST}用 /continue-task 选一个恢复，或直接说新诉求开新 task。"

jq -n --arg ctx "$CONTEXT" --arg wp "$CWD/.claude/tasks/" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx, watchPaths: [$wp]}}'

exit 0
