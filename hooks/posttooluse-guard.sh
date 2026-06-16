#!/bin/bash
# PostToolUse hook(工具成功时触发): 追踪"做了工作但没更新 Task"
#   Edit/Write Task 文件 → edits 归零(模型在更新进度)
#   Edit/Write 代码文件 → edits +1,Stop hook 读计数拦截
#   Bash 成功 → 不计工作量(只读命令占多数),只重置连败计数(失败侧在 posttoolusefailure.sh)
#   无活跃 task 但持续编辑代码 → 编辑到第 3 次时软提示开 task(补 Stop gate 的盲区)
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
# 只认 tasks/ 直下的 .md 为"更新进度";outputs/、archive/ 子目录下的(brief、归档)不算
if echo "$FILE_PATH" | grep -q '\.claude/tasks/[^/]*\.md$'; then
  EDITS=0
else
  EDITS=$((EDITS + 1))
fi
FAILURES=0

_save_hook_state

# 闭环入口兜底:无活跃 task 时 Stop gate 不工作(它需要活跃 task 才拦)。
# 编辑代码累计到第 3 次仍没有任何活跃 task → 注入一次提示,建议先开 task。
# 用 ==3 一次性触发:无 task 时 EDITS 不会被归零,故只命中一次,不刷屏。
if [ "$EDITS" -eq 3 ]; then
  _find_active_tasks
  if [ "$ACTIVE_COUNT" -eq 0 ]; then
    CONTEXT="📋 已编辑 ${EDITS} 个文件,但本项目没有进行中的 Task。建议先 /bcc-start 开一个——进度记录、压缩恢复、收尾检查都依赖活跃 Task,否则这些纪律 hook 会静默失效。"
    jq -n --arg ctx "$CONTEXT" \
      '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
  fi
fi
