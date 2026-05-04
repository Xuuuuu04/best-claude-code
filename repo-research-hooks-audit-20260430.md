# 仓库研究报告：Hooks 脚本逐个审读

## 结论（TL;DR）

15 个 hook 脚本 + 2 个 _lib 辅助脚本全部功能真实有效，无空壳或占位。整体质量较高（12 个 A/B 级，3 个 B-/C 级有明确瑕疵）。主要问题集中在：cost-log 路径违反 dotclaude-layout 规范、pre-compact 备份路径同样违反规范、clarification-gate 的 block JSON 格式可能不被 Claude Code 正确消费。

## Wrapper 层（_lib/）

### run-with-logging.sh（79 行）
- **功能**：统一入口 wrapper。职责：(1) hook profile 门控（读 hook-flags.sh 判断是否跳过）；(2) 捕获 stderr + 非零退出码写入全局/项目级 `hook-errors.log`；(3) 回放 stderr 给 Claude Code
- **质量评级：A**
- exit code 2（block tool use）被排除在日志之外，设计正确
- 临时文件用 mktemp + rm -f 清理，无泄露

### hook-flags.sh（137 行）
- **功能**：15 个 hook 的 profile 登记 + is_hook_enabled 判定 API
- **质量评级：A**
- 所有 15 个 hook 全部登记在 `_HOOK_MIN_PROFILE` 数组中，与实际文件一一对应
- 黑名单（CLAUDE_DISABLED_HOOKS）优先于 profile 级别，逻辑正确

---

## 逐个脚本审读

### artifact-index-suggest.sh
- **有效代码行数**：41
- **触发**：PostToolUse（Edit|Write），在写入 `.claude/artifacts/` 文件后检查
- **功能**：当某 task-id 的 artifact 累计 >=3 时，注入 additionalContext 提示主会话建立 index 文件
- **质量评级：A**
- 优点：用 marker 文件避免重复提示、用 find 统计数量、task-id 提取正则覆盖了所有 prefix
- 问题：无
- **建议：保留**

### artifact-write-guard.sh
- **有效代码行数**：19
- **触发**：PreToolUse（Edit|Write）
- **功能**：当 `CLAUDE_LEGION_ARTIFACT_ONLY=1` 时，阻止 agent 写入 `.claude/artifacts/` 之外的文件
- **质量评级：A**
- 优点：简洁、目的明确、permissionDecision:deny 格式正确
- 注意：依赖环境变量 `CLAUDE_LEGION_ARTIFACT_ONLY` 由调度器注入，若未设置则完全 no-op
- **建议：保留**

### clarification-gate.sh
- **有效代码行数**：139
- **触发**：UserPromptSubmit（第二位，在 intent-classify 之后）
- **功能**：检测模糊/转述类用户输入，block 并追问 3-5 个精准问题
- **质量评级：B**
- 优点：bypass 机制完整（pending 文件保存原 prompt + TTL 10 分钟 + bypass 关键词回放）；放行条件合理（长 prompt、有文件引用、有代码块均放行）；领域检测定制追问
- 问题：
  1. **block JSON 格式存疑**：输出的 JSON 同时包含 `decision:"block"` 顶层字段和 `hookSpecificOutput`，但 Claude Code UserPromptSubmit hook 是否消费 `decision` 字段来 block 不确定（文档中未找到确认）。如果 Claude Code 不认这个字段，则 block 实际无效——仅 additionalContext 被注入
  2. `$HOME` 硬编码路径用于 state 和 logs（与其他脚本一致，非独特问题，但与 `run-with-logging.sh` 已有的 `$HOME/.claude/logs` 路径重复）
- **建议：保留，但需验证 block 机制是否真正生效**

### instructions-audit.sh
- **有效代码行数**：25
- **触发**：InstructionsLoaded（async）
- **功能**：记录每次会话加载了哪些指令文件，写两份日志（全局 JSONL + 项目级 text）
- **质量评级：A**
- 优点：项目级日志只在 `CLAUDE_PROJECT_DIR/.claude` 存在时写入，避免污染非项目目录；人类可读格式带触发文件溯源
- 问题：
  1. 项目级日志写入 `$PROJ_DIR/.claude/instructions-log.txt`，按 dotclaude-layout 规范应写入 `$PROJ_DIR/.claude/logs/instructions-log.txt`
- **建议：保留，修复日志路径**

### intent-classify.sh
- **有效代码行数**：169
- **触发**：UserPromptSubmit（第一位）
- **功能**：用户意图 5 档分类（trivial/small/medium/large/unclear），注入 `[LEGION-INTENT-HINT]` 为参考信号
- **质量评级：A**
- 优点：v3.4 保守化改造后逻辑清晰（高强度 large 词 1 个即升档、中强度需 >=2 个）；trivial 对中文口语化咨询覆盖充分；默认升档阈值从 200 提升到 500 字节；元对话锚词避免"还有需要升级的吗"被误判 large
- 问题：无显著问题
- **建议：保留**

