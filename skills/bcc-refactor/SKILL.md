---
name: bcc-refactor
description: 重构流水线。行为不变、测试前后必须完全一致通过。适用于模块拆分、函数抽取、命名改进、去除重复代码等。
disable-model-invocation: true
---

# 重构流水线

`$ARGUMENTS` 是重构目标描述，如"抽取 src/auth/ 中的 token 解析逻辑为独立模块"。

重构的特殊性：**行为必须完全不变**，只有代码结构变。现有 `/bcc-new-feature`（新行为）和 `/bcc-fix-bug`（修复错误行为）都不适合——它们假设行为需要变化。

---

## 核心纪律

1. **Tests before = Tests after**：重构前跑一次完整测试套件，记录每个测试的通过状态。重构后再跑一次，**完全一致**才算成功
2. **禁止"顺便修 bug"**：重构中发现 bug → 停下来记录 → 完成重构 → 另起 `/bcc-fix-bug`
3. **禁止改接口**：对外 API / 函数签名保持不变（即使你觉得新签名更好）。签名变更属于"新功能"
4. **小步快走**：单次重构 scope 控制小，宁可多次 refactor 不一次大改

---

## Phase 1: 基线建立

### 1.1 派遣 researcher 理解重构范围

```
任务：分析重构范围和影响面。

重构目标：{$ARGUMENTS}

请产出到 .claude/artifacts/refactor-basis-{task-id}.md：
1. 涉及的文件清单（范围候选）
2. 涉及函数/模块的调用者（反向依赖图，验证接口稳定性需要）
3. 现有测试覆盖情况（哪些测试覆盖了这部分代码）
4. 潜在风险：紧耦合、隐藏依赖、无测试覆盖的分支
```

### 1.2 测试基线

在任何改动前，**必须**跑一次完整测试套件并记录：

```bash
{项目的 test 命令} > .claude/artifacts/test-baseline-{task-id}.txt 2>&1
```

如果测试本身就有失败 → **停止**重构。要求用户先修复测试（用 `/bcc-fix-bug`），否则无法验证"行为不变"。

---

## Phase 2: 重构方案设计

### 2.1 派遣 architect（轻量模式）

```
任务：为此重构设计方案和 scope-lock。

调研报告：.claude/artifacts/refactor-basis-{task-id}.md
重构目标：{$ARGUMENTS}

重点约束（务必在 scope-lock 中体现）：
- 禁止修改对外接口签名
- 禁止增删测试用例（只允许调整测试的内部实现）
- 禁止引入新依赖
- 明确标记"不变量"：哪些行为必须完全保持

产出：architecture-{task-id}.md + scope-lock-{task-id}-*.md
特别在 architecture 里加一段"不变量清单"。
```

### 2.2 quality-guardian 架构审查（仅关注"是否真的只是重构"）

```
审查类型：architecture-review（重构模式）
对象：architecture-{task-id}.md + scope-locks

额外重点：
- 验证"不变量清单"完整性
- 检查有无"顺便加功能"的嫌疑
- 测试的变动范围合理性（只允许内部实现变化，不改测试断言）
```

---

## Phase 3: 实现

按通用流水线派遣 implementer。但在任务提示中**额外强调**：

```
额外约束（重构模式）：
- 不变量：{从 architecture 复制不变量清单}
- 完成前请再次运行测试，对比 test-baseline 文件，任何测试状态变化都是异常
- 对比命令示例：diff .claude/artifacts/test-baseline-{task-id}.txt <(npm test 2>&1)
```

---

## Phase 4: 等价性验证（重构流水线的核心环节）

派遣 quality-guardian 做**等价性测试**：

```
审查类型：refactor-equivalence（新增模式）
对象：
- .claude/artifacts/test-baseline-{task-id}.txt（重构前）
- 当前测试运行结果（重构后）
- impl-reports

请验证：
1. 所有测试的通过/失败状态与基线完全一致
2. 测试耗时无明显退化（>20% 增长需报警）
3. 编译/类型检查无新错误
4. （如可用）性能基准无退化

任何一条不满足 → 驳回。重构流水线对"等价"的要求比普通代码审查严苛。
```

---

## Phase 5: 完成

### 5.1 提交

```
refactor({scope}): {短描述}

Tests before/after: identical (N passed)
No behavior change; internal structure only.

Refs: .claude/artifacts/refactor-basis-{task-id}.md
```

### 5.2 向用户汇报

```
✓ 重构完成：{目标}
  └ 修改文件：{N}
  └ 测试：{M passed}（前后一致 ✓）
  └ 不变量：全部保持 ✓
```

---

## 适合 / 不适合的判断

**适合 `/bcc-refactor`：**
- 抽取公共函数、拆分长文件
- 重命名（变量、函数、类——注意所有调用者同步更新）
- 替换重复代码为共享实用工具
- 改变内部数据结构但保持对外接口
- 拆分过大的函数

**不适合（走其他流水线）：**
- 改变对外 API（→ `/bcc-new-feature`，视为 breaking change）
- 修 bug（→ `/bcc-fix-bug`）
- 升级框架/库版本（→ `/bcc-migrate`）
- 优化性能（→ `/bcc-perf`，行为是否完全不变存疑）
- 没有测试覆盖的代码（→ 先加测试，再重构）
