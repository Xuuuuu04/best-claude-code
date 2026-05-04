#!/bin/bash
# stop-quality-gate.sh
# Block session stop when a DispatchTicket declares gates that have no evidence.

set -uo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

LIB="$HOME/.claude/hooks/_lib/legion-state.sh"
[ -r "$LIB" ] && . "$LIB"

SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")"
CWD="$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")"
STATE_FILE="$(legion_state_file "$CWD")"
[ -f "$STATE_FILE" ] || exit 0

TICKET_SESSION="$(jq -r '.session_id // empty' "$STATE_FILE" 2>/dev/null || echo "")"
if [ -n "$SESSION_ID" ] && [ -n "$TICKET_SESSION" ] && [ "$SESSION_ID" != "$TICKET_SESSION" ]; then
  exit 0
fi

PHASE="$(jq -r '.phase // empty' "$STATE_FILE" 2>/dev/null || echo "")"
EXECUTOR="$(jq -r '.executor // empty' "$STATE_FILE" 2>/dev/null || echo "")"
QUALITY="$(jq -r '.quality_strategy // "adversarial-default"' "$STATE_FILE" 2>/dev/null || echo "adversarial-default")"
TASK_ID="$(jq -r '.task_id // "unknown-task"' "$STATE_FILE" 2>/dev/null || echo "unknown-task")"
FINAL_CONFIRMATION="$(jq -r '.final_confirmation // empty' "$STATE_FILE" 2>/dev/null || echo "")"

if [ "$PHASE" = "done" ] && [ -n "$FINAL_CONFIRMATION" ] && [ "$FINAL_CONFIRMATION" != "accepted" ]; then
  REASON="最终确认未完成：task '$TASK_ID' phase=done 但 final_confirmation='$FINAL_CONFIRMATION'。请先向用户确认接受当前结果，用户接受后再置为 accepted/done。"
  jq -c -n --arg reason "$REASON" '{decision:"block",reason:$reason}'
  exit 0
fi

case "$PHASE" in
  done|blocked|needs_user|paused) exit 0 ;;
esac

MISSING=""
REQUIRED="$(jq -r '.required_gates[]? // empty' "$STATE_FILE" 2>/dev/null || true)"

if [ -n "$REQUIRED" ]; then
  while IFS= read -r gate; do
    [ -z "$gate" ] && continue
    STATE="$(jq -r --arg g "$gate" '.gate_status[$g] // empty' "$STATE_FILE" 2>/dev/null || echo "")"
    EVIDENCE="$(jq -r --arg g "$gate" '.evidence[$g] // empty' "$STATE_FILE" 2>/dev/null || echo "")"
    case "$STATE" in
      pass|passed|accepted|not_applicable|skipped_by_user) ;;
      *)
        if [ -z "$EVIDENCE" ] || [ "$EVIDENCE" = "null" ]; then
          MISSING="${MISSING}${gate} "
        fi
        ;;
    esac
  done <<< "$REQUIRED"
fi

if [ -n "$MISSING" ]; then
  REASON="质量闸门未闭合：task '$TASK_ID' 缺少证据或通过状态：${MISSING}。请继续派对应审查/测试 Agent，或在 DispatchTicket 中记录 skipped_by_user / not_applicable 及理由后再收工。"
  jq -c -n --arg reason "$REASON" '{decision:"block",reason:$reason}'
  exit 0
fi

if [ "$QUALITY" = "adversarial-default" ] || [ "$QUALITY" = "full" ]; then
  IMPL_COUNT="$(jq -r '.evidence.impl_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
  REVIEW_COUNT="$(jq -r '.evidence.review_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
  if [ "${IMPL_COUNT:-0}" -gt 0 ] && [ "${REVIEW_COUNT:-0}" -eq 0 ] && [ "$EXECUTOR" != "main-fast-path" ]; then
    REASON="对抗审查未完成：task '$TASK_ID' 有实现证据但没有独立 review 证据。请派高级代码审查师，或明确切换为 compressed 并记录用户快速处理要求。"
    jq -c -n --arg reason "$REASON" '{decision:"block",reason:$reason}'
    exit 0
  fi
fi

ALL_REQUIRED_CLOSED=1
if [ -n "$REQUIRED" ]; then
  while IFS= read -r gate; do
    [ -z "$gate" ] && continue
    STATE="$(jq -r --arg g "$gate" '.gate_status[$g] // empty' "$STATE_FILE" 2>/dev/null || echo "")"
    case "$STATE" in
      pass|passed|accepted|not_applicable|skipped_by_user) ;;
      *) ALL_REQUIRED_CLOSED=0 ;;
    esac
  done <<< "$REQUIRED"
else
  ALL_REQUIRED_CLOSED=0
fi

if [ "$ALL_REQUIRED_CLOSED" -eq 1 ] && [ "$FINAL_CONFIRMATION" != "accepted" ] && [ "$FINAL_CONFIRMATION" != "asked" ]; then
  REASON="质量证据已闭合但尚未向用户做最终确认：task '$TASK_ID'。请设置 phase=needs_user、final_confirmation=asked，并询问用户：接受当前结果、继续深挖、扩大检查范围，或指定继续检查点。"
  jq -c -n --arg reason "$REASON" '{decision:"block",reason:$reason}'
  exit 0
fi

exit 0
