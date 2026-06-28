---
name: bcc-start
description: 当用户提出一个新的独立工作诉求时,开启一个新 Task —— 增强意图、一句话确认、写入符合 schema 的 Task 文件到 <project>/.claude/tasks/。这是 Task-Centric Harness 的入口。也可在用户显式说"开新 task"/"/bcc-start"时调用。
argument-hint: "[用户诉求描述]"
---

# /bcc-start

用户的新诉求 → 一个结构化的 Task 文件。这个文件既是持久化记忆,也是子代理的通信总线。

## 何时调用

主代理判断:**这条新输入能否独立成一个 commit?**
- 能 → 调用本 skill 开新 Task
- 不能(是对当前 task 的澄清/追问/微调) → 把内容追加到当前 task 的 Prompt 段,**不调用本 skill**
- 用户显式说"开新 task" / `/bcc-start` → 直接调用

## 当前环境（动态注入）

!`echo "- 项目根: $(pwd)"; echo "- 项目名: $(basename "$(pwd)")"; echo "- 时间戳: $(date '+%Y-%m-%d %H:%M')"; echo "- 文件名时间: $(date +%Y-%m-%d-%H%M)"; echo "- Git 分支: $(git branch --show-current 2>/dev/null || echo '(非 git 仓库)')"; if [ -d ".claude/tasks" ]; then COUNT=$(grep -l 'status: in_progress' .claude/tasks/*.md 2>/dev/null | wc -l | tr -d ' '); echo "- 活跃 Task: ${COUNT} 个"; else echo "- 活跃 Task: 0（tasks 目录不存在，将自动创建）"; fi`

## 执行步骤

### 1. 定位项目和 tasks 目录

使用上方注入的项目根路径：

```bash
PROJECT_ROOT=<上方注入的项目根>
TASKS_DIR="$PROJECT_ROOT/.claude/tasks"
mkdir -p "$TASKS_DIR/outputs"
```

如果当前目录不是某个项目根(例如在用户主目录下临时使用),退化:`TASKS_DIR=$HOME/.claude/tasks-floating/`,并在 Task frontmatter 的 `project` 字段写 `floating`。

### 2. 生成文件名

使用上方注入的文件名时间，格式:`Task-{YYYY-MM-DD}-{HHMM}-{slug}.md`
- slug:2-4 个英文小写词,从用户 prompt 提炼,用连字符,例如 `fix-auth-bug`、`add-payment-flow`、`refactor-router`
- 完整示例:`Task-2026-05-15-1030-fix-auth-bug.md`

### 3. 增强用户意图

读用户原话,推理填充以下三项(每项 1-3 行):
- **目标**:做这件事的根本目的(不只是表面动作)
- **验收**:1-3 条可验证标准(测试通过?某个文件存在?某个 UI 显示?)
- **约束**:必须遵守的边界(API contract 不能改?向后兼容?不能动 .env?)

注意:增强是把用户没说出来但暗含的意图**写明白**,不是替用户加需求。

### 4. 一句话确认(用户偏好:轻量确认)

向用户输出一句:
> 我理解为「[目标]」,验收为「[验收第一条]」,开始吗?(直接 enter 即继续)

如果用户回 enter / "好" / "可以" → 继续第 5 步
如果用户改正 → 按改正重新填,再确认一次
如果用户说"等等让我想想" → 不写文件,保持在 confirmation 状态

### 5. 写入 Task 文件

按下面模板填充,用 Write 工具写到 `$TASKS_DIR/$FILENAME`。

### 6. 返回路径并开始工作

输出:
> ✓ Task 已开:`<相对路径>`. 开始干活。

然后按 Plan 段开始执行,实时把每步追加到 Execution Log。

## Task 文件模板

