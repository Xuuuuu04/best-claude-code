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

SETTINGS_PATH="$LEGION_DIR/settings.json"
if [ ! -f "$SETTINGS_PATH" ] && [ -f "$LEGION_DIR/settings.example.json" ]; then
  SETTINGS_PATH="$LEGION_DIR/settings.example.json"
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

if [ -f "$SETTINGS_PATH" ]; then
  DEFAULT_MODE="$(python3 -c "
import json
d=json.load(open('$SETTINGS_PATH'))
print(d.get('permissions', {}).get('defaultMode', ''))
" 2>/dev/null || true)"
  if [ "$DEFAULT_MODE" = "dontAsk" ]; then
    warn "$(basename "$SETTINGS_PATH") permissions.defaultMode=dontAsk（偏激进）"
  elif [ -n "$DEFAULT_MODE" ]; then
    pass "$(basename "$SETTINGS_PATH") permissions.defaultMode=$DEFAULT_MODE"
  fi

  SKIP_DANGEROUS="$(python3 -c "
import json
d=json.load(open('$SETTINGS_PATH'))
print(str(d.get('skipDangerousModePermissionPrompt', False)).lower())
" 2>/dev/null || true)"
  if [ "$SKIP_DANGEROUS" = "true" ]; then
    warn "$(basename "$SETTINGS_PATH") 跳过危险权限提示（偏激进）"
  else
    pass "$(basename "$SETTINGS_PATH") 保留危险权限提示"
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

if [ -f "$SETTINGS_PATH" ]; then
  if grep -q "scope-lock-guard.sh" "$SETTINGS_PATH" 2>/dev/null; then
    pass "PreToolUse 已启用 scope-lock-guard"
  else
    warn "PreToolUse 未启用 scope-lock-guard（文档与默认配置不一致）"
  fi
fi

# ── 3. Agents ──────────────────────────────────────────────────────────────
section "3. Agents"

AGENT_COUNT=0
MEMORY_DRIFT=0
PRELOAD_HEAVY=0
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

  # 检查 permissionMode
  if ! grep -q "^permissionMode:" "$f"; then
    warn "agents/$BASENAME.md 未设 permissionMode"
  fi

  MODE="$(awk '/^---$/{c++; if(c==2)exit; next} c==1 && /^permissionMode:/ {sub(/^permissionMode:[[:space:]]*/, ""); print; exit}' "$f")"
  MEMORY_SCOPE="$(awk '/^---$/{c++; if(c==2)exit; next} c==1 && /^memory:/ {sub(/^memory:[[:space:]]*/, ""); print; exit}' "$f")"
  case "$BASENAME" in
    client|creative|repo-researcher|tech-researcher|product-analyst|requirements-reviewer|pm|architect|scope-planner|architecture-reviewer|code-reviewer|security-auditor|functional-tester|visual-tester|test-lead|doc-writer|visual-designer|prompt-engineer)
      if [ "$MODE" = "bypassPermissions" ]; then
        warn "agents/$BASENAME.md 使用 bypassPermissions（建议收紧）"
      fi
      ;;
    implementer-frontend|implementer-backend|implementer-mobile|miniprogram-dev|database-engineer|ml-engineer)
      if [ "$MODE" = "bypassPermissions" ]; then
        warn "agents/$BASENAME.md 使用 bypassPermissions（建议改为 acceptEdits）"
      fi
      ;;
    devops)
      if [ "$MODE" = "bypassPermissions" ]; then
        warn "agents/$BASENAME.md 使用 bypassPermissions（高风险）"
      fi
      ;;
  esac

  if printf '%s\n' "$BASENAME" | grep -Eq '^(client|creative|product-analyst|requirements-reviewer|pm|architect|scope-planner|architecture-reviewer|code-reviewer|security-auditor|functional-tester|visual-tester|test-lead|repo-researcher|tech-researcher|doc-writer|visual-designer|prompt-engineer|database-engineer|ml-engineer|miniprogram-dev)$'; then
    if ! grep -q "^tools: .*Edit" "$f" 2>/dev/null || ! grep -q "^tools: .*Write" "$f" 2>/dev/null; then
      fail "agents/$BASENAME.md 缺 Edit/Write，无法落盘 artifact"
    fi
  fi

  case "$BASENAME" in
    client|creative|visual-designer|prompt-engineer)
      [ "$MEMORY_SCOPE" != "user" ] && warn "agents/$BASENAME.md memory=$MEMORY_SCOPE（按 LEGION 应为 user）" && MEMORY_DRIFT=$((MEMORY_DRIFT + 1))
      ;;
    *)
      [ "$MEMORY_SCOPE" != "project" ] && warn "agents/$BASENAME.md memory=$MEMORY_SCOPE（按 LEGION 应为 project）" && MEMORY_DRIFT=$((MEMORY_DRIFT + 1))
      ;;
  esac

  PRELOAD_LINES=0
  IN_SKILLS=0
  while IFS= read -r line; do
    case "$line" in
      skills:*) IN_SKILLS=1; continue ;;
      memory:*|permissionMode:*|tools:*|model:*|color:*|name:*|description:*) IN_SKILLS=0 ;;
    esac
    if [ "$IN_SKILLS" -eq 1 ]; then
      SKILL_NAME="$(printf '%s\n' "$line" | sed -n 's/^[[:space:]]*-[[:space:]]*//p')"
      if [ -n "$SKILL_NAME" ] && [ -f "$LEGION_DIR/skills/$SKILL_NAME/SKILL.md" ]; then
        L="$(wc -l < "$LEGION_DIR/skills/$SKILL_NAME/SKILL.md" | tr -d ' ')"
        PRELOAD_LINES=$((PRELOAD_LINES + L))
      fi
    fi
  done < "$f"
  if [ "$PRELOAD_LINES" -gt 350 ]; then
    warn "agents/$BASENAME.md 预加载 Skill ${PRELOAD_LINES} 行（建议拆短协议 + references）"
    PRELOAD_HEAVY=$((PRELOAD_HEAVY + 1))
  fi
