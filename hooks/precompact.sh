#!/bin/bash
# PreCompact hook: 上下文压缩前在活跃 Task 文件追加一笔,
# 防止用户最痛的"上下文炸了忘交接"。
# 输入: stdin JSON,含 .cwd
# 输出: stdout 注入到压缩后的上下文(让主代理记得 task 文件位置)

set -e

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty')

if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
  exit 0
fi

# 找当前 in_progress 的 task
ACTIVE_FILES=$(grep -l 'status: in_progress' "$CWD/.claude/tasks/"*.md 2>/dev/null)

if [ -z "$ACTIVE_FILES" ]; then
  exit 0
fi

TIMESTAMP=$(date "+%H:%M")
COUNT=$(echo "$ACTIVE_FILES" | wc -l | tr -d ' ')

# 在每个活跃 task 文件追加一行
echo "$ACTIVE_FILES" | while read -r FILE; do
  echo "- $TIMESTAMP [PreCompact] 上下文即将压缩,自动落档" >> "$FILE"
done

# 输出给主代理(压缩后会作为 additionalContext)
echo "[PreCompact hook] 已在 $COUNT 个活跃 task 文件追加压缩标记。压缩后建议优先重读:"
echo "$ACTIVE_FILES" | while read -r FILE; do
  echo "  - $FILE"
done

exit 0
