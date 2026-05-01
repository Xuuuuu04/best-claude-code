---
name: review-tracing-protocol
description: >
  Review Tracing 协议。保存每次跨 Agent 审稿调用的完整上下文，
  用于 reviewer-independence 审计、可复现性和 harness 改进分析。
when_to_use: >
  仅当 review-tracing 被显式启用时加载。默认关闭（off）。
  不适用于纯信息性 LLM 调用。
---

# Review Tracing Protocol

## 目的

保存每次跨 Agent 审稿调用的完整上下文，实现：
- **Reviewer-independence 审计**：验证执行者只传递了文件路径，未传递摘要
- **可复现性**：保留会话标识支持续传
- **Harness 改进分析**：为系统进化提供数据输入

## 何时追踪

每次以下 Agent 完成审查后：
- code-reviewer、security-auditor、functional-tester、visual-tester
- academic-paper-reviewer、research-reviewer、content-reviewer

不追踪：纯信息性调用（非审查功能）。

## 追踪目录

```
.claude/logs/traces/
└── {agent-name}/
    └── {YYYY-MM-DD}_run{NN}/
        ├── run.meta.json
        ├── 001-{purpose}.request.json
        ├── 001-{purpose}.response.md
        └── 001-{purpose}.meta.json
```

- `{agent-name}`：触发审查的 Agent 名称（如 `code-reviewer`）
- `{YYYY-MM-DD}_run{NN}`：日期 + 序号（从 01 开始）
- `{purpose}`：短 kebab-case 标签（如 `scope-lock-review`、`security-audit`）

## 文件格式

### run.meta.json
```json
{
  "agent": "code-reviewer",
  "run_id": "2026-05-01_run01",
  "started_at": "2026-05-01T14:30:00+08:00",
  "executor": "implementer-frontend",
  "task_id": "feat-20260501-01"
}
```

### NNN-{purpose}.request.json
```json
{
  "call_number": 1,
  "purpose": "scope-lock-review",
  "timestamp": "2026-05-01T14:31:00+08:00",
  "files_referenced": ["src/auth.ts", "src/api.ts"],
  "context_summary": "审查登录功能实现"
}
```

### NNN-{purpose}.response.md
审查者的完整响应原文。不截断，不摘要。

### NNN-{purpose}.meta.json
```json
{
  "call_number": 1,
  "purpose": "scope-lock-review",
  "timestamp": "2026-05-01T14:33:00+08:00",
  "duration_ms": 42000,
  "status": "ok",
  "verdict": "PASS"
}
```

## 配置

三级模式：
- **`full`**（默认）：保存完整 request context + response
- **`meta`**：仅保存元数据（无详细内容），适用于敏感项目
- **`off`**：关闭追踪

## 隐私

- `.claude/logs/traces/` 已纳入 `.gitignore`
- 追踪内容可能包含敏感信息，视为机密
- 严格保密项目使用 `off`
