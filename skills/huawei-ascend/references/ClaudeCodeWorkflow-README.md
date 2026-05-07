# Ascend C 算子 Debug 自动化工作流

## 目标

构建一套自动化系统，用于：
1. **有策略地注入**算子代码错误
2. **基于文档**自动诊断和修复
3. **编译验证**修复结果
4. **积累知识**形成可复用的 Debug 模式库

## 系统架构

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           调度器（主会话）                                │
│  1. 选择算子 + 错误类型 → 派 bug-injector                               │
│  2. 拿到 buggy 代码 + 症状 → 派 debugger                                │
│  3. 拿到修复提案 → 派 verifier（CPU 模式先跑）                          │
│  4. PASS → 更新 ascendc-debug-patterns Skill                            │
│  5. FAIL → 派 debugger 重试（最多 3 次）                                │
└─────────────────────────────────────────────────────────────────────────┘

     ┌──────────────┐      ┌──────────────┐      ┌──────────────┐
     │ bug-injector │ ──→  │   debugger   │ ──→  │   verifier   │
     │  (错误注入)   │      │  (文档修复)   │      │  (编译验证)   │
     └──────────────┘      └──────────────┘      └──────────────┘
            │                      │                      │
            ▼                      ▼                      ▼
    buggy-operator-*.md    fix-proposal-*.md    verification-*.md
```

## Agent 清单

| Agent | 角色 | Artifact | 下一跳 |
|:--|:--|:--|:--|
| `ascendc-bug-injector` | 错误注入器 | `buggy-operator-{task-id}.md` | `ascendc-debugger` |
| `ascendc-debugger` | 文档修复器 | `fix-proposal-{task-id}.md` | `ascendc-verifier` |
| `ascendc-verifier` | 编译验证器 | `verification-{task-id}.md` | 调度器（更新 Skill 或重试） |

## Skill 清单

| Skill | 类型 | 用途 |
|:--|:--|:--|
| `ascendc-debug-patterns` | `*-patterns` | 错误模式库，按类型分类，持续积累 |

## 错误模式库（初始）

| 错误类型 | 注入方式 | 预期症状 | 修复依据 |
|:--|:--|:--|:--|
| **TilingAlign** | 改 TILE_NUM 使 tileLength 非 32B 对齐 | CPU: SIGABRT + "32B align"<br>NPU: 静默截断，精度失败 | asc-devkit/docs/api/ 数据搬运对齐要求 |
| **KernelType** | AIV_ONLY 改 AIC_ONLY 或反之 | 207001 kernel launch failure | 核类型与硬件匹配文档 |
| **DataType** | half/float 混用 | 精度异常或编译错误 | API 参数类型约束 |
| **BufferOverflow** | DataCopy 长度 > buffer 大小 | 越界崩溃或数据污染 | InitBuffer vs DataCopy 长度对账 |
| **SyncMissing** | 删除 aclrtSynchronizeStream | 数据竞争，结果随机 | 流同步机制文档 |
| **OffsetError** | CopyOut offset 计算互换 % / | 数据位置错乱 | 多核并行数据切分逻辑 |
| **SocVersion** | 编译目标与实际硬件不匹配 | 运行警告或异常 | socversion 匹配要求 |

## 工作流命令

| 场景 | 命令 |
|:--|:--|
| 全自动跑一轮 | `/bcc-ascendc-debug --operator 5_addn_kernellaunch --mode auto` |
| 注入指定错误 | `/bcc-ascendc-debug --operator 5_addn_kernellaunch --bug-type TilingAlign` |
| 仅验证修复 | `/bcc-ascendc-verify --operator 5_addn_kernellaunch --fix fix-proposal-xxx.md` |
| 查看模式库 | `/bcc-ascendc-patterns` |

## 目录结构

```
ClaudeCodeWorkflow/
├── README.md                      # 本文件
├── WORKFLOW.md                    # 完整流水线协议
├── agents/
│   ├── ascendc-bug-injector.md    # 错误注入 Agent
│   ├── ascendc-debugger.md        # 文档修复 Agent
│   └── ascendc-verifier.md        # 编译验证 Agent
├── skills/
│   └── ascendc-debug-patterns/
│       ├── SKILL.md               # 模式库入口
│       └── references/
│           ├── error-taxonomy.md  # 错误分类体系
│           └── fix-recipes/       # 修复配方（按类型）
└── artifacts/
    └── template/                  # artifact 模板
```

## 与现有 Agent Legion 集成

本工作流作为 **项目级扩展**，放置在 `.claude/agents/` 和 `.claude/skills/` 下即可被调度器识别。

调度真源补充条目：

| 用户信号 | 首调 Agent | Artifact | 下一跳 | 并发 |
|:--|:--|:--|:--|:--|
| 算子 debug / 注入错误 / 测试修复 | `ascendc-bug-injector` | `buggy-operator-*` | `ascendc-debugger` | S0 |
| 修复算子 / 查文档修 bug | `ascendc-debugger` | `fix-proposal-*` | `ascendc-verifier` | S0 |
| 验证算子修复 | `ascendc-verifier` | `verification-*` | 调度器/更新 Skill | S3 |
