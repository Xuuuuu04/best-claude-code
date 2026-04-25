#!/usr/bin/env bash
# tidy-dotclaude.sh — 只读诊断某个项目的 .claude/ 是否符合 dotclaude-layout 规范
#
# 用法：
#   bin/tidy-dotclaude.sh                        # 当前目录
#   bin/tidy-dotclaude.sh /path/to/project       # 指定项目
#   bin/tidy-dotclaude.sh --suggest              # 输出 shell 迁移建议（只打印，不执行）
#   bin/tidy-dotclaude.sh --apply /path/to/proj  # 真的迁移（需显式 --apply，不写业务代码）
#
# 输出：
#   - 根目录乱放的文件清单 + 应迁移目标
#   - artifact 命名不合规清单（依赖 validate-artifacts.sh）
#   - .broken 备份、空目录等清理建议
#
# 退出码：
#   0 = 一切合规
#   1 = 有建议（不是错误）

set -uo pipefail
IFS=$'\n\t'

MODE="report"
TARGET=""
SUGGEST=0
APPLY=0

while [ $# -gt 0 ]; do
  case "$1" in
    --suggest) SUGGEST=1; shift ;;
    --apply)   APPLY=1; SUGGEST=1; shift ;;
    -h|--help)
      sed -n '1,20p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) TARGET="$1"; shift ;;
  esac
done

if [ -z "$TARGET" ]; then
  TARGET="$PWD"
fi

if [ ! -d "$TARGET/.claude" ]; then
  echo "ERROR: $TARGET/.claude 不存在" >&2
  exit 2
fi

CLAUDE_DIR="$TARGET/.claude"

# 颜色
if [ -t 1 ]; then
  C_OK=$'\033[0;32m'; C_WARN=$'\033[0;33m'; C_ERR=$'\033[0;31m'; C_OFF=$'\033[0m'; C_DIM=$'\033[0;90m'
else
  C_OK=""; C_WARN=""; C_ERR=""; C_OFF=""; C_DIM=""
fi

echo "Tidying: $CLAUDE_DIR"
echo ""

# ─── 根目录允许清单 ────────────────────────────────────────────────────────
ALLOWED_DIRS=(artifacts agent-memory logs state worktrees skills agents rules commands hooks output-styles projects)
ALLOWED_FILES=(settings.local.json CLAUDE.md)

# 检查函数：某条目是否合规在根目录
is_allowed_in_root() {
  local name="$1"
  local entry
  for entry in "${ALLOWED_DIRS[@]}" "${ALLOWED_FILES[@]}"; do
    [ "$name" = "$entry" ] && return 0
  done
  return 1
}

# 规则：某条目应该去哪里
target_location() {
  local name="$1"
  case "$name" in
    # 日志类
    cost-log.txt|instructions-log.txt|hook-errors.log|*.log|*.jsonl) echo "logs/" ;;
    cost-log.txt.broken.*|*.broken.*) echo "logs/backups/" ;;
    backups) echo "logs/backups/（合并到此，或按内容拆到 archive/）" ;;
    # 状态类
    scheduled_tasks.lock|scheduled_tasks.json|*.lock|*.pid|session-*) echo "state/" ;;
    # 临时类
    tmp|.tmp|.cache) echo "tmp/（或删除）" ;;
    *) echo "" ;;
  esac
}

