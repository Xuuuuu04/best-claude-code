#!/bin/bash
# session-stop-remind.sh
# 目的：会话结束时，如有足够的 subagent 活动，提醒用户执行 /bcc-update-memory
# 触发：Stop hook
#
# 判据：从 subagent-events.jsonl 中统计本会话的 agent 调用次数
#       若 ≥3 次实现/审查类 agent 调用 → 注入提醒

set -uo pipefail

INPUT="$(cat || true)"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")"
[ -z "$SESSION_ID" ] && exit 0

EVENTS_LOG="$HOME/.claude/logs/subagent-events.jsonl"
[ ! -f "$EVENTS_LOG" ] && exit 0

# 统计本会话的实现/审查类 agent 调用次数
PRODUCER_COUNT=$(grep "$SESSION_ID" "$EVENTS_LOG" 2>/dev/null | \
  jq -r 'select(.agent != null)' 2>/dev/null | \
  grep -cE 'implementer-|code-reviewer|security-auditor|functional-tester|visual-tester|miniprogram-dev|database-engineer' 2>/dev/null || echo 0)

PRODUCER_COUNT=$(echo "$PRODUCER_COUNT" | tr -d ' \n')
[ "${PRODUCER_COUNT:-0}" -lt 3 ] && exit 0

# 注入提醒
jq -c -n --arg count "$PRODUCER_COUNT" '{
  hookSpecificOutput: {
    hookEventName: "Stop",
    additionalContext: ("本次会话有 \($count) 次 Agent 调用。建议执行 /bcc-update-memory 记录可复用经验——避免知识丢失。")
  }
}' 2>/dev/null || true

exit 0