```markdown
---
id: Task-2026-05-15-1030-fix-auth-bug
status: in_progress
started: 2026-05-15 10:30
finished: null
model: opus-4-7
parent: null
project: <项目名,从 pwd 或项目 CLAUDE.md 推断>
tags: [<根据诉求加 1-3 个>]
---

# <一句话标题,首字母大写,英文>

## Prompt(用户原话,append-only)
> 2026-05-15 10:30
> <用户原话粘贴在这里>

## Intent(主代理增强)
- 目标:<一句话>
- 验收:
  - [ ] <可验证标准 1>
  - [ ] <可验证标准 2>
- 约束:<必须遵守的边界>

## Spec

### Requirements
- [ ] FR-1: <功能需求 1,可验证>
- [ ] FR-2: <功能需求 2,可验证>
- [ ] NFR-1: <非功能需求,如性能/安全约束>

### Review Dimensions
| Dimension       | Weight | Threshold | Description          |
|-----------------|--------|-----------|----------------------|
| correctness     | 30%    | ≥ 7       | 逻辑正确,边缘情况处理 |
| security        | 20%    | ≥ 7       | 无注入/泄露/越权      |
| performance     | 15%    | ≥ 6       | 无 N+1/阻塞/内存泄露  |
| maintainability | 20%    | ≥ 6       | 命名/结构/可读性      |
| test_coverage   | 15%    | ≥ 6       | 覆盖失败路径不只 happy |

## Plan
1. <步骤 1>
2. <步骤 2>
3. <步骤 3>

## Execution Log
- HH:MM Task 创建,开始执行

## Subagent Calls
<可选;调过 subagent 想留追溯就记一行,outputs/ 里的文件本身也是记录>

## Decisions
<还没有时为空>

## Review History
<由主代理在每轮 review 后追加,格式见下>

## Completion
<尚未完成时为空,/bcc-finish 时填>
```

## 字段填充指南

- `id` = 文件名去掉 `.md`
- `started` = 当前本地时间
- `model` = 当前主代理使用的模型 ID(如 `opus-4-7`)
- `project` = 从 `pwd` 推断(项目根目录名),或读项目 CLAUDE.md 的 `## 项目身份` 段
- `tags` = 推断 1-3 个,例:`[bug-fix, auth]`、`[feature, ui]`、`[refactor]`、`[docs]`
- Plan 段如果用户诉求很简单(<3 步),写 1-3 步就好,不要硬凑

### Spec 填充指南

- **Requirements**: 从 Intent 的验收项展开,编号 FR-1/FR-2(功能)、NFR-1(非功能)。每条必须可验证——"跑 X 命令结果是 Y"比"代码质量好"有用 100 倍
- **Review Dimensions**: 默认用上面模板的 5 维度 + 权重。可按任务性质调整:
  - 纯重构: maintainability 权重提到 35%,security 降到 10%
  - 安全相关: security 权重提到 35%,performance 降到 10%
  - 新功能: 默认权重即可
  - 纯文档/配置: 不写 Spec 段(跳过 review 评分流程)
- **Threshold**: 默认 correctness/security ≥ 7,其余 ≥ 6。安全敏感任务可全部提到 ≥ 8

### Review History 格式(由主代理在每轮 review 后追加)

```markdown
## Review History

### Round 1 (14:30)
- Weighted: 5.2 | correctness: 6 security: 8 performance: 7 maintainability: 5 test_coverage: 3
- Blocking: correctness, maintainability, test_coverage
- Action: 重构 refreshToken 拆函数 + 加 3 个测试

### Round 2 (15:10)
- Weighted: 7.15 | correctness: 8(+2) security: 9(+1) performance: 7(=) maintainability: 6(+1) test_coverage: 5(+2)
- Blocking: test_coverage
- Action: 加网络中断测试
```

主代理每轮 review 完成后读 review JSON,提取分数追加到这里。这段写在 Task 文件里,跨 compact/跨会话不丢。

## 反例(别这样做)

- ❌ 用户说"我看下日志"也开 Task —— 这是探索性闲聊,不该开 Task
- ❌ 用户每次澄清都开新 Task —— 应该追加到现有 task 的 Prompt 段
- ❌ 一句话确认改成长篇大论 —— 用户明确要轻量确认
- ❌ 增强意图时引入用户没说过的功能 —— 增强不是发明
- ❌ Plan 段写得比 Intent 还详细 —— Plan 是提纲,不是 spec

## 示例流程

用户说"修 token 刷新掉线" → 增强为目标+验收+约束 → 一句话确认 → Write Task 文件 → 输出路径 → 开始执行。
