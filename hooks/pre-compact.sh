#!/bin/bash
# pre-compact.sh
# 目的：在上下文压缩前保存当前工作状态快照
# 触发：PreCompact hook

set -uo pipefail

INPUT=$(cat)

# 仅在 git 仓库中执行
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${CLAUDE_PROJECT_DIR:-.}/.claude/backups"
mkdir -p "$BACKUP_DIR"

# 保存当前 git diff
git diff > "$BACKUP_DIR/state-${TIMESTAMP}.diff" 2>/dev/null || true
git diff --cached > "$BACKUP_DIR/staged-${TIMESTAMP}.diff" 2>/dev/null || true

# 保存当前 artifact 快照清单
if [ -d "${CLAUDE_PROJECT_DIR:-.}/.claude/artifacts" ]; then
  ls -la "${CLAUDE_PROJECT_DIR:-.}/.claude/artifacts"/*.md > "$BACKUP_DIR/artifacts-${TIMESTAMP}.txt" 2>/dev/null || true
fi

# 清理超过 30 天的备份
find "$BACKUP_DIR" -name "state-*.diff" -mtime +30 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "staged-*.diff" -mtime +30 -delete 2>/dev/null || true
find "$BACKUP_DIR" -name "artifacts-*.txt" -mtime +30 -delete 2>/dev/null || true

exit 0