### permissionrequest-exit-plan-allow.sh
- **有效代码行数**：6
- **触发**：PermissionRequest（matcher: ExitPlanMode）
- **功能**：自动批准 ExitPlanMode 权限请求，免去 plan mode 完成后的确认对话
- **质量评级：A**
- 优点：极简，只做一件事，stdin 消费后直接输出 allow JSON
- 问题：无
- **建议：保留**

### post-compact.sh
- **有效代码行数**：25
- **触发**：PostCompact
- **功能**：压缩后注入调度器身份恢复提示 + 当前进行中 artifact 列表
- **质量评级：B+**
- 优点：恢复提示内容精准（3 条核心纪律 + artifact 列表）
- 问题：
  1. artifact 遍历用 `for f in .../*.md`，如果没有 md 文件，glob 不展开，循环体不会执行（正确），但 `ARTIFACTS` 不会被赋值——实际上此行为是正确的
  2. `jq -n` 没有 `-c` 标志（不影响功能，因为输出只有一行 JSON）
- **建议：保留**

### post-edit-lint.sh
- **有效代码行数**：49
- **触发**：PostToolUse（Edit|Write），async，timeout 30s
- **功能**：文件编辑后自动运行对应语言的 linter/formatter
- **质量评级：A**
- 优点：覆盖 7 种语言（TS/JS、Python、Go、Rust、Swift、Kotlin、Dart）；全部用 `command -v` 检查工具存在性；`npx --no-install` 避免意外安装；全部 `|| true` 容错
- 问题：
  1. `INPUT=$(cat)` 没有加 `|| true`，但在非极端情况下不会失败（stdin 由 Claude Code 提供）
- **建议：保留**

### pre-compact.sh
- **有效代码行数**：17
- **触发**：PreCompact（async）
- **功能**：压缩前保存 git diff / staged diff / artifact 快照到 `.claude/backups/`
- **质量评级：B-**
- 优点：30 天自动清理旧备份
- 问题：
  1. **路径违反 dotclaude-layout 规范**：备份写入 `$CLAUDE_PROJECT_DIR/.claude/backups/`，规范要求应写入 `.claude/logs/backups/` 或 `.claude/artifacts/archive/`
  2. `ls -la *.md` 在无 md 文件时会报错（虽有 `2>/dev/null || true` 容错）
- **建议：保留，修复备份路径到 `.claude/logs/backups/`**

### review-gate.sh
- **有效代码行数**：36
- **触发**：UserPromptSubmit（第三位，在 intent-classify + clarification-gate 之后）
- **功能**：检测本会话是否有 实现工程师 改动未过 高级代码审查师，注入 `[REVIEW-PENDING]` 提示
- **质量评级：A**
- 优点：数据源清晰（subagent-events.jsonl）；仅看本 session_id 的事件；agent 类型匹配覆盖了所有 实现工程师 变体 + 小程序开发专家 + 资深数据库工程师 + 机器学习工程师 + 高级运维工程师；只提示不 block
- 问题：
  1. `grep -F "\"session_id\":\"$SESSION_ID\""` 假设 JSONL 中 session_id 紧跟冒号后无空格——与 `jq -c` 输出一致，问题不大
- **建议：保留**

### scope-lock-guard.sh
- **有效代码行数**：79
- **触发**：PreToolUse（Edit|Write）
- **功能**：enforce scope-lock 白名单，阻止 subagent 写入白名单外文件
- **质量评级：A**
- 优点：主会话豁免（无 agent_id + 无 env）；白名单来源双通道（环境变量 + artifact 解析）；兼容 frontmatter 和 markdown 两种 accepted 格式；artifact 自身写入豁免；awk 解析器支持 3 种条目格式
- 问题：
  1. `shopt -s extglob globstar nullglob` 在 while 循环内每次迭代都调用，微性能浪费（不影响正确性）
- **建议：保留**

### session-start.sh
- **有效代码行数**：44
- **触发**：SessionStart（startup|resume|clear|compact）
- **功能**：会话启动时注入 git 状态（分支、未提交改动、最近提交）+ 进行中 artifact 列表
- **质量评级：A**
- 优点：非 git 仓库完全容错；新仓库无 commit 容错；artifact 目录不存在容错；10% 概率触发日志轮转避免每次启动都跑
- 问题：
  1. `ls .claude/artifacts/*.md` 在无 md 文件时 glob 不展开会报错——但有 `2>/dev/null || true` 兜底
- **建议：保留**

### subagent-start-mark.sh
- **有效代码行数**：11
- **触发**：SubagentStart（async）
- **功能**：在 /tmp 写入 agent 状态文件（agent_name + start_timestamp），供 statusline 读取
- **质量评级：A**
- 优点：每个 (session, agent_id) 独立文件，支持并发多 agent；agent_id 缺失时回退时间戳避免冲突
- 问题：无
- **建议：保留**

