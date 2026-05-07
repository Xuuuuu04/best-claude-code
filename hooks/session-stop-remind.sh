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

# 统计本会话的实现/审查类 agent 调用次数。兼容当前中文 agent 名与早期英文 id。
AGENT_NAMES="$(jq -r --arg sid "$SESSION_ID" \
  'select((.session // .session_id // .raw.session_id // "") == $sid) | (.agent // .agent_type // .raw.agent_type // empty)' \
  "$EVENTS_LOG" 2>/dev/null || echo "")"

PRODUCER_PATTERN='高级前端工程师|高级后端工程师|高级移动端工程师|高级桌面应用工程师|小程序开发专家|资深数据库工程师|机器学习工程师|高级运维工程师|仓颉语言开发专家|华为昇腾开发专家|多媒体内容生成师|高级代码审查师|高级安全审计师|高级功能测试师|高级视觉测试师|质量总监|高级架构审查师|高级需求审查师|高级内容审查师|高级调研审查师'
PRODUCER_COUNT=$(echo "$AGENT_NAMES" | \
  grep -cE "$PRODUCER_PATTERN" 2>/dev/null || echo 0)

PRODUCER_COUNT=$(echo "$PRODUCER_COUNT" | tr -d ' \n')
[ "${PRODUCER_COUNT:-0}" -lt 3 ] && exit 0

# 注入提醒（Stop 事件不支持 hookSpecificOutput，用 systemMessage）
jq -c -n --arg count "$PRODUCER_COUNT" --arg msg "本次会话有 $PRODUCER_COUNT 次 Agent 调用。建议执行 /bcc-update-memory 记录可复用经验——避免知识丢失。" '{
  systemMessage: $msg
}' 2>/dev/null || true

exit 0
