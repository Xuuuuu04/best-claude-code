---
name: start-task
description: 当用户提出一个新的独立工作诉求时,开启一个新 Task —— 增强意图、一句话确认、写入符合 schema 的 Task 文件到 <project>/.claude/tasks/。这是 Task-Centric Harness 的入口。也可在用户显式说"开新 task"/"/start-task"时调用。
---

# /start-task

把用户的新诉求转化成一个结构化的 Task 文件,作为本次工作的持久化记忆和子代理通信总线。

## 何时调用

主代理判断:**这条新输入能否独立成一个 commit?**
- 能 → 调用本 skill 开新 Task
- 不能(是对当前 task 的澄清/追问/微调) → 把内容追加到当前 task 的 Prompt 段,**不调用本 skill**
- 用户显式说"开新 task" / `/start-task` → 直接调用

## 执行步骤

### 1. 定位项目和 tasks 目录

```bash
PROJECT_ROOT=$(pwd)
TASKS_DIR="$PROJECT_ROOT/.claude/tasks"
mkdir -p "$TASKS_DIR/outputs"
```

如果当前目录不是某个项目根(例如在用户主目录下临时使用),退化:`TASKS_DIR=$HOME/.claude/tasks-floating/`,并在 Task frontmatter 的 `project` 字段写 `floating`。

### 2. 生成文件名

格式:`Task-{YYYY-MM-DD}-{HHMM}-{slug}.md`

- 日期时间用 `date +%Y-%m-%d-%H%M`
- slug:2-4 个英文小写词,从用户 prompt 提炼,用连字符,例如 `fix-auth-bug`、`add-payment-flow`、`refactor-router`
- 完整示例:`Task-2026-05-15-1030-fix-auth-bug.md`

### 3. 增强用户意图

读用户原话,推理填充以下三项(每项 1-3 行):
- **目标**:做这件事的根本目的(不只是表面动作)
- **验收**:1-3 条可验证标准(测试通过?某个文件存在?某个 UI 显示?)
- **约束**:必须遵守的边界(API contract 不能改?向后兼容?不能动 .env?)

注意:增强不应**改变**用户意图,只是 explicit 化用户隐含的意图。

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

## Plan
1. <步骤 1>
2. <步骤 2>
3. <步骤 3>

## Execution Log
- HH:MM Task 创建,开始执行

## Subagent Calls
<还没有时为空>

## Decisions
<还没有时为空>

## Completion
<尚未完成时为空,/finish-task 时填>
```

## 字段填充指南

- `id` = 文件名去掉 `.md`
- `started` = 当前本地时间
- `model` = 当前主代理使用的模型 ID(如 `opus-4-7`)
- `project` = 从 `pwd` 推断(项目根目录名),或读项目 CLAUDE.md 的 `## 项目身份` 段
- `tags` = 推断 1-3 个,例:`[bug-fix, auth]`、`[feature, ui]`、`[refactor]`、`[docs]`
- Plan 段如果用户诉求很简单(<3 步),写 1-3 步就好,不要硬凑

## 反例(别这样做)

- ❌ 用户说"我看下日志"也开 Task —— 这是探索性闲聊,不该开 Task
- ❌ 用户每次澄清都开新 Task —— 应该追加到现有 task 的 Prompt 段
- ❌ 一句话确认改成长篇大论 —— 用户明确要轻量确认
- ❌ 增强意图时引入用户没说过的功能 —— 增强不是发明
- ❌ Plan 段写得比 Intent 还详细 —— Plan 是提纲,不是 spec

## 完整示例

用户:"修一下漫展 web 端 token 刷新的问题,登录半天后就掉线"

主代理:
1. `pwd` = `/Users/mumuxsy/Desktop/项目群/漫展官网购票系统` → tasks 目录 `.claude/tasks/`
2. 生成文件名:`Task-2026-05-15-1030-fix-token-refresh.md`
3. 增强:目标=修复 token 刷新失败导致掉线;验收=登录后 24h 持续可用;约束=不改后端
4. 输出:「我理解为「修复 token 刷新失败导致 24h 内掉线」,验收为「登录后 24h 持续可用」,开始吗?」
5. 用户 enter → Write 文件
6. 输出:「✓ Task 已开:`.claude/tasks/Task-2026-05-15-1030-fix-token-refresh.md`. 开始干活。」

然后开始执行,首先调用 Explore subagent 查 auth flow,通过 `/brief` 生成 briefing。
