#!/usr/bin/env bash
# tool-failure-capture.sh
#
# 触发：PostToolUseFailure hook（工具调用失败时）
# 目的：记录工具失败详情到审计日志，替代旧版 tool-failure-audit.sh 的
#       PostToolUse matcher 方案（旧方案需在 PostToolUse 中匹配错误，新方案
#       使用专用 PostToolUseFailure 事件，更精确且不干扰正常 PostToolUse 流程）
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

if command -v jq >/dev/null 2>&1; then
  TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null || echo "")"
  ERROR_MSG="$(echo "$INPUT" | jq -r '.error // .tool_response.error // empty' 2>/dev/null | head -c 500 || echo "")"
  SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")"
  CWD="$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || echo "")"
  TOOL_INPUT_PREVIEW="$(echo "$INPUT" | jq -c '.tool_input // empty' 2>/dev/null | head -c 200 || echo "")"

  jq -c -n \
    --arg ts "$TS" \
    --arg tool "$TOOL_NAME" \
    --arg err "$ERROR_MSG" \
    --arg session "$SESSION_ID" \
    --arg cwd "$CWD" \
    --arg input_preview "$TOOL_INPUT_PREVIEW" \
    --arg source "PostToolUseFailure" \
    '{timestamp: $ts, tool: $tool, error: $err, session_id: $session, cwd: $cwd, input_preview: $input_preview, source: $source}' \
    >> "$LOG_FILE" 2>/dev/null || true
else
  echo "{\"timestamp\":\"$TS\",\"tool\":\"unknown\",\"error\":\"jq not available\",\"source\":\"PostToolUseFailure\"}" >> "$LOG_FILE" 2>/dev/null || true
fi

exit 0
