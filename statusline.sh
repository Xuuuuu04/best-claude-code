#!/usr/bin/env bash
# Agent Legion · Status Line
# ──────────────────────────────────────────────────────────────────────────────
# Reads JSON from stdin. Fields used:
#   model.display_name / model.id
#   workspace.current_dir
#   context_window.used_percentage
#   context_window.current_usage.input_tokens
#   context_window.context_window_size
#   output_style.name
#
# Design: multi-segment with modern dot separators, gradient context bar,
# LEGION brand prefix, rich git state, and session clock. Works without
# Nerd Font (pure unicode + emoji).
# ──────────────────────────────────────────────────────────────────────────────

set -uo pipefail

# ── Colors (truecolor where possible, 256 fallback) ─────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"
ITALIC="\033[3m"

# True-color palette — warm, modern, Agent Legion inspired
C_LEGION="\033[38;2;255;184;77m"     # gold
C_LEGION_BG="\033[48;2;69;39;160m"   # deep purple
C_MODEL="\033[38;2;167;139;250m"     # violet-300
C_DIR="\033[38;2;34;211;238m"        # cyan-400
C_GIT="\033[38;2;251;191;36m"        # amber-400
C_GIT_DIRTY="\033[38;2;248;113;113m" # red-400
C_GIT_AHEAD="\033[38;2;74;222;128m"  # green-400
C_GIT_BEHIND="\033[38;2;251;146;60m" # orange-400
C_BAR_LOW="\033[38;2;74;222;128m"    # green
C_BAR_MID="\033[38;2;251;191;36m"    # amber
C_BAR_HIGH="\033[38;2;251;146;60m"   # orange
C_BAR_CRIT="\033[38;2;248;113;113m"  # red
C_BAR_EMPTY="\033[38;2;55;65;81m"    # gray-700
C_TOKEN="\033[38;2;148;163;184m"     # slate-400
C_STYLE="\033[38;2;236;72;153m"      # pink-500
C_TIME="\033[38;2;100;116;139m"      # slate-500
C_SEP="\033[38;2;71;85;105m"         # slate-600
C_AGENT_BG="\033[48;2;5;150;105m"    # emerald-600 background
C_AGENT_FG="\033[38;2;236;253;245m"  # emerald-50 foreground
C_COST_ICO="\033[38;2;168;162;158m"  # stone-400 (sum sign)
C_COST_CALL="\033[38;2;251;191;36m"  # amber-400 (call count)
C_COST_TOK="\033[38;2;148;163;184m"  # slate-400 (token nums)
C_COST_HEAVY="\033[38;2;251;146;60m" # orange-400 (heavy)
BLINK="\033[5m"

# ── Unicode icons ────────────────────────────────────────────────────────────
ICO_LEGION="⚡"
ICO_MODEL="◆"
ICO_DIR="▸"
ICO_BRANCH=""  # set conditionally if Nerd Font detected-ish; fallback:
ICO_CLOCK="◷"
ICO_STYLE="✦"
ICO_AGENT="▶"
ICO_SUM="Σ"

# Fallback branch icon (works everywhere)
BR_SYM="⎇"   # branch-ish unicode
UP_SYM="↑"
DN_SYM="↓"

# Separator: elegant middle-dot
SEP="${C_SEP}  ·  ${RESET}"

# ── Read stdin JSON ──────────────────────────────────────────────────────────
INPUT="$(cat 2>/dev/null || echo '{}')"

jq_get() { echo "$INPUT" | jq -r "$1 // empty" 2>/dev/null; }

# ── Session ID (for active-subagent detection) ──────────────────────────────
SESSION_ID="$(jq_get '.session_id')"

# ── 1. LEGION brand prefix ──────────────────────────────────────────────────
LEGION_SEG="${BOLD}${C_LEGION}${ICO_LEGION} LEGION${RESET}"

