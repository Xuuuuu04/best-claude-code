#!/usr/bin/env bash
# tool-failure-audit.sh
#
# 触发：PostToolUseFailure hook
# 目的：工具失败时记录审计链，便于排查 Claude 行为偏差
#
# 输入：stdin JSON（含 tool_name, tool_input, error 等）
# 输出：写入 logs/tool-failures.jsonl，不影响主流程
#
# 设计：纯审计，不阻塞，不返回额外 context（避免污染 Claude 上下文）

set -uo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/tool-failures.jsonl"

TS="$(date +%Y-%m-%dT%H:%M:%S%z)"

# 提取关键字段（无 jq 时降级为空）
if command -v jq >/dev/null 2>&1; then
  TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")"
  ERROR_MSG="$(echo "$INPUT" | jq -r '.tool_response.error // .error // empty' 2>/dev/null | head -c 500 || echo "")"
  SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")"
  CWD="$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")"

  # 写入 JSONL（一行一条）
  jq -c -n \
    --arg ts "$TS" \
    --arg tool "$TOOL_NAME" \
    --arg err "$ERROR_MSG" \
    --arg session "$SESSION_ID" \
    --arg cwd "$CWD" \
    '{timestamp: $ts, tool: $tool, error: $err, session_id: $session, cwd: $cwd}' \
    >> "$LOG_FILE" 2>/dev/null || true
else
  # 无 jq 降级
  echo "{\"timestamp\":\"$TS\",\"tool\":\"unknown\",\"error\":\"jq not available\"}" >> "$LOG_FILE" 2>/dev/null || true
fi

# 不输出任何内容到 stdout（避免污染 Claude 上下文）
exit 0
