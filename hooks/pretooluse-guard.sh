#!/bin/bash
# PreToolUse hook: 确定性拦截危险操作
# 把 rules/git-safety.md 和 sensitive-files.md 从"建议"变成"铁栏杆"
# exit 0 + permissionDecision:"deny" = 拦截; exit 0 无输出 = 放行

command -v jq &>/dev/null || exit 0

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

_deny() {
  jq -n --arg r "BCC safety guard: $1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

case "$TOOL" in
  Bash)
    CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
    [ -z "$CMD" ] && exit 0

    # --- git 危险操作 ---
    # git push --force / -f (--force-with-lease 放行)
    if echo "$CMD" | grep -qE 'git\s+push\b' && echo "$CMD" | grep -qE '\s(-f\b|--force)\b'; then
      echo "$CMD" | grep -q 'force-with-lease' || _deny "git push --force 被禁止"
    fi
    echo "$CMD" | grep -qE 'git\s+reset\s+--hard'                && _deny "git reset --hard 被禁止"
    echo "$CMD" | grep -qE 'git\s+checkout\s+--\s+\.'            && _deny "git checkout -- . 被禁止"
    echo "$CMD" | grep -qE 'git\s+restore\s+\.'                  && _deny "git restore . 被禁止"
    echo "$CMD" | grep -qE 'git\s+clean\s+.*-[a-zA-Z]*f'         && _deny "git clean -f 被禁止"
    echo "$CMD" | grep -qE 'git\s+branch\s+-D\b'                 && _deny "git branch -D 被禁止(用小写 -d)"
    echo "$CMD" | grep -qE 'git\b.*--no-verify'                  && _deny "--no-verify 被禁止"
    echo "$CMD" | grep -qE 'git\b.*--no-gpg-sign'                && _deny "--no-gpg-sign 被禁止"

    # --- rm -rf 危险目标 ---
    if echo "$CMD" | grep -qE '\brm\b' && echo "$CMD" | grep -qE -- '-r' && echo "$CMD" | grep -qE -- '-f'; then
      echo "$CMD" | grep -qE '\brm\s+\S+\s+/(\s|$)'             && _deny "rm -rf / 被禁止"
      echo "$CMD" | grep -qE '\brm\s+\S+\s+~/?(\s|$)'           && _deny "rm -rf ~ 被禁止"
    fi
    ;;

  Read|Edit|Write|MultiEdit|NotebookEdit)
    FP=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    [ -z "$FP" ] && exit 0
    BN=$(basename "$FP")

    # .env 文件(.env.example / .env.sample / .env.template 放行)
    if echo "$BN" | grep -qiE '\.env($|\.)'; then
      echo "$BN" | grep -qiE '\.(example|sample|template)$' || _deny "访问 .env 文件被禁止"
    fi

    # 凭证 JSON
    case "$BN" in
      credentials.json|auth.json|api_keys.json) _deny "访问 $BN 被禁止" ;;
    esac

    # SSH / AWS 目录
    case "$FP" in
      */.ssh/*|*/.aws/*) _deny "访问 SSH/AWS 凭证目录被禁止" ;;
    esac
    ;;
esac

exit 0
