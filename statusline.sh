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
SEP="${C_SEP} · ${RESET}"

# ── Read stdin JSON ──────────────────────────────────────────────────────────
INPUT="$(cat 2>/dev/null || echo '{}')"

jq_get() { echo "$INPUT" | jq -r "$1 // empty" 2>/dev/null; }

# ── Session ID (for active-subagent detection) ──────────────────────────────
SESSION_ID="$(jq_get '.session_id')"

STATE_LIB="$HOME/.claude/hooks/_lib/legion-state.sh"
[ -r "$STATE_LIB" ] && . "$STATE_LIB"

TERM_COLUMNS="${COLUMNS:-120}"
case "$TERM_COLUMNS" in
  ''|*[!0-9]*) TERM_COLUMNS=120 ;;
esac
COMPACT=0
[ "$TERM_COLUMNS" -lt 100 ] && COMPACT=1

shorten_task_id() {
  local task_id="$1"
  local max_len="${2:-28}"
  local short=""

  [ -n "$task_id" ] || return 0
  if [ "${#task_id}" -le "$max_len" ]; then
    printf '%s\n' "$task_id"
    return 0
  fi

  short="$(printf '%s\n' "$task_id" | awk -F- 'NF >= 3 {print $1 "…" $(NF-1) "-" $NF; next} {print substr($0,1,10) "…" substr($0,length($0)-9)}')"
  printf '%s\n' "$short"
}

fmt_elapsed() {
  local elapsed="${1:-0}"
  if [ "$elapsed" -lt 60 ]; then
    printf '%ss\n' "$elapsed"
  elif [ "$elapsed" -lt 3600 ]; then
    printf '%dm%02ds\n' "$(( elapsed / 60 ))" "$(( elapsed % 60 ))"
  else
    printf '%dh%02dm\n' "$(( elapsed / 3600 ))" "$(( (elapsed % 3600) / 60 ))"
  fi
}

abbr_final_confirmation() {
  case "$1" in
    required) printf 'req' ;;
    asked) printf 'ask' ;;
    accepted) printf 'ok' ;;
    continue_requested) printf 'cont' ;;
    specified_check) printf 'spec' ;;
    *) printf '%s' "$1" ;;
  esac
}

# ── 1. LEGION brand prefix ──────────────────────────────────────────────────
LEGION_SEG="${BOLD}${C_LEGION}${ICO_LEGION} LEGION${RESET}"

