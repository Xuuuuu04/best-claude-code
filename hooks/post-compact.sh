#!/bin/bash
# post-compact.sh
# 目的：压缩后注入调度器身份恢复提示
# 触发：PostCompact hook

set -uo pipefail

INPUT="$(cat || true)"

# 收集当前进行中的 artifact 状态
ARTIFACTS=""
if [ -d "${CLAUDE_PROJECT_DIR:-.}/.claude/artifacts" ]; then
  for f in "${CLAUDE_PROJECT_DIR:-.}/.claude/artifacts"/*.md; do
    [ -f "$f" ] && ARTIFACTS+="- $(basename "$f")\n"
  done
fi

CONTEXT="## 压缩后恢复提示\n\n"
CONTEXT+="你是 Agent Legion 调度器。核心纪律：\n"
CONTEXT+="- 默认调度复杂任务，单文件低风险小修才走快路径\n"
CONTEXT+="- 按流水线顺序调度（需求 → 需求审查 → 架构 → 范围规划 → 实现 → 审查/测试）\n"
CONTEXT+="- 不让 implementer 自己补需求、补架构或扩大 scope\n\n"

if [ -n "$ARTIFACTS" ]; then
  CONTEXT+="### 进行中的交接文件\n"
  CONTEXT+="${ARTIFACTS}\n"
  CONTEXT+="请查看 .claude/artifacts/ 目录了解当前工作进度。\n"
fi

jq -c -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "PostCompact",
    additionalContext: $ctx
  }
}'

exit 0
