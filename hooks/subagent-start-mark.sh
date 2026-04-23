#!/bin/bash
# subagent-start-mark.sh
# 目的：标记当前活跃的 subagent，供 statusline 读取
# 触发：SubagentStart hook

set -uo pipefail

INPUT="$(cat || true)"

SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")"
AGENT_NAME="$(echo "$INPUT" | jq -r '.agent_type // .subagent_type // .agent // "unknown"' 2>/dev/null || echo "unknown")"
START_TS="$(date +%s)"

# 写到会话专属的状态文件
STATE_FILE="/tmp/claude-legion-active-${SESSION_ID}"
printf "%s\t%s\n" "$AGENT_NAME" "$START_TS" > "$STATE_FILE" 2>/dev/null || true

exit 0
