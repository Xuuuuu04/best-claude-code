#!/usr/bin/env bash
# Hook-B v1.1.0 (2026-04-18): WebSearch 失败/空结果时软引导到 MCP 搜索工具
# 事件：PostToolUse
# Matcher：WebSearch
# 逻辑：检查 tool_response 是否含失败信号 OR 返回空结果，命中则 stdout 注入 MCP fallback 指引
# 覆盖痛点：
#   1. 三方模型（非 Kimi）不支持内置 WebSearch，但常执着于重试而不 fallback
#   2. WebSearch 返回空结果（无报错但 results 数组为空），LLM 错误认为"确实没有信息"
# 策略：内建优先，MCP 作 fallback；空结果和错误均触发注入

HOOK_NAME="B-websearch-fallback"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json

tool_name="$(jq_get '.tool_name')"
if [[ "$tool_name" != "WebSearch" ]]; then
    hook_pass
fi

# tool_response 可能是字符串或对象，统一转字符串做匹配
response_text="$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_response | if type == "string" then . else tostring end' 2>/dev/null || echo "")"

# ── 检查 1：明确失败信号 ──────────────────────────────────────────────────────
fail_pattern='(failed|Failed|FAILED|unauthorized|Unauthorized|403|401|rate.?limit|blocked|not.?supported|unavailable|API.?key|quota.?exceeded|network.?error|Search.?is.?not.?available)'
is_failure=0
if printf '%s' "$response_text" | grep -Eq "$fail_pattern"; then
    is_failure=1
fi

# ── 检查 2：空结果判定 ────────────────────────────────────────────────────────
# 结构化 JSON：results 数组为空（[]）或长度为 0
# 同时兼容 tool_response 直接是 JSON 对象和被 tostring 序列化两种情况
is_empty_result=0
raw_response="$(printf '%s' "$HOOK_INPUT" | jq -r '.tool_response' 2>/dev/null || echo "")"
if printf '%s' "$raw_response" | jq -e '
    (type == "object" and (
        (.results? | (type == "array" and length == 0)) or
        (.organic_results? | (type == "array" and length == 0)) or
        (.webPages? | (.value? | (type == "array" and length == 0))) or
        (.items? | (type == "array" and length == 0))
    )) or
    (type == "array" and length == 0)
' > /dev/null 2>&1; then
    is_empty_result=1
fi

# 两个条件都不满足，放行
if [[ "$is_failure" -eq 0 && "$is_empty_result" -eq 0 ]]; then
    hook_pass
fi

# ── 日志 & 注入 ───────────────────────────────────────────────────────────────
if [[ "$is_failure" -eq 1 ]]; then
    hook_log "$HOOK_NAME" "INFO" "WebSearch failure detected, injecting MCP fallback guidance"
fi
if [[ "$is_empty_result" -eq 1 ]]; then
    hook_log "$HOOK_NAME" "INFO" "empty-result fallback triggered — WebSearch returned no results, injecting MCP fallback guidance"
fi

# stdout 内容会被 Claude Code 作为 additional context 喂回给 LLM
cat <<'EOF'
<system-reminder>
检测到内置 WebSearch 不可用或返回空结果（内建优先策略：先尝试内置，失败或空结果时切换 MCP）。

请改用 MCP 搜索工具，按以下优先级：

1. mcp__web-search-prime__web_search_prime  ← 优先（通用搜索）
2. mcp__web-search-prime__webSearchPrime     ← 备用
3. mcp__web-reader__webReader                ← 已知 URL 读正文
4. mcp__fetch__fetch                         ← 直接抓网页

不要反复重试内置 WebSearch——空结果或失败状态不会因重试而改变。
</system-reminder>
EOF
exit 0
