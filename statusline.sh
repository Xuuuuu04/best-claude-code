#!/usr/bin/env bash
# Claude Code 状态栏脚本
# 字段来源（stdin JSON）：
#   model.display_name / model.id     → 模型名称
#   workspace.current_dir              → 当前工作目录
#   context_window.used_percentage     → 上下文使用百分比（预计算）
#   context_window.current_usage.*     → token 详细用量
#   context_window.context_window_size → 上下文窗口总大小
# macOS 兼容，依赖：bash, jq
# 图标: emoji（任意字体均可显示，不依赖 Nerd Font）

# ── ANSI 颜色定义（256色） ────────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

# 前景色
C_WHITE="\033[97m"
C_GRAY="\033[90m"
C_GREEN="\033[92m"
C_YELLOW="\033[93m"
C_ORANGE="\033[38;5;208m"
C_RED="\033[91m"
C_CYAN="\033[96m"
C_BLUE="\033[94m"
C_MAGENTA="\033[95m"

# 分隔符颜色
C_SEP="\033[38;5;240m"

# ── Emoji 图标变量（无字体依赖） ──────────────────────────────────────────────
ICON_MODEL="🤖"   # 模型
ICON_DIR="📁"     # 目录
ICON_BRANCH="🌿"  # git 分支

# ── 读取 stdin JSON ───────────────────────────────────────────────────────────
INPUT=$(cat)

# ── 1. 模型 ───────────────────────────────────────────────────────────────────
MODEL=$(echo "$INPUT" | jq -r '.model.display_name // .model.id // empty' 2>/dev/null)

# ── 2. 工作目录 + Git 分支 ────────────────────────────────────────────────────
CWD=$(echo "$INPUT" | jq -r '.workspace.current_dir // empty' 2>/dev/null)
DIR_BASENAME=""
GIT_PART=""

if [ -n "$CWD" ]; then
  DIR_BASENAME=$(basename "$CWD")
  # 检测 git 分支（--no-optional-locks 避免锁文件竞争）
  if git -C "$CWD" --no-optional-locks rev-parse --git-dir &>/dev/null 2>&1; then
    BRANCH=$(git -C "$CWD" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
             || git -C "$CWD" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
    if [ -n "$BRANCH" ]; then
      # 检测 dirty 状态
      DIRTY=""
      if ! git -C "$CWD" --no-optional-locks diff --quiet 2>/dev/null || \
         ! git -C "$CWD" --no-optional-locks diff --cached --quiet 2>/dev/null; then
        DIRTY="*"
      fi
      GIT_PART=" ${ICON_BRANCH} ${BRANCH}${DIRTY}"
    fi
  fi
fi

# ── 3. 上下文进度条 ───────────────────────────────────────────────────────────
USED_PCT=$(echo "$INPUT" | jq -r '.context_window.used_percentage // empty' 2>/dev/null)
CTX_SIZE=$(echo "$INPUT" | jq -r '.context_window.context_window_size // empty' 2>/dev/null)
INPUT_TOKENS=$(echo "$INPUT" | jq -r '.context_window.current_usage.input_tokens // empty' 2>/dev/null)

BAR_PART=""
if [ -n "$USED_PCT" ] && [ "$USED_PCT" != "null" ]; then
  # 四舍五入到整数
  PCT=$(printf "%.0f" "$USED_PCT" 2>/dev/null || echo "0")

  # 确定颜色
  if   [ "$PCT" -ge 90 ]; then BAR_COLOR="$C_RED"
  elif [ "$PCT" -ge 75 ]; then BAR_COLOR="$C_ORANGE"
  elif [ "$PCT" -ge 50 ]; then BAR_COLOR="$C_YELLOW"
  else                         BAR_COLOR="$C_GREEN"
  fi

  # 绘制 10 格进度条
  FILLED=$(( PCT * 10 / 100 ))
  EMPTY=$(( 10 - FILLED ))
  BAR=""
  for (( i=0; i<FILLED; i++ )); do BAR="${BAR}▰"; done
  for (( i=0; i<EMPTY;  i++ )); do BAR="${BAR}▱"; done

  # 显示 token 数（若有）
  if [ -n "$INPUT_TOKENS" ] && [ -n "$CTX_SIZE" ]; then
    # 格式化为 K 单位
    USED_K=$(( INPUT_TOKENS / 1000 ))
    TOTAL_K=$(( CTX_SIZE / 1000 ))
    REMAIN_PCT=$(( 100 - PCT ))
    TOKEN_LABEL="${USED_K}K/${TOTAL_K}K 剩${REMAIN_PCT}%"
  else
    REMAIN_PCT=$(( 100 - PCT ))
    TOKEN_LABEL="已用${PCT}% 剩${REMAIN_PCT}%"
  fi

  BAR_PART="${BAR_COLOR}${BAR}${RESET} ${DIM}${TOKEN_LABEL}${RESET}"
fi

# ── 拼装输出（总长度 ≤120 字符）────────────────────────────────────────────────
SEP="${C_SEP} │ ${RESET}"
OUT=""

# 模型段
if [ -n "$MODEL" ]; then
  OUT="${OUT}${C_MAGENTA}${ICON_MODEL} ${MODEL}${RESET}"
fi

# 目录段
if [ -n "$DIR_BASENAME" ]; then
  [ -n "$OUT" ] && OUT="${OUT}${SEP}"
  OUT="${OUT}${C_CYAN}${ICON_DIR} ${DIR_BASENAME}${RESET}${C_YELLOW}${GIT_PART}${RESET}"
fi

# 上下文段
if [ -n "$BAR_PART" ]; then
  [ -n "$OUT" ] && OUT="${OUT}${SEP}"
  OUT="${OUT}${BAR_PART}"
fi

printf "%b" "$OUT"
