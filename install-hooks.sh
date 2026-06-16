#!/bin/bash
# install-hooks.sh — 把 BCC 的 5 个事件 hook 注册进 ~/.claude/settings.json
#
# 为什么需要它:settings.json 被 .gitignore(含 API keys),hook 注册随之不进 git。
# 搬机器 / 重装后 hook 会全部丢失且不自知。这个脚本进 git,跑一次即恢复注册。
#
# 幂等:只覆盖 hooks 段里这 5 个 key,保留 settings.json 其他字段和 hooks 里的自定义项。
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
HOOKS_DIR="${CLAUDE_DIR}/hooks"
SETTINGS="${CLAUDE_DIR}/settings.json"

command -v jq >/dev/null || { echo "需要 jq:brew install jq / apt install jq" >&2; exit 1; }

# 1. 5 个 hook 脚本必须存在,并确保可执行
for s in session-start precompact posttooluse-guard posttoolusefailure stop-progress-gate; do
  f="${HOOKS_DIR}/${s}.sh"
  [ -f "$f" ] || { echo "缺脚本:$f" >&2; exit 1; }
  chmod +x "$f"
done

# 2. settings.json 不存在则初始化为空对象
[ -f "$SETTINGS" ] || echo '{}' > "$SETTINGS"

# 3. 构造 hooks 段(命令路径用当前 $HOME,跨机器自适应)
HOOKS_JSON=$(jq -n --arg h "$HOOKS_DIR" '{
  SessionStart:       [ { matcher: "",                                       hooks: [ { type: "command", command: ($h + "/session-start.sh") } ] } ],
  PreCompact:         [ { matcher: "",                                       hooks: [ { type: "command", command: ($h + "/precompact.sh") } ] } ],
  PostToolUse:        [ { matcher: "Edit|Write|MultiEdit|NotebookEdit|Bash", hooks: [ { type: "command", command: ($h + "/posttooluse-guard.sh") } ] } ],
  PostToolUseFailure: [ { matcher: "Bash",                                   hooks: [ { type: "command", command: ($h + "/posttoolusefailure.sh") } ] } ],
  Stop:               [ { matcher: "",                                       hooks: [ { type: "command", command: ($h + "/stop-progress-gate.sh") } ] } ]
}')

# 4. merge:保留 hooks 里已有的其他 key,只覆盖这 5 个;mktemp + mv 原子写
TMP=$(mktemp "${SETTINGS}.XXXXXX")
jq --argjson hooks "$HOOKS_JSON" '.hooks = (.hooks // {}) + $hooks' "$SETTINGS" > "$TMP" && mv "$TMP" "$SETTINGS"

echo "✓ 已把 5 个事件 hook 注册进 $SETTINGS(路径基于 $HOME)"
echo "  重启 Claude Code 生效,或跑 /bcc-check 验证。"
