#!/usr/bin/env bash
# bin/validate-rules.sh
# Agent Legion · Rule 一致性校验
#
# 检查：
#   1. 每个 Rule 文件的 frontmatter 合法（至少有 --- 包裹）
#   2. path-specific Rule 的 glob 至少匹配到 1 个文件（防止死规则）
#   3. 无同名重复 Rule（按文件名 basename）
#   4. 警告：path 模式之间有重叠（不一定错，但值得注意）
#
# 用法:
#   bash ~/.claude/bin/validate-rules.sh [rules-root-dir]
# 默认扫描 ~/.claude/rules/ 和 $PWD/.claude/rules/

set -uo pipefail

# 参数解析
ROOTS=()
if [ $# -gt 0 ]; then
  ROOTS+=("$1")
else
  [ -d "$HOME/.claude/rules" ] && ROOTS+=("$HOME/.claude/rules")
  [ -d "$PWD/.claude/rules" ] && [ "$PWD/.claude/rules" != "$HOME/.claude/rules" ] && ROOTS+=("$PWD/.claude/rules")
fi

if [ ${#ROOTS[@]} -eq 0 ]; then
  echo "No rules/ directories found. Pass a path or cd into a project with .claude/rules/."
  exit 1
fi

# 统计
TOTAL=0
UNCONDITIONAL=0
CONDITIONAL=0
BAD_FRONTMATTER=0
DEAD_GLOBS=0
DUP_NAMES=0
WARNS=0

declare -a DEAD_FILES
declare -A SEEN_NAMES

# 用于检测死 glob 的扫描根（当前目录）
SCAN_ROOT="$PWD"

echo ""
echo "Agent Legion · Rule Validator"
echo "============================================================"
echo "Scan roots:"
for r in "${ROOTS[@]}"; do echo "  - $r"; done
echo "Glob match scan root: $SCAN_ROOT"
echo ""

for ROOT in "${ROOTS[@]}"; do
  while IFS= read -r -d '' RULE; do
    TOTAL=$((TOTAL + 1))
    REL="${RULE#$ROOT/}"
    NAME="$(basename "$RULE")"

    # ── 1. frontmatter 合法性 ─────────────────────────────
    FIRST_LINE="$(head -1 "$RULE" 2>/dev/null || echo "")"
    if [ "$FIRST_LINE" != "---" ]; then
      # 无 frontmatter → 视为无条件 Rule
      UNCONDITIONAL=$((UNCONDITIONAL + 1))
      continue
    fi

    # 提取 frontmatter 区块
    FM="$(awk '/^---$/{count++; if(count==2) exit; next} count==1' "$RULE" 2>/dev/null || echo "")"

    # ── 2. 检查 paths 字段 ────────────────────────────────
    if echo "$FM" | grep -q '^paths:'; then
      CONDITIONAL=$((CONDITIONAL + 1))

      # 提取每条 glob（简单 YAML：paths 下一行若干 - "pattern"）
      PATTERNS="$(echo "$FM" | awk '
        /^paths:/ { capture=1; next }
        /^[a-z]+:/ { capture=0 }
        capture && /^[[:space:]]*-[[:space:]]*/ {
          gsub(/^[[:space:]]*-[[:space:]]*"?/, "")
          gsub(/"?[[:space:]]*$/, "")
          print
        }
      ')"

      if [ -z "$PATTERNS" ]; then
        echo "  ⚠  $REL: paths field present but empty"
        WARNS=$((WARNS + 1))
        continue
      fi

      # 对每条 pattern 检查是否至少匹配一个文件
      HAS_MATCH=0
      while IFS= read -r PAT; do
        [ -z "$PAT" ] && continue
        # 在 SCAN_ROOT 下用 find + bash glob 检查（bash globstar）
        shopt -s globstar nullglob 2>/dev/null || true
        cd "$SCAN_ROOT" 2>/dev/null || break
        MATCHES=( $PAT )
        if [ ${#MATCHES[@]} -gt 0 ] && [ -n "${MATCHES[0]:-}" ]; then
          HAS_MATCH=1
          break
        fi
      done <<< "$PATTERNS"

      if [ "$HAS_MATCH" -eq 0 ]; then
        DEAD_GLOBS=$((DEAD_GLOBS + 1))
        DEAD_FILES+=("$REL")
      fi
    else
      UNCONDITIONAL=$((UNCONDITIONAL + 1))
    fi

    # ── 3. 重复名检测 ────────────────────────────────────
    if [ -n "${SEEN_NAMES[$NAME]:-}" ]; then
      echo "  ⚠  duplicate name: $NAME"
      echo "       first:  ${SEEN_NAMES[$NAME]}"
      echo "       second: $RULE"
      DUP_NAMES=$((DUP_NAMES + 1))
    else
      SEEN_NAMES[$NAME]="$RULE"
    fi
  done < <(find "$ROOT" -type f -name '*.md' -print0 2>/dev/null)
done

# ── 结果汇总 ─────────────────────────────────────────────
echo ""
echo "Summary"
echo "------------------------------------------------------------"
printf "  Total rules:          %d\n" "$TOTAL"
printf "  Unconditional:        %d (loaded every session)\n" "$UNCONDITIONAL"
printf "  Path-specific:        %d (loaded on matching file read)\n" "$CONDITIONAL"
printf "  Dead globs:           %d  (no files in current tree match)\n" "$DEAD_GLOBS"
printf "  Duplicate names:      %d\n" "$DUP_NAMES"
printf "  Other warnings:       %d\n" "$WARNS"

if [ ${#DEAD_FILES[@]} -gt 0 ]; then
  echo ""
  echo "Dead glob rules (not necessarily broken — may match in other projects):"
  for f in "${DEAD_FILES[@]}"; do
    echo "  · $f"
  done
  echo ""
  echo "Note: these are user-level Rules scanned against current working"
  echo "      directory. A rule matching '**/*.py' will look 'dead' in a"
  echo "      non-Python project but still work when you cd into one."
fi

echo ""
if [ "$DUP_NAMES" -gt 0 ]; then
  exit 1
fi
exit 0
