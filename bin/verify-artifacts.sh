#!/bin/bash
# verify-artifacts.sh — 在 verdict 前检查所有必需 artifact 是否存在、有效且无 STALE
# 基于 ARIS verify_paper_audits.sh 思想，适配为 Agent Legion 通用 verifier
set -uo pipefail

ARTIFACTS_DIR="${1:-.claude/artifacts}"
EXIT_CODE=0

echo "=== Artifact Verifier ==="
echo "Directory: $ARTIFACTS_DIR"
echo ""

# 检查必需 artifact 类型是否存在
# 对于 submission assurance，以下 artifact 类型至少应有一份
check_artifact() {
    local pattern="$1"
    local description="$2"
    local required="${3:-false}"

    local count
    count=$(find "$ARTIFACTS_DIR" -maxdepth 1 -name "$pattern" 2>/dev/null | wc -l | tr -d ' ')

    if [ "$count" -gt 0 ]; then
        echo "  ✓ $description — found $count file(s)"
    else
        if [ "$required" = "true" ]; then
            echo "  ✗ $description — MISSING (required)"
            EXIT_CODE=1
        else
            echo "  ⚠ $description — not found (optional)"
        fi
    fi
}

# 检查头部字段完整性
check_header() {
    local file="$1"
    local missing=0

    grep -q "^# " "$file" 2>/dev/null || missing=$((missing + 1))
    grep -q "^\*\*Task ID\*\*" "$file" 2>/dev/null || missing=$((missing + 1))
    grep -q "^\*\*生成时间\*\*" "$file" 2>/dev/null || missing=$((missing + 1))
    grep -q "^\*\*产出者\*\*" "$file" 2>/dev/null || missing=$((missing + 1))
    grep -q "^\*\*状态\*\*" "$file" 2>/dev/null || missing=$((missing + 1))

    if [ "$missing" -gt 0 ]; then
        echo "    ✗ Header incomplete ($missing fields missing)"
        EXIT_CODE=1
    else
        echo "    ✓ Header complete"
    fi
}

echo "1. Required artifacts:"
check_artifact "requirements-*.md" "Requirements" "true"
check_artifact "scope-lock-*.md" "Scope Lock" "true"
check_artifact "impl-report-*.md" "Implementation Report" "true"
check_artifact "review-code-*.md" "Code Review" "true"

echo ""
echo "2. Optional artifacts:"
check_artifact "architecture-*.md" "Architecture" "false"
check_artifact "review-security-*.md" "Security Audit" "false"
check_artifact "review-functional-*.md" "Functional Test" "false"
check_artifact "review-visual-*.md" "Visual Test" "false"
check_artifact "verdict-*.md" "Verdict" "false"

echo ""
echo "3. Header validation (latest artifacts):"
for f in "$ARTIFACTS_DIR"/requirements-*.md "$ARTIFACTS_DIR"/scope-lock-*.md "$ARTIFACTS_DIR"/impl-report-*.md "$ARTIFACTS_DIR"/review-code-*.md; do
    [ -f "$f" ] || continue
    echo "  $(basename "$f"):"
    check_header "$f"
done

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
    echo "=== Result: ALL GREEN ==="
else
    echo "=== Result: BLOCKED ==="
    echo "Missing required artifacts or incomplete headers. Fix before submission."
fi

exit $EXIT_CODE
