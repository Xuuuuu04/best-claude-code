#!/bin/bash
# clarification-gate.sh — Agent Legion Router · 需求澄清门
# 触发：UserPromptSubmit hook（同事件上游是 intent-classify.sh）
#
# 目的：
#   拦截"模糊 / 转述 / 缺关键信息"的请求，给出 3-5 个精准追问。
#   避免主会话"假设性推进"导致改错方向。
#
# 设计原则（极度保守，避免骚扰）：
#   1. 只对明确的"unclear"信号 block；medium/large 即便信号少也放行
#   2. 提供清晰 bypass 机制（"直接做"/"按你想的来"/"skip"）
#   3. 长 prompt（>500 字符）默认放行——用户已在提供信息
#   4. 有文件路径/错误日志/代码引用的 → 放行
#
# 返回：
#   block 时：{"decision":"block","reason":"追问文本"}
#   放行时：exit 0（无输出）

set -uo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

# 提取 prompt
PROMPT=""
if command -v jq >/dev/null 2>&1; then
  PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")"
fi
[ -z "$PROMPT" ] && exit 0

NORMALIZED="$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')"
LEN="${#PROMPT}"

# ─── Bypass 关键词（用户明确表示跳过追问） ────────────────────────────────
BYPASS_PATTERNS=(
  '直接做' '就这样' '按你.*想' '按你.*来' '随便.*做' '你看着办'
  '不用.*问' '不要.*问' '别问了' 'skip.*clarif' 'bypass'
  '就是这.*意思' '我说了' '上面.*说了' '刚.*说'
)

for p in "${BYPASS_PATTERNS[@]}"; do
  if echo "$NORMALIZED" | grep -qE "$p"; then
    exit 0  # 放行
  fi
done

# ─── 放行条件：已提供足够信息 ───────────────────────────────────────────────

# 长 prompt（用户已在努力描述）
if [ "$LEN" -ge 500 ]; then
  exit 0
fi

# 含文件路径、代码片段、错误堆栈 → 放行
if echo "$PROMPT" | grep -qE '\.[a-z]{1,5}[^a-z]|src/|/src|\\\\.*\\\\|file:|error:|exception|at \w+\.|line [0-9]+'; then
  exit 0
fi

# 含代码块 / 行号引用
if echo "$PROMPT" | grep -qE '```|^[[:space:]]{2,}[a-zA-Z]|L[0-9]+|:[0-9]+:'; then
  exit 0
fi

# ─── Unclear 触发模式（必须明确有"转述/模糊"信号才 block） ────────────────
UNCLEAR_PATTERNS=(
  '客户说' '客户发' '客户反馈' '客户给我' '客户方' '甲方'
  '他说' '他们说' '对方说' '他要我'
  '感觉.*不.*对' '感觉.*有问题' '好像.*不行' '好像.*不对'
  '似乎有.*问题' '有点.*问题' '总之.*有.*问题'
  '帮我看看' '瞅瞅' '看一下.*情况'
  '搞一下' '弄一下' '整一下' '处理一下'
  '随便.*改改' '大概.*这样'
)

UNCLEAR_HIT=0
MATCHED_SIGNAL=""
for p in "${UNCLEAR_PATTERNS[@]}"; do
  if echo "$NORMALIZED" | grep -qE "$p"; then
    UNCLEAR_HIT=$((UNCLEAR_HIT+1))
    [ -z "$MATCHED_SIGNAL" ] && MATCHED_SIGNAL="$p"
  fi
done

# 低于阈值放行（单个弱信号不 block）
if [ "$UNCLEAR_HIT" -lt 1 ]; then
  exit 0
fi

# ─── 构造精准追问（根据信号类型定制问题） ───────────────────────────────────

# 检测任务领域线索
DOMAIN_HINT=""
if echo "$NORMALIZED" | grep -qE '小程序|wechat|微信|miniapp|uni-?app'; then
  DOMAIN_HINT="miniprogram"
elif echo "$NORMALIZED" | grep -qE '部署|上线|发版|生产|staging|prod|deploy'; then
  DOMAIN_HINT="deployment"
elif echo "$NORMALIZED" | grep -qE '登录|auth|token|鉴权|权限'; then
  DOMAIN_HINT="auth"
elif echo "$NORMALIZED" | grep -qE '支付|pay|订单|order'; then
  DOMAIN_HINT="payment"
elif echo "$NORMALIZED" | grep -qE '后端|api|接口|server|服务端'; then
  DOMAIN_HINT="backend"
elif echo "$NORMALIZED" | grep -qE '前端|ui|页面|样式|css|frontend'; then
  DOMAIN_HINT="frontend"
fi

# 通用问题
Q_COMMON='1. 发生位置：线上 / staging / 本地开发环境？
2. 能提供错误日志、截图、或最小复现步骤吗？
3. 期待的正确行为是什么？（一句话即可）'

# 领域专项问题（加在通用之前）
case "$DOMAIN_HINT" in
  miniprogram)
    Q_DOMAIN='0. 涉及范围：小程序前端（.wxml/.js）/ 云函数 / 云开发数据库 / 小程序后端？'
    ;;
  deployment)
    Q_DOMAIN='0. 部署目标：哪个服务？哪个环境？最近一次成功部署是什么时候？'
    ;;
  auth)
    Q_DOMAIN='0. 哪个认证链路出问题：登录 / 刷新 token / 权限校验 / 第三方 OAuth？'
    ;;
  payment)
    Q_DOMAIN='0. 支付链路哪一步：下单 / 预支付 / 回调 / 对账 / 退款？'
    ;;
  backend)
    Q_DOMAIN='0. 服务名 + 接口路径？用户能复现还是只在日志里发现？'
    ;;
  frontend)
    Q_DOMAIN='0. 哪个页面 / 组件？哪些浏览器能复现？'
    ;;
  *)
    Q_DOMAIN=''
    ;;
esac

REASON=$'⚠️ Clarification Gate — 信息不足以开工\n\n检测到模糊/转述信号，为避免改错方向，请先回答：\n\n'
if [ -n "$Q_DOMAIN" ]; then
  REASON+="$Q_DOMAIN"$'\n'
fi
REASON+="$Q_COMMON"$'\n\n'
REASON+=$'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
REASON+=$'回答后重发请求即可继续。\n如确认不需澄清，回复中包含 "直接做" / "按你想的来" / "skip" 任一即自动通过。'

# ─── 日志 ──────────────────────────────────────────────────────────────────
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/clarification-gate.jsonl"
TS="$(date +%Y-%m-%dT%H:%M:%S%z)"
PROMPT_PREVIEW="$(echo "$PROMPT" | head -c 200 | tr '\n' ' ')"

if command -v jq >/dev/null 2>&1; then
  jq -c -n --arg ts "$TS" --arg sig "$MATCHED_SIGNAL" --arg dom "$DOMAIN_HINT" \
           --arg preview "$PROMPT_PREVIEW" --argjson hits "$UNCLEAR_HIT" \
    '{timestamp:$ts, action:"block", signal:$sig, domain:$dom, hits:$hits, preview:$preview}' \
    >> "$LOG_FILE" 2>/dev/null || true
fi

# ─── 返回 block 决策 ───────────────────────────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  jq -c -n --arg reason "$REASON" \
    '{decision:"block", reason:$reason, hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:"[CLARIFICATION-GATE] blocked; user must provide more detail or say '"'"'直接做'"'"' to bypass"}}'
else
  # 无 jq 降级：直接 plain stdout + exit 0（退回放行，因为无法正确构造 block JSON）
  exit 0
fi

exit 0