done
pass "$AGENT_COUNT 个 Agent 定义"
[ "$MEMORY_DRIFT" -eq 0 ] && pass "Agent Memory scope 与 LEGION 策略一致"
[ "$PRELOAD_HEAVY" -eq 0 ] && pass "Agent 预加载 Skill 行数在预算内"

# ── 4. Skills ───────────────────────────────────────────────────────────────
section "4. Skills"

SKILL_COUNT=0
NESTED_WRONG=0
MISSING_SKILL_MD=0
LONG_SKILL=0
MISSING_DESC=0
UNOWNED_CAPABILITY=0
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
  [ -z "$DESC" ] && warn "skills/$DIRNAME/SKILL.md 缺 description" && MISSING_DESC=$((MISSING_DESC + 1))
  if [ ${#DESC} -gt 1536 ]; then
    warn "skills/$DIRNAME description 过长（${#DESC} 字符，上限 1536）"
  fi

  SKILL_LINES="$(wc -l < "$d/SKILL.md" | tr -d ' ')"
  if [ "$SKILL_LINES" -gt 500 ]; then
    warn "skills/$DIRNAME/SKILL.md $SKILL_LINES 行（建议长资料移入 references/）"
    LONG_SKILL=$((LONG_SKILL + 1))
  fi
done
pass "$SKILL_COUNT 个 Skill（扁平结构）"
[ "$NESTED_WRONG" -gt 0 ] && fail "$NESTED_WRONG 个嵌套 SKILL.md（不会被发现）"
[ "$MISSING_DESC" -eq 0 ] && pass "Skill description 完整"
[ "$LONG_SKILL" -eq 0 ] && pass "Skill 主文件行数在预算内"

CAPABILITY_SKILLS="pptx-workflow docx-workflow xlsx-workflow pdf-workflow webapp-testing-protocol frontend-design-protocol mcp-builder-protocol agent-guardrails-protocol"
for SK in $CAPABILITY_SKILLS; do
  [ -d "$LEGION_DIR/skills/$SK" ] || continue
  if ! grep -R "^[[:space:]]*-[[:space:]]*$SK$" "$LEGION_DIR/agents"/*.md >/dev/null 2>&1; then
    warn "能力 Skill $SK 未被任何 Agent 预加载"
    UNOWNED_CAPABILITY=$((UNOWNED_CAPABILITY + 1))
  fi
done
[ "$UNOWNED_CAPABILITY" -eq 0 ] && pass "能力 Skill 均有 owner Agent"

if [ -d "$LEGION_DIR/skills/project-knowledge" ]; then
  fail "用户级 skills/project-knowledge 存在（具体项目知识必须放项目级 .claude/skills/）"
elif [ -d "$LEGION_DIR/skills/project-knowledge-template" ]; then
  pass "用户级仅保留 project-knowledge-template"
else
  warn "缺少 project-knowledge-template（/bcc-init-project 可用性下降）"
fi

# ── 5. Rules ────────────────────────────────────────────────────────────────
section "5. Rules"

if [ -f "$LEGION_DIR/rules/_global/dispatch-table.md" ]; then
  pass "调度真源 dispatch-table.md 存在"
else
  fail "缺少 rules/_global/dispatch-table.md（调度真源）"
fi

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

# ── 11. Skill 参考样品覆盖率 ────────────────────────────────────────────────
section "11. Skill References & Examples"

REF_COUNT=0
EXAMPLE_COUNT=0
for d in "$LEGION_DIR"/skills/*/; do
  [ -d "$d" ] || continue
  [ -d "$d/references" ] && REF_COUNT=$((REF_COUNT + 1))
  [ -d "$d/examples" ] && EXAMPLE_COUNT=$((EXAMPLE_COUNT + 1))
done
info "${REF_COUNT} skill 含 references/，${EXAMPLE_COUNT} skill 含 examples/"

# ── 12. Skill Usage ─────────────────────────────────────────────────────────
section "12. Skill Usage"

if [ -x "$LEGION_DIR/bin/skill-usage-summary.sh" ]; then
  USAGE_LINES="$($LEGION_DIR/bin/skill-usage-summary.sh 2>/dev/null | grep -v '^#' | wc -l | tr -d ' ')"
  if [ "$USAGE_LINES" -gt 0 ]; then
    info "最近 instructions 加载统计可用（$USAGE_LINES 项），运行 bash ~/.claude/bin/skill-usage-summary.sh 查看"
  else
    info "暂无 Skill/Rule 加载统计样本"
  fi
else
  warn "缺少 bin/skill-usage-summary.sh"
fi

# ── 13. README 徽章漂移（仅 Legion 仓库本身） ───────────────────────────────
# 当前在 Legion 仓库时，检查 README.md 的数字徽章是否与实际统计一致
if [ -f "$LEGION_DIR/README.md" ] && [ -f "$LEGION_DIR/LEGION.md" ]; then
  section "13. README Badge Drift (Legion repo)"

  ACTUAL_AGENTS="$(ls "$LEGION_DIR"/agents/*.md 2>/dev/null | wc -l | tr -d ' ')"
  ACTUAL_SKILLS="$(find "$LEGION_DIR"/skills -maxdepth 2 -name 'SKILL.md' 2>/dev/null | wc -l | tr -d ' ')"
  ACTUAL_RULES="$(find "$LEGION_DIR"/rules -name '*.md' 2>/dev/null | wc -l | tr -d ' ')"

  check_badge() {
    local label="$1"
    local actual="$2"
    local pattern="$3"
    local declared=""
    declared="$(grep -oE "$pattern" "$LEGION_DIR/README.md" 2>/dev/null | head -1 | grep -oE '[0-9]+' 2>/dev/null || true)"

    if [ -z "${declared}" ]; then
      info "$label 徽章未在 README 中声明"
    elif [ "${declared}" = "$actual" ]; then
      pass "$label 徽章: ${declared}（与实际一致）"
    else
      warn "$label 徽章: ${declared} 声明 vs $actual 实际（漂移）"
    fi
  }

  check_badge "Agents" "$ACTUAL_AGENTS" "Agents-[0-9]+"
  check_badge "Skills" "$ACTUAL_SKILLS" "Skills-[0-9]+"
  check_badge "Rules"  "$ACTUAL_RULES"  "Rules-[0-9]+"
fi

# ── 14. Hook Profile ────────────────────────────────────────────────────────
section "14. Hook Profile"

HOOK_FLAGS_LIB="$LEGION_DIR/hooks/_lib/hook-flags.sh"
if [ -r "$HOOK_FLAGS_LIB" ]; then
  if bash -n "$HOOK_FLAGS_LIB" 2>/dev/null; then
    pass "hook-flags.sh 语法正确"
  else
    fail "hook-flags.sh 语法错误"
  fi
  # 在 subshell 中 source 并查询，避免污染当前 doctor 脚本的 IFS 等
  CURRENT_PROFILE="$(bash -c ". '$HOOK_FLAGS_LIB' && get_hook_profile" 2>/dev/null || echo "unknown")"
  DISABLED_HOOKS="$(bash -c ". '$HOOK_FLAGS_LIB' && get_disabled_hook_ids" 2>/dev/null || echo "")"
  REGISTERED="$(bash -c ". '$HOOK_FLAGS_LIB' && list_registered_hooks" 2>/dev/null | awk 'NF>0' | wc -l | tr -d ' ')"

  info "当前 profile: $CURRENT_PROFILE (env CLAUDE_HOOK_PROFILE)"
  if [ -n "$DISABLED_HOOKS" ]; then
    info "黑名单 hooks: $(echo "$DISABLED_HOOKS" | tr '\n' ',' | sed 's/,$//')"
  else
    info "黑名单为空 (CLAUDE_DISABLED_HOOKS 未设置)"
  fi
  info "已登记 hook 数量: $REGISTERED"

  # 检查登记数与 hooks/ 实际脚本数是否一致
  ACTUAL_HOOK_COUNT="$(find "$LEGION_DIR/hooks" -maxdepth 1 -name '*.sh' -type f 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$REGISTERED" -lt "$ACTUAL_HOOK_COUNT" ]; then
    warn "hooks/ 存在 $ACTUAL_HOOK_COUNT 个脚本，但 hook-flags 只登记了 $REGISTERED 个（新脚本建议登记）"
  elif [ "$REGISTERED" -gt "$ACTUAL_HOOK_COUNT" ]; then
    warn "hook-flags 登记了 $REGISTERED 个 hook，但 hooks/ 只有 $ACTUAL_HOOK_COUNT 个脚本（可能有登记残留）"
  fi
else
  warn "缺少 hooks/_lib/hook-flags.sh（Hook Profile 门控未启用）"
fi

# 运行单元测试（存在才跑）
if [ -x "$LEGION_DIR/bin/test-hook-flags.sh" ]; then
  TEST_OUT="$(bash "$LEGION_DIR/bin/test-hook-flags.sh" 2>&1)"
  TEST_RC=$?
  TEST_PASS="$(echo "$TEST_OUT" | grep -E '^PASS:' | awk '{print $2}')"
  TEST_FAIL="$(echo "$TEST_OUT" | grep -E '^FAIL:' | awk '{print $2}')"
  if [ "$TEST_RC" -eq 0 ] && [ "${TEST_FAIL:-1}" = "0" ]; then
    pass "test-hook-flags: ${TEST_PASS:-?} 个测试全部通过"
  else
    fail "test-hook-flags: ${TEST_FAIL:-?} 失败（运行 bash bin/test-hook-flags.sh 查看详情）"
  fi
else
  info "缺少 bin/test-hook-flags.sh（建议补齐单元测试）"
fi

# ── 15. Artifact Schema ─────────────────────────────────────────────────────
section "15. Artifact Schema"

VALIDATOR="$LEGION_DIR/bin/validate-artifacts.sh"
if [ ! -x "$VALIDATOR" ]; then
  warn "缺少 bin/validate-artifacts.sh"
else
  # 汇总所有候选 artifact 目录，用 realpath 去重，避免 $LEGION_DIR/artifacts
  # 与 $PROJ_DIR/artifacts 指向同目录时重复扫描
  _seen=""
  for CAND in "$LEGION_DIR/artifacts" "$PROJ_DIR/.claude/artifacts" "$PROJ_DIR/artifacts"; do
    [ -d "$CAND" ] || continue
    REAL="$(cd "$CAND" 2>/dev/null && pwd -P)"
    [ -z "$REAL" ] && continue
    case " $_seen " in *" $REAL "*) continue ;; esac
    _seen="$_seen $REAL"

    VA_OUT="$(bash "$VALIDATOR" "$CAND" 2>&1)"
    VA_RC=$?
    VA_CRIT="$(echo "$VA_OUT" | awk -F: '/^CRITICAL:/{gsub(/[[:space:]]/,"",$2); print $2}')"
    VA_WARN="$(echo "$VA_OUT" | awk -F: '/^WARNING:/{gsub(/[[:space:]]/,"",$2); print $2}')"
    VA_PASS="$(echo "$VA_OUT" | awk -F: '/^PASS:/{gsub(/[[:space:]]/,"",$2); print $2}')"
    # 用相对 HOME 的显示路径，输出更紧凑
    LABEL="${CAND/#$HOME/~}"
    if [ "$VA_RC" -eq 0 ] && [ "${VA_CRIT:-0}" = "0" ]; then
      pass "$LABEL: ${VA_PASS:-0} PASS / ${VA_WARN:-0} WARNING / ${VA_CRIT:-0} CRITICAL"
    else
      fail "$LABEL: ${VA_CRIT:-?} CRITICAL（运行 bash bin/validate-artifacts.sh $CAND 查看详情）"
    fi
  done
