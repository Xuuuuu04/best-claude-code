---
name: bcc-migrate
description: 迁移流水线。适用于 schema 变更、框架/库大版本升级和大型数据迁移。
disable-model-invocation: true
---

# 迁移流水线

`$ARGUMENTS` 是迁移描述。迁移强调：**多步骤、可回滚、先 staging 后 production**。

调度真源：`rules/_global/dispatch-table.md`。若本 Skill 与调度表冲突，以调度表为准。迁移、数据库、生产部署属于 `S0` 高风险链路，默认禁止并发。

## Phase 1: 影响分析与方案

### 1.1 `repo-researcher`

产出 `.claude/artifacts/migration-impact-{task-id}.md`：
- 直接/间接影响
- 数据量级
- 读写者列表
- 破坏性分析
- 风险与回滚难度

### 1.2 `tech-researcher`（按需）

若是框架/库/语言大版本升级，补外部 breaking changes 和迁移指南。

### 1.3 `architect`

产出 `.claude/artifacts/migration-plan-{task-id}.md`：
- 多步迁移方案
- 每步验证
- 每步回滚
- 观察期与 feature flag

### 1.4 `scope-planner`

为每个迁移 step 产出独立 scope-lock。

迁移 step 即使看起来互不相关，也默认串行。只有纯代码适配、无 schema/依赖/部署目标共享，且 `scope-plan` 明确同 Batch 时，才允许按 `S2` 并发。

### 1.5 审查

- `architecture-reviewer` 审迁移步骤是否独立可执行
- `security-auditor` 审数据完整性、配置和权限风险

## Phase 2: Staging 执行

用户确认后，按 step 串行执行：
- schema / migration 步 → `database-engineer`
- 小程序生态迁移步 → `miniprogram-dev`
- 普通代码步 → 对应 implementer
- 运维 / 发布步 → `devops`

每步后：
- `code-reviewer` 审实现
- `security-auditor` 审 schema、配置、权限、数据完整性风险
- `functional-tester` 验证行为

## Phase 3: Production 执行

staging 全部通过后，先派遣 `test-lead` 做生产前裁决；通过后再二次 AskUserQuestion 确认生产执行。

生产执行后：
- `devops` 写入 `deploy-report-{task-id}.md`
- `functional-tester` 做生产关键路径 smoke test（如允许）
- `test-lead` 根据部署报告与 smoke test 给最终裁决

## Phase 4: 清理与归档

- 清理双写 / 过渡代码
- 产出 migration-report
- 调用 `/bcc-update-project`
