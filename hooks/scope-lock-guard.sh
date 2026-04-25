#!/bin/bash
# scope-lock-guard.sh
# 目的：enforce scope-lock 白名单——拒绝 subagent 写入白名单外的文件
# 触发：PreToolUse hook，matcher: Edit|Write
#
# 激活条件（按优先级）：
#   1. 环境变量 CLAUDE_LEGION_SCOPE_ALLOW 非空（显式注入）
#   2. 在 subagent 内（stdin 含 agent_id）+ 项目级有 accepted scope-lock artifact
#   3. 都不满足时 → no-op（主会话快路径不受限）
#
# 设计：
# - **主会话默认豁免**：调度器判断快路径是 output-style 的职责，不是 hook 的职责
# - subagent 调用时由 hook 兜底：从最新 accepted scope-lock 推导白名单
# - 兼容新旧 status 格式：frontmatter `status: accepted` 或 markdown `**状态**: accepted`
# - 白名单段落识别多种格式：### N. 编号 / - path 列表 / 代码块路径
#
# 阻止方式：stdout 输出 permissionDecision:deny 的 JSON

set -uo pipefail

INPUT="$(cat || true)"

# ─── 主会话豁免判断 ────────────────────────────────────────────────────────
AGENT_ID="$(echo "$INPUT" | jq -r '.agent_id // empty' 2>/dev/null || echo "")"
HAS_EXPLICIT_ENV="${CLAUDE_LEGION_SCOPE_ALLOW:-}"

# 主会话（无 agent_id）且未显式设 env → 完全豁免
if [ -z "$AGENT_ID" ] && [ -z "$HAS_EXPLICIT_ENV" ]; then
  exit 0
fi

# ─── 白名单来源 ────────────────────────────────────────────────────────────
ALLOW_LIST="$HAS_EXPLICIT_ENV"

# 未显式注入 env → 从最新 accepted scope-lock artifact 提取
if [ -z "$ALLOW_LIST" ] && [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  ARTIFACT_DIR="$CLAUDE_PROJECT_DIR/.claude/artifacts"
  if [ -d "$ARTIFACT_DIR" ]; then
    # 找所有 scope-lock-*.md，按修改时间倒序，取第一个 accepted 的
    SCOPE_FILE=""
    while IFS= read -r f; do
      [ -z "$f" ] && continue
      # 兼容两种 accepted 格式
      if grep -qE '^status:[[:space:]]*accepted$|^\*\*状态\*\*:[[:space:]]*accepted' "$f" 2>/dev/null; then
        SCOPE_FILE="$f"
        break
      fi
    done < <(find "$ARTIFACT_DIR" -maxdepth 1 -name 'scope-lock-*.md' -type f 2>/dev/null \
              | xargs ls -t 2>/dev/null)

    if [ -n "$SCOPE_FILE" ]; then
      # 提取"改动白名单" / "白名单" / "Scope" / "File Whitelist" 段落
      # 支持 3 种条目格式：
      #   1. ### N. path           （编号子段）
      #   2. - path                （列表项）
      #   3. ` path `              （行内代码）
      ALLOW_LIST="$(awk '
        /^##[[:space:]]+(禁止事项|Out[[:space:]]+of[[:space:]]+Scope|输出格式|输出|完成标准)/ {inlist=0}
        /^##[[:space:]]+(改动白名单|白名单|Scope|File[[:space:]]+Whitelist|文件白名单)/ {inlist=1; next}
        inlist && /^###[[:space:]]+[0-9]+\.[[:space:]]+/ {
          line=$0
          sub(/^###[[:space:]]+[0-9]+\.[[:space:]]+/, "", line)
          sub(/[[:space:]]+[—-].*$/, "", line)
          gsub(/`/, "", line)
          if (line != "") print line
        }
        inlist && /^-[[:space:]]+/ {
          line=$0
          sub(/^-[[:space:]]+/, "", line)
          # 取代码块内的部分；否则截断到第一个空格
          if (match(line, /`[^`]+`/)) {
            line=substr(line, RSTART+1, RLENGTH-2)
          } else {
            sub(/[[:space:]].*$/, "", line)
          }
          if (line != "") print line
        }
      ' "$SCOPE_FILE")"
    fi
  fi
fi

# 仍无白名单 → no-op（subagent 但 artifact 不存在，让任务能跑）
if [ -z "$ALLOW_LIST" ]; then
  exit 0
fi

# ─── 提取目标文件路径 ──────────────────────────────────────────────────────
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")"
[ -z "$FILE_PATH" ] && exit 0

# artifact 自身的写入永远豁免（agent 在写 impl-report 等）
case "$FILE_PATH" in
  *.claude/artifacts/*) exit 0 ;;
  *.claude/agent-memory/*) exit 0 ;;
esac

# 规范化：去掉前导 ./
NORM_PATH="${FILE_PATH#./}"

# ─── 对照白名单匹配 ────────────────────────────────────────────────────────
MATCHED=0
while IFS= read -r PATTERN; do
  [ -z "$PATTERN" ] && continue
  shopt -s extglob globstar nullglob 2>/dev/null || true
  case "$NORM_PATH" in
    $PATTERN) MATCHED=1; break ;;
  esac
  case "$FILE_PATH" in
    $PATTERN) MATCHED=1; break ;;
  esac
done <<< "$ALLOW_LIST"

if [ "$MATCHED" -eq 1 ]; then
  exit 0
fi

# ─── 不在白名单 → 拒绝 ────────────────────────────────────────────────────
REASON="scope-lock violation: 尝试写入 '$FILE_PATH'，但它不在当前任务的白名单中。"
REASON+="请只修改 scope-lock 列出的文件。如确需扩展范围，停止并向调度器汇报。"

jq -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'

exit 0
