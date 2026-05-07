#!/bin/bash
# subagent-stop-log.sh
# 目的：
#   1. 记录 Subagent 完成事件到 JSONL 日志（供 /bcc-update-memory 分析）
#   2. 从 subagent transcript 累计 token 用量 → 写入项目级 cost-log.txt
# 触发：SubagentStop hook
#
# 字段说明（基于真实 Claude Code 事件）：
#   hook 输入 JSON：
#     session_id, agent_id, agent_type, agent_transcript_path,
#     hook_event_name, cwd, permission_mode, last_assistant_message,
#     stop_hook_active, transcript_path
#
#   注意：hook 输入中 NO usage / model / duration_ms。
#   真实 token 数据需要从 agent_transcript_path 的 JSONL 文件
#   内每条 assistant message 的 .message.usage 聚合获得。

set -uo pipefail

INPUT="$(cat || true)"
TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%S%z)"

LIB="$HOME/.claude/hooks/_lib/legion-state.sh"
[ -r "$LIB" ] && . "$LIB"

# 基础字段
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")"
AGENT_ID="$(echo "$INPUT" | jq -r '.agent_id // "unknown"' 2>/dev/null || echo "unknown")"
AGENT_TYPE="$(echo "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null || echo "")"
TRANSCRIPT="$(echo "$INPUT" | jq -r '.agent_transcript_path // empty' 2>/dev/null || echo "")"
CWD="$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")"
LAST_MSG="$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null || echo "")"

# agent_type 为空时（主会话直接调用 Agent 工具的 inline case），用 "inline" 标记
[ -z "$AGENT_TYPE" ] && AGENT_TYPE="inline"

# ── 1. JSONL 原始日志（compact 单行，供 /bcc-update-memory 分析） ─────────────────
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true

# 使用 -c 保证单行（之前因为默认 pretty-print 导致多行坏格式）
jq -c -n \
  --arg ts "$TIMESTAMP" \
  --arg event "SubagentStop" \
  --arg agent "$AGENT_TYPE" \
  --arg session "$SESSION_ID" \
  --argjson raw "${INPUT:-null}" \
  '{timestamp: $ts, event: $event, agent: $agent, session: $session, raw: $raw}' \
  >> "$LOG_DIR/subagent-events.jsonl" 2>/dev/null || true

