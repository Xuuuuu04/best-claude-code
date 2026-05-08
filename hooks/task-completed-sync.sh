#!/usr/bin/env bash
# task-completed-sync.sh
#
# 触发：TaskCompleted hook（Agent Teams 任务完成时）
# 目的：自动同步 Agent Teams 任务完成事件到 legion-session.json
#       更新 gate_status 和 evidence，减少手工状态更新遗漏
#
# 输入：stdin JSON（含 task_id, task_title, agent_name 等）
# 输出：更新 legion-session.json 的 teams.tasks 数组和 gate_status
#
# 设计：纯审计+状态同步，不阻塞。退出码 2 可阻止完成并反馈。

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
    --arg event "TaskCompleted" \
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
      jq --arg ts "$TS" --arg tid "$TASK_ID" --arg agent "$AGENT_NAME" '
        .teams = (.teams // {})
        | .teams.tasks = (.teams.tasks // [])
        | .teams.tasks = [.teams.tasks[] | if .id == $tid then .status = "completed" | .completed_at = $ts | .completed_by = $agent else . end]
        | .updated_at = $ts
        | .evidence = (.evidence // {})
        | .evidence.team_task_completed = ($tid + ":" + $agent)
      ' "$STATE_FILE" > "$TMP_STATE" 2>/dev/null && mv "$TMP_STATE" "$STATE_FILE" 2>/dev/null || rm -f "$TMP_STATE" 2>/dev/null || true
    fi
  fi
else
  echo "{\"timestamp\":\"$TS\",\"event\":\"TaskCompleted\",\"error\":\"jq not available\"}" >> "$LOG_FILE" 2>/dev/null || true
fi

exit 0
