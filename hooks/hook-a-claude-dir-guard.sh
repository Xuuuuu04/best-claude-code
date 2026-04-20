#!/usr/bin/env bash
# Hook-A: 防止主进程直改 ~/.claude/ 核心文件
# 事件：PreToolUse    Matcher：Write | Edit | NotebookEdit
# 维护模式下（~/.claude/.maintenance-mode 新鲜 / HARNESS_HOOK_ALLOW_CORE=1）放行 + 警告日志
# 对应铁律：GP-O09
#
# v1.2 — 2026-04-18
# 变更：新增静态白名单 ~/.claude/agents/**/*.md 和 ~/.claude/knowledge-base/**
#        prompt-engineer agent 合法写入路径，由 prompt-engineer 自保护。
#        Claude Code Hook 协议目前不暴露 agent 身份，故采用静态白名单方案（用户授权，一次性）。

HOOK_NAME="A-claude-dir-guard"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json

tool_name="$(jq_get '.tool_name')"
file_path="$(jq_get '.tool_input.file_path')"

case "$tool_name" in
    Write|Edit|NotebookEdit) ;;
    *) hook_pass ;;
esac

if [[ -z "$file_path" ]]; then
    hook_pass
fi

expanded_path="${file_path/#\~/$HOME}"
case "$expanded_path" in
    "$HOME/.claude/"*) ;;
    *) hook_pass ;;
esac

# 白名单放行
case "$expanded_path" in
    "$HOME/.claude/projects/"*) hook_pass ;;
    "$HOME/.claude/memory/"*) hook_pass ;;
    "$HOME/.claude/tasks/"*) hook_pass ;;
    "$HOME/.claude/plans/"*) hook_pass ;;
    "$HOME/.claude/sessions/"*) hook_pass ;;
    "$HOME/.claude/cache/"*) hook_pass ;;
    "$HOME/.claude/logs/"*) hook_pass ;;
    "$HOME/.claude/history"*) hook_pass ;;
    "$HOME/.claude/file-history/"*) hook_pass ;;
    "$HOME/.claude/paste-cache/"*) hook_pass ;;
    "$HOME/.claude/session-env/"*) hook_pass ;;
    "$HOME/.claude/shell-snapshots/"*) hook_pass ;;
    "$HOME/.claude/telemetry/"*) hook_pass ;;
    "$HOME/.claude/backup/"*) hook_pass ;;
    "$HOME/.claude/backups/"*) hook_pass ;;
    "$HOME/.claude/ide/"*) hook_pass ;;
    "$HOME/.claude/teams/"*) hook_pass ;;
    # v1.2 — 2026-04-18：prompt-engineer 合法写入路径（静态白名单，用户一次性授权）
    # Claude Code Hook 协议不暴露 agent 身份，故用路径白名单。
    # prompt-engineer 作为唯一 agent 文件修改通道，自保护此路径。
    "$HOME/.claude/agents/"*) hook_pass ;;
    "$HOME/.claude/knowledge-base/"*) hook_pass ;;
    # v1.3 — 2026-04-20：扩充 prompt-engineer 合法写入白名单
    # 理由：runtime-packs/output-styles/guides/docs/hooks 均属 prompt-engineer 职责范围
    # 经用户拍板（Phase 2 全面改造），一次性静态授权。
    "$HOME/.claude/shared/runtime-packs/"*) hook_pass ;;
    "$HOME/.claude/output-styles/"*) hook_pass ;;
    "$HOME/.claude/shared/guides/"*) hook_pass ;;
    "$HOME/.claude/docs/"*) hook_pass ;;
    "$HOME/.claude/hooks/"*) hook_pass ;;
esac

# 维护模式下放行（记录 WARN 日志供审计）
if is_maintenance_mode; then
    hook_log "$HOOK_NAME" "WARN" "MAINTENANCE_MODE pass: $expanded_path"
    hook_pass
fi

hook_reject "$HOOK_NAME" "$(cat <<EOF
禁止直改 Harness 核心文件：
  $file_path

违反铁律 GP-O09：Agent prompt / output-style / shared 规程等文件修改必须经 提示词工程师 评审。

如你是在执行 /项目分析 等收尾动作：不要把生成的 CLAUDE.md 落在 ~/.claude/ 下，该命令只处理用户指定的项目目录（默认 \$PWD）。

如确需修改 Harness 核心文件：
  1. 派 提示词工程师（subagent_type: 提示词工程师）
  2. 说明修改原因 / 范围 / 风险
  3. 由其输出改动方案，经用户拍板后执行

临时维护模式（仅开发者手动使用）：
  touch ~/.claude/.maintenance-mode    # 创建后 1 小时内 Hook-A 放行
  rm ~/.claude/.maintenance-mode       # 完成后务必删除

白名单（可直写）：~/.claude/projects ~/.claude/memory ~/.claude/tasks ~/.claude/plans 等运行时数据目录。
EOF
)"
