#!/bin/bash
# hook-flags.sh — Hook runtime profile / disable controls.
#
# 启发来源：ECC (everything-claude-code) 的 scripts/lib/hook-flags.js。
# 本实现是独立的 bash 版本，适配 Agent Legion 的 run-with-logging 入口。
#
# 环境变量：
#   CLAUDE_HOOK_PROFILE    minimal | standard | strict   (默认: standard)
#   CLAUDE_DISABLED_HOOKS  逗号分隔的 hook id（= 脚本 basename 去掉 .sh）
#
# Profile 语义（单调递增，越严越包含）：
#   minimal  —— 只跑生命周期必需的 hook（身份恢复、状态保存、statusline 标记）
#   standard —— minimal + 审计 / 安全 / 质量（默认档，日常使用）
#   strict   —— standard + 未来更强约束（当前等价于 standard，为预留留位）
#
# 用法（由 run-with-logging.sh 调用，无需每个 hook 感知）：
#   source "$DIR/hook-flags.sh"
#   hid="$(hook_id_from_path "$HOOK_SCRIPT")"
#   is_hook_enabled "$hid" || { cat >/dev/null; exit 0; }

set -uo pipefail

# ---- 配置区（新增 hook 时在此登记） -----------------------------------------

# 每个 hook 的最低要求 profile。未登记的 hook 默认按 standard 处理。
# 格式："hook_id:min_profile"
_HOOK_MIN_PROFILE=(
  "session-start:minimal"
  "pre-compact:minimal"
  "post-compact:minimal"
  "subagent-start-mark:minimal"
  "intent-classify:minimal"
  "permissionrequest-exit-plan-allow:minimal"
  "tool-failure-audit:minimal"
  "scope-lock-guard:standard"
  "artifact-write-guard:standard"
  "post-edit-lint:standard"
  "subagent-stop-log:standard"
  "instructions-audit:standard"
  "clarification-gate:standard"
  "review-gate:standard"
  "artifact-index-suggest:standard"
)

# ---- 内部工具 --------------------------------------------------------------

_hook_flags_normalize() {
  echo "${1:-}" | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]'
}

_hook_flags_profile_rank() {
  case "$(_hook_flags_normalize "$1")" in
    minimal) echo 0 ;;
    standard) echo 1 ;;
    strict) echo 2 ;;
    *) echo 1 ;;
  esac
}

# ---- 公共 API ---------------------------------------------------------------

# 返回当前生效的 profile；非法值回退 standard
get_hook_profile() {
  local raw
  raw="$(_hook_flags_normalize "${CLAUDE_HOOK_PROFILE:-standard}")"
  case "$raw" in
    minimal|standard|strict) echo "$raw" ;;
    *) echo "standard" ;;
  esac
}

# 返回禁用集合（换行分隔）；没禁用任何 hook 返回空
get_disabled_hook_ids() {
  local raw="${CLAUDE_DISABLED_HOOKS:-}"
  [ -z "$raw" ] && return 0
  echo "$raw" | tr ',' '\n' | sed 's/[[:space:]]//g' | awk 'NF>0' | tr '[:upper:]' '[:lower:]'
}

# 根据脚本路径推出 hook id（= 文件名去掉 .sh）
hook_id_from_path() {
  local p="${1:-}"
  [ -z "$p" ] && return 1
  local base
  base="$(basename "$p")"
  echo "${base%.sh}"
}

# 查询指定 hook 的最低 profile；未登记返回 standard
get_hook_min_profile() {
  local hid
  hid="$(_hook_flags_normalize "${1:-}")"
  [ -z "$hid" ] && { echo "standard"; return 0; }
  local entry k v
  for entry in "${_HOOK_MIN_PROFILE[@]}"; do
    k="${entry%%:*}"
    v="${entry##*:}"
    if [ "$k" = "$hid" ]; then
      echo "$v"
      return 0
    fi
  done
  echo "standard"
}

# 主入口：当前环境下 hook 是否应该执行
# 返回 0 = 启用，1 = 禁用
is_hook_enabled() {
  local hid
  hid="$(_hook_flags_normalize "${1:-}")"
  [ -z "$hid" ] && return 0  # 未知 id 默认放行，避免把合法 hook 误拦

  # 黑名单优先
  local disabled
  disabled="$(get_disabled_hook_ids)"
  if [ -n "$disabled" ] && echo "$disabled" | grep -Fxq "$hid"; then
    return 1
  fi

  # Profile 级别对齐
  local min_p cur_p min_r cur_r
  min_p="$(get_hook_min_profile "$hid")"
  cur_p="$(get_hook_profile)"
  min_r="$(_hook_flags_profile_rank "$min_p")"
  cur_r="$(_hook_flags_profile_rank "$cur_p")"
  [ "$cur_r" -ge "$min_r" ]
}

# 列出所有登记 hook 及其最低 profile（调试/doctor 用）
list_registered_hooks() {
  local entry k v
  for entry in "${_HOOK_MIN_PROFILE[@]}"; do
    k="${entry%%:*}"
    v="${entry##*:}"
    printf '%-24s %s\n' "$k" "$v"
  done
}
