#!/usr/bin/env bash
# Hook-C2: 用户输入后注入（compact 铁律复习 / weak-model 模式提醒等）
# 事件：UserPromptSubmit
# 逻辑：
#   - 若 C1 留下了 compact reminder flag → 注入铁律并删除 flag（一次性）
#   - 每次都注入 ★ Insight 强制要求（软提醒，不拦截）
# 覆盖痛点：弱模型忘记输出 Insight；compact 后铁律失忆

HOOK_NAME="C2-prompt-inject"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json

session_id="$(jq_get '.session_id')"
if [[ -z "$session_id" ]]; then
    session_id="$(jq_get '.transcript_path' | sed 's|.*/||; s|\.jsonl$||')"
fi
if [[ -z "$session_id" ]]; then
    session_id="default"
fi

flag_file="/tmp/harness-compact-reminder-${session_id}"

# 如果有 post-compact reminder，消费它（一次性）
if [[ -f "$flag_file" ]]; then
    cat "$flag_file"
    rm -f "$flag_file"
    hook_log "$HOOK_NAME" "INFO" "Consumed post-compact reminder for session $session_id"
fi

# 每轮都注入的轻量提醒（非常短，不占 token）
cat <<'EOF'
<system-reminder>
【Harness 调度协议 · 本轮必须】
1. 先过 ~/.claude/CLAUDE.md 的调度信号表，派对应 Agent（不越权自做）
2. 调度前后必输出 ★ Insight 四要素：当前动作 / 决策依据 / 主要风险 / 用户拍板
3. 一轮只派一个 Agent（GP-O01）
</system-reminder>
EOF

exit 0
