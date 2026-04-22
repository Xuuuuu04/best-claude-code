#!/bin/bash
# subagent-stop-log.sh
# 目的：记录 Subagent 完成事件到日志（用于 /evolve 分析和性能洞察）
# 触发：SubagentStop hook

set -euo pipefail

INPUT=$(cat)

# 提取关键字段
AGENT_NAME=$(echo "$INPUT" | jq -r '.agent_type // .subagent_type // "unknown"' 2>/dev/null || echo "unknown")
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S%z)

# 日志目录
LOG_DIR="${CLAUDE_PROJECT_DIR:-$HOME/.claude}/logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/subagent-events.jsonl"

# 追加一条 JSON Lines 记录
jq -n \
  --arg ts "$TIMESTAMP" \
  --arg event "SubagentStop" \
  --arg agent "$AGENT_NAME" \
  --arg session "$SESSION_ID" \
  --argjson raw "$INPUT" \
  '{timestamp: $ts, event: $event, agent: $agent, session: $session, raw: $raw}' \
  >> "$LOG_FILE" 2>/dev/null || true

# 清理超过 90 天的旧日志（按大小切分更好，这里简单按时间）
# 保留当前文件，删除老的归档（如果将来加归档机制）

exit 0
