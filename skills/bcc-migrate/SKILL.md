---
name: bcc-migrate
description: 迁移流水线。适用于 schema 变更、框架/库大版本升级、语言版本升级、大型数据格式迁移。强调多步骤、双写、可回滚。
disable-model-invocation: true
---

# 迁移流水线

`$ARGUMENTS` 是迁移描述，如：
- "把 users 表的 email 列从 VARCHAR(100) 扩展到 VARCHAR(255)"
- "升级 Next.js 13 → 15"
- "把所有 `moment` 使用替换为 `dayjs`"
- "PostgreSQL 14 → 16"

迁移与新功能的本质差别：**数据或运行态不能中断**。线上有用户正在使用，迁移必须边跑边迁，任何一步失败都要可回滚。

---

## 核心纪律

1. **多步骤设计**：绝不单步 DDL 改完、部署完。标准流程是"新增 → 双写 → 回填 → 切读 → 停写旧 → 删除旧"
2. **每步可回滚**：每个步骤都必须有明确的回滚命令/流程
3. **数据完整性优先**：宁可慢不要快。迁移过程中任何可能丢数据的操作停下来报告
4. **生产前 staging 验证**：完整流程先在 staging 跑一遍
5. **迁移执行不等于应用部署**：迁移分步推进，应用部署独立进行——两者的 rollback 策略不同

---

## Phase 1: 分析与方案

### 1.1 派遣 researcher 做影响面分析

```
任务：分析此迁移的完整影响面。
目标：{$ARGUMENTS}

产出 .claude/artifacts/migration-impact-{task-id}.md：

1. 直接影响
   - 涉及的 schema/代码/数据文件
   - 数据量级（行数、大小）
   - 读写频率（每秒请求）

2. 间接影响
   - 所有读取者列表（代码中的查询/使用点）
   - 所有写入者列表
   - 关联服务（消息队列、缓存、下游依赖）

3. 破坏性分析
   - 哪些是向后兼容变更
   - 哪些是破坏性（必须多步走）
   - 哪些数据需要回填/转换

4. 风险清单
   - 锁表/停服风险
   - 数据丢失风险
   - 性能退化风险
   - 回滚难度评级（easy / medium / hard / irreversible）
```

### 1.2 派遣 architect 设计迁移步骤

```
任务：基于影响面分析，设计多步迁移方案。
影响面报告：.claude/artifacts/migration-impact-{task-id}.md
目标：{$ARGUMENTS}

产出 .claude/artifacts/migration-plan-{task-id}.md：

1. 迁移步骤（每步独立、可验证、可回滚）
   Step 1：{具体操作}
     - 改动文件/SQL：...
     - 执行命令：...
     - 验证方式：...
     - 回滚命令：...
     - 预计持续：...

   Step 2：...

2. 每步之间的观察期
   - Step N 完成后观察 {多久}，检查 {哪些指标}，达标再进下一步

3. feature flag 策略（如涉及代码双写/双读）

4. 最终验收标准

5. 紧急回滚预案
   - 如在 Step N 发现问题，回退到 Step N-1 的完整命令
   - 数据丢失场景的恢复方式

同时为每个 Step 产出独立的 scope-lock-{task-id}-step-{N}.md。
```

### 1.3 quality-guardian 做迁移方案审查（关键）

```
审查类型：migration-review（新增模式）
对象：migration-impact + migration-plan + 所有 scope-lock

审查重点（比普通架构审查更严）：
- [ ] 每个步骤真的独立可部署？
- [ ] 每步的回滚命令明确且经过思考？
- [ ] 数据完整性在每步中间状态都被保持？
- [ ] 双写逻辑正确处理了并发冲突？
- [ ] 回填策略不会锁表过久？
- [ ] 观察期的指标可测量？
- [ ] 最坏情况（Step 3 失败，数据已在新列）的处理方案？

驳回 = 迁移方案需要重做。不接受"可能有问题但先试试"的态度。
```

---

## Phase 2: Staging 执行

### 2.1 用户确认 + 环境切换

```
迁移方案已准备就绪。执行前请确认：
- 目标环境：staging（建议先 staging 完整跑一遍）
- 预计总时长：...
- Step 数：...
- 回滚可行性：[ok / 部分步骤单向]

是否开始在 staging 执行？
```

使用 `AskUserQuestion` 等待确认。用户同意后进入。

### 2.2 逐步执行（每步一个 implementer/devops）

对每个 Step，派遣合适的 Agent：
- schema 相关 → implementer-backend + devops
- 代码双写/双读逻辑 → 对应领域 implementer
- 运维步骤 → devops

**前台阻塞**执行每个 Step，等观察期达标才进下一步。每 Step 完成后产出 impl-report。

### 2.3 每步后 quality-guardian 验证

```
审查类型：migration-step-verify
对象：Step N 的 impl-report + 相关监控指标

检查：
- 预期效果达成？
- 观察期指标在正常范围？
- 无预期外副作用？
```

未通过则**立即执行该 Step 的回滚命令**，停止流水线，汇报用户。

---

## Phase 3: 生产执行（需再次确认）

staging 完整成功后，**必须用户二次确认**才能在生产执行：

```
staging 迁移验证通过（耗时 {X}，覆盖 {Y} 条数据）。

生产环境迁移是不可完全自动化的动作，需要人工把关：
- 建议执行窗口：{低峰时段}
- 预计生产耗时：{Z}（基于 staging × 流量比例）
- 回滚预案：已准备（见 migration-plan-{task-id}.md § 紧急回滚）

是否开始生产迁移？建议有工程师实时值守。
```

生产 Step 之间的观察期比 staging 更长。

---

## Phase 4: 清理与归档

### 4.1 迁移完成后删除过渡代码/数据

如果有双写逻辑、feature flag、旧列等过渡物：派遣 implementer 走 scope-lock 最终清理。

### 4.2 产出迁移报告

`.claude/artifacts/migration-report-{task-id}.md`：

```markdown
# 迁移报告：{目标}

## 执行时间线
- Step 1: 2026-04-23 02:00 - 02:15
- 观察期 1: 24h
- Step 2: 2026-04-24 02:30 - 03:00
- ...

## 实际指标
- 数据量：迁移 X 行
- 耗时：总 Y
- 峰值延迟影响：Z

## 遇到的问题
（无 / 列出并说明如何处理）

## 保留的过渡代码
（如需后续清理，列出）
```

### 4.3 更新 project-knowledge

静默触发 `/bcc-update-project` 更新项目状态（新 schema、新依赖版本等）。

---

## 不适合走 `/bcc-migrate` 的场景

- 纯内部代码重构（→ `/bcc-refactor`）
- 新功能伴随的 schema 新增（→ `/bcc-new-feature`，自带 migration 设计）
- 小补丁级库升级（patch version，→ devops 直接处理）
- 单文件格式转换（→ `/bcc-quick-fix` 或直接处理）
