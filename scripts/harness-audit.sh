#!/usr/bin/env bash
# Harness Consistency Audit
# 每次升级 Harness 后手动跑，或接入 cron 定期自检
# 输出分级：[OK] / [WARN] / [FAIL]
# 退出码：0 = 全绿；1 = 有 WARN；2 = 有 FAIL

set -u
HARNESS="${HOME}/.claude"
FAIL_COUNT=0
WARN_COUNT=0
OK_COUNT=0

ok()   { printf '\033[32m[OK]\033[0m   %s\n' "$1"; OK_COUNT=$((OK_COUNT+1)); }
warn() { printf '\033[33m[WARN]\033[0m %s\n' "$1"; WARN_COUNT=$((WARN_COUNT+1)); }
fail() { printf '\033[31m[FAIL]\033[0m %s\n' "$1"; FAIL_COUNT=$((FAIL_COUNT+1)); }
section() { printf '\n\033[1m▸ %s\033[0m\n' "$1"; }

# =============================================================
section "1. Agent 数量一致性"
# =============================================================

agent_count=$(ls "$HARNESS/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$agent_count" == "22" ]]; then
    ok "agents/ 目录 = 22 个文件"
else
    fail "agents/ 目录 = $agent_count 个（期望 22）"
fi

# CLAUDE.md 调度索引应至少包含 22 个 agent 名字
missing_in_claudemd=0
for name in 项目管理师 客户沟通师 开发组长 架构师 数据库工程师 技术调研师 深度研究员 创意策划师 视觉设计师 后端开发师 前端开发师 小程序开发师 机器学习工程师 代码审计师 安全审计师 功能测试师 界面测试师 测试总监师 运维部署工程师 文档工程师 提示词工程师 进度管理师; do
    if ! grep -q "$name" "$HARNESS/CLAUDE.md" 2>/dev/null; then
        fail "CLAUDE.md 未出现 agent：$name"
        missing_in_claudemd=$((missing_in_claudemd+1))
    fi
done
if [[ $missing_in_claudemd -eq 0 ]]; then
    ok "CLAUDE.md 包含全部 22 个 agent 名字"
fi

# =============================================================
section "2. Agent frontmatter 命名一致性"
# =============================================================

# 每个 agent 的 name 字段必须与 CLAUDE.md 调度表里的名字一致（都带"师/工程师"后缀）
declare -a expected_names=(
    "项目管理师" "客户沟通师" "开发组长" "架构师" "数据库工程师"
    "技术调研师" "深度研究员" "创意策划师" "视觉设计师" "后端开发师"
    "前端开发师" "小程序开发师" "机器学习工程师" "代码审计师" "安全审计师"
    "功能测试师" "界面测试师" "测试总监师" "运维部署工程师" "文档工程师"
    "提示词工程师" "进度管理师"
)

missing_count=0
for name in "${expected_names[@]}"; do
    if grep -l "^name: ${name}$" "$HARNESS/agents/"*.md >/dev/null 2>&1; then
        :
    else
        fail "agents/ 中缺少 name=${name}"
        missing_count=$((missing_count+1))
    fi
done
if [[ $missing_count -eq 0 ]]; then
    ok "22 个 agent name 字段全部与 CLAUDE.md 调度表对齐"
fi

# 检测 name 是否带正确后缀（师 / 员 / 长 / 工程师）
bad_names=$(grep -h '^name: ' "$HARNESS/agents/"*.md | awk -F': ' '{print $2}' | grep -vE '(师|员|长)$' || true)
if [[ -z "$bad_names" ]]; then
    ok "所有 agent name 都带中文职位后缀（师 / 员 / 长）"
else
    fail "以下 agent name 缺职位后缀：$bad_names"
fi

# =============================================================
section "3. Agent charter 长度（token 控制）"
# =============================================================

for f in "$HARNESS/agents/"*.md; do
    lines=$(wc -l < "$f" | tr -d ' ')
    name=$(basename "$f" .md)
    if [[ "$lines" -gt 450 ]]; then
        fail "$name.md = $lines 行（硬顶 450）"
    elif [[ "$lines" -gt 400 ]]; then
        warn "$name.md = $lines 行（软顶 400）"
    fi
done
avg_lines=$(wc -l "$HARNESS/agents/"*.md | tail -1 | awk '{print $1/22}')
ok "agent charter 平均 $(printf '%.0f' "$avg_lines") 行"

# =============================================================
section "4. Agent color 冲突检测"
# =============================================================

# 同色下聚类查看，允许但警告
color_report=$(grep -h '^color: ' "$HARNESS/agents/"*.md | sort | uniq -c | awk '$1 > 4 {print}')
if [[ -z "$color_report" ]]; then
    ok "没有单一颜色超过 4 个 agent（色彩分布均匀）"
else
    warn "以下颜色聚集过多（单色 > 4 个 agent）：$(echo "$color_report" | tr '\n' ' ')"
fi

# =============================================================
section "5. Hook 基础设施"
# =============================================================

declare -a required_hooks=(
    "hook-a-claude-dir-guard.sh"
    "hook-b-websearch-fallback.sh"
    "hook-c1-precompact-save.sh"
    "hook-c2-prompt-inject.sh"
    "hook-d-insight-check.sh"
    "hook-e-parallel-agent-block.sh"
    "hook-f-git-secret-scan.sh"
    "hook-g-session-start.sh"
)

