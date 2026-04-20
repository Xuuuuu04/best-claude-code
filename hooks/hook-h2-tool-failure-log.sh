#!/usr/bin/env bash
# Hook-H2: 工具失败时 dump 结构化上下文到日志
# 事件：PostToolUseFailure
# 价值：弱模型自诊断能力差，结构化错误 log 后续可被 /会话交接 / /快速修复 利用

HOOK_NAME="H2-tool-failure-log"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json

tool_name="$(jq_get '.tool_name')"
tool_use_id="$(jq_get '.tool_use_id')"
session_id="$(jq_get '.session_id')"
cwd="$(jq_get '.cwd')"
# error 可能是字符串或对象，统一转 string
error_text="$(printf '%s' "$HOOK_INPUT" | jq -rc '.error // .tool_response // "unknown error"' 2>/dev/null | head -c 2000)"
tool_input="$(printf '%s' "$HOOK_INPUT" | jq -rc '.tool_input // {}' 2>/dev/null | head -c 1500)"

# 追加结构化记录到专用失败日志
FAIL_LOG="${HOOK_LOG_DIR}/tool-failures.log"
{
    printf -- '---\n'
    printf 'ts: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')"
    printf 'session: %s\n' "$session_id"
    printf 'tool_use_id: %s\n' "$tool_use_id"
    printf 'tool: %s\n' "$tool_name"
    printf 'cwd: %s\n' "$cwd"
    printf 'input: %s\n' "$tool_input"
    printf 'error: %s\n' "$error_text"
    printf '\n'
} >> "$FAIL_LOG" 2>/dev/null

hook_log "$HOOK_NAME" "INFO" "logged failure: tool=$tool_name use_id=$tool_use_id"

# 软播 warn 音，提醒用户
hook_sound warn

# 非阻塞：工具已失败，hook 不能回滚。只记录 + 可选注入修复建议
# 如果是常见的可恢复错误，可以通过 stdout 给 Claude 一点修复指引
case "$tool_name" in
    Edit|Write|NotebookEdit)
        if printf '%s' "$error_text" | grep -qi "has not been read"; then
            printf '<system-reminder>提示：Write/Edit 前需先 Read 该文件。请先用 Read 工具读取后再重试。</system-reminder>\n'
        fi
        ;;
    Bash)
        if printf '%s' "$error_text" | grep -qi "command not found"; then
            printf '<system-reminder>提示：命令未找到。检查拼写 / 是否需要 brew install / 是否在 PATH。</system-reminder>\n'
        fi
        ;;
esac

exit 0
