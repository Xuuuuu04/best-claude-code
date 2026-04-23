#!/usr/bin/env bash
# bin/rotate-logs.sh
# Agent Legion · 日志轮转
#
# 对 Agent Legion 产生的各类长期日志做大小控制：
#   - 超过阈值时：当前文件 → `.1.gz`（压缩归档）
#   - 保留最多 5 份历史（`.1.gz` ~ `.5.gz`）
#   - 超过 5 份的老归档自动删除
#
# 用法:
#   bash ~/.claude/bin/rotate-logs.sh          # 在当前项目轮转
#   bash ~/.claude/bin/rotate-logs.sh --force  # 无视阈值立即轮转

set -uo pipefail

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

# 每条：路径 → 阈值（字节）
declare -A TARGETS=(
  ["$HOME/.claude/logs/subagent-events.jsonl"]=52428800       # 50 MB
  ["$HOME/.claude/logs/hook-errors.log"]=5242880              # 5 MB
  ["$HOME/.claude/logs/instructions-loaded.jsonl"]=52428800   # 50 MB
)

# 项目级日志（如果在项目里）
if [ -n "${CLAUDE_PROJECT_DIR:-}" ] && [ -d "${CLAUDE_PROJECT_DIR}/.claude" ]; then
  TARGETS["${CLAUDE_PROJECT_DIR}/.claude/cost-log.txt"]=10485760            # 10 MB
  TARGETS["${CLAUDE_PROJECT_DIR}/.claude/hook-errors.log"]=5242880          # 5 MB
  TARGETS["${CLAUDE_PROJECT_DIR}/.claude/instructions-log.txt"]=20971520    # 20 MB
fi

MAX_KEEP=5
ROTATED=0
SKIPPED=0

echo ""
echo "┌─────────────────────────────────────────────────┐"
echo "│  Agent Legion · Log Rotation                    │"
echo "└─────────────────────────────────────────────────┘"
echo ""

for LOG in "${!TARGETS[@]}"; do
  THRESHOLD="${TARGETS[$LOG]}"
  [ ! -f "$LOG" ] && continue

  SIZE="$(stat -f%z "$LOG" 2>/dev/null || stat -c%s "$LOG" 2>/dev/null || echo 0)"

  if [ "$FORCE" -eq 0 ] && [ "$SIZE" -lt "$THRESHOLD" ]; then
    SIZE_KB=$((SIZE / 1024))
    THRESHOLD_KB=$((THRESHOLD / 1024))
    printf "  \033[90mskip\033[0m %s (%dKB < %dKB)\n" "$LOG" "$SIZE_KB" "$THRESHOLD_KB"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # 轮转：.5 删除, .4→.5, .3→.4, .2→.3, .1→.2, current→.1.gz
  DIR="$(dirname "$LOG")"
  BASE="$(basename "$LOG")"

  # 删除最老的
  rm -f "$DIR/$BASE.${MAX_KEEP}.gz" 2>/dev/null || true

  # 依次后移
  for i in $(seq $((MAX_KEEP - 1)) -1 1); do
    NEXT=$((i + 1))
    [ -f "$DIR/$BASE.$i.gz" ] && mv "$DIR/$BASE.$i.gz" "$DIR/$BASE.$NEXT.gz" 2>/dev/null
  done

  # 当前 → .1 + gzip
  if command -v gzip >/dev/null 2>&1; then
    mv "$LOG" "$DIR/$BASE.1" && gzip "$DIR/$BASE.1"
  else
    mv "$LOG" "$DIR/$BASE.1"
  fi

  # 重新创建空文件（保持文件存在便于下次追加）
  touch "$LOG" 2>/dev/null || true

  SIZE_MB=$((SIZE / 1048576))
  printf "  \033[32mrotated\033[0m %s (%dMB → .1.gz)\n" "$LOG" "$SIZE_MB"
  ROTATED=$((ROTATED + 1))
done

echo ""
echo "─────────────────────────────────────────────────"
printf "  rotated: %d | skipped: %d\n" "$ROTATED" "$SKIPPED"
echo "─────────────────────────────────────────────────"
