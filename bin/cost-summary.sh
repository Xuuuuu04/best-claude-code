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
NR==1 { next }
{
  count[$2]++
  turns[$2]+=$4
  input[$2]+=$5
  output[$2]+=$6
  cache_cr[$2]+=$7
  cache_rd[$2]+=$8
  total_n++
  total_turns+=$4
  total_in+=$5; total_out+=$6; total_cr+=$7; total_rd+=$8
}
END {
  printf "\n══════ Agent Legion · Cost Summary ══════\n\n"
  printf "Project: %s\n\n", PROJ
  printf "%-24s %5s %6s %12s %12s %12s %12s\n", "Agent", "Calls", "Turns", "Input", "Output", "CacheCr", "CacheRd"
  printf "%-24s %5s %6s %12s %12s %12s %12s\n", "─────", "─────", "─────", "─────", "──────", "───────", "───────"
  for (a in count) {
    printf "%-24s %5d %6d %12d %12d %12d %12d\n", a, count[a], turns[a], input[a], output[a], cache_cr[a], cache_rd[a]
  }
  printf "%-24s %5s %6s %12s %12s %12s %12s\n", "─────", "─────", "─────", "─────", "──────", "───────", "───────"
  printf "%-24s %5d %6d %12d %12d %12d %12d\n", "TOTAL", total_n, total_turns, total_in, total_out, total_cr, total_rd

  # 成本估算（按 Sonnet 4.x 典型 Anthropic 价：$3/M input, $15/M output,
  #           $3.75/M cache_write, $0.30/M cache_read）
  # 注：你用的是 GLM/国产 API，价格更低；这里是 Anthropic 直连的参考值
  cost_usd = (total_in * 3 + total_out * 15 + total_cr * 3.75 + total_rd * 0.30) / 1000000
  printf "\n按 Sonnet-4 价格估算: $%.4f (仅参考；实际按 provider 计费)\n\n", cost_usd
}
' PROJ="$PROJ" "$LOG"
