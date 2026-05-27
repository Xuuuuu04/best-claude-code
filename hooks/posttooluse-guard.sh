#!/bin/bash
# PostToolUse hook: 追踪代码编辑次数 + 检测连续 Bash 失败
# 两个职责：
#   1. 编辑了代码文件但没更新 Task → 累计计数，Stop hook 读这个计数拦截
#   2. Bash 连续失败 ≥3 次 → 注入"走 /bcc-debug 流程"
source "$(dirname "$0")/_common.sh"

_init_hook

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')
TOOL_INPUT=$(echo "$INPUT" | jq -r '.tool_input // empty')
TOOL_OUTPUT=$(echo "$INPUT" | jq -r '.tool_output // empty')

_require_tasks_dir

STATE_FILE="$CWD/.claude/tasks/.hook-state.json"

# 初始化 state 文件
if [ ! -f "$STATE_FILE" ]; then
  echo '{"edits_since_task_update":0,"consecutive_bash_failures":0}' > "$STATE_FILE"
fi

EDITS=$(jq -r '.edits_since_task_update // 0' "$STATE_FILE")
FAILURES=$(jq -r '.consecutive_bash_failures // 0' "$STATE_FILE")

CONTEXT=""

case "$TOOL_NAME" in
  Edit|Write|MultiEdit)
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
    if echo "$FILE_PATH" | grep -q '\.claude/tasks/.*\.md$'; then
      # 编辑的是 Task 文件 → 重置计数（模型在更新进度）
      EDITS=0
    else
      # 编辑的是代码文件 → 累加
      EDITS=$((EDITS + 1))
    fi
    FAILURES=0
    ;;

  Bash)
    # 检测 Bash 失败：优先用 tool_input 里的 exit_code，fallback 到文本匹配
    IS_FAILURE=false
    EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_input.exit_code // .tool_output_metadata.exit_code // empty' 2>/dev/null)
    if [ -n "$EXIT_CODE" ] && [ "$EXIT_CODE" != "0" ]; then
      IS_FAILURE=true
    elif echo "$TOOL_OUTPUT" | grep -qE '(exit code|exitCode|Exit code)[: ]+[1-9][0-9]*'; then
      IS_FAILURE=true
    else
      # fallback: 常见失败模式（排除只读命令的误判）
      CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
      if ! echo "$CMD" | grep -qE '^(grep|find|ls|cat|echo|head|tail|wc)'; then
        if echo "$TOOL_OUTPUT" | grep -qE '(Traceback|SyntaxError|ReferenceError|TypeError|FAIL|FAILED|fatal|FATAL|panic|No such file|command not found|Permission denied)'; then
          IS_FAILURE=true
        fi
      fi
    fi

    if [ "$IS_FAILURE" = true ]; then
      FAILURES=$((FAILURES + 1))
      if [ "$FAILURES" -ge 3 ]; then
        CONTEXT="⚠️ 检测到连续 ${FAILURES} 次命令失败。停下来，不要继续盲猜盲修。

请走系统化调试流程（/bcc-debug skill）：
1. 阶段 1：认真读错误信息 → 稳定复现 → 检查最近改动 → 追踪数据流
2. 阶段 2：找到能工作的类似代码，对比差异
3. 阶段 3：形成单一假设，最小化验证
4. 阶段 4：写失败测试，实施单一修复

如果已经尝试 3+ 次修复都没解决 → 这可能是架构问题，和用户讨论。"
      fi
    else
      # 成功 → 重置失败计数
      FAILURES=0
    fi

    # Bash 也算一次"工作"
    EDITS=$((EDITS + 1))
    ;;
esac

# 原子写回 state（先写临时文件再 mv，防中断写出半截 JSON）
TMP_STATE=$(mktemp "${STATE_FILE}.XXXXXX" 2>/dev/null || echo "${STATE_FILE}.tmp")
jq -n --argjson e "$EDITS" --argjson f "$FAILURES" \
  '{edits_since_task_update: $e, consecutive_bash_failures: $f}' > "$TMP_STATE" && mv "$TMP_STATE" "$STATE_FILE"

# 输出
if [ -n "$CONTEXT" ]; then
  jq -n --arg ctx "$CONTEXT" \
    '{hookSpecificOutput: {hookEventName: "PostToolUse", additionalContext: $ctx}}'
fi
