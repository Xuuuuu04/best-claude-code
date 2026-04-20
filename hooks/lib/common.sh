#!/usr/bin/env bash
# Harness Hook Common Library  v1.1

set -u

HOOK_LOG_DIR="${HOME}/.claude/logs/hooks"
mkdir -p "$HOOK_LOG_DIR"
HARNESS_MAINTENANCE_FLAG="${HOME}/.claude/.maintenance-mode"

# ---------------- 日志 ----------------
hook_log() {
    local hook="${1:-unknown}" level="${2:-INFO}" msg="${3:-}"
    local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '[%s] [%s] %s\n' "$ts" "$level" "$msg" >> "${HOOK_LOG_DIR}/${hook}.log" 2>/dev/null || true
}

# ---------------- JSON ----------------
read_stdin_json() {
    HOOK_INPUT="$(cat)"
    [[ -z "$HOOK_INPUT" ]] && HOOK_INPUT="{}"
}
jq_get() { printf '%s' "$HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null || true; }

# ---------------- 维护模式 ----------------
is_maintenance_mode() {
    [[ "${HARNESS_HOOK_ALLOW_CORE:-0}" == "1" ]] && return 0
    if [[ -f "$HARNESS_MAINTENANCE_FLAG" ]]; then
        local mtime now
        mtime=$(stat -f %m "$HARNESS_MAINTENANCE_FLAG" 2>/dev/null || stat -c %Y "$HARNESS_MAINTENANCE_FLAG" 2>/dev/null || echo 0)
        now=$(date +%s)
        (( now - mtime < 3600 )) && return 0
    fi
    return 1
}

# ---------------- 声音 ----------------
hook_sound() {
    [[ "${HARNESS_HOOK_SILENT:-0}" == "1" ]] && return 0
    local type="${1:-done}" sound_file=""
    case "$type" in
        done)  sound_file="/System/Library/Sounds/Glass.aiff" ;;
        block) sound_file="/System/Library/Sounds/Basso.aiff" ;;
        warn)  sound_file="/System/Library/Sounds/Funk.aiff" ;;
        *) return 0 ;;
    esac
    if command -v afplay >/dev/null 2>&1 && [[ -f "$sound_file" ]]; then
        ( afplay "$sound_file" >/dev/null 2>&1 & disown ) 2>/dev/null
    fi
    return 0
}

# ---------------- 读"本轮所有 assistant 消息"（关键修复） ----------------
# 一个 turn 可能被 Claude Code 拆成多条 assistant 记录（text 一条、tool_use 一条）
# 本函数：找到最后一条 "role":"user" 行之后的所有 assistant 行，合并输出
# 用法：read_current_turn_assistants <transcript_path>
read_current_turn_assistants() {
    local tp="$1"
    [[ -f "$tp" ]] || { echo ""; return 0; }
    # 先找到最后一个 user 行号
    local last_user_line
    last_user_line=$(awk '/"role":"user"/ { n=NR } END { print n+0 }' "$tp" 2>/dev/null)
    if [[ -z "$last_user_line" || "$last_user_line" == "0" ]]; then
        # 没找到 user，退回到读所有 assistant
        awk '/"role":"assistant"/ { print }' "$tp" 2>/dev/null
        return 0
    fi
    # 输出 last_user_line 之后的所有 assistant 行
    awk -v from="$last_user_line" 'NR>from && /"role":"assistant"/ { print }' "$tp" 2>/dev/null
}

# 兼容旧版：最后一条 assistant 行
read_last_assistant_line() {
    local tp="$1"
    [[ -f "$tp" ]] || { echo ""; return 0; }
    awk '/"role":"assistant"/ { last=$0 } END { print last }' "$tp" 2>/dev/null
}

# ---------------- 退出 ----------------
hook_pass() { exit 0; }

hook_reject() {
    local hook="$1"; shift; local msg="$*"
    hook_log "$hook" "BLOCK" "$msg"
    hook_sound block
    printf '⛔ [Harness Hook %s 拦截]\n%s\n' "$hook" "$msg" >&2
    exit 2
}

hook_notify() {
    local hook="$1"; shift; local msg="$*"
    hook_log "$hook" "INFO" "$msg"
    printf '%s\n' "$msg"
    exit 0
}
