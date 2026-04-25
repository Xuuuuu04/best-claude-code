---
name: bcc-route
description: 预览 Agent Legion Router 对一段输入的分类结果（trivial/small/medium/large/unclear），调试或验证分类规则用。
when_to_use: 当用户怀疑 intent-classify 误判、想测试不同措辞会被分到哪个档位，或调 router 规则前先看效果时使用。
disable-model-invocation: true
allowed-tools: Bash($HOME/.claude/hooks/intent-classify.sh)
arguments: prompt
argument-hint: [要预览分类的文本]
---

# /bcc-route — Router 分类预览

Agent Legion 的 `UserPromptSubmit` hook 链由 `intent-classify.sh` 起头，把每条 prompt 分到 5 档：`trivial / small / medium / large / unclear`。本 Skill 让你**不发真任务**就能预览分类结果，便于调试 router 规则或测试不同措辞。

## 使用

```text
/bcc-route 客户说小程序登录有问题你帮我看看
/bcc-route 把 src/auth/login.ts 里的 redirect 改成 push
/bcc-route 重构整个支付模块
```

## 工作流程

1. 取参数 `$ARGUMENTS` 作为模拟 prompt
2. 用 jq 构造 hook 输入 JSON：`{"prompt": "<参数>", "cwd": "<cwd>", "session_id": "route-preview"}`
3. 调用 `~/.claude/hooks/intent-classify.sh` 把 JSON 喂给 stdin
4. 解析输出 JSON，提取 `additionalContext` 里的 `[LEGION-INTENT]` 行
5. 把 `tier` / `signals` / `suggest` 三段格式化后展示

## 输出格式

```
═══════════════════════════════════════════════════
  Router Preview
═══════════════════════════════════════════════════
  Input  : <用户输入预览>
  Tier   : <trivial|small|medium|large|unclear>
  Signals: <命中的特征>
  Suggest: <建议调度路径>
═══════════════════════════════════════════════════

调度建议（依据 output-styles/legion-dispatch.md 映射表）：
  trivial → 主会话直接答，不派 subagent
  small   → 快路径或 1 个 implementer，code-reviewer 建议
  medium  → product-analyst → implementer → code-reviewer（必经）
  large   → 完整流水线 + 全门控
  unclear → 已 / 将被 clarification-gate 拦截
```

## 实现（执行此命令）

```bash
PROMPT_INPUT="$ARGUMENTS"
if [ -z "$PROMPT_INPUT" ]; then
  echo "用法：/bcc-route <要预览分类的文本>"
  exit 0
fi

# 安全 JSON 化（处理引号/换行）
INPUT_JSON="$(jq -n --arg p "$PROMPT_INPUT" --arg cwd "$PWD" \
  '{prompt:$p, cwd:$cwd, session_id:"route-preview"}')"

OUTPUT="$(echo "$INPUT_JSON" | bash $HOME/.claude/hooks/intent-classify.sh)"

# 提取 additionalContext
CTX="$(echo "$OUTPUT" | jq -r '.hookSpecificOutput.additionalContext // empty')"
if [ -z "$CTX" ]; then
  echo "ERROR: intent-classify 未返回有效结果"
  exit 1
fi

# 解析 tier / signals / suggest
TIER="$(echo "$CTX" | grep -oE 'tier=[a-z]+' | sed 's/tier=//')"
SIGNALS="$(echo "$CTX" | sed -E 's/.*signals=([^|]*).*/\1/' | sed 's/[[:space:]]*$//')"
SUGGEST="$(echo "$CTX" | sed -E 's/.*suggest=//')"

# 格式化输出
INPUT_PREVIEW="$(echo "$PROMPT_INPUT" | head -c 80)"

cat <<EOF
═══════════════════════════════════════════════════
  Router Preview
═══════════════════════════════════════════════════
  Input  : $INPUT_PREVIEW
  Tier   : $TIER
  Signals: $SIGNALS
  Suggest: $SUGGEST
═══════════════════════════════════════════════════
EOF
```

## 失败模式

- 参数为空 → 提示用法后退出
- `intent-classify.sh` 不存在或失败 → 提示用户检查 hook 安装
- 输出无 `additionalContext` → 通常是 hook 内部错误，建议查 `~/.claude/logs/intent-classify.jsonl`

## 与现有机制的关系

- 不是 router 本体，只是观察窗口；真实分类仍由 `UserPromptSubmit` hook 自动跑
- 不写日志（避免污染 `intent-classify.jsonl` 真实统计）
- `disable-model-invocation: true`：只允许用户 `/bcc-route` 主动调用，主会话不会自动触发