# ── 1b. Active subagent badge (supports N concurrent agents) ────────────────
AGENT_SEG=""
if [ -n "$SESSION_ID" ]; then
  NOW_TS="$(date +%s)"
  ACTIVE_NAMES=()
  MAX_ELAPSED=0
  ACTIVE_TTL="${CLAUDE_LEGION_ACTIVE_TTL_SECONDS:-21600}"
  case "$ACTIVE_TTL" in
    ''|*[!0-9]*) ACTIVE_TTL=21600 ;;
  esac

  shopt -s nullglob 2>/dev/null || true
  for STATE_FILE in /tmp/claude-legion-active-${SESSION_ID}-*; do
    [ -f "$STATE_FILE" ] || continue
    NAME="$(jq -r '.agent_type // empty' "$STATE_FILE" 2>/dev/null || echo "")"
    START="$(jq -r '.started_at // empty' "$STATE_FILE" 2>/dev/null || echo "")"
    if [ -z "$NAME" ]; then
      # Legacy TSV written before active state moved to JSON.
      NAME="$(awk -F'\t' 'NR==1 {print $1}' "$STATE_FILE" 2>/dev/null || echo "")"
      START="$(awk -F'\t' 'NR==1 {print $2}' "$STATE_FILE" 2>/dev/null || echo "")"
    fi
    [ -z "$NAME" ] && continue
    case "$START" in
      ''|*[!0-9]*) START="$NOW_TS" ;;
    esac

    ELAPSED=$(( NOW_TS - START ))
    if [ "$ELAPSED" -lt 0 ] || [ "$ELAPSED" -gt "$ACTIVE_TTL" ]; then
      rm -f "$STATE_FILE" 2>/dev/null || true
      continue
    fi
    [ "$ELAPSED" -gt "$MAX_ELAPSED" ] && MAX_ELAPSED=$ELAPSED
    ACTIVE_NAMES+=("$NAME")
  done

  if [ ${#ACTIVE_NAMES[@]} -gt 0 ]; then
    ELAPSED_STR="$(fmt_elapsed "$MAX_ELAPSED")"

    if [ ${#ACTIVE_NAMES[@]} -eq 1 ]; then
      LABEL="${ACTIVE_NAMES[0]} · ${ELAPSED_STR}"
    else
      SUMMARY="$(printf '%s\n' "${ACTIVE_NAMES[@]}" | sort | uniq -c | awk '{name=$2; for (i=3;i<=NF;i++) name=name " " $i; item=$1 "x " name; out=(out==""?item:out " · " item)} END {print out}')"
      LABEL="${SUMMARY:-${#ACTIVE_NAMES[@]}x} · max ${ELAPSED_STR}"
    fi

    AGENT_SEG=" ${C_AGENT_BG}${C_AGENT_FG}${BOLD} ${ICO_AGENT} 代理 ${LABEL} ${RESET}"
  fi
fi

# ── 1c. Agent Teams badge (if team config exists) ─────────────────────────
TEAMS_SEG=""
TEAMS_DIR="$HOME/.claude/teams"
if [ -d "$TEAMS_DIR" ] && command -v jq >/dev/null 2>&1; then
  TEAM_COUNT=0
  IDLE_COUNT=0
  for TEAM_DIR in "$TEAMS_DIR"/*/; do
    [ -d "$TEAM_DIR" ] || continue
    CONFIG_FILE="${TEAM_DIR}config.json"
    [ -f "$CONFIG_FILE" ] || continue
    MEMBERS="$(jq -r '.members // [] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)"
    [ "$MEMBERS" -gt 0 ] || continue
    TEAM_COUNT=$(( TEAM_COUNT + 1 ))
    IDLE_MEMBERS="$(jq -r '[.members[] | select(.status == "idle" or .status == "stopped")] | length' "$CONFIG_FILE" 2>/dev/null || echo 0)"
    IDLE_COUNT=$(( IDLE_COUNT + IDLE_MEMBERS ))
  done
  if [ "$TEAM_COUNT" -gt 0 ]; then
    C_TEAMS="\033[38;2;139;92;246m"
    ICO_TEAMS="⬡"
    if [ "$COMPACT" -eq 1 ]; then
      TEAMS_SEG=" ${C_TEAMS}${ICO_TEAMS}${TEAM_COUNT}T${RESET}"
    else
      TEAMS_SEG=" ${C_TEAMS}${ICO_TEAMS} 团队 ${TEAM_COUNT}${RESET}"
    fi
  fi
fi

# ── 2. Model ────────────────────────────────────────────────────────────────
MODEL="$(jq_get '.model.display_name')"
[ -z "$MODEL" ] && MODEL="$(jq_get '.model.id')"
# 简化：去掉括号注释 "(1M context)" / "[high]" 等冗余（用 bash 字符串切，BSD/GNU 通用）
MODEL="${MODEL%% (*}"
MODEL="${MODEL%% [*}"
MODEL="${MODEL%"${MODEL##*[![:space:]]}"}"  # 右侧 trim
MODEL_SEG=""
if [ -n "$MODEL" ]; then
  MODEL_SEG="${C_TOKEN}模型${RESET} ${C_MODEL}${ICO_MODEL} ${MODEL}${RESET}"
fi

# ── 2b. Permission mode ────────────────────────────────────────────────────
PERMISSION_MODE="$(jq_get '.permission_mode')"
[ -z "$PERMISSION_MODE" ] && PERMISSION_MODE="$(jq_get '.permissions.mode')"
PERMISSION_SEG=""
if [ -n "$PERMISSION_MODE" ]; then
  case "$PERMISSION_MODE" in
    bypassPermissions|dangerously-skip-permissions)
      PERMISSION_LABEL="bypass"; PERMISSION_COLOR="$C_BAR_CRIT" ;;
    acceptEdits)
      PERMISSION_LABEL="accept-edits"; PERMISSION_COLOR="$C_BAR_LOW" ;;
    plan)
      PERMISSION_LABEL="plan"; PERMISSION_COLOR="$C_BAR_MID" ;;
    default)
      PERMISSION_LABEL="default"; PERMISSION_COLOR="$C_TOKEN" ;;
    *)
      PERMISSION_LABEL="$PERMISSION_MODE"; PERMISSION_COLOR="$C_TOKEN" ;;
  esac
  if [ "$COMPACT" -eq 1 ]; then
    PERMISSION_SEG="${C_TOKEN}P${RESET} ${PERMISSION_COLOR}${PERMISSION_LABEL}${RESET}"
  else
    PERMISSION_SEG="${C_TOKEN}权限${RESET} ${PERMISSION_COLOR}${PERMISSION_LABEL}${RESET}"
  fi
fi

# ── 3. Output style (if custom) ─────────────────────────────────────────────
STYLE="$(jq_get '.output_style.name')"
STYLE_SEG=""
# 隐藏默认 / Legion 自身 style（避免每行都有冗余）；其他自定义 style 才显示
case "$STYLE" in
  ""|default|legion-dispatch) ;;
  *) STYLE_SEG="${C_TOKEN}风格${RESET} ${C_STYLE}${ICO_STYLE} ${STYLE}${RESET}" ;;
esac

# ── 4. Directory + Git state ────────────────────────────────────────────────
CWD="$(jq_get '.workspace.current_dir')"
[ -z "$CWD" ] && CWD="$(jq_get '.workspace.project_dir')"
[ -z "$CWD" ] && CWD="$(pwd 2>/dev/null || echo '')"

DIR_SEG=""
BRANCH_SEG=""
TASK_SEG=""
PHASE_SEG=""
RISK_SEG=""
GATES_SEG=""
EVIDENCE_SEG=""
UNDERSTANDING_SEG=""
ITER_SEG=""
CONFIRM_SEG=""
if [ -n "$CWD" ]; then
  BASENAME="$(basename "$CWD" 2>/dev/null || echo '?')"
  DIR_SEG="${C_TOKEN}项目${RESET} ${C_DIR}${ICO_DIR} ${BASENAME}${RESET}"

  # DispatchTicket / gate state. Never guess: no state means no-ticket.
  STATE_FILE=""
  if command -v legion_state_file >/dev/null 2>&1; then
    STATE_FILE="$(legion_state_file "$CWD" 2>/dev/null || echo "")"
  fi
  if [ -n "$STATE_FILE" ] && [ -r "$STATE_FILE" ] && command -v jq >/dev/null 2>&1; then
    TASK_ID="$(jq -r '.task_id // "no-task"' "$STATE_FILE" 2>/dev/null || echo "no-task")"
    PHASE="$(jq -r '.phase // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
    RISK="$(jq -r '.risk // "unknown"' "$STATE_FILE" 2>/dev/null || echo "unknown")"
    QUALITY="$(jq -r '.quality_strategy // "adversarial-default"' "$STATE_FILE" 2>/dev/null || echo "adversarial-default")"

    case "$RISK" in
      low)      C_RISK="$C_BAR_LOW" ;;
      medium)   C_RISK="$C_BAR_MID" ;;
      high)     C_RISK="$C_BAR_HIGH" ;;
      critical) C_RISK="$C_BAR_CRIT" ;;
      *)        C_RISK="$C_TOKEN" ;;
    esac
    case "$QUALITY" in
      compressed) Q_LABEL="fast" ;;
      full) Q_LABEL="full" ;;
      *) Q_LABEL="adv" ;;
    esac

    TASK_DISPLAY="$(shorten_task_id "$TASK_ID" "$([ "$COMPACT" -eq 1 ] && echo 20 || echo 34)")"
    if [ "$COMPACT" -eq 1 ]; then
      TASK_SEG="${C_TOKEN}T${RESET} ${C_STYLE}${TASK_DISPLAY}${RESET}"
      PHASE_SEG="${C_TOKEN}P${RESET} ${C_MODEL}${PHASE}${RESET}"
      RISK_SEG="${C_TOKEN}R${RESET} ${C_RISK}${RISK}${RESET} ${C_TOKEN}${Q_LABEL}${RESET}"
    else
      TASK_SEG="${C_TOKEN}任务${RESET} ${C_STYLE}${TASK_DISPLAY}${RESET}"
      PHASE_SEG="${C_TOKEN}阶段${RESET} ${C_MODEL}${PHASE}${RESET}"
      RISK_SEG="${C_TOKEN}风险${RESET} ${C_RISK}${RISK}${RESET} ${C_TOKEN}${Q_LABEL}${RESET}"
    fi

    GATE_LABELS=""
    REQUIRED_GATES="$(jq -r '.required_gates[]? // empty' "$STATE_FILE" 2>/dev/null || true)"
    while IFS= read -r gate; do
      [ -z "$gate" ] && continue
      GATE_STATE="$(jq -r --arg g "$gate" '.gate_status[$g] // "pending"' "$STATE_FILE" 2>/dev/null || echo "pending")"
      GATE_DISPLAY="$gate"
      if [ "$COMPACT" -eq 1 ]; then
        case "$gate" in
          code) GATE_DISPLAY="c" ;;
          security) GATE_DISPLAY="s" ;;
          functional) GATE_DISPLAY="f" ;;
          visual) GATE_DISPLAY="v" ;;
          verdict) GATE_DISPLAY="vd" ;;
          impl) GATE_DISPLAY="i" ;;
        esac
      fi
      case "$GATE_STATE" in
        pass|passed|accepted|PASS) MARK="${C_BAR_LOW}✓${RESET}" ;;
        CONDITIONAL_PASS|conditional_pass|conditional) MARK="${C_BAR_MID}~${RESET}" ;;
        blocked|reject|rejected|fail|failed|BLOCKED) MARK="${C_BAR_CRIT}×${RESET}" ;;
        skipped_by_user|not_applicable) MARK="${C_TOKEN}-${RESET}" ;;
        *) MARK="${C_BAR_MID}…${RESET}" ;;
      esac
      GATE_LABELS="${GATE_LABELS}${GATE_LABELS:+ }${GATE_DISPLAY}:${MARK}"
    done <<< "$REQUIRED_GATES"
    if [ -n "$GATE_LABELS" ]; then
      if [ "$COMPACT" -eq 1 ]; then
        GATES_SEG="${C_TOKEN}G${RESET} ${GATE_LABELS}"
      else
        GATES_SEG="${C_TOKEN}门控${RESET} ${GATE_LABELS}"
      fi
    fi

    IMPL_COUNT="$(jq -r '.evidence.impl_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
    REVIEW_COUNT="$(jq -r '.evidence.review_count // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
    EVIDENCE_SEG="${C_TOKEN}证据${RESET} impl:${IMPL_COUNT} review:${REVIEW_COUNT}"

    UNDERSTANDING_STATUS="$(jq -r '.understanding.status // empty' "$STATE_FILE" 2>/dev/null || echo "")"
    UNDERSTANDING_CONF="$(jq -r '.understanding.confidence // empty' "$STATE_FILE" 2>/dev/null || echo "")"
    ITER_MODE="$(jq -r '.iteration.mode // empty' "$STATE_FILE" 2>/dev/null || echo "")"
    ITER_ROUND="$(jq -r '.iteration.round // 0' "$STATE_FILE" 2>/dev/null || echo 0)"
    FINAL_CONFIRMATION="$(jq -r '.final_confirmation // empty' "$STATE_FILE" 2>/dev/null || echo "")"

    if [ -n "$UNDERSTANDING_STATUS" ]; then
      case "$UNDERSTANDING_STATUS" in
        clear) C_UNDER="$C_BAR_LOW" ;;
        assumed) C_UNDER="$C_BAR_MID" ;;
        needs_user|missing_asset|contradictory) C_UNDER="$C_BAR_CRIT" ;;
        *) C_UNDER="$C_TOKEN" ;;
      esac
      CONF_LABEL=""
      if [ -n "$UNDERSTANDING_CONF" ] && [ "$UNDERSTANDING_CONF" != "null" ]; then
        if [ "$COMPACT" -eq 1 ]; then
          CONF_LABEL=":$(printf '%s' "$UNDERSTANDING_CONF" | sed 's/^0//')"
        else
          CONF_LABEL=":${UNDERSTANDING_CONF}"
        fi
      fi
      if [ "$COMPACT" -eq 1 ]; then
        UNDERSTANDING_SEG="${C_TOKEN}U${RESET} ${C_UNDER}${UNDERSTANDING_STATUS}${CONF_LABEL}${RESET}"
      else
        UNDERSTANDING_SEG="${C_TOKEN}理解${RESET} ${C_UNDER}${UNDERSTANDING_STATUS}${CONF_LABEL}${RESET}"
      fi
    fi
    if [ -n "$ITER_MODE" ] || [ "${ITER_ROUND:-0}" != "0" ]; then
      ITER_LABEL="${ITER_MODE:-iter}"
      if [ "$COMPACT" -eq 1 ]; then
        case "$ITER_LABEL" in
          until_pass) ITER_LABEL="pass" ;;
        esac
        ITER_SEG="${C_TOKEN}I${RESET} ${C_MODEL}${ITER_LABEL}#${ITER_ROUND:-0}${RESET}"
      else
        ITER_SEG="${C_TOKEN}迭代${RESET} ${C_MODEL}${ITER_LABEL}#${ITER_ROUND:-0}${RESET}"
      fi
    fi
    if [ -n "$FINAL_CONFIRMATION" ]; then
      case "$FINAL_CONFIRMATION" in
        accepted) C_CONFIRM="$C_BAR_LOW" ;;
        asked|required|continue_requested|specified_check) C_CONFIRM="$C_BAR_MID" ;;
        *) C_CONFIRM="$C_TOKEN" ;;
      esac
      if [ "$COMPACT" -eq 1 ]; then
        CONFIRM_SEG="${C_TOKEN}C${RESET} ${C_CONFIRM}$(abbr_final_confirmation "$FINAL_CONFIRMATION")${RESET}"
      else
        CONFIRM_SEG="${C_TOKEN}确认${RESET} ${C_CONFIRM}${FINAL_CONFIRMATION}${RESET}"
      fi
    fi
  else
    if [ "$COMPACT" -eq 1 ]; then
      TASK_SEG="${C_TOKEN}T${RESET} ${C_BAR_EMPTY}no-ticket${RESET}"
    else
      TASK_SEG="${C_TOKEN}任务${RESET} ${C_BAR_EMPTY}no-ticket${RESET}"
    fi
  fi

  # Git info（独立成段，与项目用 SEP 分隔，不再粘在一起）
  if git -C "$CWD" --no-optional-locks rev-parse --git-dir &>/dev/null; then
    BRANCH="$(git -C "$CWD" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null \
              || git -C "$CWD" --no-optional-locks rev-parse --short HEAD 2>/dev/null \
              || echo '')"
    if [ -n "$BRANCH" ]; then
      # Dirty check：用中文 "(改)" 替代 ● 字符，加空格分开 branch 名
      DIRTY_NOTE=""
      if ! git -C "$CWD" --no-optional-locks diff --quiet 2>/dev/null \
         || ! git -C "$CWD" --no-optional-locks diff --cached --quiet 2>/dev/null; then
        DIRTY_NOTE=" ${C_GIT_DIRTY}(改)${RESET}"
      fi

      # Ahead/behind (only if upstream exists)
      AHEAD_BEHIND=""
      UPSTREAM="$(git -C "$CWD" --no-optional-locks rev-parse --abbrev-ref '@{u}' 2>/dev/null || echo '')"
      if [ -n "$UPSTREAM" ]; then
        COUNTS="$(git -C "$CWD" --no-optional-locks rev-list --left-right --count "HEAD...@{u}" 2>/dev/null || echo '0	0')"
        AHEAD="$(echo "$COUNTS" | awk '{print $1}')"
        BEHIND="$(echo "$COUNTS" | awk '{print $2}')"
        [ "${AHEAD:-0}" != "0" ] && AHEAD_BEHIND="${AHEAD_BEHIND} ${C_GIT_AHEAD}${UP_SYM}${AHEAD}${RESET}"
        [ "${BEHIND:-0}" != "0" ] && AHEAD_BEHIND="${AHEAD_BEHIND} ${C_GIT_BEHIND}${DN_SYM}${BEHIND}${RESET}"
      fi

      BRANCH_SEG="${C_TOKEN}分支${RESET} ${C_GIT}${BR_SYM} ${BRANCH}${RESET}${DIRTY_NOTE}${AHEAD_BEHIND}"
    fi
  fi
fi

# ── 5. Context bar (gradient fill) ──────────────────────────────────────────
USED_PCT="$(jq_get '.context_window.used_percentage')"
CTX_SIZE="$(jq_get '.context_window.context_window_size')"
INPUT_TOKENS="$(jq_get '.context_window.current_usage.input_tokens')"
# Fallback: total_input_tokens (available even when current_usage is null)
TOTAL_INPUT="$(jq_get '.context_window.total_input_tokens')"

# 如果 used_percentage 为 null，尝试从 total_input_tokens / context_window_size 推算
if [ -z "$USED_PCT" ] || [ "$USED_PCT" = "null" ]; then
  EFFECTIVE_TOKENS="${INPUT_TOKENS}"
  ([ -z "$EFFECTIVE_TOKENS" ] || [ "$EFFECTIVE_TOKENS" = "null" ]) && EFFECTIVE_TOKENS="${TOTAL_INPUT}"
  if [ -n "$EFFECTIVE_TOKENS" ] && [ "$EFFECTIVE_TOKENS" != "null" ] && [ -n "$CTX_SIZE" ] && [ "$CTX_SIZE" != "null" ] && [ "$CTX_SIZE" -gt 0 ] 2>/dev/null; then
    USED_PCT="$(( EFFECTIVE_TOKENS * 100 / CTX_SIZE ))"
  fi
fi
# 如果 input_tokens 为 null，用 total_input_tokens 替代
if [ -z "$INPUT_TOKENS" ] || [ "$INPUT_TOKENS" = "null" ]; then
  INPUT_TOKENS="${TOTAL_INPUT}"
fi

BAR_SEG=""
if [ -n "$USED_PCT" ] && [ "$USED_PCT" != "null" ]; then
  PCT="$(printf "%.0f" "$USED_PCT" 2>/dev/null || echo "0")"

  # Choose primary color based on usage
  if   [ "$PCT" -ge 90 ]; then BAR_COLOR="$C_BAR_CRIT"
  elif [ "$PCT" -ge 75 ]; then BAR_COLOR="$C_BAR_HIGH"
  elif [ "$PCT" -ge 50 ]; then BAR_COLOR="$C_BAR_MID"
  else                         BAR_COLOR="$C_BAR_LOW"
  fi

  # 10-slot bar — 紧凑窄屏友好
  TOTAL_SLOTS=10
  FILLED=$(( PCT * TOTAL_SLOTS / 100 ))
  [ "$FILLED" -gt "$TOTAL_SLOTS" ] && FILLED=$TOTAL_SLOTS
  EMPTY=$(( TOTAL_SLOTS - FILLED ))

  BAR="${BAR_COLOR}"
  for (( i=0; i<FILLED; i++ )); do BAR="${BAR}▰"; done
  BAR="${BAR}${C_BAR_EMPTY}"
  for (( i=0; i<EMPTY;  i++ )); do BAR="${BAR}▱"; done
  BAR="${BAR}${RESET}"

  # Token label：仅在 token > 0 时附加 K 数（避免显示 "0K"）
  LABEL="${BAR_COLOR}${PCT}%${RESET}"
  if [ -n "$INPUT_TOKENS" ] && [ "$INPUT_TOKENS" != "null" ] && [ "$INPUT_TOKENS" -gt 500 ]; then
    USED_K=$(( INPUT_TOKENS / 1000 ))
    [ "$USED_K" -gt 0 ] && LABEL="${LABEL}${C_TOKEN} ${USED_K}K${RESET}"
  fi

  if [ "$COMPACT" -eq 1 ]; then
    BAR_SEG="${C_TOKEN}CTX${RESET} ${LABEL}"
  else
    BAR_SEG="${C_TOKEN}上下文${RESET} ${BAR} ${LABEL}"
  fi
fi

# ── 6. Project cost aggregate (only if cost-log.txt exists in cwd/.claude) ──
COST_SEG=""
if [ -n "$CWD" ] && [ -f "$CWD/.claude/logs/cost-log.txt" ]; then
  COST_LINE="$(awk -F'\t' '
    NR==1 {next}
    {c++; in_t+=$5; out_t+=$6; cr+=$7; rd+=$8}
    END {printf "%d %d %d %d %d", c+0, in_t+0, out_t+0, cr+0, rd+0}
  ' "$CWD/.claude/logs/cost-log.txt" 2>/dev/null)"

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

    # 中文标签 + 紧凑数值
    COST_SEG="${C_TOKEN}成本${RESET} ${C_COST_ICO}${ICO_SUM}${RESET} ${C_COST_CALL}${CALLS}${RESET} ${NUM_COLOR}${IN_STR}↓${OUT_STR}↑${RESET}"
  fi
fi

# ── 7. Clock (dim, small) ───────────────────────────────────────────────────
NOW="$(date '+%H:%M' 2>/dev/null || echo '')"
TIME_SEG=""
if [ -n "$NOW" ]; then
  if [ "$COMPACT" -eq 1 ]; then
    TIME_SEG="${C_TIME}${ICO_CLOCK} ${NOW}${RESET}"
  else
    TIME_SEG="${C_TOKEN}时间${RESET} ${C_TIME}${ICO_CLOCK} ${NOW}${RESET}"
  fi
fi

# ── Assemble (两行布局) ──────────────────────────────────────────────────────
# Line 1: 品牌 · 活跃 agent（如有）· 模型 · 权限
# Line 2: task · phase · risk · gates · understanding · iteration · confirm · context · time

LINE1="$LEGION_SEG"
[ -n "$AGENT_SEG" ] && LINE1="${LINE1}${AGENT_SEG}"
[ -n "$TEAMS_SEG" ] && LINE1="${LINE1}${TEAMS_SEG}"
[ -n "$MODEL_SEG" ] && LINE1="${LINE1}${SEP}${MODEL_SEG}"
[ -n "$PERMISSION_SEG" ] && LINE1="${LINE1}${SEP}${PERMISSION_SEG}"
[ -n "$STYLE_SEG" ] && LINE1="${LINE1}${SEP}${STYLE_SEG}"

LINE2=""
[ -n "$TASK_SEG" ]   && LINE2="${TASK_SEG}"
[ -n "$PHASE_SEG" ]  && LINE2="${LINE2:+${LINE2}${SEP}}${PHASE_SEG}"
[ -n "$RISK_SEG" ]   && LINE2="${LINE2:+${LINE2}${SEP}}${RISK_SEG}"
[ -n "$GATES_SEG" ]  && LINE2="${LINE2:+${LINE2}${SEP}}${GATES_SEG}"
[ -n "$UNDERSTANDING_SEG" ] && LINE2="${LINE2:+${LINE2}${SEP}}${UNDERSTANDING_SEG}"
[ -n "$ITER_SEG" ] && LINE2="${LINE2:+${LINE2}${SEP}}${ITER_SEG}"
[ -n "$CONFIRM_SEG" ] && LINE2="${LINE2:+${LINE2}${SEP}}${CONFIRM_SEG}"
[ -n "$BAR_SEG" ]    && LINE2="${LINE2:+${LINE2}${SEP}}${BAR_SEG}"
[ -n "$TIME_SEG" ]   && LINE2="${LINE2:+${LINE2}${SEP}}${TIME_SEG}"

if [ -n "$LINE2" ]; then
  printf "%b\n%b" "$LINE1" "$LINE2"
else
  printf "%b" "$LINE1"
fi
exit 0
