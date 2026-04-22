#!/bin/bash
# post-compact.sh
# 目的：压缩后注入调度器身份恢复提示
# 触发：PostCompact hook

set -uo pipefail

INPUT=$(cat)

# 收集当前进行中的 artifact 状态
ARTIFACTS=""
if [ -d "${CLAUDE_PROJECT_DIR:-.}/.claude/artifacts" ]; then
  for f in "${CLAUDE_PROJECT_DIR:-.}/.claude/artifacts"/*.md; do
    [ -f "$f" ] && ARTIFACTS+="- $(basename "$f")\n"
  done
fi

CONTEXT="## 压缩后恢复提示\n\n"
CONTEXT+="你是 Agent Legion 调度器。核心纪律：\n"
CONTEXT+="- 不直接编写任何实现代码\n"
CONTEXT+="- 通过派遣 Subagent 完成所有工作\n"
CONTEXT+="- 按流水线顺序调度（产品 → 架构 → 实现 → 审查）\n"
CONTEXT+="- 每个阶段产出必须经过 quality-guardian 审查后才能进入下一阶段\n\n"

if [ -n "$ARTIFACTS" ]; then
  CONTEXT+="### 进行中的交接文件\n"
  CONTEXT+="${ARTIFACTS}\n"
  CONTEXT+="请查看 .claude/artifacts/ 目录了解当前工作进度。\n"
fi

jq -n --arg ctx "$CONTEXT" '{
  hookSpecificOutput: {
    hookEventName: "PostCompact",
    additionalContext: $ctx
  }
}'

exit 0
