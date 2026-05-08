#!/bin/bash
# permission-auto-claude.sh — PermissionRequest hook，自动批准 .claude/ 目录下的编辑请求
#
# 用途：解决 Claude Code 编辑 .claude/ 目录文件时反复弹权限确认的问题
# 原理：当 PermissionRequest 是 Edit/Write 工具且路径在 .claude/ 下时，exit 0（批准）
#       其他情况 exit 1（不批准，走正常权限流程）
#
# 注册方式：在 ~/.claude/settings.json 的 hooks 字段中添加：
#   "PermissionRequest": [
#     {
#       "hooks": [
#         {
#           "type": "command",
#           "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/permission-auto-claude.sh"
#         }
#       ]
#     }
#   ]
#
# 安全说明：
#   - 仅自动批准 .claude/ 和 ~/.claude/ 目录下的 Edit/Write 请求
#   - 不批准 .claude/ 外的任何文件编辑（包括业务代码、配置文件等）
#   - 不批准 Bash 工具、Read 工具等其他工具的权限请求
#   - 建议配合 CLAUDE_HOOK_PROFILE=standard 使用，保持其他 hook 正常运作

set -uo pipefail

# 读取 stdin 中的 JSON 输入
INPUT=$(cat)

# 提取 tool_name 和 file_path/path
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path // empty')

# 仅处理 Edit 和 Write 工具
if [ "$TOOL_NAME" != "Edit" ] && [ "$TOOL_NAME" != "Write" ]; then
  exit 1
fi

# 检查路径是否在 .claude/ 目录下
case "$FILE_PATH" in
  .claude/*|~/.claude/*|*/.claude/*)
    exit 0
    ;;
  *)
    exit 1
    ;;
esac
