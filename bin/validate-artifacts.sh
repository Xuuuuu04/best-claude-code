#!/usr/bin/env bash
# validate-artifacts.sh — Artifact Schema Checker (lightweight bash, no YAML parser).
#
# 校验目标：.claude/artifacts/*.md
#
# 级别划分（不 overdesign 的关键）：
#   CRITICAL  — 结构性错误（文件名与 type 冲突、status 非法值、verdict 无结论枚举）
#   WARNING   — 旧 artifact 缺 frontmatter、可选字段缺失（不阻塞流水线）
#   PASS      — 完整 frontmatter + 专项字段齐全
#
# 设计原则：
#   1. 不引入外部依赖（不用 yq/ajv），只用 bash + awk + grep
#   2. 向后兼容：没 frontmatter 的老 artifact 只报 WARNING
#   3. 严格只对"有 frontmatter 的新 artifact"执行 schema 校验
#   4. 默认扫当前工作区的 .claude/artifacts/；可传入目录参数
#
# 用法：
#   bin/validate-artifacts.sh              # 扫 ./artifacts 或 ./.claude/artifacts
#   bin/validate-artifacts.sh /path/dir    # 指定目录
#
# 退出码：
#   0 = 无 CRITICAL（WARNING 不影响 exit code）
#   1 = 有 CRITICAL

set -uo pipefail
IFS=$'\n\t'

# -----------------------------------------------------------------------------
# 配置
# -----------------------------------------------------------------------------

# type 枚举（与 rules/_global/artifact-protocol.md 保持一致）
# 注意：脚本顶部设置了 IFS=$'\n\t'，空格不再是分隔符，故用数组展开
VALID_TYPES=(
  requirements client-brief creative dispatch
  dispatch-ticket
  architecture scope-lock scope-plan schema
  ml-report impl-report
  review-requirements review-architecture review-code
  review-security review-functional review-visual
  verdict doc design prompt-governance
  deploy-report incident
  repo-research tech-research
  init-analysis update-analysis
  evolve-audit evolve-proposals evolve-log
)

# status 枚举
VALID_STATUS=(draft accepted rejected superseded)

# verdict 专项：必须包含以下结论之一
VALID_VERDICT_VALUES="PASS CONDITIONAL_PASS BLOCKED"

# scope-lock 专项：必须出现以下标题之一（中英文包容）
SCOPE_LOCK_SECTIONS_REGEX='^##[[:space:]]+(改动白名单|白名单|Scope|scope|文件白名单|File Whitelist)'

# -----------------------------------------------------------------------------
# 工具
# -----------------------------------------------------------------------------

color_on=""
color_off=""
if [ -t 1 ]; then
  color_on=$'\033[0;33m'
  color_red=$'\033[0;31m'
  color_green=$'\033[0;32m'
  color_off=$'\033[0m'
else
  color_on=""; color_red=""; color_green=""; color_off=""
fi

CRITICAL_COUNT=0
WARNING_COUNT=0
PASS_COUNT=0

emit_critical() {
  echo "${color_red}✗ CRITICAL${color_off} $1: $2"
  CRITICAL_COUNT=$((CRITICAL_COUNT+1))
}

emit_warning() {
  echo "${color_on}⚠ WARNING ${color_off} $1: $2"
  WARNING_COUNT=$((WARNING_COUNT+1))
}

emit_pass() {
  echo "${color_green}✓ PASS    ${color_off} $1"
  PASS_COUNT=$((PASS_COUNT+1))
}

# 从文件提取 frontmatter 块（首对 --- 之间内容，不含分隔符）；无 frontmatter 返回空
extract_frontmatter() {
  awk '
    NR==1 && $0 !~ /^---[[:space:]]*$/ { exit }
    /^---[[:space:]]*$/ { c++; if (c==1) next; if (c==2) exit }
    c==1 { print }
  ' "$1"
}

# 从 frontmatter 中读指定键（只取第一个匹配值）
fm_get() {
  local fm="$1" key="$2"
  echo "$fm" | awk -v k="$key" '
    $0 ~ "^"k":" { sub("^"k":[[:space:]]*", ""); print; exit }
  '
}

# 从文件名猜测 type 前缀（artifact-protocol: {type}-{task-id}[-{seq}].md）
guess_type_from_filename() {
  local base="$1" t
  # 按声明顺序匹配（多段 type 如 scope-lock 在前，不会被 scope 抢占）
  for t in "${VALID_TYPES[@]}"; do
    case "$base" in
      "$t"-*) echo "$t"; return 0 ;;
    esac
  done
  echo ""
}

# -----------------------------------------------------------------------------
# 单文件校验
# -----------------------------------------------------------------------------

