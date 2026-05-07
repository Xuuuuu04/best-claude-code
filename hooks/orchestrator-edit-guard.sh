#!/bin/bash
# orchestrator-edit-guard.sh
# Prevent the main orchestrator from editing business files without a DispatchTicket.

set -uo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

command -v jq >/dev/null 2>&1 || exit 0

LIB="$HOME/.claude/hooks/_lib/legion-state.sh"
[ -r "$LIB" ] && . "$LIB"

SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")"
AGENT_ID="$(echo "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null || echo "")"
AGENT_TYPE="$(echo "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null || echo "")"
CWD="$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")"
[ -z "$FILE_PATH" ] && exit 0

# Subagents are governed by scope-lock/artifact guards. This hook is for the main session.
if [ -n "$AGENT_ID" ] || [ -n "$AGENT_TYPE" ]; then
  exit 0
fi

# Internal control-plane writes are always allowed.
case "$FILE_PATH" in
  .claude/artifacts/*|*/.claude/artifacts/*|artifacts/*|*/artifacts/*) exit 0 ;;
  .claude/state/*|*/.claude/state/*|state/*|*/state/*) exit 0 ;;
  .claude/logs/*|*/.claude/logs/*|logs/*|*/logs/*) exit 0 ;;
  .claude/agent-memory/*|*/.claude/agent-memory/*) exit 0 ;;
  */.claude/tmp/*|.claude/tmp/*) exit 0 ;;
esac

# User-level Agent Legion system files are allowed: maintaining the harness is a main-session task.
if [ -n "$HOME" ]; then
  case "$FILE_PATH" in
    "$HOME/.claude"/*) exit 0 ;;
  esac
fi

STATE_FILE="$(legion_state_file "$CWD")"
if [ ! -f "$STATE_FILE" ]; then
  REASON="orchestrator-edit violation: 主会话准备修改业务文件 '$FILE_PATH'，但当前没有 DispatchTicket。请先写入 .claude/state/legion-session.json，声明 tier/risk/executor/required_gates；若是快路径，executor 必须是 main-fast-path。"
  jq -c -n --arg reason "$REASON" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
fi

TICKET_SESSION="$(jq -r '.session_id // empty' "$STATE_FILE" 2>/dev/null || echo "")"
EXECUTOR="$(jq -r '.executor // empty' "$STATE_FILE" 2>/dev/null || echo "")"
RISK="$(jq -r '.risk // empty' "$STATE_FILE" 2>/dev/null || echo "")"
FAST_REASON="$(jq -r '.fast_path_reason // empty' "$STATE_FILE" 2>/dev/null || echo "")"
USER_OVERRIDE="$(jq -r '.user_override // "none"' "$STATE_FILE" 2>/dev/null || echo "none")"

if [ -n "$SESSION_ID" ] && [ -n "$TICKET_SESSION" ] && [ "$SESSION_ID" != "$TICKET_SESSION" ]; then
  REASON="orchestrator-edit violation: DispatchTicket 属于另一个 session，不能复用来修改 '$FILE_PATH'。请为当前会话重新写票据。"
  jq -c -n --arg reason "$REASON" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
fi

if [ "$EXECUTOR" != "main-fast-path" ]; then
  REASON="orchestrator-edit violation: 当前 DispatchTicket executor='$EXECUTOR'，主会话不得直接修改业务文件 '$FILE_PATH'。请派对应实现 Agent，或明确改成 main-fast-path 并写明 fast_path_reason。"
  jq -c -n --arg reason "$REASON" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
fi

case "$RISK" in
  high|critical)
    if [ "$USER_OVERRIDE" != "explicit-fast" ]; then
      REASON="orchestrator-edit violation: 当前风险为 '$RISK'，不允许主会话快路径修改 '$FILE_PATH'，除非用户明确要求快速亲自处理并在 ticket.user_override=explicit-fast 中记录。"
      jq -c -n --arg reason "$REASON" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
      exit 0
    fi
    ;;
esac

if [ -z "$FAST_REASON" ] || [ "$FAST_REASON" = "null" ]; then
  REASON="orchestrator-edit violation: main-fast-path 必须写明 fast_path_reason，说明为什么主会话可以直接修改 '$FILE_PATH'。"
  jq -c -n --arg reason "$REASON" '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
  exit 0
fi

LOG="$(legion_event_log)"
mkdir -p "$(dirname "$LOG")" 2>/dev/null || true
TS="$(date +%Y-%m-%dT%H:%M:%S%z)"
jq -c -n --arg ts "$TS" --arg event "main_edit_allowed" --arg session "$SESSION_ID" --arg file "$FILE_PATH" \
  --arg executor "$EXECUTOR" --arg risk "$RISK" \
  '{timestamp:$ts,event:$event,session_id:$session,file:$file,executor:$executor,risk:$risk}' \
  >> "$LOG" 2>/dev/null || true

exit 0

