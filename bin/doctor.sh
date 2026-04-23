#!/usr/bin/env bash
# bin/doctor.sh
# Agent Legion · 系统健康检查
#
# 诊断项：
#   - settings.json / settings.local.json JSON 合法性
#   - 所有 hook 脚本可执行性 + 基本语法检查
#   - Agent 定义 frontmatter 合法性
#   - Skill 目录层级合规性（必须扁平在 skills/ 下）
#   - Rule 一致性（调用 validate-rules.sh）
#   - Memory 容量（MEMORY.md 接近 200 行上限？）
#   - Artifact 堆积（过期文件建议归档？）
#   - 日志文件大小（需要轮转？）
#   - Hook 错误日志近期事件

set -uo pipefail

LEGION_DIR="$HOME/.claude"
PROJ_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"

# ── 统计器 ────────────────────────────────────────────────────────────────
PASS=0
WARN=0
FAIL=0

pass() { printf "  \033[32m✓\033[0m %s\n" "$1"; PASS=$((PASS + 1)); }
warn() { printf "  \033[33m⚠\033[0m %s\n" "$1"; WARN=$((WARN + 1)); }
fail() { printf "  \033[31m✗\033[0m %s\n" "$1"; FAIL=$((FAIL + 1)); }
info() { printf "  \033[90mi\033[0m %s\n" "$1"; }

section() { printf "\n\033[1m%s\033[0m\n" "$1"; }

echo ""
echo "┌─────────────────────────────────────────────────┐"
echo "│  Agent Legion · Doctor                          │"
echo "└─────────────────────────────────────────────────┘"

# ── 1. 配置文件 ──────────────────────────────────────────────────────────────
section "1. Configuration"

if [ ! -f "$LEGION_DIR/settings.json" ]; then
  fail "settings.json 不存在"
else
  if python3 -c "import json; json.load(open('$LEGION_DIR/settings.json'))" 2>/dev/null; then
    pass "settings.json 合法"
  else
    fail "settings.json JSON 格式错误"
  fi
fi

if [ -f "$LEGION_DIR/settings.local.json" ]; then
  if python3 -c "import json; json.load(open('$LEGION_DIR/settings.local.json'))" 2>/dev/null; then
    pass "settings.local.json 合法"
  else
    fail "settings.local.json JSON 格式错误"
  fi
fi

# CLAUDE.md 行数
if [ -f "$LEGION_DIR/CLAUDE.md" ]; then
  LINES="$(wc -l < "$LEGION_DIR/CLAUDE.md" | tr -d ' ')"
  if [ "$LINES" -gt 200 ]; then
    warn "CLAUDE.md $LINES 行（建议 <200）"
  elif [ "$LINES" -gt 150 ]; then
    info "CLAUDE.md $LINES 行（接近上限）"
  else
    pass "CLAUDE.md $LINES 行"
  fi
fi

# ── 2. Hooks ───────────────────────────────────────────────────────────────
section "2. Hooks"

HOOK_COUNT=0
for f in "$LEGION_DIR"/hooks/*.sh "$LEGION_DIR"/hooks/_lib/*.sh; do
  [ -f "$f" ] || continue
  HOOK_COUNT=$((HOOK_COUNT + 1))
  NAME="${f#$LEGION_DIR/hooks/}"

  if [ ! -x "$f" ]; then
    fail "hooks/$NAME 不可执行（chmod +x）"
    continue
  fi

  # bash 语法检查
  if ! bash -n "$f" 2>/dev/null; then
    fail "hooks/$NAME 语法错误"
    continue
  fi

  # 检查是否用了危险的 set -e（我们已知陷阱）
  if grep -q "^set -e\|^set -euo" "$f" 2>/dev/null; then
    warn "hooks/$NAME 使用了 set -e（Claude Code hook 易触发误杀）"
  fi
done
info "扫描了 $HOOK_COUNT 个 hook 脚本"

# ── 3. Agents ──────────────────────────────────────────────────────────────
section "3. Agents"

AGENT_COUNT=0
declare -a SEEN_AGENT_NAMES
for f in "$LEGION_DIR"/agents/*.md; do
  [ -f "$f" ] || continue
  AGENT_COUNT=$((AGENT_COUNT + 1))
  BASENAME="$(basename "$f" .md)"

  # frontmatter 必须以 --- 开始
  FIRST="$(head -1 "$f")"
  if [ "$FIRST" != "---" ]; then
    fail "agents/$BASENAME.md 无 frontmatter"
    continue
  fi

  # 提取 name 字段
  NAME="$(awk '/^---$/{c++; if(c==2)exit; next} c==1 && /^name:/ {sub(/^name:[[:space:]]*/, ""); print; exit}' "$f")"
  if [ -z "$NAME" ]; then
    fail "agents/$BASENAME.md 缺 name 字段"
  elif [ "$NAME" != "$BASENAME" ]; then
    warn "agents/$BASENAME.md 的 name=$NAME 与文件名不一致"
  fi

  # 检查 permissionMode（我们约定全部 bypassPermissions）
  if ! grep -q "^permissionMode:" "$f"; then
    warn "agents/$BASENAME.md 未设 permissionMode"
  fi
