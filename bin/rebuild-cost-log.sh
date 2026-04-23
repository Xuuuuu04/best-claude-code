#!/usr/bin/env bash
# bin/rebuild-cost-log.sh
# 从 JSONL 事件日志 + subagent transcripts 重建项目级 cost-log.txt
# 用于修复旧 cost-log 中 token 全 0 的问题（因旧版 hook 读错字段）
#
# 用法: bash ~/.claude/bin/rebuild-cost-log.sh <项目路径>

set -uo pipefail

PROJ="${1:-}"
if [ -z "$PROJ" ] || [ ! -d "$PROJ/.claude" ]; then
  echo "Usage: $0 <project-dir>  (must contain .claude/)"
  exit 1
fi

COST_LOG="$PROJ/.claude/cost-log.txt"
BACKUP="$COST_LOG.broken.$(date +%s)"
EVENTS_LOG="$HOME/.claude/logs/subagent-events.jsonl"

if [ ! -f "$EVENTS_LOG" ]; then
  echo "No events log at $EVENTS_LOG"
  exit 1
fi

# 备份旧 cost-log（即使它是 broken 的）
[ -f "$COST_LOG" ] && cp "$COST_LOG" "$BACKUP" && echo "Backed up old cost-log to $BACKUP"

# 找 project 路径对应的 cwd
PROJ_ABS="$(cd "$PROJ" && pwd)"
echo "Rebuilding for cwd: $PROJ_ABS"

# 写表头
printf "# timestamp\tagent\tmodel\tturns\tinput\toutput\tcache_cr\tcache_rd\n" > "$COST_LOG"

# 从 events.jsonl 过滤本项目的事件，聚合每个 transcript
COUNT=0
while IFS= read -r EVENT; do
  TS="$(echo "$EVENT" | jq -r '.timestamp // empty')"
  CWD="$(echo "$EVENT" | jq -r '.raw.cwd // empty')"
  [ "$CWD" != "$PROJ_ABS" ] && continue

  AGENT="$(echo "$EVENT" | jq -r '.raw.agent_type // empty')"
  [ -z "$AGENT" ] && AGENT="inline"
  TRANSCRIPT="$(echo "$EVENT" | jq -r '.raw.agent_transcript_path // empty')"

  INPUT_TOK=0; OUTPUT_TOK=0; CACHE_CR=0; CACHE_RD=0; MODEL="unknown"; TURNS=0

  if [ -n "$TRANSCRIPT" ] && [ -f "$TRANSCRIPT" ]; then
    AGG="$(jq -s '
      [.[] | select(.type == "assistant" and .message.usage != null) | .message.usage] as $u |
      [.[] | select(.type == "assistant" and .message.model != null) | .message.model] as $m |
      {
        t: ($u | length),
        i: ($u | map(.input_tokens // 0) | add // 0),
        o: ($u | map(.output_tokens // 0) | add // 0),
        cc: ($u | map(.cache_creation_input_tokens // 0) | add // 0),
        cr: ($u | map(.cache_read_input_tokens // 0) | add // 0),
        md: ($m | last // "unknown")
      }
    ' "$TRANSCRIPT" 2>/dev/null)"
    [ -n "$AGG" ] && {
      TURNS="$(echo "$AGG" | jq -r '.t')"
      INPUT_TOK="$(echo "$AGG" | jq -r '.i')"
      OUTPUT_TOK="$(echo "$AGG" | jq -r '.o')"
      CACHE_CR="$(echo "$AGG" | jq -r '.cc')"
      CACHE_RD="$(echo "$AGG" | jq -r '.cr')"
      MODEL="$(echo "$AGG" | jq -r '.md')"
    }
  fi

  printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$TS" "$AGENT" "$MODEL" "$TURNS" \
    "$INPUT_TOK" "$OUTPUT_TOK" "$CACHE_CR" "$CACHE_RD" \
    >> "$COST_LOG"
  COUNT=$((COUNT + 1))
done < <(jq -c 'select(.event == "SubagentStop")' "$EVENTS_LOG" 2>/dev/null)

echo ""
echo "Rebuilt $COUNT records → $COST_LOG"
echo ""
bash "$HOME/.claude/bin/cost-summary.sh" "$PROJ"
