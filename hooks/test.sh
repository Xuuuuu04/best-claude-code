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

pretool_json() { # toolname key value — 造 PreToolUse stdin
  jq -n --arg t "$1" --arg k "$2" --arg v "$3" \
    '{tool_name:$t, tool_input:{($k):$v}}'
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
assert_empty "无 task 编辑 → 不注入(提示已移交 UserPromptSubmit)" "$OUT"
assert_eq "  └ 但仍计数 EDITS=3"            "$(get_field "$EMPTY" edits_since_task_update)" "3"
set_state "$EMPTY" 5 0
assert_empty "无 task EDITS 起点>3 → 仍静默(回归防旧 -eq3 坑)" "$(run_hook posttooluse-guard.sh "$(stdin_json "$EMPTY" "Edit" "$EMPTY/src/c.js")")"

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

echo "=== Stop v3.0: Review 状态检查 ==="
# 给活跃 task 加 Spec 段
echo '## Spec' >> "$ACTIVE/.claude/tasks/Task-active.md"
set_state "$ACTIVE" 0 0
assert_contains "有Spec无review → block"     "$(run_hook stop-progress-gate.sh "$(stdin_json "$ACTIVE" "" "")")" "review"

# 放一个 pass:false 的 review JSON
echo '{"pass":false,"round":1,"weighted_score":5.2,"blocking_dimensions":["test_coverage"]}' > "$ACTIVE/.claude/tasks/outputs/review-test-r1.json"
set_state "$ACTIVE" 0 0
assert_contains "review未通过 → block"        "$(run_hook stop-progress-gate.sh "$(stdin_json "$ACTIVE" "" "")")" "block"
assert_contains "block含weighted分数"         "$(run_hook stop-progress-gate.sh "$(stdin_json "$ACTIVE" "" "")")" "5.2"

# 改成 pass:true
echo '{"pass":true,"round":2,"weighted_score":7.8,"blocking_dimensions":[]}' > "$ACTIVE/.claude/tasks/outputs/review-test-r1.json"
set_state "$ACTIVE" 0 0
assert_empty "review通过 → 放行"              "$(run_hook stop-progress-gate.sh "$(stdin_json "$ACTIVE" "" "")")"

# 无 Spec 的 task 不检查 review
set_state "$EMPTY" 0 0
assert_empty "无Spec → 不检查review"          "$(run_hook stop-progress-gate.sh "$(stdin_json "$EMPTY" "" "")")"

echo "=== Stop v3.1: Review block 防死循环 ==="
# 连续 review block 3 次后应降级为警告放行
rm -f "$ACTIVE/.claude/tasks/outputs/review-"*.json
set_state "$ACTIVE" 0 0
# 不在轮次间调 set_state,否则 review_blocks 字段被清掉
run_hook stop-progress-gate.sh "$(stdin_json "$ACTIVE" "" "")" >/dev/null   # block 1
run_hook stop-progress-gate.sh "$(stdin_json "$ACTIVE" "" "")" >/dev/null   # block 2
OUT3=$(run_hook stop-progress-gate.sh "$(stdin_json "$ACTIVE" "" "")")       # 第3次 review_blocks>=3 → 降级
assert_contains "review block 第3次 → 降级放行" "$OUT3" "放行"
# 恢复:放一个 pass:true 的 review JSON,重新初始化 state
echo '{"pass":true,"round":1,"weighted_score":8.0,"blocking_dimensions":[]}' > "$ACTIVE/.claude/tasks/outputs/review-test-r1.json"
set_state "$ACTIVE" 0 0

echo "=== PreToolUse: 危险 git 操作 ==="
assert_contains "git push --force → deny"     "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git push --force origin main")")" "deny"
assert_contains "git push -f → deny"          "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git push -f")")" "deny"
assert_empty    "git push (正常) → 放行"       "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git push origin main")")"
assert_empty    "git push --force-with-lease → 放行" "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git push --force-with-lease")")"
assert_contains "git reset --hard → deny"     "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git reset --hard HEAD~1")")" "deny"
assert_contains "git clean -fd → deny"        "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git clean -fd")")" "deny"
assert_contains "git branch -D → deny"        "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git branch -D feature")")" "deny"
assert_empty    "git branch -d → 放行"        "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git branch -d feature")")"
assert_contains "--no-verify → deny"          "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git commit --no-verify -m test")")" "deny"
assert_contains "git checkout -- . → deny"    "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git checkout -- .")")" "deny"
assert_contains "git restore . → deny"        "$(run_hook pretooluse-guard.sh "$(pretool_json Bash command "git restore .")")" "deny"

