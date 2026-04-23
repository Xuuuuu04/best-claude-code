#!/bin/bash
# subagent-stop-log.sh
# 目的：
#   1. 记录 Subagent 完成事件到 JSONL 日志（供 /bcc-evolve 分析）
#   2. 提取 token 用量并累加到会话级成本文件（给用户即时反馈）
# 触发：SubagentStop hook

set -uo pipefail

INPUT="$(cat || true)"
TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%S%z)"

# 提取字段（宽容处理——字段名按 Claude Code 实际输出可能有变体）
AGENT_NAME="$(echo "$INPUT" | jq -r '.agent_type // .subagent_type // .agent // "unknown"' 2>/dev/null || echo "unknown")"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")"
INPUT_TOKENS="$(echo "$INPUT" | jq -r '.usage.input_tokens // .tokens.input // 0' 2>/dev/null || echo "0")"
OUTPUT_TOKENS="$(echo "$INPUT" | jq -r '.usage.output_tokens // .tokens.output // 0' 2>/dev/null || echo "0")"
CACHE_CREATE="$(echo "$INPUT" | jq -r '.usage.cache_creation_input_tokens // 0' 2>/dev/null || echo "0")"
CACHE_READ="$(echo "$INPUT" | jq -r '.usage.cache_read_input_tokens // 0' 2>/dev/null || echo "0")"
DURATION_MS="$(echo "$INPUT" | jq -r '.duration_ms // 0' 2>/dev/null || echo "0")"
MODEL="$(echo "$INPUT" | jq -r '.model // "unknown"' 2>/dev/null || echo "unknown")"

# ── 1. JSONL 原始日志（/bcc-evolve 用） ──────────────────────────────────────
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
jq -n \
  --arg ts "$TIMESTAMP" \
  --arg event "SubagentStop" \
  --arg agent "$AGENT_NAME" \
  --arg session "$SESSION_ID" \
  --argjson raw "${INPUT:-null}" \
  '{timestamp: $ts, event: $event, agent: $agent, session: $session, raw: $raw}' \
  >> "$LOG_DIR/subagent-events.jsonl" 2>/dev/null || true

# ── 2. 会话级成本累加（用户可读） ────────────────────────────────────────────
# 格式: tsv 单文件，每行一次 subagent 调用；另有汇总行
PROJ_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -n "$PROJ_DIR" ] && [ -d "$PROJ_DIR/.claude" ]; then
  COST_LOG="$PROJ_DIR/.claude/cost-log.txt"

  # 若是新文件，先写表头
  if [ ! -f "$COST_LOG" ]; then
    printf "# timestamp\tagent\tmodel\tinput\toutput\tcache_cr\tcache_rd\tdur_ms\n" > "$COST_LOG"
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$TIMESTAMP" "$AGENT_NAME" "$MODEL" \
    "$INPUT_TOKENS" "$OUTPUT_TOKENS" "$CACHE_CREATE" "$CACHE_READ" "$DURATION_MS" \
    >> "$COST_LOG" 2>/dev/null || true
fi

# ── 3. 清除活跃 subagent 状态文件（供 statusline） ──────────────────────────
STATE_FILE="/tmp/claude-legion-active-${SESSION_ID}"
rm -f "$STATE_FILE" 2>/dev/null || true

exit 0
