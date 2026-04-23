#!/bin/bash
# instructions-audit.sh
# 目的：记录每次会话加载了哪些指令文件（CLAUDE.md、Rules、Skills）
# 触发：InstructionsLoaded hook
#
# 用途：
# - 调试"规则没生效"问题：查 .claude/instructions-log.txt 看加载时间/原因
# - /bcc-evolve 可分析 ~/.claude/logs/instructions-loaded.jsonl 找从未触发的 Rule
#
# 行为：
# - 写两份日志：机器可读 JSONL（全局）+ 人类可读文本（项目级，如在项目目录）

set -uo pipefail

INPUT="$(cat || true)"
TIMESTAMP="$(date +%Y-%m-%dT%H:%M:%S%z)"
SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // "unknown"' 2>/dev/null || echo "unknown")"

# ── 1. 机器日志（全量 JSONL，供 /bcc-evolve 分析） ──────────────────────────
GLOBAL_LOG_DIR="$HOME/.claude/logs"
mkdir -p "$GLOBAL_LOG_DIR" 2>/dev/null || true

jq -n \
  --arg ts "$TIMESTAMP" \
  --arg session "$SESSION_ID" \
  --argjson raw "${INPUT:-null}" \
  '{timestamp: $ts, session: $session, raw: $raw}' \
  >> "$GLOBAL_LOG_DIR/instructions-loaded.jsonl" 2>/dev/null || true

# ── 2. 人类日志（精简单行，供日常排查） ──────────────────────────────────────
# 只在 CLAUDE_PROJECT_DIR 下写项目级日志，避免污染不相关目录
PROJ_DIR="${CLAUDE_PROJECT_DIR:-}"
if [ -n "$PROJ_DIR" ] && [ -d "$PROJ_DIR/.claude" ]; then
  PROJ_LOG="$PROJ_DIR/.claude/instructions-log.txt"

  # 提取有用字段（依官方字段名：file_path / load_reason / trigger_file_path）
  FILE_PATH="$(echo "$INPUT" | jq -r '.file_path // empty' 2>/dev/null || echo "")"
  LOAD_REASON="$(echo "$INPUT" | jq -r '.load_reason // empty' 2>/dev/null || echo "")"
  TRIGGER="$(echo "$INPUT" | jq -r '.trigger_file_path // empty' 2>/dev/null || echo "")"

  # 至少要有 file_path 才写一行（避免空行噪音）
  if [ -n "$FILE_PATH" ]; then
    # 格式：时间戳 | 加载原因 | 文件 [← 触发文件]
    LINE="${TIMESTAMP} | ${LOAD_REASON:-?} | ${FILE_PATH}"
    [ -n "$TRIGGER" ] && LINE="${LINE}  ← ${TRIGGER}"
    echo "$LINE" >> "$PROJ_LOG" 2>/dev/null || true
  fi
fi

exit 0
