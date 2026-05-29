#!/bin/bash
# hooks/_common.sh — 6 个事件 hook 共享的基础函数
# 用法: source "$(dirname "$0")/_common.sh"

if ! command -v jq &>/dev/null; then
  echo '{"error":"jq not installed. brew install jq (macOS) / apt install jq (Linux)"}' >&2
  exit 1
fi

_init_hook() {
  INPUT=$(cat)
  CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
}

_require_tasks_dir() {
  if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
    exit 0
  fi
}

_find_active_tasks() {
  ACTIVE_FILES=$(grep -l 'status: in_progress' "$CWD/.claude/tasks/"*.md 2>/dev/null || true)
  if [ -n "$ACTIVE_FILES" ]; then
    ACTIVE_COUNT=$(echo "$ACTIVE_FILES" | wc -l | tr -d ' ')
  else
    ACTIVE_COUNT=0
  fi
}

_task_id()       { basename "$1" .md; }
_task_title()    { grep -m1 '^# ' "$1" 2>/dev/null | sed 's/^# //' || echo "(无标题)"; }
_task_last_log() { grep -E '^- [0-9]{2}:[0-9]{2} ' "$1" 2>/dev/null | tail -1 | sed 's/^- //' || true; }

_reset_hook_state() {
  local state_file="$CWD/.claude/tasks/.hook-state.json"
  if [ -f "$state_file" ]; then
    local tmp=$(mktemp "${state_file}.XXXXXX" 2>/dev/null || echo "${state_file}.tmp")
    echo '{"edits_since_task_update":0,"consecutive_bash_failures":0}' > "$tmp" && mv "$tmp" "$state_file"
  fi
}