done
pass "$AGENT_COUNT 个 Agent 定义"

# ── 4. Skills ───────────────────────────────────────────────────────────────
section "4. Skills"

SKILL_COUNT=0
NESTED_WRONG=0
MISSING_SKILL_MD=0
for d in "$LEGION_DIR"/skills/*/; do
  [ -d "$d" ] || continue
  DIRNAME="$(basename "$d")"

  # 检查是否有 SKILL.md
  if [ ! -f "$d/SKILL.md" ]; then
    # 也许是个分类子目录（旧结构）？检查嵌套
    if find "$d" -mindepth 2 -name "SKILL.md" -type f 2>/dev/null | grep -q .; then
      fail "skills/$DIRNAME/ 下有嵌套的 SKILL.md（Claude Code 不识别此结构）"
      NESTED_WRONG=$((NESTED_WRONG + 1))
    else
      warn "skills/$DIRNAME/ 不含 SKILL.md"
      MISSING_SKILL_MD=$((MISSING_SKILL_MD + 1))
    fi
    continue
  fi

  SKILL_COUNT=$((SKILL_COUNT + 1))

  # frontmatter 检查
  FIRST="$(head -1 "$d/SKILL.md")"
  [ "$FIRST" != "---" ] && fail "skills/$DIRNAME/SKILL.md 无 frontmatter"

  NAME="$(awk '/^---$/{c++; if(c==2)exit; next} c==1 && /^name:/ {sub(/^name:[[:space:]]*/, ""); print; exit}' "$d/SKILL.md")"
  [ -z "$NAME" ] && fail "skills/$DIRNAME/SKILL.md 缺 name"

  # 描述长度（<1536 字符推荐）
  DESC="$(awk '/^---$/{c++; if(c==2)exit; next} c==1 && /^description:/ {sub(/^description:[[:space:]]*/, ""); print; exit}' "$d/SKILL.md")"
  if [ ${#DESC} -gt 1536 ]; then
    warn "skills/$DIRNAME description 过长（${#DESC} 字符，上限 1536）"
  fi
done
pass "$SKILL_COUNT 个 Skill（扁平结构）"
[ "$NESTED_WRONG" -gt 0 ] && fail "$NESTED_WRONG 个嵌套 SKILL.md（不会被发现）"

# ── 5. Rules ────────────────────────────────────────────────────────────────
section "5. Rules"

if [ -f "$LEGION_DIR/bin/validate-rules.sh" ]; then
  VALIDATE_OUT="$(bash "$LEGION_DIR/bin/validate-rules.sh" 2>&1 | tail -20)"
  TOTAL_R="$(echo "$VALIDATE_OUT" | grep -E "^  Total rules:" | awk '{print $NF}')"
  DUP_R="$(echo "$VALIDATE_OUT" | grep -E "^  Duplicate names:" | awk '{print $NF}')"
  DEAD_R="$(echo "$VALIDATE_OUT" | grep -E "^  Dead globs:" | awk '{print $3}')"

  [ -n "$TOTAL_R" ] && pass "$TOTAL_R 个 Rule"
  [ "${DUP_R:-0}" -gt 0 ] && fail "$DUP_R 个重复名 Rule"
  if [ -n "${DEAD_R:-}" ] && [ "$DEAD_R" -gt 0 ]; then
    info "$DEAD_R 个 Rule 在当前目录下无匹配文件（可能正常，取决于 pwd）"
  fi
else
  warn "bin/validate-rules.sh 不存在"
fi

# ── 6. Memory ───────────────────────────────────────────────────────────────
section "6. Memory"

# Auto Memory
AUTO_MEM_DIR="$(find "$HOME/.claude/projects" -type d -name memory 2>/dev/null | head -1)"
if [ -n "$AUTO_MEM_DIR" ] && [ -f "$AUTO_MEM_DIR/MEMORY.md" ]; then
  LINES="$(wc -l < "$AUTO_MEM_DIR/MEMORY.md" | tr -d ' ')"
  if [ "$LINES" -gt 180 ]; then
    warn "Auto Memory MEMORY.md $LINES 行（接近 200 行上限，考虑 /bcc-evolve）"
  else
    pass "Auto Memory $LINES/200 行"
  fi
fi

# Agent Memory 目录
AGENT_MEM_COUNT=0
if [ -d "$HOME/.claude/agent-memory" ]; then
  for d in "$HOME/.claude/agent-memory"/*/; do
    [ -d "$d" ] || continue
    AGENT_MEM_COUNT=$((AGENT_MEM_COUNT + 1))
    if [ -f "$d/MEMORY.md" ]; then
      L="$(wc -l < "$d/MEMORY.md" | tr -d ' ')"
      [ "$L" -gt 180 ] && warn "$(basename "$d") Agent Memory $L 行"
    fi
  done
fi
info "$AGENT_MEM_COUNT 个 Agent 有独立 Memory"

# ── 7. Artifacts（项目级） ───────────────────────────────────────────────────
section "7. Artifacts"

if [ -d "$PROJ_DIR/.claude/artifacts" ]; then
  TOTAL="$(find "$PROJ_DIR/.claude/artifacts" -maxdepth 1 -name "*.md" -type f 2>/dev/null | wc -l | tr -d ' ')"
  OLD="$(find "$PROJ_DIR/.claude/artifacts" -maxdepth 1 -name "*.md" -mtime +30 2>/dev/null | wc -l | tr -d ' ')"

  if [ "$TOTAL" -eq 0 ]; then
    info "当前项目无 artifact"
  else
    info "当前项目 $TOTAL 个 artifact"
    [ "$OLD" -gt 10 ] && warn "$OLD 个 artifact 超过 30 天，建议归档到 artifacts/archive/"
  fi
fi

# ── 8. Logs ─────────────────────────────────────────────────────────────────
section "8. Logs"

check_log_size() {
  local path="$1"
  local threshold_mb="$2"
  local label="$3"

  [ ! -f "$path" ] && return

  local size_bytes="$(stat -f%z "$path" 2>/dev/null || stat -c%s "$path" 2>/dev/null || echo 0)"
  local size_mb=$((size_bytes / 1048576))

  if [ "$size_mb" -gt "$threshold_mb" ]; then
    warn "$label: ${size_mb}MB（建议轮转，运行 \`bash ~/.claude/bin/rotate-logs.sh\`）"
  else
    pass "$label: ${size_mb}MB（阈值 ${threshold_mb}MB）"
  fi
}

check_log_size "$HOME/.claude/logs/subagent-events.jsonl" 50 "subagent-events.jsonl"
check_log_size "$HOME/.claude/logs/hook-errors.log" 5 "hook-errors.log（全局）"
check_log_size "$PROJ_DIR/.claude/cost-log.txt" 10 "cost-log.txt（项目）"
check_log_size "$PROJ_DIR/.claude/hook-errors.log" 5 "hook-errors.log（项目）"
check_log_size "$PROJ_DIR/.claude/instructions-log.txt" 20 "instructions-log.txt（项目）"

# ── 9. Recent Hook Errors ──────────────────────────────────────────────────
section "9. Recent Hook Errors (近 5 条)"

ERR_LOG="$HOME/.claude/logs/hook-errors.log"
if [ -f "$ERR_LOG" ] && [ -s "$ERR_LOG" ]; then
  RECENT="$(tail -5 "$ERR_LOG" 2>/dev/null)"
  if [ -n "$RECENT" ]; then
    echo "$RECENT" | while IFS= read -r line; do info "$line"; done
    warn "有 hook 错误记录，检查完整日志: tail -50 $ERR_LOG"
  fi
else
  pass "无 hook 错误记录"
fi

# ── 10. MCP ────────────────────────────────────────────────────────────────
section "10. MCP"

MCP_COUNT="$(python3 -c "
import json
try:
  d=json.load(open('$LEGION_DIR/settings.json'))
  print(len(d.get('mcpServers', {})))
except: print(0)
" 2>/dev/null || echo 0)"
info "配置了 $MCP_COUNT 个 MCP 服务器"

# 检查 github PAT 是否仍是占位符
if grep -q "REPLACE_WITH_YOUR_GITHUB_PAT" "$LEGION_DIR/settings.json" 2>/dev/null; then
  warn "github MCP 的 GITHUB_PERSONAL_ACCESS_TOKEN 仍是占位符"
fi

# ── 汇总 ────────────────────────────────────────────────────────────────────
echo ""
echo "═════════════════════════════════════════════════"
printf "  Summary: \033[32m%d passed\033[0m | \033[33m%d warnings\033[0m | \033[31m%d failures\033[0m\n" \
  "$PASS" "$WARN" "$FAIL"
echo "═════════════════════════════════════════════════"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
