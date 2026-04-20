#!/usr/bin/env bash
# Hook-C1: Compact 前保存铁律/关键状态，供 compact 后注入
# 事件：PreCompact
# 逻辑：在 /tmp 下写一个 session 相关的 flag 文件，下次 UserPromptSubmit 时由 C2 注入铁律提醒
# 覆盖痛点：compact 后 LLM 忘记 "禁止直改 agent 文件" 等铁律，开始越权

HOOK_NAME="C1-precompact-save"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json

# session_id 可能在 .session_id 或其它位置，兼容取
session_id="$(jq_get '.session_id')"
if [[ -z "$session_id" ]]; then
    session_id="$(jq_get '.transcript_path' | sed 's|.*/||; s|\.jsonl$||')"
fi
if [[ -z "$session_id" ]]; then
    session_id="default"
fi

flag_file="/tmp/harness-compact-reminder-${session_id}"

cat > "$flag_file" <<'EOF'
<system-reminder>
【刚刚经过了 context compaction。以下 Harness 铁律必须复习并严格遵守】

1. 禁止并行派 Agent — 一轮只派一个（GP-O01）
2. 禁止直改 ~/.claude/agents/ 和 ~/.claude/output-styles/ — 要改必须派 提示词工程师（GP-O09）
3. 每轮必输出 ★ Insight 块，四要素齐全（当前动作 / 决策依据 / 主要风险 / 用户拍板）
4. 用户输入必须先过调度信号表 → 派对应专职 Agent
5. 质量闭环节点（代码审计师/安全审计师/功能测试师/界面测试师/测试总监师）不可跳过
6. WebSearch 调不通请 fallback 到 mcp__web-search-prime__web_search_prime

如果你刚才正在派 Agent 或写代码，**暂停** → 回顾上述铁律 → 再继续。
</system-reminder>
EOF

hook_log "$HOOK_NAME" "INFO" "Saved post-compact reminder to $flag_file"
exit 0
