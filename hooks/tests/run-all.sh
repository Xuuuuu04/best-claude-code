#!/usr/bin/env bash
# Harness Hook 单测集合 v2
# 每次改 hook 后跑：bash ~/.claude/hooks/tests/run-all.sh

set -u
export HARNESS_HOOK_SILENT=1
HOOKS_DIR="$HOME/.claude/hooks"
PASS=0; FAIL=0
FAILED_CASES=()

rm -f ~/.claude/.maintenance-mode

assert() {
    local name="$1" exp_exit="$2" stderr_keyword="$3" stdin="$4" hook="$5"
    local out err act_exit
    err=$(mktemp); out=$(mktemp)
    printf '%s' "$stdin" | bash "$hook" >"$out" 2>"$err"
    act_exit=$?
    local ok=true
    [[ "$act_exit" != "$exp_exit" ]] && ok=false
    [[ -n "$stderr_keyword" ]] && ! grep -q "$stderr_keyword" "$err" && ok=false
    if $ok; then
        printf '  \033[32m✓\033[0m %s\n' "$name"; PASS=$((PASS+1))
    else
        printf '  \033[31m✗\033[0m %s (exit=%s, expected %s)\n' "$name" "$act_exit" "$exp_exit"
        [[ -s "$err" ]] && printf '     stderr: %s\n' "$(head -2 "$err" | tr '\n' '|')"
        FAIL=$((FAIL+1)); FAILED_CASES+=("$name")
    fi
    rm -f "$err" "$out"
}

assert_stdout() {
    local name="$1" exp_substring="$2" stdin="$3" hook="$4"
    local out
    out=$(printf '%s' "$stdin" | bash "$hook" 2>/dev/null)
    if printf '%s' "$out" | grep -qF "$exp_substring"; then
        printf '  \033[32m✓\033[0m %s\n' "$name"; PASS=$((PASS+1))
    else
        printf '  \033[31m✗\033[0m %s (stdout no match for "%s")\n' "$name" "$exp_substring"
        FAIL=$((FAIL+1)); FAILED_CASES+=("$name")
    fi
}

# =============================================
echo "Hook-A: ~/.claude/ 核心文件守卫"
# =============================================
assert "A1 拦截 agents/pm.md" 2 "GP-O09" \
    '{"tool_name":"Write","tool_input":{"file_path":"/Users/mumuxsy/.claude/agents/pm.md"}}' \
    "$HOOKS_DIR/hook-a-claude-dir-guard.sh"
assert "A2 拦截 CLAUDE.md" 2 "GP-O09" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/Users/mumuxsy/.claude/CLAUDE.md"}}' \
    "$HOOKS_DIR/hook-a-claude-dir-guard.sh"
assert "A3 放行 projects/ 写入" 0 "" \
    '{"tool_name":"Write","tool_input":{"file_path":"/Users/mumuxsy/.claude/projects/x/y.md"}}' \
    "$HOOKS_DIR/hook-a-claude-dir-guard.sh"
assert "A4 放行 memory/" 0 "" \
    '{"tool_name":"Write","tool_input":{"file_path":"/Users/mumuxsy/.claude/memory/x.md"}}' \
    "$HOOKS_DIR/hook-a-claude-dir-guard.sh"
assert "A5 放行 /tmp" 0 "" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/test.py"}}' \
    "$HOOKS_DIR/hook-a-claude-dir-guard.sh"
assert "A6 非 Write/Edit 工具放行" 0 "" \
    '{"tool_name":"Read","tool_input":{"file_path":"/Users/mumuxsy/.claude/agents/pm.md"}}' \
    "$HOOKS_DIR/hook-a-claude-dir-guard.sh"
touch ~/.claude/.maintenance-mode
assert "A7 维护模式下放行" 0 "" \
    '{"tool_name":"Write","tool_input":{"file_path":"/Users/mumuxsy/.claude/CLAUDE.md"}}' \
    "$HOOKS_DIR/hook-a-claude-dir-guard.sh"
rm -f ~/.claude/.maintenance-mode

# =============================================
echo "Hook-B: WebSearch fallback"
# =============================================
assert "B1 失败响应注入 MCP 指引" 0 "" \
    '{"tool_name":"WebSearch","tool_response":"Error: 403 unauthorized"}' \
    "$HOOKS_DIR/hook-b-websearch-fallback.sh"
