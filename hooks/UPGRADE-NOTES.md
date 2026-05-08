# Hook 升级配置说明（v5.0）

本文件记录 Agent Legion v5.0 升级所需的 settings.json hook 配置变更。
将这些配置合并到 `~/.claude/settings.json` 的 `hooks` 字段中。

## 新增 Hook 事件注册

### TaskCreated（Agent Teams 任务创建同步）

```json
"TaskCreated": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/task-created-sync.sh"
      }
    ]
  }
]
```

### TaskCompleted（Agent Teams 任务完成同步）

```json
"TaskCompleted": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/task-completed-sync.sh"
      }
    ]
  }
]
```

### FileChanged（Artifact 文件变更校验）

```json
"FileChanged": [
  {
    "matcher": ".claude/artifacts/|artifacts/",
    "hooks": [
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/artifact-file-changed.sh"
      }
    ]
  }
]
```

注意：FileChanged 的 matcher 使用字面文件名（不支持正则），用 `|` 分隔多个监视目标。

### PostToolUseFailure（工具失败捕获）

```json
"PostToolUseFailure": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/tool-failure-capture.sh"
      }
    ]
  }
]
```

此 hook 替代旧版 `tool-failure-audit.sh` 的 `PostToolUse` matcher 方案。
旧版配置（PostToolUse 中 matcher 为 Bash 的 tool-failure-audit 条目）可在确认新 hook 正常后移除。

## Prompt-based Hook 升级（clarification-gate）

clarification-gate 可升级为 prompt-based hook，利用 Claude 模型做语义判断替代 bash 关键词正则。

### 方案 A：纯 Prompt-based（推荐，需 Claude Code v2.1.80+）

在 UserPromptSubmit hook 链中，将 clarification-gate 的 bash 脚本替换为 prompt-based hook：

```json
"UserPromptSubmit": [
  {
    "hooks": [
      {
        "type": "prompt",
        "prompt": "你是 Agent Legion 的需求澄清门控。判断用户 prompt 是否缺少关键信息。\n\n规则：\n1. 如果请求明确且完整（有具体目标、文件路径、错误日志、验收标准中的至少一项），返回 {\"decision\": \"allow\"}\n2. 如果请求提到截图/图片/设计稿但没有附件，返回 {\"decision\": \"block\", \"reason\": \"⚠️ Clarification Gate — 缺少关键资产\\n\\n请补充截图/图片/设计稿后重发。如确认不需，回复 直接做 即可。\"}\n3. 如果请求提到报错/崩溃但没有错误日志或复现步骤，返回 {\"decision\": \"block\", \"reason\": \"⚠️ Clarification Gate — 缺少错误信息\\n\\n请补充错误日志或复现步骤后重发。如确认不需，回复 直接做 即可。\"}\n4. 如果请求模糊但无硬性缺失（如 帮我看看/搞一下/优化一下），返回 {\"decision\": \"allow\"}，但在 reason 中写 [UNDERSTANDING-CHECK] 提示主会话做理解自检\n5. 长 prompt（>500 字符）默认放行\n6. 用户说 直接做/按你想的来/skip 时放行\n\n只返回 JSON，不要额外解释。"
      },
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/review-gate.sh"
      }
    ]
  }
]
```

### 方案 B：Bash Fallback（兼容旧版本）

保留 bash 版 clarification-gate.sh 作为 fallback，在 prompt hook 不可用时降级：

```json
"UserPromptSubmit": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/clarification-gate.sh"
      },
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/review-gate.sh"
      }
    ]
  }
]
```

### 方案 C：Prompt + Bash 双保险

先尝试 prompt hook，失败时 fallback 到 bash：

```json
"UserPromptSubmit": [
  {
    "hooks": [
      {
        "type": "prompt",
        "prompt": "（同方案 A 的 prompt 内容）"
      },
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/clarification-gate.sh"
      },
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/review-gate.sh"
      }
    ]
  }
]
```

注意：方案 C 中 prompt hook 和 bash hook 都会执行。如果 prompt hook 已 block，bash hook 仍会运行但 Claude Code 已处理了 block 决策。建议选择方案 A 或 B，不要同时使用。

## 迁移步骤

1. 备份当前 settings.json：`cp ~/.claude/settings.json ~/.claude/settings.json.bak`
2. 将上述新 hook 事件配置合并到 settings.json 的 `hooks` 字段
3. 选择 clarification-gate 升级方案（A/B/C），更新 UserPromptSubmit 配置
4. 重启 Claude Code 会话
5. 运行 `/bcc-doctor` 验证 hook 注册状态
6. 测试新 hook：修改 artifact 文件触发 FileChanged、使用 Agent Teams 触发 TaskCreated/TaskCompleted
7. 确认 PostToolUseFailure 正常后，可移除旧版 tool-failure-audit 的 PostToolUse matcher 条目

## 新增 PermissionRequest Hook（v5.2）

解决 Claude Code 编辑 `.claude/` 目录文件时反复弹权限确认的问题。

```json
"PermissionRequest": [
  {
    "hooks": [
      {
        "type": "command",
        "command": "$HOME/.claude/hooks/_lib/run-with-logging.sh $HOME/.claude/hooks/permission-auto-claude.sh"
      }
    ]
  }
]
```

**安全说明**：
- 仅自动批准 `.claude/` 和 `~/.claude/` 目录下的 Edit/Write 请求
- 不批准 `.claude/` 外的任何文件编辑（业务代码、配置文件等）
- 不批准 Bash 工具、Read 工具等其他工具的权限请求
- 建议配合 `CLAUDE_HOOK_PROFILE=standard` 使用

## Hook 计数变更

| 变更 | 数量 |
|:--|:--|
| 原有主 hook | 17 |
| 新增 hook | 4（task-created-sync / task-completed-sync / artifact-file-changed / permission-auto-claude） |
| 替代 hook | 1（tool-failure-capture 替代 tool-failure-audit 的 PostToolUse matcher 用法） |
| 升级后总计 | 21 主 hook + 3 `_lib` 辅助脚本 |
