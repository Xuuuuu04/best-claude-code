#!/bin/bash
# clarification-gate.sh — Agent Legion Router · 需求澄清门
# 触发：UserPromptSubmit hook（在 review-gate 之前）
#
# 目的：
#   1. 缺截图/图片/日志/目标环境等关键资产时硬拦截。
#   2. 普通模糊需求不粗暴拦截，而是注入 UNDERSTANDING-CHECK，要求主会话先理解自检并 AskUserQuestion。
#   3. 用户明确 bypass 时回放原始请求，并要求主会话记录 assumptions。
#
# 设计原则（极度保守，避免骚扰）：
#   1. 只对明确的"unclear"信号 block；medium/large 即便信号少也放行
#   2. 提供清晰 bypass 机制（"直接做"/"按你想的来"/"skip"）
#   3. 长 prompt（>500 字符）默认放行——用户已在提供信息
#   4. 有文件路径/错误日志/代码引用的 → 放行
#
# 返回：
#   block 时：{"decision":"block","reason":"追问文本"}
#   soft 时：hookSpecificOutput.additionalContext
#   放行时：exit 0（无输出）

set -uo pipefail

INPUT="$(cat || true)"
[ -z "$INPUT" ] && exit 0

# 提取 prompt 和 session_id
PROMPT=""
SESSION_ID=""
if command -v jq >/dev/null 2>&1; then
  PROMPT="$(echo "$INPUT" | jq -r '.prompt // empty' 2>/dev/null || echo "")"
  SESSION_ID="$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null || echo "")"
fi
[ -z "$PROMPT" ] && exit 0

NORMALIZED="$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]' | tr -s '[:space:]' ' ')"
LEN="${#PROMPT}"

# ─── Pending state（block 时保存原 prompt，bypass 时回放给 AI） ───────────
STATE_DIR="$HOME/.claude/state"
mkdir -p "$STATE_DIR" 2>/dev/null || true
SESSION_KEY="${SESSION_ID:-default}"
# sanitize（只留字母数字 _ -）
SESSION_KEY="$(echo "$SESSION_KEY" | tr -cd 'A-Za-z0-9_-' | head -c 64)"
PENDING_FILE="$STATE_DIR/clarification-pending-${SESSION_KEY}.json"
PENDING_TTL=600  # 10 分钟

# ─── Bypass 关键词（用户明确表示跳过追问） ────────────────────────────────
BYPASS_PATTERNS=(
  '直接做' '就这样' '按你.*想' '按你.*来' '随便.*做' '你看着办'
  '不用.*问' '不要.*问' '别问了' 'skip.*clarif' 'bypass'
  '就是这.*意思' '我说了' '上面.*说了' '刚.*说'
  '^skip$' '^skip[[:space:]]'
)

for p in "${BYPASS_PATTERNS[@]}"; do
  if echo "$NORMALIZED" | grep -qE "$p"; then
    # 尝试读出上一次被拦的原 prompt，注入回会话
    if command -v jq >/dev/null 2>&1 && [ -f "$PENDING_FILE" ]; then
      ORIGINAL_PROMPT="$(jq -r '.prompt // empty' "$PENDING_FILE" 2>/dev/null || echo "")"
      PENDING_TS="$(jq -r '.timestamp // 0' "$PENDING_FILE" 2>/dev/null || echo 0)"
      NOW_TS="$(date +%s)"
      AGE=$((NOW_TS - PENDING_TS))

      if [ -n "$ORIGINAL_PROMPT" ] && [ "$AGE" -lt "$PENDING_TTL" ]; then
        rm -f "$PENDING_FILE" 2>/dev/null || true
        CTX=$'[CLARIFICATION-BYPASS] 用户已通过 bypass 关键词跳过 clarification-gate。\n以下是上一次被拦截的原始请求，请按此处理（用户当前消息只是 bypass 信号，不是新需求）：\n\n---\n'"$ORIGINAL_PROMPT"$'\n---'
        jq -c -n --arg ctx "$CTX" \
          '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$ctx}}' 2>/dev/null || true
        exit 0
      fi
      rm -f "$PENDING_FILE" 2>/dev/null || true
    fi
    exit 0  # 放行（无 pending 或已过期）
  fi
done

# ─── 理解检查：资产、路径、代码、模糊信号 ───────────────────────────────────

HAS_ATTACHMENT=0
if command -v jq >/dev/null 2>&1; then
  ATTACH_COUNT="$(echo "$INPUT" | jq '[.attachments[]?, .images[]?, .files[]?, .pastedContents[]?] | length' 2>/dev/null || echo 0)"
  [ "${ATTACH_COUNT:-0}" -gt 0 ] && HAS_ATTACHMENT=1
fi

HAS_PATH_OR_CODE=0
if echo "$PROMPT" | grep -qE '\.[a-z]{1,5}[^a-z]|src/|/src|\\\\.*\\\\|file:|error:|exception|at \w+\.|line [0-9]+|```|^[[:space:]]{2,}[a-zA-Z]|L[0-9]+|:[0-9]+:'; then
  HAS_PATH_OR_CODE=1
fi

MISSING_ASSET=0
ASSET_KIND=""
if echo "$NORMALIZED" | grep -qE '截图|图片|图里|这张图|设计稿|原图|附件|看图|圈出|参考图|海报|照片'; then
  if [ "$HAS_ATTACHMENT" -eq 0 ] && [ "$HAS_PATH_OR_CODE" -eq 0 ]; then
    MISSING_ASSET=1
    ASSET_KIND="截图/图片/设计稿"
  fi
