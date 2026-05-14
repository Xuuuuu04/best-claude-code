#!/bin/bash
# SessionStart hook: 会话开始时扫描当前项目的 in_progress task,
# 提示用户是否恢复某个未完成任务。
# 输入: stdin JSON,含 .cwd
# 输出: stdout 注入到会话开头上下文,主代理会"看到"这个提示

set -e

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
  exit 0
fi

ACTIVE_FILES=$(grep -l 'status: in_progress' "$CWD/.claude/tasks/"*.md 2>/dev/null)

if [ -z "$ACTIVE_FILES" ]; then
  exit 0
fi

COUNT=$(echo "$ACTIVE_FILES" | wc -l | tr -d ' ')

echo "📋 检测到 $COUNT 个进行中的 Task(本项目):"
echo ""

# 最近 5 个,按修改时间倒序
echo "$ACTIVE_FILES" | xargs -I {} stat -f "%m {}" {} 2>/dev/null | sort -rn | head -5 | while read -r MTIME FILE; do
  TASK_ID=$(basename "$FILE" .md)
  TITLE=$(grep -m1 '^# ' "$FILE" | sed 's/^# //')
  STARTED=$(grep -m1 '^started:' "$FILE" | sed 's/^started: //')
  LAST_LOG=$(grep -E '^- [0-9]{2}:[0-9]{2} ' "$FILE" | tail -1 | sed 's/^- //')
  echo "  • $TASK_ID"
  echo "    标题: $TITLE"
  echo "    开始: $STARTED"
  [ -n "$LAST_LOG" ] && echo "    最近: $LAST_LOG"
  echo ""
done

echo "用 /continue-task 选一个恢复,或直接说新诉求开新 task。"

exit 0