# ── 1b. Active subagent badge (supports N concurrent agents) ────────────────
AGENT_SEG=""
if [ -n "$SESSION_ID" ]; then
  NOW_TS="$(date +%s)"
  ACTIVE_NAMES=()
  MAX_ELAPSED=0

  shopt -s nullglob 2>/dev/null || true
  for STATE_FILE in /tmp/claude-legion-active-${SESSION_ID}-*; do
    [ -f "$STATE_FILE" ] || continue
    AGENT_LINE="$(cat "$STATE_FILE" 2>/dev/null || echo '')"
    [ -z "$AGENT_LINE" ] && continue

    NAME="$(echo "$AGENT_LINE" | awk -F'\t' '{print $1}')"
    START="$(echo "$AGENT_LINE" | awk -F'\t' '{print $2}')"
    [ -z "$NAME" ] && continue
    [ -z "$START" ] && START="$NOW_TS"

    ELAPSED=$(( NOW_TS - START ))
    [ "$ELAPSED" -gt "$MAX_ELAPSED" ] && MAX_ELAPSED=$ELAPSED
    ACTIVE_NAMES+=("$NAME")
  done

  if [ ${#ACTIVE_NAMES[@]} -gt 0 ]; then
    # Format elapsed (longest-running)
    if [ "$MAX_ELAPSED" -lt 60 ]; then
      ELAPSED_STR="${MAX_ELAPSED}s"
    else
      ELAPSED_STR="$(( MAX_ELAPSED / 60 ))m$(( MAX_ELAPSED % 60 ))s"
    fi

    if [ ${#ACTIVE_NAMES[@]} -eq 1 ]; then
      LABEL="${ACTIVE_NAMES[0]} · ${ELAPSED_STR}"
    else
      # 多个 agent：显示 Nx 计数 + 简略名单（前 2 个）
      if [ ${#ACTIVE_NAMES[@]} -le 2 ]; then
        JOINED="$(IFS=+; echo "${ACTIVE_NAMES[*]}")"
        LABEL="${JOINED} · ${ELAPSED_STR}"
      else
        JOINED="${ACTIVE_NAMES[0]}+${ACTIVE_NAMES[1]}+…"
        LABEL="${#ACTIVE_NAMES[@]}× ${JOINED} · ${ELAPSED_STR}"
      fi
    fi

    AGENT_SEG=" ${C_AGENT_BG}${C_AGENT_FG}${BOLD} ${ICO_AGENT} ${LABEL} ${RESET}"
  fi
fi

# ── 2. Model ────────────────────────────────────────────────────────────────
MODEL="$(jq_get '.model.display_name')"
[ -z "$MODEL" ] && MODEL="$(jq_get '.model.id')"
MODEL_SEG=""
if [ -n "$MODEL" ]; then
  MODEL_SEG="${C_MODEL}${ICO_MODEL} ${MODEL}${RESET}"
fi

# ── 3. Output style (if custom) ─────────────────────────────────────────────
STYLE="$(jq_get '.output_style.name')"
STYLE_SEG=""
if [ -n "$STYLE" ] && [ "$STYLE" != "default" ]; then
  STYLE_SEG="${C_STYLE}${ICO_STYLE} ${STYLE}${RESET}"
fi

# ── 4. Directory + Git state ────────────────────────────────────────────────
CWD="$(jq_get '.workspace.current_dir')"
[ -z "$CWD" ] && CWD="$(jq_get '.workspace.project_dir')"
[ -z "$CWD" ] && CWD="$(pwd 2>/dev/null || echo '')"

DIR_SEG=""
if [ -n "$CWD" ]; then
  BASENAME="$(basename "$CWD" 2>/dev/null || echo '?')"
  DIR_SEG="${C_DIR}${ICO_DIR} ${BASENAME}${RESET}"

  # Git info
  if git -C "$CWD" --no-optional-locks rev-parse --git-dir &>/dev/null; then
    BRANCH="$(git -C "$CWD" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
              || git -C "$CWD" --no-optional-locks rev-parse --short HEAD 2>/dev/null \
              || echo '')"
    if [ -n "$BRANCH" ]; then
      # Dirty check
      DIRTY_MARK=""
      if ! git -C "$CWD" --no-optional-locks diff --quiet 2>/dev/null \
         || ! git -C "$CWD" --no-optional-locks diff --cached --quiet 2>/dev/null; then
        DIRTY_MARK="${C_GIT_DIRTY}●${RESET}"
      fi

      # Ahead/behind (only if upstream exists)
      AHEAD_BEHIND=""
      UPSTREAM="$(git -C "$CWD" --no-optional-locks rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo '')"
      if [ -n "$UPSTREAM" ]; then
        COUNTS="$(git -C "$CWD" --no-optional-locks rev-list --left-right --count "HEAD...@{u}" 2>/dev/null || echo '0	0')"
        AHEAD="$(echo "$COUNTS" | awk '{print $1}')"
        BEHIND="$(echo "$COUNTS" | awk '{print $2}')"
        [ "${AHEAD:-0}" != "0" ] && AHEAD_BEHIND="${AHEAD_BEHIND}${C_GIT_AHEAD}${UP_SYM}${AHEAD}${RESET}"
        [ "${BEHIND:-0}" != "0" ] && AHEAD_BEHIND="${AHEAD_BEHIND}${C_GIT_BEHIND}${DN_SYM}${BEHIND}${RESET}"
      fi

      DIR_SEG="${DIR_SEG} ${C_GIT}${BR_SYM} ${BRANCH}${RESET}${DIRTY_MARK}${AHEAD_BEHIND}"
    fi
  fi
fi

# ── 5. Context bar (gradient fill) ──────────────────────────────────────────
USED_PCT="$(jq_get '.context_window.used_percentage')"
CTX_SIZE="$(jq_get '.context_window.context_window_size')"
INPUT_TOKENS="$(jq_get '.context_window.current_usage.input_tokens')"

BAR_SEG=""
if [ -n "$USED_PCT" ] && [ "$USED_PCT" != "null" ]; then
  PCT="$(printf "%.0f" "$USED_PCT" 2>/dev/null || echo "0")"

  # Choose primary color based on usage
  if   [ "$PCT" -ge 90 ]; then BAR_COLOR="$C_BAR_CRIT"
  elif [ "$PCT" -ge 75 ]; then BAR_COLOR="$C_BAR_HIGH"
  elif [ "$PCT" -ge 50 ]; then BAR_COLOR="$C_BAR_MID"
  else                         BAR_COLOR="$C_BAR_LOW"
  fi

  # 12-slot bar — finer than 10 for more precision
  TOTAL_SLOTS=12
  FILLED=$(( PCT * TOTAL_SLOTS / 100 ))
  [ "$FILLED" -gt "$TOTAL_SLOTS" ] && FILLED=$TOTAL_SLOTS
  EMPTY=$(( TOTAL_SLOTS - FILLED ))

  BAR="${BAR_COLOR}"
  for (( i=0; i<FILLED; i++ )); do BAR="${BAR}▰"; done
  BAR="${BAR}${C_BAR_EMPTY}"
  for (( i=0; i<EMPTY;  i++ )); do BAR="${BAR}▱"; done
  BAR="${BAR}${RESET}"

  # Token label
  if [ -n "$INPUT_TOKENS" ] && [ "$INPUT_TOKENS" != "null" ]; then
    USED_K=$(( INPUT_TOKENS / 1000 ))
    LABEL="${BAR_COLOR}${PCT}%${RESET}${C_TOKEN} · ${USED_K}K${RESET}"
  else
    LABEL="${BAR_COLOR}${PCT}%${RESET}"
  fi

  BAR_SEG="${C_TOKEN}上下文${RESET} ${BAR} ${LABEL}"
fi

# ── 6. Project cost aggregate (only if cost-log.txt exists in cwd/.claude) ──
COST_SEG=""
if [ -n "$CWD" ] && [ -f "$CWD/.claude/cost-log.txt" ]; then
  COST_LINE="$(awk -F'\t' '
    NR==1 {next}
    {c++; in_t+=$5; out_t+=$6; cr+=$7; rd+=$8}
    END {printf "%d %d %d %d %d", c+0, in_t+0, out_t+0, cr+0, rd+0}
  ' "$CWD/.claude/cost-log.txt" 2>/dev/null)"

  CALLS="$(echo "$COST_LINE" | awk '{print $1}')"
  IN_TOK="$(echo "$COST_LINE" | awk '{print $2}')"
  OUT_TOK="$(echo "$COST_LINE" | awk '{print $3}')"
  CACHE_RD="$(echo "$COST_LINE" | awk '{print $5}')"

  if [ -n "$CALLS" ] && [ "$CALLS" -gt 0 ]; then
    TOTAL_EFFECTIVE=$(( IN_TOK + CACHE_RD / 10 + OUT_TOK ))

    fmt_tok() {
      local n="$1"
      if [ "$n" -lt 1000 ]; then
        echo "${n}"
      elif [ "$n" -lt 1000000 ]; then
        echo "$(( n / 1000 ))K"
      else
        printf "%.1fM" "$(echo "scale=1; $n/1000000" | bc 2>/dev/null || echo "$(( n / 1000000 ))")"
      fi
    }

    IN_STR="$(fmt_tok "$IN_TOK")"
    OUT_STR="$(fmt_tok "$OUT_TOK")"

    # 如果 effective token 超过 1M 用 heavy 色警示
    if [ "$TOTAL_EFFECTIVE" -ge 1000000 ]; then
      NUM_COLOR="$C_COST_HEAVY"
    else
      NUM_COLOR="$C_COST_TOK"
    fi

    COST_SEG="${C_COST_ICO}本项目累计${RESET} ${C_COST_CALL}${CALLS} 次${RESET} ${C_COST_TOK}·${RESET} ${NUM_COLOR}${IN_STR}↓ ${OUT_STR}↑${RESET}"
  fi
fi

# ── 7. Clock (dim, small) ───────────────────────────────────────────────────
NOW="$(date '+%H:%M' 2>/dev/null || echo '')"
TIME_SEG=""
if [ -n "$NOW" ]; then
  TIME_SEG="${C_TIME}${ICO_CLOCK} ${NOW}${RESET}"
fi

# ── Assemble (两行布局) ──────────────────────────────────────────────────────
# Line 1: 品牌 · 活跃 agent（如有）· 模型 · 风格
# Line 2: 目录 ⎇ 分支 · 上下文进度 · 项目消耗 · 时钟

LINE1="$LEGION_SEG"
[ -n "$AGENT_SEG" ] && LINE1="${LINE1}${AGENT_SEG}"
[ -n "$MODEL_SEG" ] && LINE1="${LINE1}${SEP}${MODEL_SEG}"
[ -n "$STYLE_SEG" ] && LINE1="${LINE1}${SEP}${STYLE_SEG}"

LINE2=""
# 目录和"本项目累计"紧贴在一起，让"项目归属"视觉成簇
[ -n "$DIR_SEG" ]   && LINE2="${DIR_SEG}"
[ -n "$COST_SEG" ]  && LINE2="${LINE2:+${LINE2}${SEP}}${COST_SEG}"
[ -n "$BAR_SEG" ]   && LINE2="${LINE2:+${LINE2}${SEP}}${BAR_SEG}"
[ -n "$TIME_SEG" ]  && LINE2="${LINE2:+${LINE2}${SEP}}${TIME_SEG}"

if [ -n "$LINE2" ]; then
  printf "%b\n%b" "$LINE1" "$LINE2"
else
  printf "%b" "$LINE1"
fi
exit 0
