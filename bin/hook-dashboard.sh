#!/bin/bash
# hook-dashboard.sh — Agent Legion Hook 运行仪表盘
# 汇总近 24h 的 hook 运行数据，快速定位问题
set -uo pipefail

LEGION_DIR="${HOME}/.claude"
LOG_DIR="$LEGION_DIR/logs"
PROJ_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
HOURS="${1:-24}"  # 默认 24h，可传参
STATE_LIB="$LEGION_DIR/hooks/_lib/legion-state.sh"
[ -r "$STATE_LIB" ] && . "$STATE_LIB"

# 颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

section() { echo -e "\n${CYAN}=== $1 ===${NC}"; }
line()    { echo "  $1"; }

# 时间窗口（ISO 8601 比较）
if command -v gdate >/dev/null 2>&1; then
  SINCE="$(gdate -d "-${HOURS} hours" +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -v-${HOURS}H +%Y-%m-%dT%H:%M:%S 2>/dev/null || echo "")"
else
  SINCE="$(date -v-${HOURS}H +%Y-%m-%dT%H:%M:%S 2>/dev/null || echo "")"
fi

# ─── Router Mode ────────────────────────────────────────────────────────────
section "Router Mode"
line "任务档位由模型按 output-styles/legion-dispatch.md 自判，并写入 DispatchTicket"
line "UserPromptSubmit 当前只统计 clarification-gate / review-gate"

# ─── DispatchTicket ─────────────────────────────────────────────────────────
section "DispatchTicket"

STATE_FILE=""
if command -v legion_state_file >/dev/null 2>&1; then
  STATE_FILE="$(legion_state_file "$PROJ_DIR" 2>/dev/null || echo "")"
elif [ -f "$PROJ_DIR/.claude/state/legion-session.json" ]; then
  STATE_FILE="$PROJ_DIR/.claude/state/legion-session.json"
elif [ -f "$LEGION_DIR/state/legion-session.json" ]; then
  STATE_FILE="$LEGION_DIR/state/legion-session.json"
fi

if [ -n "$STATE_FILE" ] && [ -r "$STATE_FILE" ] && command -v jq >/dev/null 2>&1; then
  TASK_ID="$(jq -r '.task_id // "no-task"' "$STATE_FILE" 2>/dev/null || echo "no-task")"
  PHASE="$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
  RISK="$(jq -r '.risk // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
  EXECUTOR="$(jq -r '.executor // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
  QUALITY="$(jq -r '.quality_strategy // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
  REQUIRED="$(jq -r '.required_gates[]? // empty' "$STATE_FILE" 2>/dev/null | paste -sd ',' - || true)"
  IMPL_COUNT="$(jq -r '.evidence.impl_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
  REVIEW_COUNT="$(jq -r '.evidence.review_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
  UNDERSTANDING_STATUS="$(jq -r '.understanding.status // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
  UNDERSTANDING_CONF="$(jq -r '.understanding.confidence // "n/a"' "$STATE_FILE" 2>/dev/null || echo "n/a")"
  UNKNOWN_COUNT="$(jq -r '(.understanding.unknowns // []) | length' "$STATE_FILE" 2>/dev/null || echo 0)"
  ASSET_COUNT="$(jq -r '(.understanding.missing_assets // []) | length' "$STATE_FILE" 2>/dev/null || echo 0)"
  ITER_MODE="$(jq -r '.iteration.mode // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
  ITER_ROUND="$(jq -r '.iteration.round // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
  FINAL_CONFIRMATION="$(jq -r '.final_confirmation // "unset"' "$STATE_FILE" 2>/dev/null || echo "unset")"

  line "task: $TASK_ID"
  line "phase/risk: $PHASE / $RISK"
  line "executor/quality: $EXECUTOR / $QUALITY"
  line "required_gates: ${REQUIRED:-none}"
  line "evidence: impl=$IMPL_COUNT review=$REVIEW_COUNT"
  line "understanding: $UNDERSTANDING_STATUS confidence=$UNDERSTANDING_CONF unknowns=$UNKNOWN_COUNT missing_assets=$ASSET_COUNT"
  line "iteration: $ITER_MODE round=$ITER_ROUND"
  line "final_confirmation: $FINAL_CONFIRMATION"
else
  line "no-ticket（无当前机读调度票据）"
fi

# ─── Clarification Gate ─────────────────────────────────────────────────────
section "Clarification Gate"

