#!/bin/bash
# PostToolUseFailure hook(matcher: Bash): 命令失败 → 连败计数 +1,3 连败注入 /bcc-debug 提示
# 失败信号来自官方事件,替代旧版 PostToolUse 里的 exit-code/正则启发式
# (旧启发式读的 .tool_output / .tool_output_metadata 不在官方 schema 里,疑似从未生效)
source "$(dirname "$0")/_common.sh"

_init_hook
_require_tasks_dir
_load_hook_state

FAILURES=$((FAILURES + 1))
EDITS=$((EDITS + 1))  # 失败的命令也是工作量,Stop gate 照样要求落档

_save_hook_state

[ "$FAILURES" -lt 3 ] && exit 0

CONTEXT="⚠️ 检测到连续 ${FAILURES} 次命令失败。停下来,不要继续盲猜盲修。

请走系统化调试流程(/bcc-debug skill):
1. 阶段 1:认真读错误信息 → 稳定复现 → 检查最近改动 → 追踪数据流
2. 阶段 2:找到能工作的类似代码,对比差异
3. 阶段 3:形成单一假设,最小化验证
4. 阶段 4:写失败测试,实施单一修复

如果已经尝试 3+ 次修复都没解决 → 这可能是架构问题,和用户讨论。"

jq -n --arg ctx "$CONTEXT" \
  '{hookSpecificOutput: {hookEventName: "PostToolUseFailure", additionalContext: $ctx}}'
