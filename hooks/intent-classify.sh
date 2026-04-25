#!/bin/bash
# intent-classify.sh — Agent Legion Router · 用户意图/复杂度分类
# 触发：UserPromptSubmit hook
#
# 输入：stdin JSON {"prompt": "...", "cwd": "...", "session_id": "...", "transcript_path": "..."}
# 输出：JSON hookSpecificOutput.additionalContext，含一行 [LEGION-INTENT] 标记
#
# 分类（5 档，优先级从高到低）：
#   unclear  - 转述/模糊/缺关键信息 → 触发 Clarification Gate
#   large    - 新功能/跨模块重构/迁移/部署 → 完整流水线
#   medium   - 跨文件清楚需求 → 产分→实现→审查
#   small    - 单文件<20 行 → quick-fix 或直接做
#   trivial  - 对话/问答/确认 → 主会话直接回
#
# 设计原则：
#   1. 纯 bash + grep，零依赖（jq 除外）
#   2. 分类保守：宁可升档不降档（降档会漏 review）
#   3. 注入为信息提示（additionalContext），不 block（block 由 clarification-gate.sh 专管）

set -uo pipefail

INPUT="$(cat || true)"

# 没输入就静默退出（保护会话）
if [ -z "$INPUT" ]; then
  exit 0
fi

# 提取 prompt；无 jq 降级到 sed
PROMPT=""
if command -v jq >/dev/null 2>&1; then
  PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")"
else
  PROMPT="$(echo "$INPUT" | sed -n 's/.*"prompt":[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)"
fi

# 空 prompt（比如只发了文件、图片）→ 不分类
if [ -z "$PROMPT" ]; then
  exit 0
fi

# 归一化：小写、去多余空白、限制长度用于模式匹配（不改变原 prompt）
NORMALIZED="$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')"
LEN="${#PROMPT}"

# ─── 分类信号库 ─────────────────────────────────────────────────────────────

# Unclear 信号（转述/模糊/代词多/缺技术指向）
UNCLEAR_PATTERNS=(
  '客户说' '客户发' '客户反馈' '客户给我' '客户方' '甲方'
  '他说' '他们说' '对方说' '他要' '他要我'
  '感觉.*不.*对' '感觉.*有问题' '好像.*不行' '好像.*不对'
  '似乎有' '有点.*问题' '反正.*有.*问题' '总之.*有.*问题'
  '帮我看看' '瞅瞅' '看一下.*情况'
  '搞一下' '弄一下' '整一下' '处理一下'
  '随便.*改改' '大概.*这样' '那种感觉'
)

# Large 信号（多文件/新能力/结构性改动/不可逆）
LARGE_PATTERNS=(
  '新功能' '新页面' '新接口' '新模块' '新服务'
  '重构' '迁移' '升级' '替换.*框架'
  '实现.*整个' '实现.*完整' '搭建' '从零' '从 0' '从头'
  '部署' '上线' '发版' 'release' 'deploy'
  '改造.*架构' '整体.*重写' '大改'
  '新增.*表' '加.*字段' 'migration' '迁移脚本'
  'rewrite' 'refactor.*core' 'redesign'
)

# Medium 信号（清楚需求 + 跨文件 / 功能级改动）
MEDIUM_PATTERNS=(
  '跨.*文件' '多个.*文件' '所有.*地方'
  '实现.*功能' '加一个.*功能' '支持.*功能'
  '添加.*接口' '增加.*接口' '新加.*api'
  '修复.*bug' '修复.*问题'
  '优化.*性能' '优化.*逻辑'
  '补.*测试' '加.*测试' '覆盖.*测试'
)

# Small 信号（单点明确）
SMALL_PATTERNS=(
  '改一下' '把.*改' '把.*替换' '替换这里'
  '加一行' '删一行' '这个函数' '这个变量'
  '加个.*字段' '改个.*名字' '改个.*颜色'
  '修改.*文件'
)

# Trivial 信号（对话/问答/确认/元讨论）
TRIVIAL_PATTERNS=(
  '^什么是' '^怎么.*是' '^为什么' '^如何.*工作'
  '是什么意思' '什么叫'
  '^好的' '^ok$' '^可以' '^行$' '^嗯' '^继续$' '^请继续'
  '谢谢' '感谢' '不错' '做得好'
  '^解释' '^讲讲' '^说说'
  # 元对话/咨询性（v3.1 新增——避免"还有需要升级的吗"被误判 large）
  '还有.*嘛' '还有.*吗' '还有.*没有'
  '剩下' '接下来呢' '下一步是'
  '建议.*嘛' '建议.*吗' '看法' '想法.*嘛' '想法.*吗'
  '对吗\?' '对吗？' '是吧\?' '是吧？' '是不是' '对不对'
  '怎么样\?' '怎么样？' '行不行' '可以.*嘛' '可以.*吗'
  '需要.*嘛' '需要.*吗'
)

# 元对话锚词（与 large 关键词冲突时优先 trivial）
META_DISCUSSION_PATTERNS=(
  '还有' '剩下' '建议' '看法' '想法' '怎么看'
  '需要.*[嘛吗]' '可以.*[嘛吗]' '是.*[嘛吗]'
)

# ─── 匹配工具 ──────────────────────────────────────────────────────────────

match_any() {
  local patterns=("$@")
  local p
  for p in "${patterns[@]}"; do
    if echo "$NORMALIZED" | grep -qE "$p"; then
      return 0
    fi
  done
  return 1
}

count_matches() {
  local patterns=("$@")
  local p n=0
  for p in "${patterns[@]}"; do
    if echo "$NORMALIZED" | grep -qE "$p"; then
      n=$((n+1))
    fi
  done
  echo "$n"
}

