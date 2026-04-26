#!/usr/bin/env bash
# bin/skill-audit.sh
# Agent Legion · Skill 健康审计
#
# 审计每个 Skill 的：
#   - SKILL.md 行数（推荐 < 200，硬上限 500）
#   - description 字符数（硬上限 1536，推荐 < 500）
#   - 是否有 when_to_use 字段（领域协议类强烈推荐）
#   - 是否有 supporting files（references/ examples/ scripts/）
#   - supporting files 中是否有骨架文件（≤10 行）
#   - 是否含 4.6 时代脚手架词（double-check / always remember 等）
#
# 用法：
#   bash bin/skill-audit.sh                    # 全量审计
#   bash bin/skill-audit.sh --skill code-review-protocol  # 单个审计
#   bash bin/skill-audit.sh --strict           # 严格模式（warnings 也 exit 1）

set -uo pipefail

LEGION_DIR="$HOME/.claude"
SKILLS_DIR="$LEGION_DIR/skills"

CRITICAL=0
WARNING=0
INFO=0
STRICT_MODE=0
TARGET_SKILL=""

for arg in "$@"; do
  case "$arg" in
    --strict) STRICT_MODE=1 ;;
    --skill) shift; TARGET_SKILL="${1:-}" ;;
  esac
done

echo "═══════════════════════════════════════════════════════════════"
echo "  Skill Audit · Agent Legion"
echo "  $(date '+%Y-%m-%d %H:%M:%S')"
echo "═══════════════════════════════════════════════════════════════"
echo ""

# ─────────────────────────────────────────────────────────────
# 硬上限（来自官方 Anthropic Skills 文档）
# ─────────────────────────────────────────────────────────────
HARD_MAX_LINES=500
SOFT_MAX_LINES=200
DESC_HARD_MAX=1536
DESC_SOFT_MAX=500
THIN_REF_LINES=10

# ─────────────────────────────────────────────────────────────
# 4.6 时代脚手架词（4.7 字面化下可能反噬）
# ─────────────────────────────────────────────────────────────
SCAFFOLDING_PATTERNS=(
  "double[- ]check"
  "double_check"
  "always remember"
  "never forget"
  "please remember"
  "don't forget"
  "make sure to"
  "be sure to"
  "check twice"
  "verify twice"
  "review twice"
  "再次确认"
  "再三确认"
  "务必记住"
  "千万不要忘记"
)

