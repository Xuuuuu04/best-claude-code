#!/bin/bash
# UserPromptSubmit hook: 每轮用户发言时注入"工作流路标 + 活跃 task 状态"。
# 目的:用户不手动打 /bcc-,靠这个每轮 refresh 引导主代理自动走对应 skill。
# 设计:hook 不替模型分类"是不是新诉求"(bash 关键词必误触发);只给客观状态 + 判据,
#       分类留给模型。对抗长对话里 CLAUDE.md 被挤远、注意力衰减。
source "$(dirname "$0")/_common.sh"

_init_hook
_require_tasks_dir   # 非 BCC 项目(无 .claude/tasks)静默,不打扰
_find_active_tasks

if [ "$ACTIVE_COUNT" -gt 0 ]; then
  TASK_LINES=""
  while IFS= read -r FILE; do
    [ -n "$FILE" ] || continue
    TASK_LINES="${TASK_LINES}  - $(_task_id "$FILE")($(_task_title "$FILE"))
"
  done <<< "$ACTIVE_FILES"
  CONTEXT="[工作流路标] 进行中的 Task:
${TASK_LINES}对照本轮诉求自检:对当前 Task 的延续 → 在其 Execution Log 记一行继续;能独立成一个 commit 的新诉求 → 先 bcc-start;用户说完成/提交/上线 → bcc-preflight 后 bcc-finish。仅提问/闲聊则忽略本提示。"
else
  CONTEXT="[工作流路标] 当前无进行中的 Task。若本轮是能独立成一个 commit 的工作诉求,先走 bcc-start 再动手(进度记录/压缩恢复/收尾检查都依赖活跃 Task);修 bug 先 bcc-debug 定位、写功能用 bcc-tdd。若只是提问/调研/闲聊,忽略本提示。"
fi

jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", additionalContext: $ctx}}'
