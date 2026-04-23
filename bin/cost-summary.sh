#!/usr/bin/env bash
# bin/cost-summary.sh
# 汇总当前项目的 subagent token 使用情况。
# 用法: bash ~/.claude/bin/cost-summary.sh [项目路径]
# 默认读取 $PWD/.claude/cost-log.txt

set -uo pipefail

PROJ="${1:-$PWD}"
LOG="$PROJ/.claude/cost-log.txt"

if [ ! -f "$LOG" ]; then
  echo "No cost log found at: $LOG"
  exit 0
fi

awk -F'\t' '
NR==1 { next }                          # skip header
{
  count[$2]++
  input[$2]+=$4
  output[$2]+=$5
  cache_cr[$2]+=$6
  cache_rd[$2]+=$7
  dur[$2]+=$8
  total_in+=$4; total_out+=$5; total_cr+=$6; total_rd+=$7; total_n++
}
END {
  printf "\n══════ Agent Legion · Cost Summary ══════\n\n"
  printf "%-24s %5s %10s %10s %10s %10s\n", "Agent", "N", "Input", "Output", "CacheCr", "CacheRd"
  printf "%-24s %5s %10s %10s %10s %10s\n", "─────", "──", "─────", "──────", "───────", "───────"
  for (a in count) {
    printf "%-24s %5d %10d %10d %10d %10d\n", a, count[a], input[a], output[a], cache_cr[a], cache_rd[a]
  }
  printf "%-24s %5s %10s %10s %10s %10s\n", "─────", "──", "─────", "──────", "───────", "───────"
  printf "%-24s %5d %10d %10d %10d %10d\n", "TOTAL", total_n, total_in, total_out, total_cr, total_rd

  # 粗略成本估算（按 Anthropic Sonnet 4.x 典型价格做参考——非精确，不同 provider 不同价）
  # Sonnet 4.6: $3/M input, $15/M output, $3.75/M cache_cr, $0.30/M cache_rd
  cost_usd = (total_in * 3 + total_out * 15 + total_cr * 3.75 + total_rd * 0.30) / 1000000
  printf "\n约等价 Sonnet 价格: $%.4f (参考值；实际按 provider 计费)\n\n", cost_usd
}
' "$LOG"
