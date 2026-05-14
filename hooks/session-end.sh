#!/bin/bash
# SessionEnd hook: 会话结束时检查所有 in_progress task,
# 提示用户是否应该先 /finish-task 再退出。
# 不强制阻塞 —— 用户可以忽略后继续退出。
# 输入: stdin JSON,含 .cwd 和 .reason
# 输出: stderr 给用户看(会话已结束,stdout 不再进入上下文)

set -e

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')

if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
  exit 0
fi

ACTIVE_FILES=$(grep -l 'status: in_progress' "$CWD/.claude/tasks/"*.md 2>/dev/null)

if [ -z "$ACTIVE_FILES" ]; then
  exit 0
fi

COUNT=$(echo "$ACTIVE_FILES" | wc -l | tr -d ' ')

# 输出到 stderr(SessionEnd 时 stdout 不再进入 Claude 上下文)
{
  echo ""
  echo "⚠️  会话结束(原因: $REASON),但有 $COUNT 个 Task 仍是 in_progress:"
  echo ""
  echo "$ACTIVE_FILES" | while read -r FILE; do
    TASK_ID=$(basename "$FILE" .md)
    TITLE=$(grep -m1 '^# ' "$FILE" | sed 's/^# //')
    echo "  • $TASK_ID — $TITLE"
  done
  echo ""
  echo "下次开启会话时,SessionStart hook 会再次提醒。"
  echo "如果某个 task 已经实质完成,只是忘了 /finish-task,下次开机时跑一下 /continue-task → /finish-task 补档。"
  echo ""
} >&2

exit 0
