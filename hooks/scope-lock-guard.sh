#!/bin/bash
# scope-lock-guard.sh
# 目的：enforce scope-lock 白名单——拒绝写入白名单外的文件
# 触发：PreToolUse hook，matcher: Edit|Write
#
# 激活条件：
#   环境变量 CLAUDE_LEGION_SCOPE_ALLOW 非空。
#   内容为换行分隔的 glob 模式列表，如：
#     src/auth/token.ts
#     src/auth/__tests__/**
#
# 未设置该变量时此 hook 是 no-op（不影响主会话自由操作）。
#
# 设计原则：
# - 只在 Subagent 生命期内通过 initialPrompt 或 dispatcher 注入的
#   env 生效。主会话不设此变量，因此永不被限制。
# - 阻止方式：stdout 输出 permissionDecision:deny 的 JSON，停止工具调用
#   并把拒绝理由反馈给 Claude，让它修正而非悄悄失败。

set -uo pipefail

INPUT="$(cat || true)"

# 未启用 → 直接放行
ALLOW_LIST="${CLAUDE_LEGION_SCOPE_ALLOW:-}"
if [ -z "$ALLOW_LIST" ]; then
  exit 0
fi

# 提取目标文件路径
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null || echo "")"
[ -z "$FILE_PATH" ] && exit 0

# 规范化：去掉前导 ./ 等
NORM_PATH="${FILE_PATH#./}"

# 对照白名单逐条匹配（glob 模式）
MATCHED=0
while IFS= read -r PATTERN; do
  [ -z "$PATTERN" ] && continue
  # 使用 bash glob 扩展（需 extglob/globstar 支持**）
  shopt -s extglob globstar nullglob 2>/dev/null || true
  case "$NORM_PATH" in
    $PATTERN) MATCHED=1; break ;;
  esac
  # 如果 pattern 是绝对路径，也尝试直接匹配
  case "$FILE_PATH" in
    $PATTERN) MATCHED=1; break ;;
  esac
done <<< "$ALLOW_LIST"

if [ "$MATCHED" -eq 1 ]; then
  exit 0
fi

# 不在白名单 → 拒绝 + 提示
REASON="scope-lock violation: 尝试写入 '$FILE_PATH'，但它不在当前任务的白名单中。请只修改 scope-lock 列出的文件。如果确实需要扩展范围，停止并向调度器汇报。"

jq -n --arg reason "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: $reason
  }
}'

exit 0