assert "B2 成功响应不打扰" 0 "" \
    '{"tool_name":"WebSearch","tool_response":"10 results"}' \
    "$HOOKS_DIR/hook-b-websearch-fallback.sh"
assert "B3 非 WebSearch 工具放行" 0 "" \
    '{"tool_name":"Read"}' \
    "$HOOKS_DIR/hook-b-websearch-fallback.sh"

# =============================================
echo "Hook-C1/C2: Compact 铁律注入"
# =============================================
rm -f /tmp/harness-compact-reminder-test-s1
assert "C1 创建 flag 文件" 0 "" \
    '{"session_id":"test-s1","transcript_path":"/tmp/fake.jsonl"}' \
    "$HOOKS_DIR/hook-c1-precompact-save.sh"
if [[ -f /tmp/harness-compact-reminder-test-s1 ]]; then
    printf '  \033[32m✓\033[0m C1b flag 被创建\n'; PASS=$((PASS+1))
else
    printf '  \033[31m✗\033[0m C1b flag 未创建\n'; FAIL=$((FAIL+1))
fi
rm -f /tmp/harness-compact-reminder-test-s1

out=$(echo '{"session_id":"test-s2"}' | bash "$HOOKS_DIR/hook-c2-prompt-inject.sh" 2>/dev/null)
if echo "$out" | grep -q "调度协议"; then
    printf '  \033[32m✓\033[0m C2 每轮注入调度协议\n'; PASS=$((PASS+1))
else
    printf '  \033[31m✗\033[0m C2 未注入\n'; FAIL=$((FAIL+1))
fi
touch /tmp/harness-compact-reminder-test-s3
echo "FAKE_RULE" > /tmp/harness-compact-reminder-test-s3
bash "$HOOKS_DIR/hook-c2-prompt-inject.sh" <<< '{"session_id":"test-s3"}' >/dev/null 2>&1
if [[ ! -f /tmp/harness-compact-reminder-test-s3 ]]; then
    printf '  \033[32m✓\033[0m C2b post-compact flag 一次性消费\n'; PASS=$((PASS+1))
else
    printf '  \033[31m✗\033[0m C2b flag 未消费\n'; FAIL=$((FAIL+1))
    rm -f /tmp/harness-compact-reminder-test-s3
fi

# =============================================
echo "Hook-D: Stop Insight 校验"
# =============================================
TP_INS=$(mktemp)
cat > "$TP_INS" <<'EOF'
{"message":{"role":"user","content":"x"}}
{"message":{"role":"assistant","content":[{"type":"text","text":"★ Insight four items - sufficient text length for testing"},{"type":"tool_use","name":"Read"}]}}
EOF
assert "D1 有 Insight + tool → 放行" 0 "" \
    "{\"transcript_path\":\"$TP_INS\"}" \
    "$HOOKS_DIR/hook-d-insight-check.sh"

TP_NO=$(mktemp)
cat > "$TP_NO" <<'EOF'
{"message":{"role":"user","content":"x"}}
{"message":{"role":"assistant","content":[{"type":"text","text":"just text without insight marker lengthy text here yes"},{"type":"tool_use","name":"Read"}]}}
EOF
assert "D2 有 tool 无 Insight → 拒绝" 2 "GP-O03" \
    "{\"transcript_path\":\"$TP_NO\"}" \
    "$HOOKS_DIR/hook-d-insight-check.sh"

TP_EMPTY=$(mktemp)
cat > "$TP_EMPTY" <<'EOF'
{"message":{"role":"user","content":"x"}}
{"message":{"role":"assistant","content":[{"type":"text","text":"ok"}]}}
EOF
assert "D3 空跑放行" 0 "" \
    "{\"transcript_path\":\"$TP_EMPTY\"}" \
    "$HOOKS_DIR/hook-d-insight-check.sh"

assert "D4 stop_hook_active 循环防护" 0 "" \
    "{\"transcript_path\":\"$TP_INS\",\"stop_hook_active\":true}" \
    "$HOOKS_DIR/hook-d-insight-check.sh"