### subagent-stop-log.sh
- **有效代码行数**：61
- **触发**：SubagentStop（async）
- **功能**：(1) 记录 SubagentStop 事件到 JSONL；(2) 从 transcript 聚合 token 用量；(3) 写入项目级 cost-log；(4) 清理 /tmp 状态文件
- **质量评级：B+**
- 优点：transcript token 聚合逻辑完整（input/output/cache_cr/cache_rd/turns/model）；agent_id 清理精确（只删自己的，保留兄弟 agent）
- 问题：
  1. **cost-log 路径违反 dotclaude-layout 规范**：写入 `$PROJ_DIR/.claude/cost-log.txt`，规范要求写入 `$PROJ_DIR/.claude/logs/cost-log.txt`
  2. `jq -c` 用法正确（遵循 hook-scripts-pattern 规范）
- **建议：保留，修复 cost-log 路径到 `.claude/logs/cost-log.txt`**

### tool-failure-audit.sh
- **有效代码行数**：24
- **触发**：PostToolUseFailure（async）
- **功能**：工具失败时记录审计日志（tool_name、error、session_id、cwd）
- **质量评级：A**
- 优点：纯审计不输出到 stdout（避免污染 Claude 上下文）；无 jq 时降级写入最小记录；`head -c 500` 限制 error 长度
- 问题：无
- **建议：保留**

---

## 汇总表

| 脚本 | 有效行数 | 评级 | 功能概述 | 建议 |
|:--|:--|:--|:--|:--|
| artifact-index-suggest.sh | 41 | A | artifact >=3 时提示建 index | 保留 |
| artifact-write-guard.sh | 19 | A | artifact-only 环境变量守卫 | 保留 |
| clarification-gate.sh | 139 | B | 模糊输入追问 + bypass 回放 | 保留，验证 block 机制 |
| instructions-audit.sh | 25 | A | 指令加载审计日志 | 保留，修复日志路径 |
| intent-classify.sh | 169 | A | 用户意图 5 档分类 | 保留 |
| permissionrequest-exit-plan-allow.sh | 6 | A | 自动批准 ExitPlanMode | 保留 |
| post-compact.sh | 25 | B+ | 压缩后恢复调度器身份 | 保留 |
| post-edit-lint.sh | 49 | A | 7 语言自动 lint/format | 保留 |
| pre-compact.sh | 17 | B- | 压缩前保存 diff 快照 | 保留，修复备份路径 |
| review-gate.sh | 36 | A | 未 review 改动提醒 | 保留 |
| scope-lock-guard.sh | 79 | A | scope-lock 白名单守卫 | 保留 |
| session-start.sh | 44 | A | 会话启动注入 git 状态 | 保留 |
| subagent-start-mark.sh | 11 | A | 标记活跃 subagent | 保留 |
| subagent-stop-log.sh | 61 | B+ | Subagent 完成日志 + token 聚合 | 保留，修复 cost-log 路径 |
| tool-failure-audit.sh | 24 | A | 工具失败审计日志 | 保留 |

**评级分布**：A 级 11 个 / B+ 级 2 个 / B 级 1 个 / B- 级 1 个

## 关键发现

1. **无空壳/占位**：全部 15 个脚本功能真实，无 TODO 或 placeholder 代码
2. **无硬编码用户名**：所有路径使用 `$HOME` 或 `$CLAUDE_PROJECT_DIR`，无 `/Users/mumuxsy` 等硬编码
3. **容错一致性高**：全部使用 `set -uo pipefail`（无 `-e`），外部命令均有 `2>/dev/null || true` 容错
4. **3 处 dotclaude-layout 路径违规**：
   - `instructions-audit.sh`：`.claude/instructions-log.txt` -> 应在 `.claude/logs/`
   - `pre-compact.sh`：`.claude/backups/` -> 应在 `.claude/logs/backups/`
   - `subagent-stop-log.sh`：`.claude/cost-log.txt` -> 应在 `.claude/logs/`
5. **clarification-gate.sh 的 block 机制需验证**：输出的 `decision:"block"` 是否被 Claude Code 的 UserPromptSubmit hook 实际消费。如果不被消费，该脚本实际效果只是注入 additionalContext（提醒 AI 追问），而非真正阻止用户 prompt 进入处理

## 次要发现

- settings.json 中还有一个内联的 Stop hook（清空 `/tmp/aitm-stop-*`）和一个内联的 PreToolUse hook（prisma migration 只读保护），这两个不在 15 个脚本清单中
- post-compact.sh 和 post-edit-lint.sh 的 `jq -n` 未加 `-c`（输出只有一行时无实际影响，但不一致）
- scope-lock-guard.sh 的 awk 解析器覆盖了 3 种白名单格式，但在极端格式（如嵌套代码块）下可能遗漏

## 未覆盖方向

- clarification-gate.sh 的 block JSON 是否被 Claude Code 正确消费——需要实测或查阅 Claude Code hook 协议文档
- scope-lock-guard.sh 的 awk 白名单解析器在真实 scope-lock artifact 上的覆盖率——需要用实际 artifact 测试
- rotate-logs.sh（被 session-start.sh 调用）的质量未评估
