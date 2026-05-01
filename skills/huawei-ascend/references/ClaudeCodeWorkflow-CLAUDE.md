# Ascend C 算子 Debug 自动化工作流

本文件定义 Ascend C 算子错误注入 → 文档修复 → 编译验证 → 知识积累的完整调度协议。

---

## 项目身份

Ascend C 算子 Debug 自动化工作流系统。4 个专职 Agent + 6 个 Skill 组成分层流水线，实现算子错误的自动注入、自主修复、经验积累。

核心理念：**修复者不预知错误，完全自主探索积累经验**。

运行环境：Claude Code CLI v2.1.59+；目标硬件：Ascend 910B4（ModelArts Notebook）。

---

## 核心模块

| 模块 | 路径 | 用途 |
|:--|:--|:--|
| Agent 定义 | `agents/` | 4 个专职 Agent（见下表） |
| Skill 定义 | `skills/` | 6 个 Skill（2 个知识库 + 4 个流水线命令） |
| 流水线协议 | `WORKFLOW.md` | 完整状态机和步骤定义 |
| 交接文件 | `.claude/artifacts/` | Agent 间 artifact 传递 |

---

## Agent 清单

| Agent | 职责 | 输入 | 输出 |
|:--|:--|:--|:--|
| `ascendc-planner` | 规划积累方向 | 模式库 | `plan-{date}.md` |
| `ascendc-injector` | 注入错误，回测验证 | 调度计划 | `injection-{task-id}.md` |
| `ascendc-fixer` | 自主探索修复，积累经验 | buggy 算子 | `fix-report-{task-id}.md` |
| `ascendc-accumulator` | 更新错误模式库 | 修复报告 | `accumulation-{task-id}.md` |

---

## Skill 清单

### 知识库 Skill

| Skill | 用途 |
|:--|:--|
| `ascendc-docs-reference` | Ascend C 官方文档核心知识提取（约束、API、硬件、调试、编译） |
| `ascendc-debug-patterns` | 错误模式库（7 种基础类型 + 修复配方） |

### 流水线命令 Skill

| 命令 | 功能 |
|:--|:--|
| `/bcc-harvest-errors` | 社区错误采集 |
| `/bcc-orchestrate` | 动态调度 |
| `/bcc-batch-eval` | 批量评测 |
| `/bcc-ascendc-debug` | 单次错误注入测试 |

---

## 流水线命令

| 场景 | 命令 |
|:--|:--|
| 社区错误采集 | `/bcc-harvest-errors` |
| 动态调度 | `/bcc-orchestrate` |
| 批量评测 | `/bcc-batch-eval` |
| 单次错误注入测试 | `/bcc-ascendc-debug` |

---

## 状态机

```
规划 → 注入 → 修复 → 积累 → 规划...
  │       │       │       │
planner injector fixer accumulator
```

---

## 调度原则

### 触发条件

- **规划**：每次注入前 / 手动触发 `/bcc-orchestrate`
- **批量评测**：模式库新增 ≥ 5 / 已测试组合 < 50%

### 并发规则

| 阶段 | 并发等级 | 说明 |
|:--|:--|:--|
| PLANNED → INJECTED | S0 | 串行，injector 依赖调度计划 |
| INJECTED → FIXED | S0 | 串行，fixer 依赖注入的 buggy 代码 |
| FIXED → ACCUMULATED | S0 | 串行，accumulator 依赖修复报告 |
| ACCUMULATED → PLANNED | S0 | 串行，planner 依赖更新后的模式库 |
| 多算子并行 | S2 | 不同算子的注入可并行，文件路径无交集 |

### 调度策略（planner）

| 策略 | 目标 | 算法 |
|:--|:--|:--|
| `coverage`（默认） | 最大化错误类型覆盖率 | 优先测试次数最少的类型 |
| `success_rate` | 快速积累成功案例 | 优先历史高 PASS 率 |
| `difficulty` | 攻克难点 | 优先 FAIL 率最高的类型 |
| `new_discovery` | 验证新发现 | 优先 NewType 模式 |

---

## 环境要求

- **远程主机**: `ascendyun` (ModelArts Notebook)
- **CANN 版本**: 8.5.2
- **NPU 型号**: Ascend 910B4
- **编译器**: bisheng (CANN 内置)
- **Python**: 3.11 (pypto env)
- **文档源**: 本地 `asc-devkit-docs/`（已克隆）

---

## 核心铁律

1. **CPU 调试先行** — 所有算子先在 `cpu` 模式验证通过，再上 NPU
2. **32B 对齐是铁律** — `count * sizeof(T)` 必须被 32 整除
3. **核类型必须匹配** — 910B 用 `AIC_ONLY`，310P 用 `AIV_ONLY`
4. **每次只改一处** — 错误注入只改一个点，保持其他逻辑不变
5. **修复必须有依据** — 所有修复方案必须引用文档或代码证据
6. **知识自动积累** — PASS 后自动更新模式库

---

## @imports

- `WORKFLOW.md` — 完整流水线协议（状态机、步骤、Artifact 命名、并发规则）
- `skills/ascendc-docs-reference/SKILL.md` — 文档知识库入口
- `skills/ascendc-debug-patterns/SKILL.md` — 错误模式库入口
