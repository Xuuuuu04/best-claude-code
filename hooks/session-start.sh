#!/bin/bash
# SessionStart hook: 会话开始时扫描 in_progress task,注入恢复上下文
source "$(dirname "$0")/_common.sh"

_init_hook
_require_tasks_dir
_find_active_tasks

# 清理 7 天没动过的 state 文件(state 按 session 隔离后会逐渐累积)
find "$CWD/.claude/tasks" -maxdepth 1 -name '.hook-state*.json' -mtime +7 -delete 2>/dev/null || true

CONTEXT=""

# 活跃 task 扫描
if [ "$ACTIVE_COUNT" -gt 0 ]; then
  # 跨平台 stat 排序
  if [[ "$OSTYPE" == "darwin"* ]]; then
    SORTED_FILES=$(echo "$ACTIVE_FILES" | xargs -I {} stat -f "%m %N" {} 2>/dev/null | sort -rn | head -5)
  else
    SORTED_FILES=$(echo "$ACTIVE_FILES" | xargs -I {} stat -c "%Y %n" {} 2>/dev/null | sort -rn | head -5)
  fi

  TASK_LIST=""
  while IFS= read -r LINE; do
    [ -z "$LINE" ] && continue
    FILE=$(echo "$LINE" | sed 's/^[0-9]* //')
    [ -z "$FILE" ] || [ ! -f "$FILE" ] && continue
    TID=$(_task_id "$FILE")
    TITLE=$(_task_title "$FILE")
    STARTED=$(grep -m1 '^started:' "$FILE" 2>/dev/null | sed 's/^started: //' || echo "unknown")
    LAST_LOG=$(_task_last_log "$FILE")

    TASK_LIST="${TASK_LIST}  * ${TID}
    标题: ${TITLE}
    开始: ${STARTED}
"
    [ -n "$LAST_LOG" ] && TASK_LIST="${TASK_LIST}    最近: ${LAST_LOG}
"
    TASK_LIST="${TASK_LIST}
"
  done <<< "$SORTED_FILES"

  CONTEXT="${CONTEXT}检测到 ${ACTIVE_COUNT} 个进行中的 Task（本项目）：

${TASK_LIST}恢复方式：直接 Read 对应 Task 文件，在 Execution Log 记一行恢复后继续；或直接说新诉求开新 task。"
fi

# 如果没有任何上下文需要注入，静默退出
[ -z "$CONTEXT" ] && exit 0

jq -n --arg ctx "$CONTEXT" --arg wp "$CWD/.claude/tasks/" \
  '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $ctx, watchPaths: [$wp]}}'
