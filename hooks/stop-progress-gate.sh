#!/bin/bash
# Stop hook: 模型想停下来时，检查 Task 进度和 Review 状态
# 1. 6+ 次文件编辑未更新 Task Execution Log → 阻止停止，强制补记录
# 2. Task 有 Spec 但没 review 记录 → 阻止停止，提示先 review
# 3. 最新 review 未通过 → 阻止停止，提示先修
source "$(dirname "$0")/_common.sh"

_init_hook
_require_tasks_dir
_find_active_tasks

# 没有活跃 Task → 不拦截
[ "$ACTIVE_COUNT" -eq 0 ] && exit 0

STATE_FILE=$(_state_file_path)

# 找到最近的活跃 Task
LATEST_TASK=""
if [[ "$OSTYPE" == "darwin"* ]]; then
  LATEST_TASK=$(echo "$ACTIVE_FILES" | xargs -I {} stat -f "%m %N" {} 2>/dev/null | sort -rn | head -1 | sed 's/^[0-9]* //')
else
  LATEST_TASK=$(echo "$ACTIVE_FILES" | xargs -I {} stat -c "%Y %n" {} 2>/dev/null | sort -rn | head -1 | sed 's/^[0-9]* //')
fi

TASK_NAME=""
[ -n "$LATEST_TASK" ] && TASK_NAME=$(_task_id "$LATEST_TASK")

# --- 检查 1: 编辑计数 ---
if [ -f "$STATE_FILE" ]; then
  EDITS=$(jq -r '.edits_since_task_update // 0' "$STATE_FILE" 2>/dev/null)
  THRESHOLD=6

  if [ "$EDITS" -ge "$THRESHOLD" ]; then
    # 重置计数（避免无限循环：拦一次就够了）
    TMP_STATE=$(mktemp "${STATE_FILE}.XXXXXX" 2>/dev/null || echo "${STATE_FILE}.tmp")
    jq '{edits_since_task_update: 0, consecutive_bash_failures: 0, review_blocks: (.review_blocks // 0)}' "$STATE_FILE" > "$TMP_STATE" && mv "$TMP_STATE" "$STATE_FILE"

    MSG="你已经做了 ${EDITS} 次操作但没有更新 Task 文件的 Execution Log。

请先在 ${TASK_NAME} 的 Execution Log 段追加本轮工作的进展记录（格式：- HH:MM 做了什么），然后再继续或结束。

如果有重要决策，也请追加到 Decisions 段。"

    jq -n --arg msg "$MSG" '{decision: "block", reason: $msg}'
    exit 0
  fi
fi

# --- 检查 2: Review 状态(v3.0 新增) ---
if [ -n "$LATEST_TASK" ] && _task_has_spec "$LATEST_TASK"; then
  # 防死循环:连续 review block 超 3 次则降级为警告放行
  RB=0
  [ -f "$STATE_FILE" ] && RB=$(jq -r '.review_blocks // 0' "$STATE_FILE" 2>/dev/null)

  REVIEW_JSON=$(_latest_review_json)
  REVIEW_ISSUE=""

  if [ -z "$REVIEW_JSON" ]; then
    REVIEW_ISSUE="Task ${TASK_NAME} 有 Spec 段但还没有经过 review。请先跑 /bcc-review。"
  else
    _read_review_result "$REVIEW_JSON"
    if [ "$REVIEW_PASS" != "true" ]; then
      REVIEW_ISSUE="Task ${TASK_NAME} 最新 review 未通过 (Round ${REVIEW_ROUND}, weighted: ${REVIEW_WEIGHTED}, blocking: [${REVIEW_BLOCKING}])。请修复后再跑 /bcc-review。"
    fi
  fi

  if [ -n "$REVIEW_ISSUE" ]; then
    RB=$((RB + 1))
    # 写回 review_blocks 计数
    if [ -f "$STATE_FILE" ]; then
      TMP_RB=$(mktemp "${STATE_FILE}.XXXXXX" 2>/dev/null || echo "${STATE_FILE}.tmp")
      jq --argjson rb "$RB" '.review_blocks = $rb' "$STATE_FILE" > "$TMP_RB" && mv "$TMP_RB" "$STATE_FILE"
    fi

    if [ "$RB" -ge 3 ]; then
      # 3 次后降级:放行但注入警告,重置计数
      TMP_RB=$(mktemp "${STATE_FILE}.XXXXXX" 2>/dev/null || echo "${STATE_FILE}.tmp")
      jq '.review_blocks = 0' "$STATE_FILE" > "$TMP_RB" && mv "$TMP_RB" "$STATE_FILE"
      jq -n --arg msg "[⚠ review 拦截已连续 ${RB} 次,本次放行] ${REVIEW_ISSUE}" \
        '{hookSpecificOutput: {hookEventName: "Stop", additionalContext: $msg}}'
      exit 0
    fi

    jq -n --arg msg "$REVIEW_ISSUE" '{decision: "block", reason: $msg}'
    exit 0
  else
    # review 问题已解决,重置计数
    if [ -f "$STATE_FILE" ] && [ "$(jq -r '.review_blocks // 0' "$STATE_FILE" 2>/dev/null)" != "0" ]; then
      TMP_RB=$(mktemp "${STATE_FILE}.XXXXXX" 2>/dev/null || echo "${STATE_FILE}.tmp")
      jq '.review_blocks = 0' "$STATE_FILE" > "$TMP_RB" && mv "$TMP_RB" "$STATE_FILE"
    fi
  fi
fi

exit 0
