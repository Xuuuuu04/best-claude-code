---
name: bcc-check
description: 检查 BCC Harness 是否完整可用——验证 hooks 可执行、settings.json 注册正确、jq 已安装、skills frontmatter 合法、MCP servers 可启动。在 /bcc-init 之后或怀疑 harness 出问题时调用。
argument-hint: "[--fix 自动修复可修的问题（可选）]"
---

# /bcc-check

一键验证 harness 健康状态。不改任何文件，只报告问题。

## 动态状态

!`echo "### jq"; which jq 2>/dev/null && jq --version || echo "NOT FOUND"; echo ""; echo "### hooks"; ls -la ~/.claude/hooks/*.sh 2>/dev/null | awk '{print $1, $NF}'; echo ""; echo "### settings hooks"; jq -r '.hooks | keys[]' ~/.claude/settings.json 2>/dev/null; echo ""; echo "### skills"; ls -d ~/.claude/skills/*/ 2>/dev/null | xargs -I {} basename {}; echo ""; echo "### rules"; ls ~/.claude/rules/*.md 2>/dev/null | xargs -I {} basename {}`

## 检查项

依次跑以下检查，每项输出 ✓ 或 ✗：

### 1. 基础依赖
```bash
# jq 必须存在
command -v jq >/dev/null && echo "✓ jq $(jq --version)" || echo "✗ jq 未安装"
```

### 2. Hook 文件完整性
```bash
HOOKS_DIR="$HOME/.claude/hooks"
REQUIRED_HOOKS=("_common.sh" "precompact.sh" "postcompact.sh" "session-start.sh" "session-end.sh" "posttooluse-guard.sh" "stop-progress-gate.sh")

for H in "${REQUIRED_HOOKS[@]}"; do
  F="$HOOKS_DIR/$H"
  if [ ! -f "$F" ]; then
    echo "✗ 缺失: $H"
  elif [ ! -x "$F" ]; then
    echo "✗ 不可执行: $H"
  else
    echo "✓ $H"
  fi
done
```

### 3. Settings.json hook 注册
```bash
REQUIRED_EVENTS=("PreCompact" "PostCompact" "SessionStart" "SessionEnd" "PostToolUse" "Stop")
REGISTERED=$(jq -r '.hooks | keys[]' ~/.claude/settings.json 2>/dev/null)

for E in "${REQUIRED_EVENTS[@]}"; do
  if echo "$REGISTERED" | grep -q "^${E}$"; then
    echo "✓ $E 已注册"
  else
    echo "✗ $E 未注册"
  fi
done
```

### 4. Hook 文件与注册一致性

检查 settings.json 里指向的文件是否都存在且可执行：
```bash
jq -r '.hooks | to_entries[] | .value[0].hooks[0].command' ~/.claude/settings.json | while read CMD; do
  if [ -x "$CMD" ]; then
    echo "✓ $CMD"
  else
    echo "✗ $CMD (不存在或不可执行)"
  fi
done
```

### 5. Skills frontmatter 格式

每个 skill 的 SKILL.md 必须有 name 和 description：
```bash
for DIR in ~/.claude/skills/*/; do
  SKILL_FILE="$DIR/SKILL.md"
  if [ ! -f "$SKILL_FILE" ]; then
    echo "✗ $(basename $DIR): 缺 SKILL.md"
    continue
  fi
  # 检查 frontmatter 有 name 和 description
  HAS_NAME=$(grep -c '^name:' "$SKILL_FILE")
  HAS_DESC=$(grep -c '^description:' "$SKILL_FILE")
  if [ "$HAS_NAME" -gt 0 ] && [ "$HAS_DESC" -gt 0 ]; then
    echo "✓ $(basename $DIR)"
  else
    echo "✗ $(basename $DIR): frontmatter 缺 name 或 description"
  fi
done
```

### 6. Rules 存在性
```bash
REQUIRED_RULES=("git-safety.md" "sensitive-files.md" "honest-communication.md")
for R in "${REQUIRED_RULES[@]}"; do
  [ -f "$HOME/.claude/rules/$R" ] && echo "✓ $R" || echo "✗ $R 缺失"
done
```

### 7. 版本检查
```bash
VERSION_FILE="$HOME/.claude/VERSION"
if [ -f "$VERSION_FILE" ]; then
  echo "✓ Harness $(cat $VERSION_FILE)"
else
  echo "⚠ 无版本文件（建议创建 ~/.claude/VERSION）"
fi
```

## 输出格式

```
BCC Harness 健康检查
====================
基础依赖:     ✓ jq 1.7.1
Hook 文件:    ✓ 7/7
Hook 注册:    ✓ 6/6
注册一致性:   ✓ 6/6
Skills:       ✓ 10/10
Rules:        ✓ 3/3
版本:         v2.1.0

总计: 全部通过 / 有 N 项问题
```

如果有 ✗，在最后列出修复建议。

## --fix 模式

如果用户传了 --fix：
- 不可执行的 hook → `chmod +x`
- 缺失的注册 → 提示（不自动改 settings.json，太危险）
- 缺失的文件 → 只报告，不自动创建
