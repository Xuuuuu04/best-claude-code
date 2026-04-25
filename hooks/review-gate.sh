#!/bin/bash
# review-gate.sh — Agent Legion Router · 未 review 改动提醒
# 触发：UserPromptSubmit hook（第三位，紧随 intent-classify + clarification-gate）
#
# 目的：
#   如果本会话派过 implementer 类 subagent 修改了代码，但从未派 code-reviewer，
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

# 筛出本 session 的事件
SESSION_EVENTS="$(grep -F "\"session_id\":\"$SESSION_ID\"" "$LOG" 2>/dev/null || echo "")"
[ -z "$SESSION_EVENTS" ] && exit 0

# 统计：修改代码的 agent 完成数 vs code-reviewer 完成数
# 修改代码的 agent 类型：任何以 implementer- 开头的，加上几个会直接写代码的
MODIFY_AGENT_PATTERN='implementer-(backend|frontend|mobile)|miniprogram-dev|database-engineer|ml-engineer|devops'

MODIFY_COUNT=$(echo "$SESSION_EVENTS" \
  | jq -r '.agent_type // empty' 2>/dev/null \
  | grep -cE "$MODIFY_AGENT_PATTERN" || echo 0)

REVIEWER_COUNT=$(echo "$SESSION_EVENTS" \
  | jq -r '.agent_type // empty' 2>/dev/null \
  | grep -cE '^code-reviewer$' || echo 0)

# 清理：grep -c 在 macOS 下某些情况会返回多行
MODIFY_COUNT="$(echo "$MODIFY_COUNT" | head -1 | tr -d ' ')"
REVIEWER_COUNT="$(echo "$REVIEWER_COUNT" | head -1 | tr -d ' ')"

# 未 review 的改动数
PENDING=$((MODIFY_COUNT - REVIEWER_COUNT))

if [ "$PENDING" -le 0 ]; then
  exit 0
fi

# ─── 注入提示 ──────────────────────────────────────────────────────────────
CTX="[REVIEW-PENDING] 本会话有 ${PENDING} 个 implementer 改动未过 code-reviewer。"
CTX+="Router 规则：medium/large 档任务完成代码改动后必经 code-reviewer。"
CTX+="若用户下一步是延续之前任务，建议在回复中说明是否现在派 code-reviewer 或由用户确认跳过。"

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
