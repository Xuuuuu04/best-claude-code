#!/usr/bin/env bash
# test-hook-flags.sh — 单元测试 hook-flags.sh 的所有公共 API。
#
# 运行：bash bin/test-hook-flags.sh
# 退出码：0 = 全部通过；1 = 有失败

set -uo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FLAGS="$REPO_DIR/hooks/_lib/hook-flags.sh"

if [ ! -r "$FLAGS" ]; then
  echo "ERROR: hook-flags.sh not readable at $FLAGS" >&2
  exit 1
fi

# shellcheck disable=SC1090
. "$FLAGS"

PASS=0
FAIL=0

_assert() {
  local name="$1"
  local expected="$2"
  local actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  ✓ $name"
    PASS=$((PASS+1))
  else
    echo "  ✗ $name"
    echo "      expected: '$expected'"
    echo "      actual:   '$actual'"
    FAIL=$((FAIL+1))
  fi
}

_enabled_string() {
  # 在 subshell 里设 env 再调 is_hook_enabled，避免污染全局 env
  if is_hook_enabled "$1"; then echo "yes"; else echo "no"; fi
}

echo "=== get_hook_profile ==="

unset CLAUDE_HOOK_PROFILE
_assert "default is standard" "standard" "$(get_hook_profile)"

export CLAUDE_HOOK_PROFILE=minimal
_assert "explicit minimal"  "minimal"  "$(get_hook_profile)"
export CLAUDE_HOOK_PROFILE=STRICT
_assert "uppercase strict"  "strict"   "$(get_hook_profile)"
export CLAUDE_HOOK_PROFILE="  Standard  "
_assert "trimmed standard"  "standard" "$(get_hook_profile)"
export CLAUDE_HOOK_PROFILE=bogus
_assert "bogus falls back"  "standard" "$(get_hook_profile)"
unset CLAUDE_HOOK_PROFILE

echo ""
echo "=== get_disabled_hook_ids ==="

unset CLAUDE_DISABLED_HOOKS
_assert "empty when unset" "" "$(get_disabled_hook_ids)"

export CLAUDE_DISABLED_HOOKS=" post-edit-lint , Scope-Lock-Guard "
# 期望两个 id，顺序按输入；全部小写、去空白
expected="$(printf 'post-edit-lint\nscope-lock-guard\n')"
_assert "two ids normalized" "$expected" "$(get_disabled_hook_ids)"
unset CLAUDE_DISABLED_HOOKS

echo ""
echo "=== hook_id_from_path ==="

_assert "strip .sh"          "scope-lock-guard" "$(hook_id_from_path /abs/path/scope-lock-guard.sh)"
_assert "basename only"      "post-edit-lint"   "$(hook_id_from_path post-edit-lint.sh)"

echo ""
echo "=== get_hook_min_profile ==="

_assert "registered minimal"  "minimal"  "$(get_hook_min_profile session-start)"
_assert "registered standard" "standard" "$(get_hook_min_profile scope-lock-guard)"
_assert "unknown defaults"    "standard" "$(get_hook_min_profile totally-unknown)"

echo ""
echo "=== is_hook_enabled: profile gating ==="

unset CLAUDE_DISABLED_HOOKS
export CLAUDE_HOOK_PROFILE=minimal
_assert "minimal allows session-start"    "yes" "$(_enabled_string session-start)"
_assert "minimal blocks scope-lock-guard" "no"  "$(_enabled_string scope-lock-guard)"
_assert "minimal blocks post-edit-lint"   "no"  "$(_enabled_string post-edit-lint)"

export CLAUDE_HOOK_PROFILE=standard
_assert "standard allows session-start"    "yes" "$(_enabled_string session-start)"
_assert "standard allows scope-lock-guard" "yes" "$(_enabled_string scope-lock-guard)"
_assert "standard allows post-edit-lint"   "yes" "$(_enabled_string post-edit-lint)"

export CLAUDE_HOOK_PROFILE=strict
_assert "strict allows session-start"     "yes" "$(_enabled_string session-start)"
_assert "strict allows scope-lock-guard"  "yes" "$(_enabled_string scope-lock-guard)"

echo ""
echo "=== is_hook_enabled: disable blacklist ==="

unset CLAUDE_HOOK_PROFILE
export CLAUDE_DISABLED_HOOKS="post-edit-lint"
_assert "blacklisted disabled even in standard" "no" "$(_enabled_string post-edit-lint)"
_assert "others still allowed"                  "yes" "$(_enabled_string scope-lock-guard)"

export CLAUDE_DISABLED_HOOKS="Post-Edit-Lint,  SCOPE-lock-guard"
_assert "blacklist case-insensitive #1" "no" "$(_enabled_string post-edit-lint)"
_assert "blacklist case-insensitive #2" "no" "$(_enabled_string scope-lock-guard)"

unset CLAUDE_DISABLED_HOOKS

echo ""
echo "=== is_hook_enabled: edge cases ==="

_assert "empty id allowed"      "yes" "$(_enabled_string "")"
_assert "unknown id allowed"    "yes" "$(_enabled_string something-new)"

echo ""
echo "=== list_registered_hooks sanity ==="
COUNT="$(list_registered_hooks | awk 'NF>0' | wc -l | tr -d ' ')"
if [ "$COUNT" -ge 9 ]; then
  echo "  ✓ registered at least 9 hooks ($COUNT total)"
  PASS=$((PASS+1))
else
  echo "  ✗ expected >=9 registered hooks, got $COUNT"
  FAIL=$((FAIL+1))
fi

echo ""
echo "---- Summary ----"
echo "PASS: $PASS"
echo "FAIL: $FAIL"
[ "$FAIL" -eq 0 ]
