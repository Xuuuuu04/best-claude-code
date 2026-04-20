#!/usr/bin/env bash
# Hook-G: SessionStart 注入当前 Harness 版本 + 铁律速查
# 事件：SessionStart
# 逻辑：在每个新会话开始注入一段系统提醒（冷启动打底）

HOOK_NAME="G-session-start"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json
source_type="$(jq_get '.source')"

hook_log "$HOOK_NAME" "INFO" "session start, source=$source_type"

# stdout 会作为 additional context 注入 system prompt
cat <<'EOF'
<system-reminder>
【Harness v23 运行环境 · 铁律速查】

调度：
  1. 禁止并行派 Agent（GP-O01）— 物理拦截已启用
  2. 每轮必出 ★ Insight 四要素（当前动作/决策依据/主要风险/用户拍板）
  3. 用户输入先过 ~/.claude/CLAUDE.md 调度信号表 → 派对应专职 Agent
  4. 质量闭环节点不可跳过：代码审计师 → 安全审计师 → 功能测试师 → 界面测试师 → 测试总监师

编辑防护：
  5. 禁止直改 ~/.claude/agents/ 和 ~/.claude/output-styles/ — 要改必派 提示词工程师
  6. git commit 前 Hook 会扫敏感词；如命中请按提示处理，不要 --no-verify 绕过

搜索降级：
  7. 内置 WebSearch 若失败，立即 fallback 到 mcp__web-search-prime__web_search_prime；
     禁止反复重试同一个不可用工具

完整规则：
  - ~/.claude/CLAUDE.md（调度铁律 7 条）
  - ~/.claude/output-styles/harness-orchestrator.md（GP-* 黄金原则）
  - ~/.claude/shared/guides/project-group-governance.md（治理详规）
</system-reminder>
EOF
exit 0
