# Ascend C 算子 Debug 自动化流水线协议

## 版本

v3.0 — 2026-04-29

## 概述

本协议定义算子错误自动注入 → 自主修复 → 经验积累的完整流水线。
v3.0 核心理念：**修复者不预知错误，完全自主探索积累经验**。

## 参与者

| 角色 | 文件 | 职责 |
|:--|:--|:--|
| 调度器 | 主会话 | 状态机控制、Agent 派遣 |
| **规划者** | `agents/ascendc-planner.md` | 阅读模式库，规划积累方向 |
| **注入者** | `agents/ascendc-injector.md` | 注入错误，回测确保错误诞生 |
| **修复者** | `agents/ascendc-fixer.md` | 自主探索修复，不预知错误，积累经验 |
| **积累者** | `agents/ascendc-accumulator.md` | 更新错误模式库 |
| 文档知识库 | `skills/ascendc-docs-reference/` | Ascend C 官方文档核心知识提取 |
| 错误模式库 | `skills/ascendc-debug-patterns/` | 修复模式积累与查询 |

## 状态机

### 完整流水线（v3.0）

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           规划层                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    规划者 planner                                    │   │
│  │  读取模式库 → 分析覆盖率 → 规划下一步                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           注入层                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    注入者 injector                                    │   │
│  │  读取计划 → 注入错误 → 回测验证 → 确保错误诞生                        │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           修复层                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    修复者 fixer                                       │   │
│  │  不预知错误 → 自主探索 → 文档驱动 → 尝试修复 → 验证成功 → 报告经验    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           积累层                                            │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │                    积累者 accumulator                                 │   │
│  │  读取报告 → 匹配模式 → 更新模式库 → 沉淀经验                          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────────────┘
```

## 详细步骤

### Step 1: 规划（PLANNED）

**Agent**: `ascendc-planner`

**触发条件**：
- 手动调用 `/bcc-orchestrate`
- 模式库新增模式数 < 3（模式库增长缓慢时自动触发）

**动作**：
1. 读取 `skills/ascendc-debug-patterns/SKILL.md`
2. 统计每种错误类型的测试次数、PASS/FAIL 率
3. 识别已覆盖和未覆盖的错误类型
4. 选择下一步注入的错误类型和算子
5. 产出 `plan-{YYYYMMDD}-{NN}.md`

**产出 Artifact**：
- `plan-{YYYYMMDD}-{NN}.md`
- 状态：`planned`

**下一跳**：派遣 `ascendc-injector`

---

### Step 2: 注入（INJECTED）

**Agent**: `ascendc-injector`

**输入**：
- `plan-{YYYYMMDD}-{NN}.md`
- `operator_path`
- `bug_type`

**动作**：
1. 读取调度计划
2. 读取算子代码，识别注入点
3. 创建备份 `*.bak`
4. 按错误模式注入 bug（只改一处）
5. 回测验证：在 CPU 模式下编译运行
6. 确认错误确实诞生
7. 产出 `injection-{task-id}.md`

**产出 Artifact**：
- `injection-{task-id}.md`
- 状态：`injected`

**下一跳**：派遣 `ascendc-fixer`

**关键原则**：
- **不向 fixer 透露注入详情**
- 只提供 `operator_path` 和 `error_log`（如有）
- 让 fixer 完全自主探索

---

### Step 3: 修复（FIXED）

**Agent**: `ascendc-fixer`

**输入**：
- `operator_path`：算子目录路径（含 buggy 代码）
- `error_log`（可选）：运行时捕获的错误日志
- **不提供**：错误注入详情、注入位置、修改内容

**自主探索流程**：

#### Phase 1: 错误现象分析
1. 运行算子，捕获错误日志
2. 识别错误类型（SIGABRT / 207001 / error ratio / 编译错误）

#### Phase 2: 文档探索
1. 查阅 `ascendc-docs-reference` Skill
2. 查阅 `ascendc-debug-patterns` Skill（如有匹配）
3. 如不足，读取 `asc-devkit-docs/` 原始文档

#### Phase 3: 代码分析
1. 阅读算子代码，理解流程
2. 对比正确模式，识别违反的约束
3. 定位根因

#### Phase 4: 尝试修复
1. 制定修复方案
2. 应用修复
3. 验证修复

#### Phase 5: 经验报告
修复成功后，报告学习经验

**产出 Artifact**：
- `fix-report-{task-id}.md`
- 状态：`PASS` / `FAIL` / `BLOCKED`

**分支**：
- **PASS** → Step 4: 经验积累
- **FAIL** → 重试（最多 3 次）
- **BLOCKED** → 调度器通知用户人工介入

**重试策略**：
- 首次 FAIL：重新分析错误日志
- 第二次 FAIL：换修复思路
- 第三次 FAIL：标记为 HARD CASE

---

### Step 4: 经验积累（ACCUMULATED）

**Agent**: `ascendc-accumulator`

**输入**：
- `fix-report-{task-id}.md`
- `skills/ascendc-debug-patterns/SKILL.md`

**动作**：
1. 读取修复报告
2. 提取错误现象、根因、修复方案、学到的经验
3. 匹配现有模式或创建新模式
4. 更新模式库：
   - 更新现有模式：追加案例到 `fix-recipes/{type}.md`
   - 创建新模式：分配 ID，写入 SKILL.md，创建 fix-recipes
5. 产出 `accumulation-{task-id}.md`

**产出 Artifact**：
- `accumulation-{task-id}.md`
- 状态：`accumulated`

**下一跳**：返回 Step 1（规划下一轮）

---

## Artifact 命名规范

| Artifact | 命名格式 | 产出者 |
|:--|:--|:--|
| 调度计划 | `plan-{YYYYMMDD}-{NN}.md` | planner |
| 错误注入报告 | `injection-{task-id}.md` | injector |
| 修复报告 | `fix-report-{task-id}.md` | fixer |
| 经验积累报告 | `accumulation-{task-id}.md` | accumulator |

## 并发规则

| 阶段 | 并发等级 | 说明 |
|:--|:--|:--|
| PLANNED → INJECTED | S0 | 串行，injector 依赖调度计划 |
| INJECTED → FIXED | S0 | 串行，fixer 依赖注入的 buggy 代码 |
| FIXED → ACCUMULATED | S0 | 串行，accumulator 依赖修复报告 |
| ACCUMULATED → PLANNED | S0 | 串行，planner 依赖更新后的模式库 |
| 多算子并行 | S2 | 不同算子的注入可并行，文件路径无交集 |

## 批量评测模式

### 触发条件

- 手动调用 `/bcc-batch-eval`
- 模式库新增模式数 ≥ 5
- 已测试组合数 < 总组合数的 50%

### 批量流程

1. **planner** 生成批量计划
2. **调度器** 按批次执行（每批次 3-5 个组合）
3. 每个组合独立走 Step 2-4
4. 产出批量报告

### 批量报告格式

```markdown
# Batch Evaluation Report: {date}

