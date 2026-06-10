#!/bin/bash
# PreCompact hook: 压缩前把恢复指引写进活跃 Task 文件(纯 side effect)
# 官方不支持 PreCompact/PostCompact 注入 additionalContext(docs/en/hooks, 2026-06),
# 恢复路径是: 指引落在文件里 → 压缩后模型重读 Task 文件时看到
source "$(dirname "$0")/_common.sh"

_init_hook
_require_tasks_dir
_find_active_tasks

[ "$ACTIVE_COUNT" -eq 0 ] && exit 0

TIMESTAMP=$(date "+%H:%M")

while IFS= read -r FILE; do
  [ -n "$FILE" ] || continue
  # 指引是静态文本,一条就够;重复追加只浪费压缩后重读的 context
  grep -q '^> \[PreCompact' "$FILE" && continue
  echo "> [PreCompact ${TIMESTAMP}] 上下文已压缩。恢复方式: 重读本文件 Intent / Plan / Decisions,从 Execution Log 最后一条继续。" >> "$FILE"
done <<< "$ACTIVE_FILES"

exit 0
