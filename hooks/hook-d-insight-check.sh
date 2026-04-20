#!/usr/bin/env bash
# Hook-D: 本轮所有 assistant 消息聚合校验 ★ Insight
HOOK_NAME="D-insight-check"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json

transcript_path="$(jq_get '.transcript_path')"
stop_hook_active="$(jq_get '.stop_hook_active')"

if [[ "$stop_hook_active" == "true" ]]; then
    hook_log "$HOOK_NAME" "INFO" "stop_hook_active=true, skip"
    hook_sound done
    hook_pass
fi

if [[ ! -f "$transcript_path" ]]; then
    hook_log "$HOOK_NAME" "WARN" "transcript not found: $transcript_path"
    hook_sound done
    hook_pass
fi

# 关键：读本轮所有 assistant 消息（不只最后一条）
current_turn="$(read_current_turn_assistants "$transcript_path")"

if [[ -z "$current_turn" ]]; then
    hook_log "$HOOK_NAME" "WARN" "no assistant messages in current turn"
    hook_sound done
    hook_pass
fi

# 工具调用检测
has_tool_use=false
if printf '%s' "$current_turn" | grep -q '"type":"tool_use"'; then
    has_tool_use=true
fi

# ★ Insight 检测（多模式兜底：直接字符、转义字符、英文 Insight）
has_insight=false
if printf '%s' "$current_turn" | grep -F -q '★ Insight' \
   || printf '%s' "$current_turn" | grep -F -q '★Insight' \
   || printf '%s' "$current_turn" | grep -F -q '\u2605 Insight' \
   || printf '%s' "$current_turn" | grep -F -q '\u2605Insight' \
   || printf '%s' "$current_turn" | grep -q '"text":"[^"]*Insight' 2>/dev/null; then
    has_insight=true
fi

text_len=${#current_turn}

# 空跑检测
if [[ "$has_tool_use" == "false" && "$text_len" -lt 300 ]]; then
    hook_log "$HOOK_NAME" "WARN" "SUSPICIOUS_EMPTY_TURN text_len=$text_len"
    hook_sound done
    hook_pass
fi

# 有工具但无 Insight → 拒绝
if [[ "$has_tool_use" == "true" && "$has_insight" == "false" ]]; then
    if is_maintenance_mode; then
        hook_log "$HOOK_NAME" "WARN" "MAINTENANCE_MODE pass"
        hook_sound done
        hook_pass
    fi
    hook_reject "$HOOK_NAME" "$(cat <<EOF
本轮进行了工具调用但未输出 ★ Insight 块。

违反铁律 GP-O03：每次调度前后必须输出 ★ Insight 四要素：
  - 当前动作：这一步在做什么
  - 决策依据：为什么这样做 / 为什么是这个 Agent
  - 主要风险：最可能出错或返工的点
  - 用户拍板：是否需要用户确认；若需要，缺的是什么决定

请补一段 ★ Insight 再结束本轮；纯查询/展示可注明「纯查询 · 无调度动作」。
EOF
)"
fi

hook_log "$HOOK_NAME" "INFO" "pass: tool_use=$has_tool_use, insight=$has_insight, text_len=$text_len"
hook_sound done
hook_pass