for h in "${required_hooks[@]}"; do
    path="$HARNESS/hooks/$h"
    if [[ ! -f "$path" ]]; then
        fail "缺少 hook: $h"
    elif [[ ! -x "$path" ]]; then
        fail "$h 缺少执行权限"
    fi
done
[[ -f "$HARNESS/hooks/lib/common.sh" ]] && ok "common.sh 存在" || fail "common.sh 缺失"

# 语法检查
for h in "${required_hooks[@]}"; do
    path="$HARNESS/hooks/$h"
    if [[ -f "$path" ]]; then
        if ! bash -n "$path" 2>/dev/null; then
            fail "$h 语法错误"
        fi
    fi
done

# =============================================================
section "6. settings.json hook 注册"
# =============================================================

if ! python3 -c "import json; json.load(open('$HARNESS/settings.json'))" 2>/dev/null; then
    fail "settings.json 不是合法 JSON"
else
    ok "settings.json 格式合法"
    events=$(python3 -c "import json; d=json.load(open('$HARNESS/settings.json')); print(' '.join(d.get('hooks',{}).keys()))")
    for required_event in SessionStart UserPromptSubmit PreCompact PreToolUse PostToolUse Stop; do
        if printf '%s' "$events" | grep -q "$required_event"; then
            :
        else
            fail "settings.json 缺少 hook 事件：$required_event"
        fi
    done
    if [[ $FAIL_COUNT -eq 0 ]]; then
        ok "6 个 hook 事件全部注册"
    fi
fi

# =============================================================
section "7. Command 基础设施"
# =============================================================

cmd_count=$(ls "$HARNESS/commands/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [[ "$cmd_count" -ge 10 ]]; then
    ok "commands/ = $cmd_count 个"
else
    warn "commands/ 只有 $cmd_count 个（期望 ≥ 10）"
fi

# 检查所有 command 是否有 frontmatter + description
for f in "$HARNESS/commands/"*.md; do
    if ! head -5 "$f" | grep -q '^description:'; then
        fail "$(basename "$f") 缺 frontmatter 的 description 字段"
    fi
done

# 命令名应该是中文
english_cmds=$(ls "$HARNESS/commands/" | grep -E '^[a-zA-Z-]+\.md$' || true)
if [[ -z "$english_cmds" ]]; then
    ok "所有 command 都是中文命名"
else
    warn "存在英文命名 command（可保留，但建议中文化）：$(echo "$english_cmds" | tr '\n' ' ')"
fi

# =============================================================
section "8. 过时文本检测"
# =============================================================

# 检查是否还有 "17→20" / "17 → 20" / "20 Agent" 等过时描述
stale_hits=$(grep -rln "17→20\|17 → 20\|20 Agent\|20 agent\|20 席\|20席" \
    "$HARNESS/CLAUDE.md" \
    "$HARNESS/agents/" \
    "$HARNESS/output-styles/" \
    "$HARNESS/shared/" 2>/dev/null || true)
if [[ -z "$stale_hits" ]]; then
    ok "核心文件中无 '17→20' / '20 Agent' 过时描述"
else
    warn "以下文件仍有过时描述：$(echo "$stale_hits" | tr '\n' ' ')"
fi

# =============================================================
section "9. 调度真源指向一致性"
# =============================================================

# CLAUDE.md 应该指向 dispatch-table.md
if grep -q 'dispatch-table.md' "$HARNESS/CLAUDE.md"; then
    ok "CLAUDE.md 指向 dispatch-table.md 作为完整调度真源"
else
    warn "CLAUDE.md 未显式指向 dispatch-table.md"
fi

# governance.md 应该标注 §3 已废弃或指向真源
if grep -Eq '本表已废弃|真源.*dispatch-table' "$HARNESS/shared/guides/project-group-governance.md"; then
    ok "governance.md §3 已明确标注废弃/指向新真源"
else
    warn "governance.md §3 未标注废弃，可能造成真源冲突"
fi

# =============================================================
section "10. 维护模式 flag 泄漏检测"
# =============================================================

flag="$HARNESS/.maintenance-mode"
if [[ -f "$flag" ]]; then
    mtime=$(stat -f %m "$flag" 2>/dev/null || stat -c %Y "$flag" 2>/dev/null)
    now=$(date +%s)
    age=$((now - mtime))
    if [[ $age -gt 3600 ]]; then
        warn "维护模式 flag 存在且已过期（${age}s > 3600s），建议删除"
    else
        warn "维护模式 flag 当前活跃（剩 $(( (3600 - age) / 60 )) 分钟自动过期）"
    fi
fi

# =============================================================
# 汇总
# =============================================================

printf '\n══════════════════════════════════\n'
printf '审计完成：\033[32m%d OK\033[0m / \033[33m%d WARN\033[0m / \033[31m%d FAIL\033[0m\n' "$OK_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
printf '══════════════════════════════════\n'

if [[ $FAIL_COUNT -gt 0 ]]; then
    exit 2
elif [[ $WARN_COUNT -gt 0 ]]; then
    exit 1
else
    exit 0
fi