# ─── 扫根目录 ──────────────────────────────────────────────────────────────
SUGGESTIONS=()
OUT_OF_PLACE=0
for entry in "$CLAUDE_DIR"/.* "$CLAUDE_DIR"/*; do
  [ -e "$entry" ] || continue
  name="$(basename "$entry")"
  # 跳过 . 和 ..
  [ "$name" = "." ] || [ "$name" = ".." ] && continue

  if is_allowed_in_root "$name"; then
    continue
  fi

  tgt="$(target_location "$name")"
  if [ -n "$tgt" ]; then
    echo "${C_WARN}✗${C_OFF} $name → ${C_DIM}$tgt${C_OFF}"
    SUGGESTIONS+=("mkdir -p \"$CLAUDE_DIR/${tgt%%（*}\" && mv \"$entry\" \"$CLAUDE_DIR/${tgt%%（*}\"")
  else
    echo "${C_WARN}?${C_OFF} $name ${C_DIM}(未知分类，手动决定)${C_OFF}"
  fi
  OUT_OF_PLACE=$((OUT_OF_PLACE+1))
done

if [ "$OUT_OF_PLACE" -eq 0 ]; then
  echo "${C_OK}✓${C_OFF} 根目录布局合规"
fi

# ─── 检查各标准子目录存在性（信息） ────────────────────────────────────────
echo ""
echo "子目录状态："
for d in artifacts agent-memory logs state; do
  if [ -d "$CLAUDE_DIR/$d" ]; then
    cnt="$(find "$CLAUDE_DIR/$d" -type f 2>/dev/null | wc -l | tr -d ' ')"
    echo "  ${C_OK}✓${C_OFF} $d/ ($cnt files)"
  else
    echo "  ${C_DIM}—${C_OFF} $d/ (不存在，首次产出时自动创建)"
  fi
done

# ─── artifact 命名合规 ──────────────────────────────────────────────────────
echo ""
echo "Artifact 命名校验："
VALIDATOR="$(dirname "$0")/validate-artifacts.sh"
if [ -x "$VALIDATOR" ] && [ -d "$CLAUDE_DIR/artifacts" ]; then
  VA_OUT="$(bash "$VALIDATOR" "$CLAUDE_DIR/artifacts" 2>&1)"
  VA_PASS="$(echo "$VA_OUT" | awk -F: '/^PASS:/{gsub(/ /,"",$2); print $2}')"
  VA_WARN="$(echo "$VA_OUT" | awk -F: '/^WARNING:/{gsub(/ /,"",$2); print $2}')"
  VA_CRIT="$(echo "$VA_OUT" | awk -F: '/^CRITICAL:/{gsub(/ /,"",$2); print $2}')"
  echo "  PASS=${VA_PASS:-0}  WARNING=${VA_WARN:-0}  CRITICAL=${VA_CRIT:-0}"
  if [ "${VA_CRIT:-0}" -gt 0 ]; then
    echo "  ${C_ERR}✗${C_OFF} 有 CRITICAL，跑 ${C_DIM}bash bin/validate-artifacts.sh $CLAUDE_DIR/artifacts${C_OFF} 查看详情"
  elif [ "${VA_WARN:-0}" -gt 0 ]; then
    echo "  ${C_WARN}⚠${C_OFF} 命名/frontmatter 有漂移（老 artifact 常见，新产出必须合规）"
  else
    echo "  ${C_OK}✓${C_OFF} 全部合规"
  fi
else
  echo "  ${C_DIM}—${C_OFF} 无 artifacts/ 或 validator 不可用，跳过"
fi

# ─── .broken 文件统计 ──────────────────────────────────────────────────────
echo ""
echo ".broken / 备份文件："
BROKEN_COUNT="$(find "$CLAUDE_DIR" -name '*.broken.*' -type f 2>/dev/null | wc -l | tr -d ' ')"
if [ "$BROKEN_COUNT" -gt 0 ]; then
  echo "  ${C_WARN}⚠${C_OFF} 发现 $BROKEN_COUNT 个 *.broken.* 文件（建议移至 logs/backups/ 或评估删除）"
  SUGGESTIONS+=("find \"$CLAUDE_DIR\" -maxdepth 1 -name '*.broken.*' -exec mv {} \"$CLAUDE_DIR/logs/backups/\" \\;")
else
  echo "  ${C_OK}✓${C_OFF} 无 .broken 残留"
fi

# ─── 归档建议 ──────────────────────────────────────────────────────────────
echo ""
echo "Artifact 归档建议："
if [ -d "$CLAUDE_DIR/artifacts" ]; then
  OLD_COUNT=0
  A_TOTAL=0
  OLD_COUNT="$(find "$CLAUDE_DIR/artifacts" -maxdepth 1 -type f -name '*.md' -mtime +30 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  A_TOTAL="$(find "$CLAUDE_DIR/artifacts" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
  OLD_COUNT="${OLD_COUNT:-0}"
  A_TOTAL="${A_TOTAL:-0}"
  echo "  活跃 artifact: ${A_TOTAL} (超过 30 天: ${OLD_COUNT})"
  if [ "${OLD_COUNT}" -gt 10 ] 2>/dev/null; then
    YEAR="$(date +%Y)"
    Q="Q$(( ( 10#$(date +%m) - 1 ) / 3 + 1 ))"
    echo "  ${C_WARN}建议${C_OFF} 归档到 artifacts/archive/${YEAR}-${Q}/"
  fi
fi

# ─── 输出迁移建议 ──────────────────────────────────────────────────────────
if [ "$SUGGEST" -eq 1 ] && [ "${#SUGGESTIONS[@]}" -gt 0 ]; then
  echo ""
  echo "${C_DIM}─── 迁移建议（逐条手动执行，或用 --apply）───${C_OFF}"
  for s in "${SUGGESTIONS[@]}"; do
    echo "$s"
  done
  if [ "$APPLY" -eq 1 ]; then
    echo ""
    echo "${C_WARN}执行迁移中…${C_OFF}"
    for s in "${SUGGESTIONS[@]}"; do
      echo "+ $s"
      eval "$s"
    done
    echo "${C_OK}完成${C_OFF}"
  fi
fi

echo ""
if [ "$OUT_OF_PLACE" -eq 0 ] && [ "${BROKEN_COUNT:-0}" -eq 0 ] && [ "${VA_CRIT:-0}" = "0" ]; then
  echo "${C_OK}项目 .claude/ 布局整洁${C_OFF}"
  exit 0
else
  echo "${C_WARN}有建议项，跑 ${0##*/} --suggest 看迁移命令${C_OFF}"
  exit 1
fi