**评测时间**: {ISO 8601}
**算子数量**: {operator_count}
**错误类型数量**: {pattern_count}
**总组合数**: {total_combinations}
**已完成**: {completed}
**PASS**: {pass_count}
**FAIL**: {fail_count}
**BLOCKED**: {blocked_count}

## 覆盖率矩阵

| 算子 \ 错误类型 | TilingAlign | KernelType | DataType | ... |
|:--|:--|:--|:--|:--|
| 5_addn | ✅ PASS | ❌ FAIL | ⏳ pending | ... |
| 25_simple_add | ⏳ pending | ⏳ pending | ⏳ pending | ... |

## 修复率统计

| 错误类型 | 测试次数 | PASS 次数 | 修复率 |
|:--|:--|:--|:--|
| TilingAlign | 3 | 2 | 66.7% |
| KernelType | 2 | 1 | 50.0% |

## 盲区报告

以下组合连续 3 次 FAIL，建议人工介入：

| 算子 | 错误类型 | 失败原因 | 建议 |
|:--|:--|:--|:--|
| 5_addn | DataType | fixer 无法定位 | 检查 fixer prompt |
```

## 环境要求

- **远程主机**: `ascendyun` (ModelArts Notebook)
- **CANN 版本**: 8.5.2
- **NPU 型号**: Ascend 910B4
- **编译器**: bisheng (CANN 内置)
- **Python**: 3.11 (pypto env)
- **文档源**: 本地 `asc-devkit-docs/`（已克隆）

## 错误处理

| 异常 | 处理 |
|:--|:--|
| 远程 SSH 失败 | 调度器重试 3 次，失败则 BLOCKED |
| 编译失败（非预期） | fixer 标记 BLOCKED，通知用户 |
| fixer 无法定位 | 重试 3 次，仍失败则 BLOCKED |
| 模式库更新失败 | accumulator 标记 WARNING，人工检查 |

## 扩展点

1. **新增错误类型**：在 `injector` 错误模式库中添加
2. **新增验证模式**：支持 sim 模式（模拟器）验证
3. **批量运行**：支持一次对多个算子注入不同错误类型
4. **回归测试**：修复后的算子加入回归测试集
5. **可视化 dashboard**：实时显示覆盖率、PASS 率、盲区热力图
6. **自进化闭环**：连续 FAIL 的 case 自动触发 Claude Code 工作流与提示词设计大师 审查 fixer prompt
