#!/usr/bin/env bash
# Hook-E v3: 简化鲁棒规则——不依赖 tool_use_id
# 规则：本轮内 (Agent tool_use 数) - (对应 tool_result 数) >= 2 → 拒绝
# 语义：只要有多于 1 个 Agent 处于"已派未返回"状态，就是并行违规
# 事件：PreToolUse    Matcher：Agent    铁律：GP-O01

HOOK_NAME="E-parallel-agent-block"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json

tool_name="$(jq_get '.tool_name')"
if [[ "$tool_name" != "Agent" ]]; then
    hook_pass
fi

transcript_path="$(jq_get '.transcript_path')"
if [[ ! -f "$transcript_path" ]]; then
    hook_log "$HOOK_NAME" "WARN" "transcript not found, pass"
    hook_pass
fi

# 最近一个真·用户消息（排除 tool_result user 消息）
last_real_user_line=$(awk '
    /"role":"user"/ {
        if (!/tool_result/) n=NR
    }
    END { print n+0 }
' "$transcript_path" 2>/dev/null)

if [[ -z "$last_real_user_line" || "$last_real_user_line" == "0" ]]; then
    hook_pass
fi

post_user=$(awk -v from="$last_real_user_line" 'NR>from' "$transcript_path" 2>/dev/null)
[[ -z "$post_user" ]] && hook_pass

# 用 jq 逐行解析；避免 JSON 字段顺序问题
agent_count=$(printf '%s' "$post_user" | \
    jq -rc 'select(.message.content | type == "array") | .message.content[] | select(.type == "tool_use" and .name == "Agent") | .id' 2>/dev/null | grep -c . 2>/dev/null)
agent_count="${agent_count//[^0-9]/}"
hook_log "$HOOK_NAME" "INFO" "v3.1 bugfix: agent_count sanitized"

# tool_result 数：仅数 Agent 相关的 tool_result（tool_use_id 在 agent_ids 集合里）
agent_ids=$(printf '%s' "$post_user" | \
    jq -rc 'select(.message.content | type == "array") | .message.content[] | select(.type == "tool_use" and .name == "Agent") | .id' 2>/dev/null)

result_count=0
if [[ -n "$agent_ids" ]]; then
    while IFS= read -r aid; do
        [[ -z "$aid" ]] && continue
        if printf '%s' "$post_user" | jq -rc 'select(.message.content | type == "array") | .message.content[] | select(.type == "tool_result") | .tool_use_id' 2>/dev/null | grep -qFx "$aid"; then
            result_count=$((result_count+1))
        fi
    done <<< "$agent_ids"
fi

agent_count="${agent_count:-0}"
result_count="${result_count:-0}"
in_flight=$(( agent_count - result_count ))

hook_log "$HOOK_NAME" "INFO" "agent=$agent_count, result=$result_count, in_flight=$in_flight"

# 规则：已有 >= 1 个在飞的 Agent，又来一个 → 并行违规
# 注意：in_flight >= 1 时，意味着 transcript 已记录至少 1 个未完成 Agent；
#       当前要派的这个还没写入 transcript（或已写入但无 result），算"又一个"。
#       触发拒绝的真条件是 in_flight >= 2（已写入 + 当前），或 in_flight >= 1（当前未写入）。
#       用宽松条件 in_flight >= 2 最稳（PreToolUse 触发时 current 几乎都已写入）
if [[ $in_flight -ge 2 ]]; then
    if is_maintenance_mode; then
        hook_log "$HOOK_NAME" "WARN" "MAINTENANCE_MODE pass in_flight=$in_flight"
        hook_pass
    fi

    # 取最早一个未返回的 subagent_type 供报错
    already=$(printf '%s' "$post_user" | \
        jq -rc 'select(.message.content | type == "array") | .message.content[] | select(.type == "tool_use" and .name == "Agent") | .input.subagent_type' 2>/dev/null | head -1)
    [[ -z "$already" ]] && already="(未识别)"

    hook_reject "$HOOK_NAME" "$(cat <<EOF
违反 GP-O01（禁止并行派 Agent）。

本轮已派发且未返回：$already

铁律：一轮只派一个 Agent，等其返回后再决定下一跳。

如确需并行（GP-O12 豁免）：
  - 条件 A：两个任务纯只读（无文件写入）+ 完全不相关
  - 条件 B：用户明确要求并行
满足后，请在 ★ Insight 明确标注「GP-O12 豁免理由：...」，分两轮派发。
EOF
)"
fi

hook_pass
