#!/usr/bin/env bash
# Hook-H1: PermissionRequest 对只读/安全工具自动放行
# 事件：PermissionRequest
# 返回 JSON {"decision":"approve"} 绕过权限弹窗；其他工具让 Claude Code 正常弹窗

HOOK_NAME="H1-permission-auto-allow"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json

tool_name="$(jq_get '.tool_name')"

# 只读工具白名单（永远自动放行）
case "$tool_name" in
    Read|Glob|Grep|LS|TodoWrite|TaskCreate|TaskUpdate|TaskList|TaskGet|ScheduleWakeup)
        hook_log "$HOOK_NAME" "INFO" "auto-approve: $tool_name"
        printf '{"decision":"approve","reason":"只读/状态类工具自动放行"}\n'
        exit 0
        ;;
esac

# Bash 的安全子集：ls / cat / head / tail / pwd / echo / git status 等
if [[ "$tool_name" == "Bash" ]]; then
    cmd="$(jq_get '.tool_input.command')"
    # 命令首个 token
    first_token="$(printf '%s' "$cmd" | awk '{print $1}' | head -c 40)"
    case "$first_token" in
        ls|pwd|echo|date|whoami|uname|which|type|printf)
            hook_log "$HOOK_NAME" "INFO" "auto-approve Bash: $first_token"
            printf '{"decision":"approve","reason":"只读 shell 命令自动放行"}\n'
            exit 0
            ;;
    esac
    # git 只读子命令
    if [[ "$first_token" == "git" ]]; then
        git_sub="$(printf '%s' "$cmd" | awk '{print $2}' | head -c 40)"
        case "$git_sub" in
            status|log|diff|show|branch|remote|config)
                hook_log "$HOOK_NAME" "INFO" "auto-approve git: $git_sub"
                printf '{"decision":"approve","reason":"只读 git 命令自动放行"}\n'
                exit 0
                ;;
        esac
    fi
fi

# 其他工具：不干预，走正常权限流程
hook_log "$HOOK_NAME" "INFO" "defer to normal permission flow: $tool_name"
hook_pass
