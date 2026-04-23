#!/bin/bash
# subagent-stop-log.sh
# 目的：
#   1. 记录 Subagent 完成事件到 JSONL 日志（供 /bcc-evolve 分析）
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

# 基础字段
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")"
AGENT_ID="$(echo "$INPUT" | jq -r '.agent_id // "unknown"' 2>/dev/null || echo "unknown")"
AGENT_TYPE="$(echo "$INPUT" | jq -r '.agent_type // empty' 2>/dev/null || echo "")"
TRANSCRIPT="$(echo "$INPUT" | jq -r '.agent_transcript_path // empty' 2>/dev/null || echo "")"

# agent_type 为空时（主会话直接调用 Agent 工具的 inline case），用 "inline" 标记
[ -z "$AGENT_TYPE" ] && AGENT_TYPE="inline"

# ── 1. JSONL 原始日志（compact 单行，供 /bcc-evolve 分析） ─────────────────
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
  COST_LOG="$PROJ_DIR/.claude/cost-log.txt"

  if [ ! -f "$COST_LOG" ]; then
    printf "# timestamp\tagent\tmodel\tturns\tinput\toutput\tcache_cr\tcache_rd\n" > "$COST_LOG"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$TIMESTAMP" "$AGENT_TYPE" "$MODEL" "$TURNS" \
    "$INPUT_TOK" "$OUTPUT_TOK" "$CACHE_CR" "$CACHE_RD" \
    >> "$COST_LOG" 2>/dev/null || true
fi

# ── 4. 清除活跃 subagent 状态文件（供 statusline） ──────────────────────────
STATE_FILE="/tmp/claude-legion-active-${SESSION_ID}"
rm -f "$STATE_FILE" 2>/dev/null || true

exit 0
