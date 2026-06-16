---
name: bcc-check
description: '检查 BCC Harness 是否完好:hooks 可执行、settings 注册、jq 已装、skills frontmatter 严格 YAML 合法。在 /bcc-init 之后或怀疑 harness 出问题时调用。'
argument-hint: "[--fix 自动修复可修的问题（可选）]"
---

# /bcc-check

跑一遍看 harness 有没有坏的。只读不改,报告问题。

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
# _common.sh 是被 source 的库，不需要 +x，只检存在；6 个事件 hook 才需可执行
[ -f "$HOOKS_DIR/_common.sh" ] && echo "✓ _common.sh (库，被 source)" || echo "✗ 缺失: _common.sh"

EVENT_HOOKS=("precompact.sh" "session-start.sh" "posttooluse-guard.sh" "posttoolusefailure.sh" "stop-progress-gate.sh" "userpromptsubmit-router.sh")
for H in "${EVENT_HOOKS[@]}"; do
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
REQUIRED_EVENTS=("PreCompact" "SessionStart" "PostToolUse" "PostToolUseFailure" "Stop" "UserPromptSubmit")
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

### 5. Skills frontmatter 严格解析

grep 行存在性查不出截断和非法 YAML(本仓库踩过两次:description 含 ` #` 被当注释截断、含 `: ` 报 ScannerError),所以严格 YAML 解析全部 SKILL.md,并比对 description 解析长度与原文行长度:

```bash
for DIR in ~/.claude/skills/*/; do
  SKILL_FILE="${DIR}SKILL.md"
  if [ ! -f "$SKILL_FILE" ]; then
    echo "✗ $(basename $DIR): 缺 SKILL.md"
    continue
  fi
  if python3 - "$SKILL_FILE" <<'PYEOF'
import re, sys, yaml
raw = open(sys.argv[1]).read().split('---')[1]
d = yaml.safe_load(raw)  # 非法 YAML 在这里直接抛错
assert d.get('name') and d.get('description'), '缺 name 或 description'
line = re.search(r'^description:\s*(.+)$', raw, re.M).group(1).strip().strip('\'"')
parsed = str(d['description']).strip()
assert len(parsed) >= len(line) - 2, f'description 截断: 解析 {len(parsed)} / 原文 {len(line)}'
PYEOF
  then
    echo "✓ $(basename $DIR)"
  else
    echo "✗ $(basename $DIR): frontmatter 非法 YAML 或 description 截断"
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
Hook 文件:    ✓ 6/6
Hook 注册:    ✓ 6/6
注册一致性:   ✓ 6/6
Skills:       ✓ 9/9
Rules:        ✓ 3/3
版本:         v2.4.0

总计: 全部通过 / 有 N 项问题
```

如果有 ✗，在最后列出修复建议。

## --fix 模式

如果用户传了 --fix：
- 不可执行的 hook → `chmod +x`
- 缺失的注册 → 提示（不自动改 settings.json，太危险）
- 缺失的文件 → 只报告，不自动创建