validate_one() {
  local path="$1"
  local base
  base="$(basename "$path")"
  [ -f "$path" ] || return 0

  local expected_type
  expected_type="$(guess_type_from_filename "$base")"

  if [ -z "$expected_type" ]; then
    emit_warning "$base" "文件名前缀不在已知 type 枚举中"
    return 0
  fi

  # ---- task-id 格式校验（v3 新增，依据 rules/_global/dotclaude-layout.md） ----
  # 合规 task-id: {prefix}-{YYYYMMDD}[-{NN|slug}]
  # prefix: feat / bug / hotfix / chore / refactor / migration / deploy / audit / research
  # 对 type 为 evolve-log / index / 等元文件豁免
  case "$expected_type" in
    evolve-log|evolve-audit|evolve-proposals) ;;
    *)
      # 去掉 type- 前缀和 .md 后缀，得到 task-id[-seq] 部分
      local task_part="${base#${expected_type}-}"
      task_part="${task_part%.md}"
      # 匹配 {prefix}-{YYYYMMDD} 至少一次
      if ! echo "$task_part" | grep -qE '^(feat|bug|hotfix|chore|refactor|migration|deploy|audit|research|init|update|ecc|legion)-[0-9]{8}(-[a-z0-9-]+)?$'; then
        emit_warning "$base" "task-id 不符合规范（应为 {prefix}-YYYYMMDD[-slug]，见 dotclaude-layout.md）"
      fi
      ;;
  esac

  local fm
  fm="$(extract_frontmatter "$path")"

  # Case 1: 没有 frontmatter — 对老 artifact 保持兼容，只发 WARNING
  if [ -z "$fm" ]; then
    emit_warning "$base" "缺少 YAML frontmatter（老 artifact 可接受，新 artifact 建议补齐）"
    # 对 scope-lock / verdict 的专项检查仍需要跑
  else
    # ---- frontmatter 内容级校验 ----
    local fm_type fm_status
    fm_type="$(fm_get "$fm" "type")"
    fm_status="$(fm_get "$fm" "status")"
    # 中文字段名 "状态"
    if [ -z "$fm_status" ]; then
      fm_status="$(fm_get "$fm" "状态")"
    fi

    if [ -n "$fm_type" ] && [ "$fm_type" != "$expected_type" ]; then
      emit_critical "$base" "frontmatter type='$fm_type' 与文件名前缀 '$expected_type' 不一致"
    fi

    if [ -n "$fm_status" ]; then
      local status_norm s ok
      status_norm="$(echo "$fm_status" | tr '[:upper:]' '[:lower:]' | awk '{$1=$1};1')"
      ok=0
      for s in "${VALID_STATUS[@]}"; do
        if [ "$status_norm" = "$s" ]; then ok=1; break; fi
      done
      if [ "$ok" -eq 0 ]; then
        emit_critical "$base" "status='$fm_status' 不在 {draft|accepted|rejected|superseded}"
      fi
    else
      emit_warning "$base" "frontmatter 缺少 status / 状态 字段"
    fi
  fi

  # ---- 专项校验 ----
  case "$expected_type" in
    scope-lock)
      if ! grep -qE "$SCOPE_LOCK_SECTIONS_REGEX" "$path"; then
        emit_critical "$base" "scope-lock 缺少 '改动白名单' / 'Scope' 等必要段落"
      fi
      ;;
    verdict)
      # 必须出现结论枚举之一
      if ! grep -qE '\b(PASS|CONDITIONAL PASS|CONDITIONAL_PASS|BLOCKED)\b' "$path"; then
        emit_critical "$base" "verdict 缺少最终结论（PASS / CONDITIONAL PASS / BLOCKED）"
      fi
      ;;
  esac

  # PASS 由 validate_dir 根据计数差值判断，此处无需输出
}

# 更健壮的 PASS 累计：比较各文件处理前后计数
validate_dir() {
  local dir="$1"
  local found=0
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    found=1
    local before_c=$CRITICAL_COUNT
    local before_w=$WARNING_COUNT
    validate_one "$f"
    local after_c=$CRITICAL_COUNT
    local after_w=$WARNING_COUNT
    if [ "$after_c" -eq "$before_c" ] && [ "$after_w" -eq "$before_w" ]; then
      emit_pass "$(basename "$f")"
    fi
  done
  if [ "$found" -eq 0 ]; then
    echo "(no artifacts found in $dir)"
  fi
}

# -----------------------------------------------------------------------------
# 入口
# -----------------------------------------------------------------------------

TARGET=""
if [ $# -ge 1 ] && [ -n "${1:-}" ]; then
  TARGET="$1"
else
  # 默认：项目级 .claude/artifacts/，或仓库根 artifacts/
  if [ -d ".claude/artifacts" ]; then
    TARGET=".claude/artifacts"
  elif [ -d "artifacts" ]; then
    TARGET="artifacts"
  elif [ -d "$HOME/.claude/artifacts" ]; then
    TARGET="$HOME/.claude/artifacts"
  else
    echo "(no artifact directory detected; pass a path explicitly)"
    exit 0
  fi
fi

if [ ! -d "$TARGET" ]; then
  echo "ERROR: '$TARGET' is not a directory" >&2
  exit 2
fi

echo "Validating artifacts in: $TARGET"
echo ""
validate_dir "$TARGET"
echo ""
echo "---- Summary ----"
echo "PASS:     $PASS_COUNT"
echo "WARNING:  $WARNING_COUNT"
echo "CRITICAL: $CRITICAL_COUNT"

[ "$CRITICAL_COUNT" -eq 0 ]