fi

# ── 16. Agent Memory Usage ──────────────────────────────────────────────────
section "16. Agent Memory Usage"

# 用户级
USER_MEM_DIR="$LEGION_DIR/agent-memory"
if [ -d "$USER_MEM_DIR" ]; then
  USER_TOTAL=0
  USER_COLD=0
  for d in "$USER_MEM_DIR"/*/; do
    [ -d "$d" ] || continue
    name="$(basename "$d")"
    n="$(find "$d" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
    USER_TOTAL=$((USER_TOTAL + n))
    if [ "$n" -eq 0 ]; then
      USER_COLD=$((USER_COLD + 1))
    fi
  done
  USER_AGENTS="$(find "$USER_MEM_DIR" -maxdepth 1 -type d -not -path "$USER_MEM_DIR" 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$USER_COLD" -gt 0 ]; then
    info "用户级：${USER_TOTAL} memories across ${USER_AGENTS} agents（其中 ${USER_COLD} 个 agent 为冷——0 memory）"
  else
    pass "用户级：${USER_TOTAL} memories across ${USER_AGENTS} agents"
  fi
fi

# 项目级（当前项目）
if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
  PROJ_MEM_DIR="$CLAUDE_PROJECT_DIR/.claude/agent-memory"
elif [ -d "$PWD/.claude/agent-memory" ]; then
  PROJ_MEM_DIR="$PWD/.claude/agent-memory"
else
  PROJ_MEM_DIR=""
fi

if [ -n "$PROJ_MEM_DIR" ] && [ -d "$PROJ_MEM_DIR" ]; then
  PROJ_TOTAL="$(find "$PROJ_MEM_DIR" -name '*.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
  info "项目级 ($PROJ_MEM_DIR)：${PROJ_TOTAL} memories"
else
  info "项目级 agent-memory 目录不存在"
fi

# Auto-memory（~/.claude/projects/<proj>/memory/MEMORY.md）
AUTO_MEM_TOTAL="$(find "$LEGION_DIR/projects" -name 'MEMORY.md' -type f 2>/dev/null | wc -l | tr -d ' ')"
if [ "$AUTO_MEM_TOTAL" -gt 0 ]; then
  info "Auto-memory：${AUTO_MEM_TOTAL} 个项目有 MEMORY.md 索引"
fi

# ── 17. Router 健康度 ──────────────────────────────────────────────────────
section "17. Router Health"

# 检查 UserPromptSubmit hook 注册
if [ -f "$SETTINGS_PATH" ]; then
  UPS_COUNT="$(python3 -c "
import json
d = json.load(open('$SETTINGS_PATH'))
print(len(d.get('hooks', {}).get('UserPromptSubmit', [{}])[0].get('hooks', [])))
" 2>/dev/null || echo 0)"
  if [ "$UPS_COUNT" -ge 3 ]; then
    pass "UserPromptSubmit 注册了 $UPS_COUNT 个 hook（Router 链完整）"
  elif [ "$UPS_COUNT" -ge 1 ]; then
    warn "UserPromptSubmit 只注册了 $UPS_COUNT 个 hook（期待 3：intent-classify / clarification-gate / review-gate）"
  else
    fail "UserPromptSubmit 未注册任何 hook（Router 不生效）"
  fi
fi

# 检查三个 hook 脚本
for h in intent-classify.sh clarification-gate.sh review-gate.sh; do
  p="$LEGION_DIR/hooks/$h"
  if [ -x "$p" ] && bash -n "$p" 2>/dev/null; then
    pass "hooks/$h 可执行 + 语法正确"
  elif [ -f "$p" ]; then
    fail "hooks/$h 存在但有问题（不可执行或语法错误）"
  else
    fail "hooks/$h 缺失"
  fi
done

# 近期 intent-classify 分类分布
if [ -f "$LEGION_DIR/logs/intent-classify.jsonl" ]; then
  RECENT="$(tail -50 "$LEGION_DIR/logs/intent-classify.jsonl" 2>/dev/null)"
  if [ -n "$RECENT" ] && command -v jq >/dev/null 2>&1; then
    echo "$RECENT" | jq -r '.tier' 2>/dev/null | sort | uniq -c | awk '{printf "    %-10s %s\n", $2, $1}' \
      | while read line; do
        [ -n "$line" ] && info "近 50 次分类：$line"
      done
  fi
fi

# ── 汇总 ────────────────────────────────────────────────────────────────────
echo ""
echo "═════════════════════════════════════════════════"
printf "  Summary: \033[32m%d passed\033[0m | \033[33m%d warnings\033[0m | \033[31m%d failures\033[0m\n" \
  "$PASS" "$WARN" "$FAIL"
echo "═════════════════════════════════════════════════"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