echo "=== PreToolUse: 敏感文件 ==="
assert_contains ".env → deny"                 "$(run_hook pretooluse-guard.sh "$(pretool_json Read file_path "/app/.env")")" "deny"
assert_contains ".env.local → deny"           "$(run_hook pretooluse-guard.sh "$(pretool_json Edit file_path "/app/.env.local")")" "deny"
assert_empty    ".env.example → 放行"         "$(run_hook pretooluse-guard.sh "$(pretool_json Read file_path "/app/.env.example")")"
assert_contains "credentials.json → deny"     "$(run_hook pretooluse-guard.sh "$(pretool_json Read file_path "/home/user/credentials.json")")" "deny"
assert_contains ".ssh → deny"                 "$(run_hook pretooluse-guard.sh "$(pretool_json Read file_path "/home/user/.ssh/id_rsa")")" "deny"
assert_contains ".aws → deny"                 "$(run_hook pretooluse-guard.sh "$(pretool_json Read file_path "/home/user/.aws/credentials")")" "deny"
assert_empty    "普通文件 → 放行"              "$(run_hook pretooluse-guard.sh "$(pretool_json Read file_path "/app/src/index.ts")")"

echo "=== UserPromptSubmit v3.0: Review 状态注入 ==="
# ACTIVE 的 Task 此时有 Spec 段 + pass:true 的 review JSON（由前面 Stop v3.0 测试段设置）
assert_contains "有Spec+review通过 → 注入PASSED"  "$(run_hook userpromptsubmit-router.sh "$(stdin_json "$ACTIVE" "" "")")" "PASSED"

# 改成 pass:false 看看注入内容
echo '{"pass":false,"round":3,"weighted_score":4.5,"blocking_dimensions":["security","correctness"]}' > "$ACTIVE/.claude/tasks/outputs/review-test-r1.json"
assert_contains "有Spec+review未通过 → 注入blocking" "$(run_hook userpromptsubmit-router.sh "$(stdin_json "$ACTIVE" "" "")")" "blocking"
assert_contains "注入含轮次"                        "$(run_hook userpromptsubmit-router.sh "$(stdin_json "$ACTIVE" "" "")")" "Round 3"

# 删掉 review JSON,测 "未开始" 分支
rm -f "$ACTIVE/.claude/tasks/outputs/review-"*.json
assert_contains "有Spec无review → 注入未开始"       "$(run_hook userpromptsubmit-router.sh "$(stdin_json "$ACTIVE" "" "")")" "未开始"

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

echo "=== _common helpers ==="
source "$HOOKS_DIR/_common.sh"
NOTITLE=$(mktemp); printf '%s\n' "正文没有标题行" > "$NOTITLE"
assert_eq "_task_title 无标题 → fallback 生效"  "$(_task_title "$NOTITLE")" "(无标题)"
WITHTITLE=$(mktemp); printf '# 有标题\n' > "$WITHTITLE"
assert_eq "_task_title 有标题 → 取标题"      "$(_task_title "$WITHTITLE")" "有标题"
rm -f "$NOTITLE" "$WITHTITLE"

echo "=== _common helpers v3.0: review ==="
SPEC_FILE=$(mktemp); printf -- '---\nstatus: in_progress\n---\n# Test\n## Spec\nsome spec\n' > "$SPEC_FILE"
NOSPEC_FILE=$(mktemp); printf -- '---\nstatus: in_progress\n---\n# Test\n## Plan\nno spec here\n' > "$NOSPEC_FILE"
_task_has_spec "$SPEC_FILE" && ok "_task_has_spec 有Spec → true" || bad "_task_has_spec 有Spec → true"
_task_has_spec "$NOSPEC_FILE" && bad "_task_has_spec 无Spec → false" || ok "_task_has_spec 无Spec → false"
rm -f "$SPEC_FILE" "$NOSPEC_FILE"

REVIEW_FILE=$(mktemp); echo '{"pass":true,"round":2,"weighted_score":8.1,"blocking_dimensions":[]}' > "$REVIEW_FILE"
_read_review_result "$REVIEW_FILE"
assert_eq "_read_review_result pass"       "$REVIEW_PASS" "true"
assert_eq "_read_review_result round"      "$REVIEW_ROUND" "2"
assert_eq "_read_review_result weighted"   "$REVIEW_WEIGHTED" "8.1"
assert_eq "_read_review_result blocking空" "$REVIEW_BLOCKING" ""
rm -f "$REVIEW_FILE"

echo ""
echo "=================================="
echo "通过 $PASS / 失败 $FAIL"
[ "$FAIL" -eq 0 ] && { echo "全部通过 ✓"; exit 0; } || { echo "有失败 ✗"; exit 1; }
