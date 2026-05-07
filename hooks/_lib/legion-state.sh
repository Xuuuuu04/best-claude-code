#!/bin/bash
# Shared state helpers for Agent Legion hooks.

set -uo pipefail

legion_state_dir() {
  local cwd="${1:-}"
  local proj="${CLAUDE_PROJECT_DIR:-}"

  if [ -n "$proj" ]; then
    if [ "$(basename "$proj" 2>/dev/null || echo "")" = ".claude" ]; then
      printf '%s\n' "$proj/state"
      return 0
    fi
    if [ -d "$proj/.claude" ]; then
      printf '%s\n' "$proj/.claude/state"
      return 0
    fi
  fi

  if [ -n "$cwd" ]; then
    if [ "$(basename "$cwd" 2>/dev/null || echo "")" = ".claude" ]; then
      printf '%s\n' "$cwd/state"
      return 0
    fi
    if [ -d "$cwd/.claude" ]; then
      printf '%s\n' "$cwd/.claude/state"
      return 0
    fi
  fi

  printf '%s\n' "$HOME/.claude/state"
}

legion_state_file() {
  local cwd="${1:-}"
  printf '%s/legion-session.json\n' "$(legion_state_dir "$cwd")"
}

legion_event_log() {
  printf '%s/.claude/logs/legion-events.jsonl\n' "$HOME"
}