# ─────────────────────────────────────────────────────────────
# 审计单个 Skill
# ─────────────────────────────────────────────────────────────
audit_skill() {
  local skill_dir="$1"
  local skill_name
  skill_name="$(basename "$skill_dir")"
  local skill_md="$skill_dir/SKILL.md"

  if [[ ! -f "$skill_md" ]]; then
    echo "❌ [$skill_name] CRITICAL: 缺 SKILL.md"
    CRITICAL=$((CRITICAL + 1))
    return
  fi

  # ── 1. 主文件行数 ──
  local lines
  lines="$(wc -l < "$skill_md" | tr -d ' ')"
  local lines_status=""
  if [[ "$lines" -gt "$HARD_MAX_LINES" ]]; then
    lines_status="❌ CRITICAL: 主文件 $lines 行超官方硬上限 500"
    CRITICAL=$((CRITICAL + 1))
  elif [[ "$lines" -gt "$SOFT_MAX_LINES" ]]; then
    lines_status="⚠️  WARNING: 主文件 $lines 行 > 推荐 200，建议拆 references/"
    WARNING=$((WARNING + 1))
  fi

  # ── 2. description 字符数 ──
  local desc
  desc="$(awk '/^---$/{f=!f; next} f && /^description:/{sub(/^description: */, ""); print}' "$skill_md" | head -1)"
  local desc_len=${#desc}
  local desc_status=""
  if [[ "$desc_len" -gt "$DESC_HARD_MAX" ]]; then
    desc_status="❌ CRITICAL: description $desc_len 字符 > 1536（会被截断）"
    CRITICAL=$((CRITICAL + 1))
  elif [[ "$desc_len" -gt "$DESC_SOFT_MAX" ]]; then
    desc_status="ℹ️  INFO: description $desc_len 字符偏长（推荐 < 500）"
    INFO=$((INFO + 1))
  fi

  # ── 3. when_to_use 字段 ──
  local has_when_to_use=0
  if grep -q "^when_to_use:" "$skill_md" 2>/dev/null; then
    has_when_to_use=1
  fi

  # ── 4. supporting files ──
  local refs_count=0
  local examples_count=0
  local scripts_count=0
  [[ -d "$skill_dir/references" ]] && refs_count=$(find "$skill_dir/references" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [[ -d "$skill_dir/examples" ]] && examples_count=$(find "$skill_dir/examples" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
  [[ -d "$skill_dir/scripts" ]] && scripts_count=$(find "$skill_dir/scripts" -type f 2>/dev/null | wc -l | tr -d ' ')

  local thin_refs=()
  if [[ -d "$skill_dir/references" ]]; then
    while IFS= read -r ref_file; do
      local ref_lines
      ref_lines="$(wc -l < "$ref_file" | tr -d ' ')"
      if [[ "$ref_lines" -le "$THIN_REF_LINES" ]]; then
        thin_refs+=("$(basename "$ref_file") ($ref_lines 行)")
      fi
    done < <(find "$skill_dir/references" -name "*.md")
  fi

  # ── 5. 4.6 脚手架词扫描 ──
  local scaffold_hits=()
  for pattern in "${SCAFFOLDING_PATTERNS[@]}"; do
    if grep -qiE "$pattern" "$skill_md" 2>/dev/null; then
      scaffold_hits+=("$pattern")
    fi
  done

  # ── 输出 ──
  echo "📦 $skill_name"
  echo "   主文件: $lines 行  |  desc: $desc_len 字符  |  refs: $refs_count  examples: $examples_count  scripts: $scripts_count"

  [[ -n "$lines_status" ]] && echo "   $lines_status"
  [[ -n "$desc_status" ]] && echo "   $desc_status"

  if [[ "$has_when_to_use" -eq 0 && "$lines" -gt 50 ]]; then
    echo "   ⚠️  WARNING: 主文件 $lines 行但缺 when_to_use（触发风险）"
    WARNING=$((WARNING + 1))
  fi

  if [[ ${#thin_refs[@]} -gt 0 ]]; then
    echo "   ⚠️  WARNING: 骨架 references: ${thin_refs[*]}"
    WARNING=$((WARNING + 1))
  fi

  if [[ ${#scaffold_hits[@]} -gt 0 ]]; then
    echo "   ⚠️  WARNING: 4.6 脚手架词: ${scaffold_hits[*]}"
    WARNING=$((WARNING + 1))
  fi

  echo ""
}

# ─────────────────────────────────────────────────────────────
# 主流程
# ─────────────────────────────────────────────────────────────
if [[ -n "$TARGET_SKILL" ]]; then
  if [[ -d "$SKILLS_DIR/$TARGET_SKILL" ]]; then
    audit_skill "$SKILLS_DIR/$TARGET_SKILL"
  else
    echo "❌ Skill 不存在: $TARGET_SKILL"
    exit 1
  fi
else
  # 全量审计
  total=0
  while IFS= read -r dir; do
    audit_skill "$dir"
    total=$((total + 1))
  done < <(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d | sort)

  echo "═══════════════════════════════════════════════════════════════"
  echo "  审计 $total 个 Skill"
  echo "  CRITICAL: $CRITICAL  |  WARNING: $WARNING  |  INFO: $INFO"
  echo "═══════════════════════════════════════════════════════════════"
fi

# ─────────────────────────────────────────────────────────────
# Agent description 字符数检查（顺带做）
# ─────────────────────────────────────────────────────────────
echo ""
echo "─── Agent description 字符数检查 ───"
agent_warn=0
for f in "$LEGION_DIR/agents"/*.md; do
  [[ -f "$f" ]] || continue
  local_desc="$(awk '/^---$/{f=!f; next} f && /^description:/{getline; while ($0 !~ /^[a-z]+:/) {print; getline}}' "$f" | head -3 | tr -d '\n')"
  local_desc_len=${#local_desc}
  if [[ "$local_desc_len" -gt "$DESC_HARD_MAX" ]]; then
    echo "❌ $(basename "$f" .md): description $local_desc_len 字符 > 1536"
    agent_warn=$((agent_warn + 1))
  fi
done
[[ "$agent_warn" -eq 0 ]] && echo "✅ 所有 Agent description 在 1536 字符内"
echo ""

# ─────────────────────────────────────────────────────────────
# 退出码
# ─────────────────────────────────────────────────────────────
if [[ "$CRITICAL" -gt 0 ]]; then
  exit 2
fi
if [[ "$STRICT_MODE" -eq 1 && "$WARNING" -gt 0 ]]; then
  exit 1
fi
exit 0
