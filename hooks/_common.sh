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
  # session_id 要进文件名,白名单消毒(正常值是 CC 生成的 UUID)
  SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "default"' | tr -cd 'A-Za-z0-9_-')
  [ -n "$SESSION_ID" ] || SESSION_ID="default"
}

_require_tasks_dir() {
  # CWD=$HOME 时 $CWD/.claude/tasks 是 Claude Code 内部目录,不是 BCC 项目
  [ "$CWD" = "$HOME" ] && exit 0
  if [ -z "$CWD" ] || [ ! -d "$CWD/.claude/tasks" ]; then
    exit 0
  fi
}

_find_active_tasks() {
  # 行首锚定:只认 frontmatter 里顶格的 status,避免正文引用 "status: in_progress" 字面串被误判
  ACTIVE_FILES=$(grep -lE '^status: in_progress' "$CWD/.claude/tasks/"*.md 2>/dev/null || true)
  if [ -n "$ACTIVE_FILES" ]; then
    ACTIVE_COUNT=$(echo "$ACTIVE_FILES" | wc -l | tr -d ' ')
  else
    ACTIVE_COUNT=0
  fi
}

_task_id()       { basename "$1" .md; }
_task_title()    { local t; t=$(grep -m1 '^# ' "$1" 2>/dev/null | sed 's/^# //'); echo "${t:-(无标题)}"; }
_task_last_log() { grep -E '^- [0-9]{2}:[0-9]{2} ' "$1" 2>/dev/null | tail -1 | sed 's/^- //' || true; }

# state 按 session 隔离:同 cwd 多会话/agent teams 下计数不互相污染
_state_file_path() { echo "$CWD/.claude/tasks/.hook-state.${SESSION_ID:-default}.json"; }

# 读 state 到 EDITS / FAILURES,文件不存在则初始化(posttooluse-guard / posttoolusefailure 共用)
_load_hook_state() {
  STATE_FILE=$(_state_file_path)
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

# --- Review 状态读取(v3.0 新增) ---

# 检查 Task 是否有 Spec 段(有 Spec 才需要量化 review)
_task_has_spec() {
  grep -q '^## Spec' "$1" 2>/dev/null
}

# 获取最新 review JSON 路径(按文件名排序取最后一个)
_latest_review_json() {
  ls -1 "$CWD/.claude/tasks/outputs/review-"*".json" 2>/dev/null | sort | tail -1
}

# 从 review JSON 读 pass/weighted_score/blocking_dimensions
_read_review_result() {
  local json_file="$1"
  [ -f "$json_file" ] || return 1
  REVIEW_PASS=$(jq -r '.pass // false' "$json_file")
  REVIEW_WEIGHTED=$(jq -r '.weighted_score // 0' "$json_file")
  REVIEW_BLOCKING=$(jq -r '(.blocking_dimensions // []) | join(", ")' "$json_file")
  REVIEW_ROUND=$(jq -r '.round // 0' "$json_file")
}