CLARIFY_FILE="$LOG_DIR/clarification-gate.jsonl"
if [ -f "$CLARIFY_FILE" ] && command -v jq >/dev/null 2>&1; then
  if [ -n "$SINCE" ]; then
    FILTER="select(.timestamp >= \"$SINCE\")"
  else
    FILTER="."
  fi
  BLOCKED=$(jq -r "$FILTER | select(.action==\"block\") | .action" "$CLARIFY_FILE" 2>/dev/null | wc -l | tr -d ' ')
  # bypass 通过检查 state 目录的 pending 文件
  PENDING_DIR="$LEGION_DIR/state"
  PENDING_COUNT=$(find "$PENDING_DIR" -name 'clarification-pending-*.json' -mmin -$((${HOURS} * 60)) 2>/dev/null | wc -l | tr -d ' ')

  line "blocked: $BLOCKED"
  if [ "$BLOCKED" -gt 0 ] && [ "$PENDING_COUNT" -eq 0 ]; then
    line "bypass_rate: ~100%（所有 block 均被绕过）"
  elif [ "$BLOCKED" -gt 0 ]; then
    BYPASSED=$((BLOCKED - PENDING_COUNT))
    [ "$BYPASSED" -lt 0 ] && BYPASSED=0
    RATE=$((BYPASSED * 100 / BLOCKED))
    line "bypassed: ~$BYPASSED (${RATE}%)"
  fi

  # 显示最近 3 次 block 的信号
  RECENT_BLOCKS=$(jq -r "$FILTER | select(.action==\"block\") | .signal" "$CLARIFY_FILE" 2>/dev/null | tail -3)
  if [ -n "$RECENT_BLOCKS" ]; then
    line "最近 block 信号:"
    echo "$RECENT_BLOCKS" | while read -r sig; do
      [ -n "$sig" ] && line "  - $sig"
    done
  fi
else
  line "clarification-gate.jsonl 不存在或无 jq"
fi

# ─── Review Gate ────────────────────────────────────────────────────────────
section "Review Gate"

REVIEW_FILE="$LOG_DIR/review-gate.jsonl"
if [ -f "$REVIEW_FILE" ] && command -v jq >/dev/null 2>&1; then
  if [ -n "$SINCE" ]; then
    FILTER="select(.timestamp >= \"$SINCE\")"
  else
    FILTER="."
  fi
  SESSIONS_WITH_PENDING=$(jq -r "$FILTER | select(.pending > 0) | .session_id" "$REVIEW_FILE" 2>/dev/null | sort -u | wc -l | tr -d ' ')
  AVG_PENDING=$(jq -r "$FILTER | select(.pending > 0) | .pending" "$REVIEW_FILE" 2>/dev/null | awk '{s+=$1; n++} END {if(n>0) printf "%.1f", s/n; else print "0"}')

  line "sessions_with_pending: $SESSIONS_WITH_PENDING"
  line "avg_pending: $AVG_PENDING"
else
  line "review-gate.jsonl 不存在或无 jq"
fi

# ─── Tool Failures ──────────────────────────────────────────────────────────
section "Tool Failures (top 5)"

FAIL_FILE="$LOG_DIR/tool-failures.jsonl"
if [ -f "$FAIL_FILE" ] && command -v jq >/dev/null 2>&1; then
  if [ -n "$SINCE" ]; then
    FILTER="select(.timestamp >= \"$SINCE\")"
  else
    FILTER="."
  fi
  TOTAL=$(jq -r "$FILTER | .tool_name" "$FAIL_FILE" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$TOTAL" -gt 0 ]; then
    jq -r "$FILTER | .tool_name" "$FAIL_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -5 | awk '{printf "  %-20s %s 次\n", $2, $1}'
    line "总计: $TOTAL 次失败"
  else
    line "无失败记录"
  fi
else
  line "tool-failures.jsonl 不存在或无 jq"
fi

# ─── Hook Errors ────────────────────────────────────────────────────────────
section "Hook Errors"

ERROR_FILE="$LOG_DIR/hook-errors.log"
if [ -f "$ERROR_FILE" ]; then
  SIZE=$(wc -c < "$ERROR_FILE" 2>/dev/null | tr -d ' ')
  LINES=$(wc -l < "$ERROR_FILE" 2>/dev/null | tr -d ' ')
  line "hook-errors.log: ${LINES} 行, ${SIZE} 字节"
  if [ "$LINES" -gt 0 ]; then
    line "最近 3 条:"
    tail -3 "$ERROR_FILE" 2>/dev/null | while read -r l; do
      [ -n "$l" ] && line "  $l"
    done
  fi
else
  line "hook-errors.log 不存在（无错误）"
fi

# ─── Subagent Cost (24h) ───────────────────────────────────────────────────
section "Subagent Cost (近 24h)"

COST_FILE=""
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -f "$CLAUDE_PROJECT_DIR/.claude/logs/cost-log.txt" ]; then
  COST_FILE="$CLAUDE_PROJECT_DIR/.claude/logs/cost-log.txt"
elif [ -f "$PWD/.claude/logs/cost-log.txt" ]; then
  COST_FILE="$PWD/.claude/logs/cost-log.txt"
fi

if [ -n "$COST_FILE" ] && [ -f "$COST_FILE" ]; then
  # cost-log.txt 是 TSV: timestamp agent_type turns input output cache
  # 只统计最近 24h
  TOTAL_LINES=$(wc -l < "$COST_FILE" 2>/dev/null | tr -d ' ')
  if [ "$TOTAL_LINES" -gt 1 ]; then
    # 跳过 header，统计最近条目
    TOTAL_TURNS=$(tail -n +2 "$COST_FILE" 2>/dev/null | awk -F'\t' '{s+=$3} END {print s+0}')
    AVG_TURNS=$(tail -n +2 "$COST_FILE" 2>/dev/null | awk -F'\t' '{s+=$3; n++} END {if(n>0) printf "%.0f", s/n; else print "0"}')
    line "总 turns: $TOTAL_TURNS"
    line "平均 turns/agent: $AVG_TURNS"
  else
    line "cost-log.txt 无数据"
  fi
else
  line "cost-log.txt 不存在"
fi

echo ""
