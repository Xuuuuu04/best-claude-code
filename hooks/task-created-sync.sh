#!/usr/bin/env bash
# task-created-sync.sh
#
# 触发：TaskCreated hook（Agent Teams 任务创建时）
# 目的：自动同步 Agent Teams 任务创建事件到 legion-session.json
#
# 输入：stdin JSON（含 task_id, task_title, agent_name 等）
# 输出：更新 legion-session.json 的 teams.tasks 数组
#
# 设计：纯审计+状态同步，不阻塞，不返回额外 context

set -uo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/team-task-events.jsonl"

TS="$(date +%Y-%m-%dT%H:%M:%S%z)"

if command -v jq >/dev/null 2>&1; then
  TASK_ID="$(echo "$INPUT" | jq -r '.task_id // empty' 2>/dev/null || echo "")"
  TASK_TITLE="$(echo "$INPUT" | jq -r '.task_title // empty' 2>/dev/null || echo "")"
  AGENT_NAME="$(echo "$INPUT" | jq -r '.agent_name // empty' 2>/dev/null || echo "")"
  SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")"
  CWD="$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")"

  jq -c -n \
    --arg ts "$TS" \
    --arg event "TaskCreated" \
    --arg tid "$TASK_ID" \
    --arg title "$TASK_TITLE" \
    --arg agent "$AGENT_NAME" \
    --arg session "$SESSION_ID" \
    '{timestamp: $ts, event: $event, task_id: $tid, title: $title, agent: $agent, session_id: $session}' \
    >> "$LOG_FILE" 2>/dev/null || true

  LIB="$HOME/.claude/hooks/_lib/legion-state.sh"
  if [ -r "$LIB" ]; then
    . "$LIB"
    STATE_FILE="$(legion_state_file "$CWD" 2>/dev/null || echo "")"
    if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ]; then
      TMP_STATE="$(mktemp -t legion-state-XXXXXX 2>/dev/null || echo "/tmp/legion-state-$$")"
      jq --arg ts "$TS" --arg tid "$TASK_ID" --arg title "$TASK_TITLE" --arg agent "$AGENT_NAME" '
        .teams = (.teams // {})
        | .teams.tasks = (.teams.tasks // [])
        | .teams.tasks += [{"id": $tid, "title": $title, "agent": $agent, "status": "created", "created_at": $ts}]
        | .updated_at = $ts
      ' "$STATE_FILE" > "$TMP_STATE" 2>/dev/null && mv "$TMP_STATE" "$STATE_FILE" 2>/dev/null || rm -f "$TMP_STATE" 2>/dev/null || true
    fi
  fi
else
  echo "{\"timestamp\":\"$TS\",\"event\":\"TaskCreated\",\"error\":\"jq not available\"}" >> "$LOG_FILE" 2>/dev/null || true
fi

exit 0
