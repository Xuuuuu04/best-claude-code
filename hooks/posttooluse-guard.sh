#!/bin/bash
# PostToolUse hook(工具成功时触发): 追踪"做了工作但没更新 Task"
#   Edit/Write Task 文件 → edits 归零(模型在更新进度)
#   Edit/Write 代码文件、Bash 成功 → edits +1,Stop hook 读计数拦截
#   Bash 成功同时把连败计数归零;失败累加在 posttoolusefailure.sh(官方失败事件,不再猜 exit code)
source "$(dirname "$0")/_common.sh"

_init_hook

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

_require_tasks_dir
_load_hook_state

case "$TOOL_NAME" in
  Edit|Write|MultiEdit|NotebookEdit)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    if echo "$FILE_PATH" | grep -q '\.claude/tasks/.*\.md$'; then
      EDITS=0
    else
      EDITS=$((EDITS + 1))
    fi
    FAILURES=0
    ;;
  Bash)
    EDITS=$((EDITS + 1))
    FAILURES=0
    ;;
  *)
    exit 0
    ;;
esac

_save_hook_state