# 多条 assistant 记录的场景（Insight 在前一条，tool 在后一条）
TP_MULTI=$(mktemp)
cat > "$TP_MULTI" <<'EOF'
{"message":{"role":"user","content":"x"}}
{"message":{"role":"assistant","content":[{"type":"text","text":"★ Insight four items with enough length of text"}]}}
{"message":{"role":"assistant","content":[{"type":"tool_use","name":"Read"}]}}
EOF
assert "D5 多条 assistant 聚合（Insight+tool 分开两条）→ 放行" 0 "" \
    "{\"transcript_path\":\"$TP_MULTI\"}" \
    "$HOOKS_DIR/hook-d-insight-check.sh"

rm -f "$TP_INS" "$TP_NO" "$TP_EMPTY" "$TP_MULTI"

# =============================================
echo "Hook-E v3: 并行 Agent 拦截（in-flight 检测）"
# =============================================
# 场景1：首次派发（current 已在 transcript 里）
TP_E1=$(mktemp)
cat > "$TP_E1" <<'EOF'
{"message":{"role":"user","content":"x"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_1","name":"Agent","input":{"subagent_type":"项目管理师"}}]}}
EOF
assert "E1 首次派 → 放行" 0 "" \
    "{\"tool_name\":\"Agent\",\"transcript_path\":\"$TP_E1\",\"tool_use_id\":\"toolu_1\",\"tool_input\":{}}" \
    "$HOOKS_DIR/hook-e-parallel-agent-block.sh"

# 场景2：串行派（前一个已完成）
TP_E2=$(mktemp)
cat > "$TP_E2" <<'EOF'
{"message":{"role":"user","content":"x"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_A","name":"Agent","input":{"subagent_type":"项目管理师"}}]}}
{"message":{"role":"user","content":[{"type":"tool_result","tool_use_id":"toolu_A","content":"done"}]}}
{"message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_B","name":"Agent","input":{"subagent_type":"代码审计师"}}]}}
EOF
assert "E2 串行第2派（前已返回）→ 放行" 0 "" \
    "{\"tool_name\":\"Agent\",\"transcript_path\":\"$TP_E2\",\"tool_use_id\":\"toolu_B\",\"tool_input\":{}}" \
    "$HOOKS_DIR/hook-e-parallel-agent-block.sh"

# 场景3：真并行（前一个未返回）
TP_E3=$(mktemp)
cat > "$TP_E3" <<'EOF'
{"message":{"role":"user","content":"x"}}
{"message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_A","name":"Agent","input":{"subagent_type":"项目管理师"}}]}}
{"message":{"role":"assistant","content":[{"type":"tool_use","id":"toolu_B","name":"Agent","input":{"subagent_type":"代码审计师"}}]}}
EOF
assert "E3 真并行（前未返回） → 拒绝" 2 "GP-O01" \
    "{\"tool_name\":\"Agent\",\"transcript_path\":\"$TP_E3\",\"tool_use_id\":\"toolu_B\",\"tool_input\":{}}" \
    "$HOOKS_DIR/hook-e-parallel-agent-block.sh"

assert "E4 非 Agent 工具放行" 0 "" \
    '{"tool_name":"Read","transcript_path":"/tmp/x"}' \
    "$HOOKS_DIR/hook-e-parallel-agent-block.sh"

# 场景5：无 tool_use_id payload
assert "E5 无 tool_use_id payload 首次派 → 放行" 0 "" \
    "{\"tool_name\":\"Agent\",\"transcript_path\":\"$TP_E1\",\"tool_input\":{}}" \
    "$HOOKS_DIR/hook-e-parallel-agent-block.sh"

rm -f "$TP_E1" "$TP_E2" "$TP_E3"

# =============================================
echo "Hook-F: git commit 密钥扫描"
# =============================================
REPO=$(mktemp -d)
( cd "$REPO"; git init -q; git config user.email t@t.com; git config user.name t
  printf 'TOKEN="ghp_16C7e42F292c6912E7710c838347Ae178B4a"\n' > app.py
  git add app.py )
assert "F1 github token 拒绝" 2 "" \
    "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git commit -m x\",\"cwd\":\"$REPO\"}}" \
    "$HOOKS_DIR/hook-f-git-secret-scan.sh"

( cd "$REPO"; git reset -q; rm app.py; echo 'TOKEN = "CHANGE_ME"' > app.py; git add app.py )
assert "F2 无泄漏放行" 0 "" \
    "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git commit -m x\",\"cwd\":\"$REPO\"}}" \
    "$HOOKS_DIR/hook-f-git-secret-scan.sh"

