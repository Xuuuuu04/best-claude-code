#!/bin/bash
# Validate Agent Legion DispatchTicket state.

set -uo pipefail

INPUT_PATH="${1:-}"

LIB="$HOME/.claude/hooks/_lib/legion-state.sh"
[ -r "$LIB" ] && . "$LIB"

if [ -z "$INPUT_PATH" ]; then
  if command -v legion_state_file >/dev/null 2>&1; then
    INPUT_PATH="$(legion_state_file "$(pwd 2>/dev/null || echo "")")"
  else
    INPUT_PATH="$HOME/.claude/state/legion-session.json"
  fi
fi

ERRORS=0
WARNINGS=0

error() {
  ERRORS=$((ERRORS + 1))
  printf 'ERROR: %s\n' "$1"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf 'WARN: %s\n' "$1"
}

field() {
  jq -r "$1 // empty" "$INPUT_PATH" 2>/dev/null || echo ""
}

allowed() {
  local value="$1"
  local list="$2"
  case " $list " in
    *" $value "*) return 0 ;;
    *) return 1 ;;
  esac
}

[ -f "$INPUT_PATH" ] || { error "ticket not found: $INPUT_PATH"; exit 1; }
command -v jq >/dev/null 2>&1 || { error "jq is required"; exit 1; }
jq empty "$INPUT_PATH" >/dev/null 2>&1 || { error "invalid JSON: $INPUT_PATH"; exit 1; }

TASK_ID="$(field '.task_id')"
TIER="$(field '.tier')"
PHASE="$(field '.phase')"
RISK="$(field '.risk')"
EXECUTOR="$(field '.executor')"
QUALITY="$(field '.quality_strategy')"
USER_OVERRIDE="$(field '.user_override')"
UNDERSTANDING_STATUS="$(field '.understanding.status')"
REASONING_MODE="$(field '.reasoning_mode')"
ITER_MODE="$(field '.iteration.mode')"
ITER_ROUND="$(field '.iteration.round')"
FINAL_CONFIRMATION="$(field '.final_confirmation')"
FAST_PATH_REASON="$(field '.fast_path_reason')"

[ -n "$TASK_ID" ] || error "task_id is required"

allowed "$TIER" "trivial small medium large unclear" || error "tier has invalid value: ${TIER:-<empty>}"
allowed "$PHASE" "intake research plan implement review security test visual verdict done blocked needs_user paused" || error "phase has invalid value: ${PHASE:-<empty>}"
allowed "$RISK" "low medium high critical" || error "risk has invalid value: ${RISK:-<empty>}"
allowed "$EXECUTOR" "main-fast-path agent-team" || error "executor has invalid value: ${EXECUTOR:-<empty>}"
allowed "$QUALITY" "compressed adversarial-default full" || error "quality_strategy has invalid value: ${QUALITY:-<empty>}"
allowed "${USER_OVERRIDE:-none}" "none explicit-fast explicit-skip-tests" || error "user_override has invalid value: ${USER_OVERRIDE:-<empty>}"

if [ "$EXECUTOR" = "main-fast-path" ] && [ -z "$FAST_PATH_REASON" ]; then
  error "fast_path_reason is required when executor=main-fast-path"
fi

if [ -n "$UNDERSTANDING_STATUS" ]; then
  allowed "$UNDERSTANDING_STATUS" "clear assumed needs_user contradictory missing_asset" || error "understanding.status has invalid value: $UNDERSTANDING_STATUS"
fi

if ! jq -e '(.understanding.confidence? == null) or ((.understanding.confidence | type) == "number" and .understanding.confidence >= 0 and .understanding.confidence <= 1)' "$INPUT_PATH" >/dev/null 2>&1; then
  error "understanding.confidence must be a number between 0.0 and 1.0"
fi

for array_field in chosen_agents required_gates understanding.unknowns understanding.assumptions understanding.missing_assets; do
  if ! jq -e --arg f "$array_field" '
    def path_for($s): $s | split(".") | map(if test("^[0-9]+$") then tonumber else . end);
    (getpath(path_for($f))? == null) or ((getpath(path_for($f)) | type) == "array")
  ' "$INPUT_PATH" >/dev/null 2>&1; then
    error "$array_field must be an array when present"
  fi
done

if [ -n "$REASONING_MODE" ]; then
  allowed "$REASONING_MODE" "direct internal_summary internal_tree adversarial internal_cot internal_tot" || error "reasoning_mode has invalid value: $REASONING_MODE"
fi

if [ -n "$ITER_MODE" ]; then
  allowed "$ITER_MODE" "until_pass" || error "iteration.mode has invalid value: $ITER_MODE"
fi

if [ -n "$ITER_ROUND" ]; then
  case "$ITER_ROUND" in
    ''|*[!0-9]*) error "iteration.round must be a non-negative integer" ;;
  esac
fi

if [ -n "$FINAL_CONFIRMATION" ]; then
  allowed "$FINAL_CONFIRMATION" "required asked accepted continue_requested specified_check" || error "final_confirmation has invalid value: $FINAL_CONFIRMATION"
fi

if [ "$PHASE" = "done" ] && [ "$FINAL_CONFIRMATION" != "accepted" ]; then
  error "phase=done requires final_confirmation=accepted"
fi

case "$FINAL_CONFIRMATION" in
  required|asked)
    [ "$PHASE" = "needs_user" ] || error "final_confirmation=$FINAL_CONFIRMATION requires phase=needs_user"
    ;;
esac

if [ "$PHASE" = "needs_user" ] && [ "$FINAL_CONFIRMATION" = "required" -o "$FINAL_CONFIRMATION" = "asked" ]; then
  warn "next user reply must be classified as accepted / continue_requested / specified_check before further dispatch"
fi

GATE_VALUES="$(jq -r '.gate_status // {} | to_entries[]? | [.key, (.value|tostring)] | @tsv' "$INPUT_PATH" 2>/dev/null || true)"
while IFS="$(printf '\t')" read -r gate state; do
  [ -n "$gate" ] || continue
  allowed "$state" "pending pass passed accepted blocked reject rejected fail failed skipped_by_user not_applicable" || error "gate_status.$gate has invalid value: $state"
done <<< "$GATE_VALUES"

REQUIRED_GATES="$(jq -r '.required_gates[]? // empty' "$INPUT_PATH" 2>/dev/null || true)"
while IFS= read -r gate; do
  [ -n "$gate" ] || continue
  allowed "$gate" "impl code security functional visual verdict needs_user" || warn "required_gates contains non-standard gate: $gate"
done <<< "$REQUIRED_GATES"

if [ "$ERRORS" -gt 0 ]; then
  printf 'DispatchTicket invalid: %d error(s), %d warning(s): %s\n' "$ERRORS" "$WARNINGS" "$INPUT_PATH"
  exit 1
fi

printf 'DispatchTicket valid: %s' "$INPUT_PATH"
[ "$WARNINGS" -gt 0 ] && printf ' (%d warning(s))' "$WARNINGS"
printf '\n'
exit 0