# ─── 分类决策（优先级从高到低） ────────────────────────────────────────────

TIER=""
SIGNALS=""

# 1. Unclear：转述/模糊 + 信号 ≥1 + 缺技术细节
UNCLEAR_HITS="$(count_matches "${UNCLEAR_PATTERNS[@]}")"
HAS_FILE_REF=0
if echo "$PROMPT" | grep -qE '\.[a-z]{1,4}[^a-z]|/|src/|\\\\|@' 2>/dev/null; then
  HAS_FILE_REF=1
fi

# 2. Trivial：短 + 问号结尾 + 无指令动词
IS_QUESTION=0
case "$PROMPT" in
  *'?'*|*'？'*) IS_QUESTION=1 ;;
esac

# 3. Large
LARGE_HITS="$(count_matches "${LARGE_PATTERNS[@]}")"

# 4. Medium
MEDIUM_HITS="$(count_matches "${MEDIUM_PATTERNS[@]}")"

# 5. Small
SMALL_HITS="$(count_matches "${SMALL_PATTERNS[@]}")"

# 6. Trivial
TRIVIAL_HITS="$(count_matches "${TRIVIAL_PATTERNS[@]}")"
META_HITS="$(count_matches "${META_DISCUSSION_PATTERNS[@]}")"

# 决策树（v3.1：trivial 提前到 large 之前，避免咨询性 prompt 命中"升级"等动词）
if [ "$UNCLEAR_HITS" -ge 1 ] && [ "$HAS_FILE_REF" -eq 0 ] && [ "$LEN" -lt 400 ]; then
  TIER="unclear"
  SIGNALS="模糊/转述 hits=$UNCLEAR_HITS|无文件引用|长度<400"
# v3.1 新增：短咨询性（trivial 优先于 large）
elif { [ "$TRIVIAL_HITS" -ge 1 ] || [ "$META_HITS" -ge 1 ] || [ "$IS_QUESTION" -eq 1 ]; } \
     && [ "$LEN" -lt 60 ] && [ "$HAS_FILE_REF" -eq 0 ]; then
  TIER="trivial"
  SIGNALS="短咨询/元对话 trivial=$TRIVIAL_HITS meta=$META_HITS q=$IS_QUESTION len=$LEN"
elif [ "$LARGE_HITS" -ge 1 ] && [ "$LEN" -ge 8 ]; then
  # 门槛 8：防止"升级"等单词被误判，但又能匹配"重构整个 X"等正常长度
  TIER="large"
  SIGNALS="复杂动词 hits=$LARGE_HITS|len=$LEN"
elif [ "$MEDIUM_HITS" -ge 1 ]; then
  TIER="medium"
  SIGNALS="跨文件/功能级 hits=$MEDIUM_HITS"
elif [ "$SMALL_HITS" -ge 1 ] || { [ "$HAS_FILE_REF" -eq 1 ] && [ "$LEN" -lt 300 ]; }; then
  TIER="small"
  SIGNALS="单点明确 hits=$SMALL_HITS|file_ref=$HAS_FILE_REF|len=$LEN"
elif [ "$TRIVIAL_HITS" -ge 1 ] || { [ "$IS_QUESTION" -eq 1 ] && [ "$LEN" -lt 120 ]; }; then
  TIER="trivial"
  SIGNALS="对话/问答 hits=$TRIVIAL_HITS|question=$IS_QUESTION|len=$LEN"
else
  # 默认：内容较多但没命中特征 → medium（安全倾斜，避免漏 review）
  if [ "$LEN" -ge 200 ]; then
    TIER="medium"
    SIGNALS="默认升档|len=$LEN"
  else
    TIER="small"
    SIGNALS="默认|len=$LEN"
  fi
fi

# ─── 建议路由 ──────────────────────────────────────────────────────────────

case "$TIER" in
  trivial)  SUGGEST="主会话直接回答，不派 subagent" ;;
  small)    SUGGEST="主会话快路径或 1 个 implementer，完成后建议 code-reviewer 轻审" ;;
  medium)   SUGGEST="product-analyst → implementer → code-reviewer（必经）" ;;
  large)    SUGGEST="完整流水线：product-analyst → architect → scope-planner → implementer → 全门控审查" ;;
  unclear)  SUGGEST="Clarification Gate 将追问；补足后重新分类" ;;
esac

# ─── 日志 ──────────────────────────────────────────────────────────────────

LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/intent-classify.jsonl"
TS="$(date +%Y-%m-%dT%H:%M:%S%z)"
PROMPT_PREVIEW="$(echo "$PROMPT" | head -c 160 | tr '\n' ' ')"

if command -v jq >/dev/null 2>&1; then
  jq -c -n --arg ts "$TS" --arg tier "$TIER" --arg signals "$SIGNALS" \
           --arg preview "$PROMPT_PREVIEW" --argjson len "$LEN" \
    '{timestamp:$ts, tier:$tier, signals:$signals, len:$len, preview:$preview}' \
    >> "$LOG_FILE" 2>/dev/null || true
fi

# ─── 注入 additionalContext ────────────────────────────────────────────────

# 把分类结果写给主会话。主会话的 output-style 会读这个标记。
ADDITIONAL_CONTEXT="[LEGION-INTENT] tier=${TIER} | signals=${SIGNALS} | suggest=${SUGGEST}"

if command -v jq >/dev/null 2>&1; then
  jq -c -n --arg ctx "$ADDITIONAL_CONTEXT" \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$ctx}}'
else
  # 无 jq 降级：直接 plain stdout 也会被 Claude Code 吸收为 context
  echo "$ADDITIONAL_CONTEXT"
fi

exit 0
