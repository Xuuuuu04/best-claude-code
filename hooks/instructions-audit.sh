#!/bin/bash
# instructions-audit.sh
# 目的：记录每次会话加载了哪些指令文件（CLAUDE.md、Rules、Skills）
# 触发：InstructionsLoaded hook
#
# 用途：
# - 调试"规则没生效"问题（确认是否加载了）
# - /evolve 可以分析哪些 Rules 从未触发

set -euo pipefail

INPUT=$(cat)

TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S%z)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")

LOG_DIR="${CLAUDE_PROJECT_DIR:-$HOME/.claude}/logs"
mkdir -p "$LOG_DIR"

LOG_FILE="$LOG_DIR/instructions-loaded.jsonl"

# 原样记录完整 JSON 便于后续分析
jq -n \
  --arg ts "$TIMESTAMP" \
  --arg session "$SESSION_ID" \
  --argjson raw "$INPUT" \
  '{timestamp: $ts, session: $session, raw: $raw}' \
  >> "$LOG_FILE" 2>/dev/null || true

exit 0
