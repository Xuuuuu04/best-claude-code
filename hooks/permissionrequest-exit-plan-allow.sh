#!/usr/bin/env bash
# permissionrequest-exit-plan-allow.sh
#
# 自动批准 ExitPlanMode 工具调用，免除 plan mode 完成后的批准对话。
# 仅匹配 ExitPlanMode（settings.json 中的 matcher 已限定），其他权限提示不受影响。
#
# 输入：stdin 上的 PermissionRequest hook JSON（这里我们不需要解析，因为 matcher 已过滤）
# 输出：stdout 上的批准 JSON
#
# 设计参考：features-overview.md § "自动批准特定权限提示"

set -uo pipefail

# 读 stdin（不使用，但避免 SIGPIPE）
cat >/dev/null

cat <<'JSON'
{"hookSpecificOutput": {"hookEventName": "PermissionRequest", "decision": {"behavior": "allow"}}}
JSON

exit 0
