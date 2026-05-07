#!/bin/bash
# artifact-write-guard.sh
# Restrict review/research/planning agents to artifact writes when CLAUDE_LEGION_ARTIFACT_ONLY=1.

set -uo pipefail

INPUT="$(cat || true)"
[ "${CLAUDE_LEGION_ARTIFACT_ONLY:-}" = "1" ] || exit 0

FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")"
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  .claude/artifacts/*.md|*/.claude/artifacts/*.md)
    exit 0
    ;;
esac

REASON="artifact-only violation: 当前 Agent 只允许写入 .claude/artifacts/*.md，不能修改业务文件 '$FILE_PATH'。请把发现写入 artifact 并交回调度器。"

jq -c -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'

exit 0
