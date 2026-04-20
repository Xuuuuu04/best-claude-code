#!/usr/bin/env bash
# Hook-E v4: 并行检测 → WARN 放行 + 强制审计日志
# 规则：检测本轮并行 Agent 数量，≥2 时记录 WARN 日志并放行
# 事件：PreToolUse    Matcher：Agent    原则：GP-O01（审慎并行）
#
# 变更历史：
#   v3: 物理拦截 in_flight ≥ 2
#   v4: 改为审计模式——记录并行事件，提醒主进程履行声明义务，不再拦截

HOOK_NAME="E-parallel-agent-audit"
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

# 统计本轮已派发的 Agent 数（含当前这一个）
agent_count=$(printf '%s' "$post_user" | \
    jq -rc 'select(.message.content | type == "array") | .message.content[] | select(.type == "tool_use" and .name == "Agent") | .id' 2>/dev/null | grep -c . 2>/dev/null)
agent_count="${agent_count//[^0-9]/}"
agent_count="${agent_count:-0}"

# tool_result 数
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

result_count="${result_count:-0}"
in_flight=$(( agent_count - result_count ))

hook_log "$HOOK_NAME" "INFO" "agent=$agent_count, result=$result_count, in_flight=$in_flight"

# v4 行为：检测并行，记录审计日志，放行
if [[ $in_flight -ge 2 ]]; then
    # 提取已派 Agent 类型列表
    already_types=$(printf '%s' "$post_user" | \
        jq -rc 'select(.message.content | type == "array") | .message.content[] | select(.type == "tool_use" and .name == "Agent") | .input.subagent_type' 2>/dev/null | paste -sd "," -)

    hook_log "$HOOK_NAME" "WARN" "PARALLEL_DETECTED in_flight=$in_flight agents=[$already_types]"

    # 播放警告音（非阻断）
    hook_sound warn

    # 输出提醒到 stderr（LLM 可见，但不阻断）
    cat >&2 <<EOF

⚠️ [Harness Hook E 审计提醒] 检测到本轮并行派发 $in_flight 个 Agent。
当前在飞：[$already_types]

请确认已在 ★ Insight 中声明：
  - 并行理由（互不依赖 + 写入不重叠）
  - 风险识别
  - 隔离边界
  - Agent 总数 ≤ 3

如未声明，请补输出 ★ Insight 后再继续。
EOF
fi

hook_pass
