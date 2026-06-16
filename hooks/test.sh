#!/bin/bash
# hooks/test.sh — BCC hooks 回归测试。造 stdin、跑 hook、断言输出/state。
# 用法: bash hooks/test.sh   (全过 exit 0,有失败 exit 1)
# 自包含:用 mktemp 临时项目,不碰真实 tasks。bash 3.2 兼容(macOS)。
set -u

HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
SID="testsid"
PASS=0
FAIL=0

command -v jq >/dev/null || { echo "需要 jq"; exit 1; }

# ---- 三种临时项目 ----
ACTIVE=$(mktemp -d)        # 有活跃 task
EMPTY=$(mktemp -d)         # 有 .claude/tasks 但无活跃 task
NONBCC=$(mktemp -d)        # 非 BCC(无 .claude/tasks)
trap 'rm -rf "$ACTIVE" "$EMPTY" "$NONBCC"' EXIT

mkdir -p "$ACTIVE/.claude/tasks/outputs" "$EMPTY/.claude/tasks/outputs"

cat > "$ACTIVE/.claude/tasks/Task-active.md" <<'EOF'
---
status: in_progress
started: 2026-06-16 10:00
---
# Active test task

## Execution Log
- 10:00 created
EOF

# #4 用例:frontmatter 是 done,但正文出现 "status: in_progress" 字面串
cat > "$EMPTY/.claude/tasks/Task-done-with-literal.md" <<'EOF'
---
status: done
started: 2026-06-16 09:00
---
# Done task

## Decisions
- 我把 status: in_progress 改成了 done
EOF

# ---- helpers ----
run_hook() { printf '%s' "$2" | bash "$HOOKS_DIR/$1" 2>/dev/null; }

state_path() { echo "$1/.claude/tasks/.hook-state.${SID}.json"; }
set_state() { # dir edits failures
  jq -n --argjson e "$2" --argjson f "$3" \
    '{edits_since_task_update:$e,consecutive_bash_failures:$f}' > "$(state_path "$1")"
}
get_field() { jq -r ".$2 // 0" "$(state_path "$1")" 2>/dev/null; }

stdin_json() { # cwd toolname filepath  (后两个可空)
  jq -n --arg c "$1" --arg s "$SID" --arg t "$2" --arg f "$3" \
    '{cwd:$c, session_id:$s} + (if $t=="" then {} else {tool_name:$t} end) + (if $f=="" then {} else {tool_input:{file_path:$f}} end)'
}

ok()   { PASS=$((PASS+1)); echo "  ✓ $1"; }
bad()  { FAIL=$((FAIL+1)); echo "  ✗ $1"; [ -n "${2:-}" ] && echo "      $2"; }

assert_contains() { if printf '%s' "$2" | grep -qF "$3"; then ok "$1"; else bad "$1" "期望含【$3】实际【$2】"; fi; }
assert_empty()    { if [ -z "$2" ]; then ok "$1"; else bad "$1" "期望空,实际【$2】"; fi; }
assert_eq()       { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "期望【$3】实际【$2】"; fi; }

echo "=== SessionStart ==="
assert_contains "有活跃 task → 注入"        "$(run_hook session-start.sh "$(stdin_json "$ACTIVE" "" "")")" "进行中"
assert_empty    "空 tasks → 静默"           "$(run_hook session-start.sh "$(stdin_json "$EMPTY" "" "")")"
assert_empty    "非 BCC → 静默"             "$(run_hook session-start.sh "$(stdin_json "$NONBCC" "" "")")"
assert_empty    "CWD=\$HOME → 守卫退出"      "$(run_hook session-start.sh "$(stdin_json "$HOME" "" "")")"

echo "=== UserPromptSubmit ==="
assert_contains "有活跃 task"               "$(run_hook userpromptsubmit-router.sh "$(stdin_json "$ACTIVE" "" "")")" "进行中的 Task"
assert_contains "无活跃 task"               "$(run_hook userpromptsubmit-router.sh "$(stdin_json "$EMPTY" "" "")")" "无进行中的 Task"
assert_empty    "非 BCC → 静默"             "$(run_hook userpromptsubmit-router.sh "$(stdin_json "$NONBCC" "" "")")"

echo "=== PostToolUse-guard ==="
set_state "$ACTIVE" 0 0
run_hook posttooluse-guard.sh "$(stdin_json "$ACTIVE" "Edit" "$ACTIVE/src/foo.js")" >/dev/null
assert_eq "代码文件编辑 → EDITS+1"          "$(get_field "$ACTIVE" edits_since_task_update)" "1"

