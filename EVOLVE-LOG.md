# Evolve Log

Agent Legion 系统的进化历史。每次 `/bcc-evolve` 执行后追加一条。

---

## 2026-04-23 · v1（首次进化）

### 触发

手动 `/bcc-evolve`。此前 `/bcc-reflect` 产出了 17 条 Memory（5 user + 11 feedback + 6 project），主要来自 Agent Legion 系统架构建造期的踩坑和自省。

### 批准的提案

**批准：4 / 4（全部）**

### 已执行的变更

- [NEW] `rules/_global/hook-scripts-pattern.md` — 合并 5 条 hook 相关 feedback 为一条全局 Rule
  - 来源：`hook-scripts-no-set-e`、`jq-append-needs-compact-mode`、`hook-if-field-env-var-danger`、`test-run-cwd-leaks`、`test-with-real-event-samples`
- [DOC] `LEGION.md § 3.4`（Subagents 机制）— 新增"SubagentStop 事件与 Transcript 对应关系"和"并发 Subagent 状态追踪"两小节
  - 来源：`subagent-stop-event-minimal-fields`、`subagent-transcript-location`、`concurrent-subagents-need-id-namespacing`
- [DOC] `LEGION.md § 3.12`（系统健康信号）— 新节
  - 来源：`healthy-prompt-cache-ratio`、`turn-count-as-quality-signal`
- [CLEAN] 清理 `feedback.md` 移除 8 条已固化条目，`project-notes.md` 移除 3 条已固化条目
  - MEMORY.md 索引同步更新，从 17 条缩到 10 条

### 跟踪指标

- 进化前 Memory 总行数: 337 → 进化后: ~160
- 新 Rule 预期触发频率: 每次修改 hook 脚本都应该被 quality-guardian 参考
- LEGION.md 体积变化: +102 行（文档增量合理，用于替代 Memory 中的重复提醒）

### 元观察（为什么这次是"保守型进化"）

本次 Memory 条目**全部来自系统建造期**，而非流水线实战。这意味着：
- 结构性事实（Skills 扁平、hook 模式）— 已经充分验证，固化是安全的
- 但流水线使用层面的痛点 — **完全没有数据**（因为还没真正跑过端到端流水线）

因此本次进化只处理了"建造期结构教训"。流水线层面的经验需要 2 周实战积累后才能进化。

### 下次审查时机

**建议 2-3 周后**（约 2026-05-10 前后），前提是：
- 至少完成 3 次端到端流水线（`/bcc-new-feature` 或 `/bcc-fix-bug`）
- 至少触发 1 次 `/bcc-quick-fix`
- `/bcc-doctor` 运行过 ≥2 次
- cost-log 积累到 ≥30 次 subagent 调用

### 回退方式

如发现本次进化产出的 Rule 或文档有问题：
```bash
git revert <本次 commit hash>
```
Memory 条目也可从 git 历史恢复。
