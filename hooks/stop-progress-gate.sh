#!/bin/bash
# Stop hook: 模型想停下来时，检查 Task 进度是否已记录
# 如果做了大量工作但没更新 Task Execution Log → 阻止停止，强制补记录
source "$(dirname "$0")/_common.sh"

_init_hook

# 没有 tasks 目录 → 不管
if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
  exit 0
fi

_find_active_tasks

# 没有活跃 Task → 不拦截
[ "$ACTIVE_COUNT" -eq 0 ] && exit 0

STATE_FILE="$CWD/.claude/tasks/.hook-state.json"

# 没有 state 文件或文件为空 → 不拦截
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

EDITS=$(jq -r '.edits_since_task_update // 0' "$STATE_FILE" 2>/dev/null)

# 阈值：做了 6+ 次编辑/命令但没更新 Task → 拦截
THRESHOLD=6

if [ "$EDITS" -ge "$THRESHOLD" ]; then
  # 找到最近的活跃 Task
  LATEST_TASK=""
  if [[ "$OSTYPE" == "darwin"* ]]; then
    LATEST_TASK=$(echo "$ACTIVE_FILES" | xargs -I {} stat -f "%m %N" {} 2>/dev/null | sort -rn | head -1 | sed 's/^[0-9]* //')
  else
    LATEST_TASK=$(echo "$ACTIVE_FILES" | xargs -I {} stat -c "%Y %n" {} 2>/dev/null | sort -rn | head -1 | sed 's/^[0-9]* //')
  fi

  TASK_NAME=""
  [ -n "$LATEST_TASK" ] && TASK_NAME=$(_task_id "$LATEST_TASK")

  # 重置计数（避免无限循环：拦一次就够了，补完后下次放行）
  TMP_STATE=$(mktemp "${STATE_FILE}.XXXXXX" 2>/dev/null || echo "${STATE_FILE}.tmp")
  jq -n '{edits_since_task_update: 0, consecutive_bash_failures: 0}' > "$TMP_STATE" && mv "$TMP_STATE" "$STATE_FILE"

  MSG="你已经做了 ${EDITS} 次操作但没有更新 Task 文件的 Execution Log。

请先在 ${TASK_NAME} 的 Execution Log 段追加本轮工作的进展记录（格式：- HH:MM 做了什么），然后再继续或结束。

如果有重要决策，也请追加到 Decisions 段。"

  jq -n --arg msg "$MSG" \
    '{decision: "block", reason: $msg}'
else
  exit 0
fi
