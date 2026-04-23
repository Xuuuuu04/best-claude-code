#!/bin/bash
# _lib/run-with-logging.sh
# Helper: wraps a hook invocation so any non-zero exit or stderr output
# gets appended to an error log. Works as a "tee+capture" layer.
#
# Usage (from settings.json):
#   "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/actual-hook.sh"
#
# Log destinations:
#   - Project: $CLAUDE_PROJECT_DIR/.claude/hook-errors.log  (if project dir exists)
#   - Global:  $HOME/.claude/logs/hook-errors.log          (always)
#
# Each entry: timestamp | hook-path | exit-code | stderr-snippet

set -uo pipefail

HOOK_SCRIPT="${1:-}"
shift || true

if [ -z "$HOOK_SCRIPT" ] || [ ! -x "$HOOK_SCRIPT" ]; then
  # Invalid wrapper use — let the real hook fail naturally rather than swallow
  exec "$HOOK_SCRIPT" "$@"
fi

# Pass stdin through unchanged, capture stderr separately
STDERR_TMP="$(mktemp -t cc-hook-stderr-XXXXXX 2>/dev/null || echo "/tmp/cc-hook-stderr-$$")"

# Run the hook, preserve its stdin and stdout, capture stderr
"$HOOK_SCRIPT" "$@" 2>"$STDERR_TMP"
EXIT_CODE=$?

# Replay stderr so Claude Code sees it too
if [ -s "$STDERR_TMP" ]; then
  cat "$STDERR_TMP" >&2
fi

# If the hook failed, log it
if [ "$EXIT_CODE" -ne 0 ] && [ "$EXIT_CODE" -ne 2 ]; then
  # Exit code 2 is "block tool use" which is valid — don't log those
  TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%S%z)"
  HOOK_NAME="$(basename "$HOOK_SCRIPT")"
  STDERR_PREVIEW="$(head -c 500 "$STDERR_TMP" 2>/dev/null | tr '\n' ' ')"

  LOG_LINE="$TIMESTAMP | $HOOK_NAME | exit=$EXIT_CODE | stderr: ${STDERR_PREVIEW:-<none>}"

  # Global log (always)
  GLOBAL_LOG="$HOME/.claude/logs/hook-errors.log"
  mkdir -p "$(dirname "$GLOBAL_LOG")" 2>/dev/null || true
  echo "$LOG_LINE" >> "$GLOBAL_LOG" 2>/dev/null || true

  # Project log (if in a project)
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}/.claude" ]; then
    echo "$LOG_LINE" >> "${CLAUDE_PROJECT_DIR}/.claude/hook-errors.log" 2>/dev/null || true
  fi
fi

rm -f "$STDERR_TMP" 2>/dev/null || true
exit "$EXIT_CODE"
