#!/bin/bash
# post-edit-lint.sh
# 目的：在文件 Edit/Write 后自动运行对应语言的 linter / formatter
# 触发：PostToolUse hook（matcher: Edit|Write）
#
# 行为：静默运行，失败不阻断 Claude 工作流。目的是"机会性修复"而非强制。

set -euo pipefail

INPUT=$(cat)

# 提取被编辑的文件路径
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null || echo "")

# 无路径或文件不存在直接退出
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

# 获取扩展名（小写）
EXT="${FILE_PATH##*.}"
EXT=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')

# 依语言选择工具（工具缺失时静默跳过）
case "$EXT" in
  ts|tsx|js|jsx|mts|cts)
    if command -v npx >/dev/null 2>&1; then
      npx --no-install eslint --fix "$FILE_PATH" >/dev/null 2>&1 || true
      npx --no-install prettier --write "$FILE_PATH" >/dev/null 2>&1 || true
    fi
    ;;
  py)
    if command -v ruff >/dev/null 2>&1; then
      ruff check --fix --quiet "$FILE_PATH" >/dev/null 2>&1 || true
      ruff format --quiet "$FILE_PATH" >/dev/null 2>&1 || true
    elif command -v black >/dev/null 2>&1; then
      black --quiet "$FILE_PATH" >/dev/null 2>&1 || true
    fi
    ;;
  go)
    if command -v gofmt >/dev/null 2>&1; then
      gofmt -w "$FILE_PATH" >/dev/null 2>&1 || true
    fi
    ;;
  rs)
    if command -v rustfmt >/dev/null 2>&1; then
      rustfmt --quiet "$FILE_PATH" >/dev/null 2>&1 || true
    fi
    ;;
  swift)
    if command -v swiftformat >/dev/null 2>&1; then
      swiftformat --quiet "$FILE_PATH" >/dev/null 2>&1 || true
    fi
    ;;
  kt|kts)
    if command -v ktlint >/dev/null 2>&1; then
      ktlint --format "$FILE_PATH" >/dev/null 2>&1 || true
    fi
    ;;
  dart)
    if command -v dart >/dev/null 2>&1; then
      dart format "$FILE_PATH" >/dev/null 2>&1 || true
    fi
    ;;
esac

exit 0
