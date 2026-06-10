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

# 读 state 到 EDITS / FAILURES,文件不存在则初始化(posttooluse-guard / posttoolusefailure 共用)
_load_hook_state() {
  STATE_FILE="$CWD/.claude/tasks/.hook-state.json"
  if [ ! -f "$STATE_FILE" ]; then
    echo '{"edits_since_task_update":0,"consecutive_bash_failures":0}' > "$STATE_FILE"
  fi
  EDITS=$(jq -r '.edits_since_task_update // 0' "$STATE_FILE")
  FAILURES=$(jq -r '.consecutive_bash_failures // 0' "$STATE_FILE")
}

# 原子写回 EDITS / FAILURES(mktemp + mv,中断也不会写出半截 JSON)
_save_hook_state() {
  local tmp
  tmp=$(mktemp "${STATE_FILE}.XXXXXX" 2>/dev/null || echo "${STATE_FILE}.tmp")
  jq -n --argjson e "$EDITS" --argjson f "$FAILURES" \
    '{edits_since_task_update: $e, consecutive_bash_failures: $f}' > "$tmp" && mv "$tmp" "$STATE_FILE"
}