fi
if echo "$NORMALIZED" | grep -qE '报错|错误|崩溃|启动不了|接口不通|访问不到|失败日志|日志'; then
  # 只在 prompt 极短（<150字）且无路径/代码/错误关键词时才升为 MISSING_ASSET
  # 长 prompt（≥150字）通常已内联提供信息，降为 UNCLEAR 而非 hard-block
  if [ "$HAS_PATH_OR_CODE" -eq 0 ] && ! echo "$NORMALIZED" | grep -qE 'error|exception|failed|stack|404|500|403|401'; then
    if [ "$LEN" -lt 150 ]; then
      MISSING_ASSET=1
      ASSET_KIND="${ASSET_KIND:-错误日志/复现信息}"
    else
      UNCLEAR_HIT=$((UNCLEAR_HIT+1))
      [ -z "$MATCHED_SIGNAL" ] && MATCHED_SIGNAL="报错/日志-软触发"
    fi
  fi
fi

UNCLEAR_PATTERNS=(
  '客户说' '客户发' '客户反馈' '客户给我' '客户方' '甲方'
  '他说' '他们说' '对方说' '他要我'
  '感觉.*不.*对' '感觉.*有问题' '好像.*不行' '好像.*不对'
  '似乎有.*问题' '有点.*问题' '总之.*有.*问题'
  '帮我看看' '瞅瞅' '看一下.*情况'
  '搞一下' '弄一下' '整一下' '处理一下'
  '随便.*改改' '大概.*这样'
  '优化一下' '改善一下' '体验.*不好' '质量.*不行'
)

UNCLEAR_HIT=0
MATCHED_SIGNAL=""
for p in "${UNCLEAR_PATTERNS[@]}"; do
  if echo "$NORMALIZED" | grep -qE "$p"; then
    UNCLEAR_HIT=$((UNCLEAR_HIT+1))
    [ -z "$MATCHED_SIGNAL" ] && MATCHED_SIGNAL="$p"
  fi
done

# 信息充分且无模糊信号 → 放行
if [ "$MISSING_ASSET" -eq 0 ] && [ "$UNCLEAR_HIT" -lt 1 ]; then
  exit 0
fi

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

Q_COMMON='1. 目标：你希望最终变成什么状态？（一句话即可）
2. 证据：请提供截图/日志/复现步骤中最关键的一项。
3. 验收：做到什么程度算通过？'

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
if [ "$MISSING_ASSET" -eq 1 ]; then
  REASON=$'⚠️ Clarification Gate — 缺少关键资产\n\n当前请求提到了 '"$ASSET_KIND"$'，但消息里没有可用附件、路径或日志。请先补充：\n\n'
fi
if [ -n "$Q_DOMAIN" ]; then
  REASON+="$Q_DOMAIN"$'\n'
fi
REASON+="$Q_COMMON"$'\n\n'
REASON+=$'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
REASON+=$'回答后重发请求即可继续。\n如确认不需澄清，回复 "直接做" / "按你想的来" / "skip" 即可——\n原始请求会自动带回给 AI（10 分钟内有效），无需重新输入。'

# ─── 日志 ──────────────────────────────────────────────────────────────────
LOG_DIR="$HOME/.claude/logs"
mkdir -p "$LOG_DIR" 2>/dev/null || true
LOG_FILE="$LOG_DIR/clarification-gate.jsonl"
TS="$(date +%Y-%m-%dT%H:%M:%S%z)"
PROMPT_PREVIEW="$(echo "$PROMPT" | head -c 200 | tr '\n' ' ')"

ACTION="context"
[ "$MISSING_ASSET" -eq 1 ] && ACTION="block"

if command -v jq >/dev/null 2>&1; then
  jq -c -n --arg ts "$TS" --arg sig "$MATCHED_SIGNAL" --arg dom "$DOMAIN_HINT" \
           --arg preview "$PROMPT_PREVIEW" --arg action "$ACTION" --arg asset "$ASSET_KIND" \
           --argjson hits "$UNCLEAR_HIT" \
    '{timestamp:$ts, action:$action, signal:$sig, domain:$dom, missing_asset:$asset, hits:$hits, preview:$preview}' \
    >> "$LOG_FILE" 2>/dev/null || true
fi

if [ "$MISSING_ASSET" -eq 1 ]; then
  # 落盘 pending：bypass 时回放给 AI
  if command -v jq >/dev/null 2>&1; then
    jq -c -n --arg p "$PROMPT" --argjson ts "$(date +%s)" \
      '{prompt:$p, timestamp:$ts}' > "$PENDING_FILE" 2>/dev/null || true
  fi
  if command -v jq >/dev/null 2>&1; then
    jq -c -n --arg reason "$REASON" \
      '{decision:"block", reason:$reason, hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:"[CLARIFICATION-GATE] blocked: missing asset; user must provide asset or say 直接做 to bypass"}}'
  fi
  exit 0
fi

# ─── 普通模糊：不硬拦，注入理解检查上下文 ───────────────────────────────────
if command -v jq >/dev/null 2>&1; then
  CTX=$'[UNDERSTANDING-CHECK] 本轮用户输入含模糊/转述/验收不明信号。主会话必须先做理解自检：目标、对象、证据资产、验收标准、不确定点。若关键缺口会改变执行路径，先调用 AskUserQuestion；若低风险且用户允许自行处理，写入 DispatchTicket.understanding.assumptions 后再推进。不要输出原始思维链，只输出理解摘要和可选项。'
  jq -c -n --arg ctx "$CTX" \
    '{hookSpecificOutput:{hookEventName:"UserPromptSubmit", additionalContext:$ctx}}'
fi

exit 0
