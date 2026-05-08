#!/usr/bin/env bash
# artifact-file-changed.sh
#
# 触发：FileChanged hook（.claude/artifacts/ 下文件变更时）
# 目的：实时校验 artifact 写入合规性，替代 PostToolUse 延迟校验
#
# 输入：stdin JSON（含 filename, change_type 等）
# 输出：校验失败时通过 additionalContext 注入警告
#
# matcher 配置：应使用字面文件名匹配，如 ".claude/artifacts/*.md"
# 注意：FileChanged 的 matcher 不遵循常规规则，使用字面文件名

set -uo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

FILENAME="$(echo "$INPUT" | jq -r '.filename // empty' 2>/dev/null || echo "")"
CHANGE_TYPE="$(echo "$INPUT" | jq -r '.change_type // empty' 2>/dev/null || echo "")"

[ -z "$FILENAME" ] && exit 0

# 只关心 .claude/artifacts/ 下的 .md 文件
case "$FILENAME" in
  *.claude/artifacts/*.md|*/artifacts/*.md) ;;
  *) exit 0 ;;
esac

# 只关心修改和创建（删除不校验）
case "$CHANGE_TYPE" in
  modified|created) ;;
  *) exit 0 ;;
esac

# 文件不存在则跳过（可能已被删除）
[ ! -f "$FILENAME" ] && exit 0

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/artifact-file-changes.jsonl"
TS="$(date +%Y-%m-%dT%H:%M:%S%z)"

# 运行 artifact 校验器（如果存在）
VALIDATOR="$HOME/.claude/bin/validate-artifacts.sh"
VALIDATION_RESULT=""
VALIDATION_EXIT=0

if [ -x "$VALIDATOR" ]; then
  VALIDATION_OUTPUT="$("$VALIDATOR" "$FILENAME" 2>&1)" || VALIDATION_EXIT=$?
  if [ "$VALIDATION_EXIT" -ne 0 ]; then
    VALIDATION_RESULT="$(echo "$VALIDATION_OUTPUT" | head -c 500)"
  fi
fi

# 基础 frontmatter 检查（不依赖外部校验器）
HAS_FRONTMATTER=0
ISSUES=""

if head -1 "$FILENAME" 2>/dev/null | grep -q '^---'; then
  HAS_FRONTMATTER=1
fi

BASENAME="$(basename "$FILENAME")"

# type 前缀与 frontmatter type 一致性检查
TYPE_PREFIX=""
case "$BASENAME" in
  scope-lock-*) TYPE_PREFIX="scope-lock" ;;
  impl-report-*) TYPE_PREFIX="impl-report" ;;
  review-code-*) TYPE_PREFIX="review-code" ;;
  review-security-*) TYPE_PREFIX="review-security" ;;
  review-functional-*) TYPE_PREFIX="review-functional" ;;
  review-visual-*) TYPE_PREFIX="review-visual" ;;
  verdict-*) TYPE_PREFIX="verdict" ;;
  architecture-*) TYPE_PREFIX="architecture" ;;
  requirements-*) TYPE_PREFIX="requirements" ;;
  dispatch-*) TYPE_PREFIX="dispatch" ;;
esac

if [ -n "$TYPE_PREFIX" ] && [ "$HAS_FRONTMATTER" -eq 1 ]; then
  FM_TYPE="$(awk '/^---/{n++; next} n==1 && /^type:/{print $2; exit}' "$FILENAME" 2>/dev/null || echo "")"
  if [ -n "$FM_TYPE" ] && [ "$FM_TYPE" != "$TYPE_PREFIX" ]; then
    ISSUES="frontmatter type='$FM_TYPE' but filename prefix='$TYPE_PREFIX'"
  fi
fi

# status 字段检查
if [ "$HAS_FRONTMATTER" -eq 1 ]; then
  FM_STATUS="$(awk '/^---/{n++; next} n==1 && /^status:/{print $2; exit}' "$FILENAME" 2>/dev/null || echo "")"
  if [ -n "$FM_STATUS" ]; then
    case "$FM_STATUS" in
      draft|in_progress|accepted|rejected|blocked) ;;
      *) ISSUES="${ISSUES:+$ISSUES; }invalid status='$FM_STATUS'" ;;
    esac
  fi
fi

# 记录日志
jq -c -n \
  --arg ts "$TS" \
  --arg file "$FILENAME" \
  --arg change "$CHANGE_TYPE" \
  --arg issues "$ISSUES" \
  --arg validator_result "$VALIDATION_RESULT" \
  '{timestamp: $ts, file: $file, change: $change, issues: $issues, validator: $validator_result}' \
  >> "$LOG_FILE" 2>/dev/null || true

# 如果有问题，注入警告到 additionalContext
if [ -n "$ISSUES" ] || [ -n "$VALIDATION_RESULT" ]; then
  WARNING="[ARTIFACT-VALIDATION-WARNING] $BASENAME"
  [ -n "$ISSUES" ] && WARNING="$WARNING — $ISSUES"
  [ -n "$VALIDATION_RESULT" ] && WARNING="$WARNING — validator: $VALIDATION_RESULT"

  jq -c -n --arg ctx "$WARNING" \
    '{hookSpecificOutput:{hookEventName:"FileChanged", additionalContext:$ctx}}'
fi

exit 0
