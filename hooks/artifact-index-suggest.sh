#!/bin/bash
# artifact-index-suggest.sh — 当某 task-id 的 artifact 累计 ≥3 时，
# 提示主会话建立 index-<task-id>.md（依据 dotclaude-layout.md 索引规则）
#
# 触发：PostToolUse hook（matcher: Edit|Write）
# 输出：仅当满足条件时输出 additionalContext，否则 silent

set -uo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null || echo "")"
[ -z "$FILE_PATH" ] && exit 0

# 仅对 .claude/artifacts/ 下的写入感兴趣
case "$FILE_PATH" in
  *.claude/artifacts/*) : ;;
  *) exit 0 ;;
esac

ART_DIR="$(dirname "$FILE_PATH")"
BASE="$(basename "$FILE_PATH")"

# 已经是 index 文件本身 → 跳过
case "$BASE" in
  index-*) exit 0 ;;
esac

# 文件名应该形如 {type}-{prefix}-{YYYYMMDD}[-{slug-or-seq}].md
# 提取 task-id = {prefix}-{YYYYMMDD}（前 2 个 -- 之间的 YYYYMMDD 是关键锚）
# 用正则提取
TASK_ID="$(echo "$BASE" | grep -oE '(feat|bug|hotfix|chore|refactor|migration|deploy|audit|research|init|update|ecc|legion)-[0-9]{8}(-[a-z0-9-]+)?' | head -1)"
[ -z "$TASK_ID" ] && exit 0

# 进一步剥掉末尾的 seq（如 -1 / -2 / -10）
TASK_ID_BASE="$(echo "$TASK_ID" | sed -E 's/-[0-9]+$//')"
[ -z "$TASK_ID_BASE" ] && exit 0

# 统计同 task-id 的 artifact 数量
COUNT="$(find "$ART_DIR" -maxdepth 1 -name "*${TASK_ID_BASE}*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"

# 至少 3 个才提示
if [ "$COUNT" -lt 3 ]; then
  exit 0
fi

# 已有 index 文件 → 跳过
INDEX_FILE="$ART_DIR/index-${TASK_ID_BASE}.md"
if [ -f "$INDEX_FILE" ]; then
  exit 0
fi

# 已经提示过（marker file）→ 跳过，避免每次写入都骚扰
MARKER_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.claude/state"
mkdir -p "$MARKER_DIR" 2>/dev/null || true
MARKER="$MARKER_DIR/index-suggested-${TASK_ID_BASE}"
if [ -f "$MARKER" ]; then
  exit 0
fi
touch "$MARKER" 2>/dev/null || true

# 列出相关 artifact（前 10 个）
LISTED="$(find "$ART_DIR" -maxdepth 1 -name "*${TASK_ID_BASE}*.md" -type f 2>/dev/null | head -10 | awk -F/ '{print "  - " $NF}')"

CTX="[ARTIFACT-INDEX-NEEDED] task-id '${TASK_ID_BASE}' 已累计 ${COUNT} 个 artifact，按 dotclaude-layout.md ≥3 seq 规则需要建索引。"
CTX+="建议在合适时机产出 ${INDEX_FILE}，列出该任务的所有 artifact + 状态。当前文件："
CTX+=$'\n'"${LISTED}"

jq -c -n --arg ctx "$CTX" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$ctx}}'

exit 0