assert "F3 --no-verify 拒绝" 2 "" \
    "{\"tool_name\":\"Bash\",\"tool_input\":{\"command\":\"git commit --no-verify -m x\",\"cwd\":\"$REPO\"}}" \
    "$HOOKS_DIR/hook-f-git-secret-scan.sh"

assert "F4 heredoc 含 git commit 不误触发" 0 "" \
    '{"tool_name":"Bash","tool_input":{"command":"cat <<EOF\nfake git commit text\n--no-verify\nEOF","cwd":"/tmp"}}' \
    "$HOOKS_DIR/hook-f-git-secret-scan.sh"

assert "F5 非 Bash 工具放行" 0 "" \
    '{"tool_name":"Read","tool_input":{"command":"git commit"}}' \
    "$HOOKS_DIR/hook-f-git-secret-scan.sh"

assert "F6 ls 命令放行" 0 "" \
    '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
    "$HOOKS_DIR/hook-f-git-secret-scan.sh"

rm -rf "$REPO"

# =============================================
echo "Hook-G: SessionStart 注入"
# =============================================
out=$(echo '{"source":"startup"}' | bash "$HOOKS_DIR/hook-g-session-start.sh" 2>/dev/null)
if echo "$out" | grep -q "Harness v23"; then
    printf '  \033[32m✓\033[0m G1 注入 v23 铁律\n'; PASS=$((PASS+1))
else
    printf '  \033[31m✗\033[0m G1 未注入\n'; FAIL=$((FAIL+1))
fi

# =============================================
echo "Hook-H1: PermissionRequest 自动放行"
# =============================================
assert_stdout "H1.1 Read 自动放行" '"decision":"approve"' \
    '{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"}}' \
    "$HOOKS_DIR/hook-h1-permission-auto-allow.sh"
assert_stdout "H1.2 Bash ls 自动放行" '"decision":"approve"' \
    '{"tool_name":"Bash","tool_input":{"command":"ls -la"}}' \
    "$HOOKS_DIR/hook-h1-permission-auto-allow.sh"
assert_stdout "H1.3 git status 自动放行" '"decision":"approve"' \
    '{"tool_name":"Bash","tool_input":{"command":"git status"}}' \
    "$HOOKS_DIR/hook-h1-permission-auto-allow.sh"
assert "H1.4 Edit 不干预（让 Claude 正常弹窗）" 0 "" \
    '{"tool_name":"Edit","tool_input":{"file_path":"/tmp/x"}}' \
    "$HOOKS_DIR/hook-h1-permission-auto-allow.sh"
assert "H1.5 Bash rm 不干预" 0 "" \
    '{"tool_name":"Bash","tool_input":{"command":"rm file"}}' \
    "$HOOKS_DIR/hook-h1-permission-auto-allow.sh"

# =============================================
echo "Hook-H2: 工具失败结构化日志"
# =============================================
# 清空日志再测
> ~/.claude/logs/hooks/tool-failures.log
assert_stdout "H2.1 Edit 未 Read 错误 → 注入指引" "请先用 Read 工具读取" \
    '{"tool_name":"Edit","tool_use_id":"toolu_x","session_id":"s","cwd":"/tmp","tool_input":{"file_path":"/tmp/x"},"error":"File has not been read yet"}' \
    "$HOOKS_DIR/hook-h2-tool-failure-log.sh"

# 检查日志文件被写入
if grep -q "tool: Edit" ~/.claude/logs/hooks/tool-failures.log; then
    printf '  \033[32m✓\033[0m H2.2 失败日志追加到 tool-failures.log\n'; PASS=$((PASS+1))
else
    printf '  \033[31m✗\033[0m H2.2 日志未写入\n'; FAIL=$((FAIL+1))
fi

# =============================================
printf '\n══════════════════════════════════\n'
printf 'Hook 单测：\033[32m%d PASS\033[0m / \033[31m%d FAIL\033[0m\n' "$PASS" "$FAIL"
if [[ $FAIL -gt 0 ]]; then
    printf '失败用例：%s\n' "${FAILED_CASES[*]}"
fi
printf '══════════════════════════════════\n'
exit $FAIL
