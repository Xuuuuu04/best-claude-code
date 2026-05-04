#!/bin/bash
# review-gate.sh — Agent Legion Router · 未 review 改动提醒
# 触发：UserPromptSubmit hook（clarification-gate 之后）
#
# 目的：
#   如果本会话派过实现类 subagent 修改了代码，但从未派 高级代码审查师，
#   在用户发下一条消息时，向主会话注入 [REVIEW-PENDING] 提示。
#
# 设计原则：
#   1. 只提示，不 block（快路径用户可能就是不要 review）
#   2. 数据源：$HOME/.claude/logs/subagent-events.jsonl（subagent-stop-log 产出）
#   3. 仅看本 session_id 的记录
#   4. 无 jq 时直接 exit 0（保护）

set -uo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")"
[ -z "$SESSION_ID" ] && exit 0

LOG="$HOME/.claude/logs/subagent-events.jsonl"
[ -f "$LOG" ] || exit 0

# 筛出本 session 的事件。subagent-stop-log 当前写顶层 session/agent，
# 同时兼容早期 session_id/agent_type 与 raw 内嵌字段。
SESSION_EVENTS="$(jq -c --arg sid "$SESSION_ID" \
  'select((.session // .session_id // .raw.session_id // "") == $sid)' \
  "$LOG" 2>/dev/null || echo "")"
[ -z "$SESSION_EVENTS" ] && exit 0

# 统计：修改代码的 agent 完成数 vs 高级代码审查师 完成数
MODIFY_AGENT_PATTERN='高级前端工程师|高级后端工程师|高级移动端工程师|高级桌面应用工程师|小程序开发专家|资深数据库工程师|机器学习工程师|高级运维工程师|仓颉语言开发专家|华为昇腾开发专家|多媒体内容生成师'

MODIFY_COUNT=$(echo "$SESSION_EVENTS" \
  | jq -r '.agent // .agent_type // .raw.agent_type // empty' 2>/dev/null \
  | grep -cE "$MODIFY_AGENT_PATTERN" || echo 0)

REVIEWER_COUNT=$(echo "$SESSION_EVENTS" \
  | jq -r '.agent // .agent_type // .raw.agent_type // empty' 2>/dev/null \
  | grep -cE '^高级代码审查师$' || echo 0)

# 清理：grep -c 在 macOS 下某些情况会返回多行
MODIFY_COUNT="$(echo "$MODIFY_COUNT" | head -1 | tr -d ' ')"
REVIEWER_COUNT="$(echo "$REVIEWER_COUNT" | head -1 | tr -d ' ')"

# 未 review 的改动数
PENDING=$((MODIFY_COUNT - REVIEWER_COUNT))

if [ "$PENDING" -le 0 ]; then
  exit 0
fi

# ─── 注入提示 ──────────────────────────────────────────────────────────────
CTX="[REVIEW-PENDING] 本会话有 ${PENDING} 个实现类 Agent 改动未过高级代码审查师。"
CTX+="Router 规则：medium/large 档任务完成代码改动后必经高级代码审查师。"
CTX+="若用户下一步是延续之前任务，建议在回复中说明是否现在派高级代码审查师或由用户确认跳过。"

# 日志
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
TS="$(date +%Y-%m-%dT%H:%M:%S%z)"
jq -c -n --arg ts "$TS" --arg sid "$SESSION_ID" \
         --argjson mod "$MODIFY_COUNT" --argjson rev "$REVIEWER_COUNT" --argjson pending "$PENDING" \
  '{timestamp:$ts, session_id:$sid, modify_count:$mod, reviewer_count:$rev, pending:$pending}' \
  >> "$LOG_DIR/review-gate.jsonl" 2>/dev/null || true

# 输出 additionalContext
jq -c -n --arg ctx "$CTX" \
  '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$ctx}}'

exit 0