set_state "$ACTIVE" 5 0
run_hook posttooluse-guard.sh "$(stdin_json "$ACTIVE" "Edit" "$ACTIVE/.claude/tasks/Task-active.md")" >/dev/null
assert_eq "Task 直下 .md → EDITS 归零"      "$(get_field "$ACTIVE" edits_since_task_update)" "0"

set_state "$ACTIVE" 5 0
run_hook posttooluse-guard.sh "$(stdin_json "$ACTIVE" "Edit" "$ACTIVE/.claude/tasks/outputs/brief-x.md")" >/dev/null
assert_eq "outputs/*.md 不归零 (#3)"        "$(get_field "$ACTIVE" edits_since_task_update)" "6"

set_state "$ACTIVE" 3 2
run_hook posttooluse-guard.sh "$(stdin_json "$ACTIVE" "Bash" "")" >/dev/null
assert_eq "Bash 成功 → FAILURES 归零"       "$(get_field "$ACTIVE" consecutive_bash_failures)" "0"
assert_eq "Bash 成功 → EDITS 不变"          "$(get_field "$ACTIVE" edits_since_task_update)" "3"

set_state "$EMPTY" 2 0
OUT=$(run_hook posttooluse-guard.sh "$(stdin_json "$EMPTY" "Edit" "$EMPTY/src/a.js")")
assert_contains "无 task 编辑到第3次 → 提示 (#1)" "$OUT" "bcc-start"
assert_eq "  └ 且 EDITS=3"                  "$(get_field "$EMPTY" edits_since_task_update)" "3"

assert_empty "非 Edit/Bash 工具 → 无操作"   "$(run_hook posttooluse-guard.sh "$(stdin_json "$ACTIVE" "Read" "")")"

echo "=== PostToolUseFailure ==="
set_state "$ACTIVE" 0 0
run_hook posttoolusefailure.sh "$(stdin_json "$ACTIVE" "Bash" "")" >/dev/null
assert_eq "失败 → FAILURES+1"               "$(get_field "$ACTIVE" consecutive_bash_failures)" "1"

set_state "$ACTIVE" 0 2
OUT=$(run_hook posttoolusefailure.sh "$(stdin_json "$ACTIVE" "Bash" "")")
assert_contains "第3次失败 → 注入 /bcc-debug" "$OUT" "bcc-debug"
assert_eq "  └ 且 FAILURES=3"               "$(get_field "$ACTIVE" consecutive_bash_failures)" "3"

set_state "$ACTIVE" 0 3
OUT=$(run_hook posttoolusefailure.sh "$(stdin_json "$ACTIVE" "Bash" "")")
assert_empty "第4次失败 → 不重复注入"        "$OUT"
assert_eq "  └ 且 FAILURES=4"               "$(get_field "$ACTIVE" consecutive_bash_failures)" "4"

echo "=== Stop ==="
set_state "$ACTIVE" 6 0
assert_contains "有task + EDITS>=6 → block"  "$(run_hook stop-progress-gate.sh "$(stdin_json "$ACTIVE" "" "")")" "block"
set_state "$ACTIVE" 3 0
assert_empty "有task + EDITS<6 → 放行"       "$(run_hook stop-progress-gate.sh "$(stdin_json "$ACTIVE" "" "")")"
set_state "$EMPTY" 9 0
assert_empty "无活跃 task → 放行"            "$(run_hook stop-progress-gate.sh "$(stdin_json "$EMPTY" "" "")")"

echo "=== PreCompact ==="
run_hook precompact.sh "$(stdin_json "$ACTIVE" "" "")" >/dev/null
N1=$(grep -c 'PreCompact' "$ACTIVE/.claude/tasks/Task-active.md")
assert_eq "有task → 写恢复指引"             "$N1" "1"
run_hook precompact.sh "$(stdin_json "$ACTIVE" "" "")" >/dev/null
N2=$(grep -c 'PreCompact' "$ACTIVE/.claude/tasks/Task-active.md")
assert_eq "再跑 → 幂等(不重复)"            "$N2" "1"

echo "=== #4 frontmatter 锚定 ==="
# EMPTY 里那个 task frontmatter 是 done,正文有 "status: in_progress" 字面串
assert_contains "正文字面串不误判为活跃"     "$(run_hook userpromptsubmit-router.sh "$(stdin_json "$EMPTY" "" "")")" "无进行中的 Task"

echo ""
echo "=================================="
echo "通过 $PASS / 失败 $FAIL"
[ "$FAIL" -eq 0 ] && { echo "全部通过 ✓"; exit 0; } || { echo "有失败 ✗"; exit 1; }
