#!/bin/bash
# subagent-start-mark.sh
# 目的：标记当前活跃的 subagent，供 statusline 读取（支持并发多 agent）
# 触发：SubagentStart hook
#
# 设计：每个 (session, agent_id) 一个独立 JSON 状态文件，支持多 agent 并发。

set -uo pipefail

INPUT="$(cat || true)"

SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")"
AGENT_ID="$(echo "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null || echo "")"
AGENT_NAME="$(echo "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null || echo "")"
[ -z "$AGENT_NAME" ] && AGENT_NAME="inline"
START_TS="$(date +%s)"

# 若 agent_id 缺失（老版本）回退到时间戳避免冲突
[ -z "$AGENT_ID" ] && AGENT_ID="ts-$START_TS"

# 每个 agent 一个独立文件。JSON 便于 stop hook 精确匹配，statusline 也能清理陈旧状态。
STATE_FILE="/tmp/claude-legion-active-${SESSION_ID}-${AGENT_ID}"
jq -c -n \
  --arg session_id "$SESSION_ID" \
  --arg agent_id "$AGENT_ID" \
  --arg agent_type "$AGENT_NAME" \
  --argjson started_at "$START_TS" \
  '{session_id:$session_id, agent_id:$agent_id, agent_type:$agent_type, started_at:$started_at}' \
  > "$STATE_FILE" 2>/dev/null || true

exit 0
