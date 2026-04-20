#!/usr/bin/env bash
# Hook-F: git commit 前扫描敏感词 / 密钥泄露
# 事件：PreToolUse    Matcher：Bash
# 严格版：只对"实际要运行 git commit 的 shell 语句"触发，避免脚本内容含该字符串时误判

HOOK_NAME="F-git-secret-scan"
source "$(dirname "$0")/lib/common.sh"

read_stdin_json

tool_name="$(jq_get '.tool_name')"
if [[ "$tool_name" != "Bash" ]]; then
    hook_pass
fi

cmd="$(jq_get '.tool_input.command')"

# ---- 判断 cmd 是否真的在跑 git commit ----
# 规则：提取 cmd 文本里所有"语句开头"，语句分界为 ^ / && / || / ; / |
# 然后看这些分界后紧跟的是否是 "git commit"
# 不看单/双引号包裹的文本、不看 heredoc body
is_git_commit_invocation() {
    local c="$1"
    # 先粗过滤：没有 "git commit" 子串直接 no
    printf '%s' "$c" | grep -q 'git[[:space:]]\+commit' || return 1
    # 语句分界 + git commit：
    # 严格模式：(行首或 &&/||/;/|/&) + 可选空白 + git + 必须至少1个空白 + commit + (空白或行尾)
    # 注意：不匹配 "command":"git commit  的情况（前置是 "）
    printf '%s' "$c" | grep -Eq '(^|[[:space:]])(&&|\|\||;|\|(?!\|)|[&])[[:space:]]*git[[:space:]]+commit([[:space:]]|$)' && return 0
    # 单独一行以 git commit 开头
    printf '%s' "$c" | grep -Eq '^[[:space:]]*git[[:space:]]+commit([[:space:]]|$)' && return 0
    return 1
}

if ! is_git_commit_invocation "$cmd"; then
    hook_pass
fi

# 从此只处理真正的 git commit 调用
# --no-verify 禁用
if printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+commit[^|;&]*--no-verify'; then
    hook_reject "$HOOK_NAME" "检测到 git commit --no-verify，禁止跳过密钥扫描。请移除该参数。"
fi

cwd="$(jq_get '.tool_input.cwd')"
[[ -z "$cwd" ]] && cwd="$(pwd)"
cd "$cwd" 2>/dev/null || hook_pass

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || hook_pass

# ---------------- 路径 1：gitleaks 8.x（首选） ----------------
if command -v gitleaks >/dev/null 2>&1; then
    hook_log "$HOOK_NAME" "INFO" "using gitleaks git --staged"

    tmp_report="$(mktemp -t gitleaks-report.XXXXXX.json)"
    trap 'rm -f "$tmp_report"' EXIT

    gitleaks git --staged "$cwd" \
        --no-banner \
        --exit-code 1 \
        --report-format json \
        --report-path "$tmp_report" \
        --log-level error \
        >/dev/null 2>&1
    gl_exit=$?

    if [[ $gl_exit -eq 0 ]]; then
        hook_pass
    fi

    findings=""
    if [[ -s "$tmp_report" ]]; then
        findings="$(jq -r '
            if length == 0 then "" else
              map("▸ [" + (.RuleID // "unknown") + "] "
                  + (.File // "?") + ":" + ((.StartLine // 0) | tostring)
                  + "  (" + (.Description // "" | .[0:120]) + ")"
              ) | .[0:10] | join("\n")
            end
        ' "$tmp_report" 2>/dev/null)"
    fi
    [[ -z "$findings" ]] && findings="gitleaks 检测到密钥泄露（运行 gitleaks git --staged . --verbose 查看详情）"

    hook_reject "$HOOK_NAME" "$(cat <<EOF
git commit 被 gitleaks 拦截：检测到敏感信息泄露。

$findings

处理建议：
  1. git reset HEAD <file> 撤出敏感文件
  2. 真值改占位符（CHANGE_ME / process.env.XXX），真值写 .env（.env 必须 gitignore）
  3. 确定误报 → 加到 .gitleaks.toml allowlist；禁止 --no-verify 绕过

若已 commit 未 push：git reset --soft HEAD~1 → 清理 → 重提交
若已 push：立即 rotate/revoke 凭据 → git filter-repo 清史
EOF
)"
fi

# ---------------- 路径 2：shell 正则 fallback ----------------
hook_log "$HOOK_NAME" "WARN" "gitleaks unavailable, shell regex fallback"

staged_diff="$(git diff --cached 2>/dev/null)"
if [[ -z "$staged_diff" ]] && printf '%s' "$cmd" | grep -Eq 'git[[:space:]]+commit[^|;&]*-[aA-Za-z]*a'; then
    staged_diff="$(git diff 2>/dev/null)"
fi

[[ -z "$staged_diff" ]] && hook_pass

added_lines="$(printf '%s' "$staged_diff" | grep -E '^\+[^+]' || true)"
[[ -z "$added_lines" ]] && hook_pass

declare -a hits=()
check_pattern() {
    local label="$1" pattern="$2" found
    found="$(printf '%s' "$added_lines" | grep -Ei "$pattern" | head -3 || true)"
    if [[ -n "$found" ]]; then
        hits+=("▸ ${label}:")
        while IFS= read -r line; do
            hits+=("    ${line:0:200}")
        done <<< "$found"
    fi
}

check_pattern "Anthropic/OpenAI API Key" 'sk-(ant-)?[A-Za-z0-9_-]{20,}'
check_pattern "GitHub Token" 'gh[pousr]_[A-Za-z0-9]{20,}'
check_pattern "AWS Access Key" 'AKIA[0-9A-Z]{16}'
check_pattern "Google API Key" 'AIza[0-9A-Za-z_-]{30,}'
check_pattern "Slack Token" 'xox[abpr]-[0-9]{10,}-[0-9]{10,}'
check_pattern "Private Key Block" 'BEGIN (RSA |EC |OPENSSH |PGP |DSA )?PRIVATE KEY'
check_pattern "JWT token" 'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
check_pattern "Hardcoded credential" '(password|passwd|pwd|secret|token|api[_-]?key)[[:space:]]*[=:][[:space:]]*["'"'"']?[A-Za-z0-9@#$%^&*_+=.-]{16,}'

[[ ${#hits[@]} -eq 0 ]] && hook_pass

joined="$(printf '%s\n' "${hits[@]}")"

hook_reject "$HOOK_NAME" "$(cat <<EOF
git commit 被拦截（shell 正则 fallback）：

$joined

建议装 gitleaks：brew install gitleaks
EOF
)"