# ── 1b. Update current DispatchTicket evidence/gate status ──────────────────
STATE_FILE="$(legion_state_file "$CWD" 2>/dev/null || echo "")"
if [ -n "$STATE_FILE" ] && [ -f "$STATE_FILE" ] && command -v jq >/dev/null 2>&1; then
  STATE_SESSION="$(jq -r '.session_id // empty' "$STATE_FILE" 2>/dev/null || echo "")"
  if [ -z "$STATE_SESSION" ] || [ "$STATE_SESSION" = "$SESSION_ID" ]; then
    FIRST_LINE="$(printf '%s\n' "$LAST_MSG" | head -1 | tr -d '`')"
    TOKEN="${FIRST_LINE%%:*}"
    ARTIFACT_PATH=""
    case "$FIRST_LINE" in
      *:*) ARTIFACT_PATH="${FIRST_LINE#*:}" ;;
    esac
    ARTIFACT_PATH="$(printf '%s' "$ARTIFACT_PATH" | awk '{$1=$1};1')"

    GATE=""
    GATE_STATE=""
    PHASE_NEXT=""
    case "$TOKEN" in
      IMPL_DONE)
        GATE="impl"; GATE_STATE="pass"; PHASE_NEXT="review" ;;
      REVIEW_PASS)
        GATE="code"; GATE_STATE="pass"; PHASE_NEXT="security" ;;
      REVIEW_REJECT)
        GATE="code"; GATE_STATE="blocked"; PHASE_NEXT="implement" ;;
      SECURITY_PASS)
        GATE="security"; GATE_STATE="pass"; PHASE_NEXT="test" ;;
      SECURITY_REJECT)
        GATE="security"; GATE_STATE="blocked"; PHASE_NEXT="blocked" ;;
      TEST_PASS)
        GATE="functional"; GATE_STATE="pass"; PHASE_NEXT="visual" ;;
      TEST_BLOCKED)
        GATE="functional"; GATE_STATE="blocked"; PHASE_NEXT="implement" ;;
      VISUAL_PASS)
        GATE="visual"; GATE_STATE="pass"; PHASE_NEXT="verdict" ;;
      VISUAL_BLOCKED)
        GATE="visual"; GATE_STATE="blocked"; PHASE_NEXT="implement" ;;
      VERDICT_PASS|VERDICT_CONDITIONAL)
        GATE="verdict"; GATE_STATE="pass"; PHASE_NEXT="needs_user" ;;
      VERDICT_BLOCKED)
        GATE="verdict"; GATE_STATE="blocked"; PHASE_NEXT="blocked" ;;
      NEEDS_USER)
        GATE="needs_user"; GATE_STATE="blocked"; PHASE_NEXT="needs_user" ;;
    esac

    if [ -n "$GATE" ]; then
      TMP_STATE="$(mktemp -t legion-state-XXXXXX 2>/dev/null || echo "/tmp/legion-state-$$")"
      jq --arg ts "$TIMESTAMP" --arg agent "$AGENT_TYPE" --arg token "$TOKEN" \
         --arg gate "$GATE" --arg state "$GATE_STATE" --arg artifact "$ARTIFACT_PATH" \
         --arg phase "$PHASE_NEXT" '
        .updated_at = $ts
        | .last_agent = $agent
        | .last_token = $token
        | .phase = (if $phase != "" then $phase else (.phase // "unknown") end)
        | .gate_status = (.gate_status // {})
        | .gate_status[$gate] = $state
        | .evidence = (.evidence // {})
        | .evidence[$gate] = (if $artifact != "" then $artifact else ($token + ":" + $agent) end)
        | if $gate == "impl" then .evidence.impl_count = ((.evidence.impl_count // 0) + 1) else . end
        | if $gate == "code" then .evidence.review_count = ((.evidence.review_count // 0) + 1) else . end
        | .iteration = (.iteration // {})
        | .iteration.mode = (.iteration.mode // "until_pass")
        | if ($token | test("REJECT|BLOCKED")) then .iteration.round = ((.iteration.round // 0) + 1) else . end
        | if ($token == "NEEDS_USER") then
            .understanding = (.understanding // {})
            | .understanding.status = "needs_user"
            | .understanding.unknowns = ((.understanding.unknowns // []) + [if $artifact != "" then $artifact else ($token + ":" + $agent) end])
          else . end
        | if ($token == "VERDICT_PASS" or $token == "VERDICT_CONDITIONAL") then
            .final_confirmation = "required"
            | .understanding = (.understanding // {})
            | .understanding.status = (.understanding.status // "clear")
          else . end
      ' "$STATE_FILE" > "$TMP_STATE" 2>/dev/null && mv "$TMP_STATE" "$STATE_FILE" 2>/dev/null || rm -f "$TMP_STATE" 2>/dev/null || true
    fi
  fi
fi

# ── 2. 从 transcript 聚合 token 用量 ─────────────────────────────────────────
INPUT_TOK=0
OUTPUT_TOK=0
CACHE_CR=0
CACHE_RD=0
MODEL="unknown"
TURNS=0

if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
  # 聚合所有 assistant turns 的 usage
  AGG="$(jq -s '
    [.[] | select(.type == "assistant" and .message.usage != null) | .message.usage] as $usages |
    [.[] | select(.type == "assistant" and .message.model != null) | .message.model] as $models |
    {
      turns: ($usages | length),
      input: ($usages | map(.input_tokens // 0) | add // 0),
      output: ($usages | map(.output_tokens // 0) | add // 0),
      cache_cr: ($usages | map(.cache_creation_input_tokens // 0) | add // 0),
      cache_rd: ($usages | map(.cache_read_input_tokens // 0) | add // 0),
      model: ($models | last // "unknown")
    }
  ' "$TRANSCRIPT" 2>/dev/null || echo '{"turns":0,"input":0,"output":0,"cache_cr":0,"cache_rd":0,"model":"unknown"}')"

  TURNS="$(echo "$AGG" | jq -r '.turns')"
  INPUT_TOK="$(echo "$AGG" | jq -r '.input')"
  OUTPUT_TOK="$(echo "$AGG" | jq -r '.output')"
  CACHE_CR="$(echo "$AGG" | jq -r '.cache_cr')"
  CACHE_RD="$(echo "$AGG" | jq -r '.cache_rd')"
  MODEL="$(echo "$AGG" | jq -r '.model')"
fi

# ── 3. 会话级成本累加（项目级 TSV，用户可读） ────────────────────────────────
PROJ_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -n "$PROJ_DIR" ] && [ -d "$PROJ_DIR/.claude" ]; then
  mkdir -p "$PROJ_DIR/.claude/logs" 2>/dev/null || true
  COST_LOG="$PROJ_DIR/.claude/logs/cost-log.txt"

  if [ ! -f "$COST_LOG" ]; then
    printf "# timestamp\tagent\tmodel\tturns\tinput\toutput\tcache_cr\tcache_rd\n" > "$COST_LOG"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$TIMESTAMP" "$AGENT_TYPE" "$MODEL" "$TURNS" \
    "$INPUT_TOK" "$OUTPUT_TOK" "$CACHE_CR" "$CACHE_RD" \
    >> "$COST_LOG" 2>/dev/null || true
fi

# ── 4. 清除活跃 subagent 状态文件（先精确，失败再同类最老回退） ─────────────
cleanup_active_agent() {
  local session_id="$1"
  local agent_id="$2"
  local agent_type="$3"
  local exact_file=""
  local fallback_file=""
  local fallback_start=""
  local state_file=""
  local file_type=""
  local file_start=""

  [ -n "$session_id" ] && [ "$session_id" != "unknown" ] || return 0

  if [ -n "$agent_id" ] && [ "$agent_id" != "unknown" ]; then
    exact_file="/tmp/claude-legion-active-${session_id}-${agent_id}"
    if [ -f "$exact_file" ]; then
      rm -f "$exact_file" 2>/dev/null || true
      return 0
    fi
  fi

  [ -n "$agent_type" ] || return 0

  shopt -s nullglob 2>/dev/null || true
  for state_file in /tmp/claude-legion-active-"${session_id}"-*; do
    [ -f "$state_file" ] || continue
    file_type="$(jq -r '.agent_type // empty' "$state_file" 2>/dev/null || echo "")"
    file_start="$(jq -r '.started_at // empty' "$state_file" 2>/dev/null || echo "")"
    if [ -z "$file_type" ]; then
      # Legacy TSV written by older hook versions.
      file_type="$(awk -F'\t' 'NR==1 {print $1}' "$state_file" 2>/dev/null || echo "")"
      file_start="$(awk -F'\t' 'NR==1 {print $2}' "$state_file" 2>/dev/null || echo "")"
    fi
    [ "$file_type" = "$agent_type" ] || continue
    case "$file_start" in
      ''|*[!0-9]*) file_start="0" ;;
    esac
    if [ -z "$fallback_file" ] || [ "$file_start" -lt "$fallback_start" ]; then
      fallback_file="$state_file"
      fallback_start="$file_start"
    fi
  done

  [ -n "$fallback_file" ] && rm -f "$fallback_file" 2>/dev/null || true
}

cleanup_active_agent "$SESSION_ID" "$AGENT_ID" "$AGENT_TYPE"

exit 0
