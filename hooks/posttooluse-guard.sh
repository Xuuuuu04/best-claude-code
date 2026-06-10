#!/bin/bash
# PostToolUse hook(工具成功时触发): 追踪"做了工作但没更新 Task"
#   Edit/Write Task 文件 → edits 归零(模型在更新进度)
#   Edit/Write 代码文件 → edits +1,Stop hook 读计数拦截
#   Bash 成功 → 不计工作量(只读命令占多数),只重置连败计数(失败侧在 posttoolusefailure.sh)
source "$(dirname "$0")/_common.sh"

_init_hook

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# 先过滤工具再碰 state,不相关路径零 IO(settings 层 matcher 收窄后这里是第二道防御)
case "$TOOL_NAME" in
  Edit|Write|MultiEdit|NotebookEdit) ;;
  Bash) RESET_ONLY=1 ;;
  *) exit 0 ;;
esac

_require_tasks_dir

# Bash 成功只重置连败计数;无 state 或计数已为零时零写盘
if [ -n "$RESET_ONLY" ]; then
  [ -f "$(_state_file_path)" ] || exit 0
  _load_hook_state
  [ "$FAILURES" -eq 0 ] && exit 0
  FAILURES=0
  _save_hook_state
  exit 0
fi

_load_hook_state

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
if echo "$FILE_PATH" | grep -q '\.claude/tasks/.*\.md$'; then
  EDITS=0
else
  EDITS=$((EDITS + 1))
fi
FAILURES=0

_save_hook_state
