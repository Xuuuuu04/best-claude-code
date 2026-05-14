---
name: continue-task
description: 列出当前项目所有 in_progress 的 Task,让用户选一个继续。用于跨会话恢复、上次/compact 后的恢复、或用户主动切回某个未完成的任务。
---

# /continue-task

跨会话/跨 compact 恢复一个未完成的 Task,把它的状态完整 load 进主代理上下文。

## 何时调用

- 用户说"继续上一个" / "接着昨天那个 X" / `/continue-task`
- `SessionStart` hook 检测到 in_progress task 并建议恢复时(用户同意)
- `/compact` 后主代理意识到要继续之前的工作

## 执行步骤

### 1. 列出当前项目的 in_progress Task

```bash
TASKS_DIR="$(pwd)/.claude/tasks"
if [ ! -d "$TASKS_DIR" ]; then
  echo "当前项目还没有任何 task。用 /start-task 开第一个。"
  exit 0
fi
grep -l 'status: in_progress' "$TASKS_DIR"/*.md 2>/dev/null | head -10
```

如果没找到 → 输出"当前没有进行中的 task,要不要 `/start-task` 开新的?"并退出。

### 2. 按 started 倒序展示

读每个文件的 frontmatter,提取 `id` / `started` / 一级标题(`# xxx`)。按 `started` 倒序输出:

```
找到 N 个进行中的 task:

[1] Task-2026-05-15-1030-fix-auth-bug
    标题: Fix auth token refresh bug
    开始: 2026-05-15 10:30(2 小时前)
    最近 Execution Log: 10:55 定位根因 refreshToken.ts:42

[2] Task-2026-05-14-1620-add-payment
    标题: Add payment flow
    开始: 2026-05-14 16:20(昨天)
    最近 Execution Log: 17:30 完成前端表单,后端 mock 待对接

[3] ...

选哪个继续?(回数字,或说"都不要,开新的")
```

### 3. 加载选中的 Task

用户选 [N] 后:
1. Read 整个 Task 文件
2. 把文件内容作为当前工作上下文,主代理"心理上"认为这是当前活跃任务
3. 在 Execution Log 段追加一行:`- HH:MM 会话恢复(/continue-task)`
4. 主代理输出一段简短的状态总结:

```
✓ 已恢复 Task-2026-05-15-1030-fix-auth-bug

当前状态:
- Plan 第 1-2 步已完成(已定位根因)
- 第 3 步待做:实施修复
- 上次决策:选择"补 header"方案

继续?(说"继续",或给新指令)
```

### 4. 等待用户的下一步指令

不要自动开始执行 —— 让用户确认或调整方向。

## 边缘情况

- **超过 10 个 in_progress task**:只展示最近 10 个,提示"还有 N 个更早的,需要看全部用 `ls .claude/tasks/`"
- **某个 Task 文件损坏**(没有 frontmatter):跳过它,提示"Task-xxx 文件格式异常,已跳过"
- **当前不在项目根目录**:警告"看起来你不在项目根,建议 `cd` 到项目根再 /continue-task"
- **多个项目都有 in_progress task**:只列当前 pwd 的,不跨项目

## 反例(别这样做)

- ❌ 自动选择"最近的那个" —— 必须用户明确选
- ❌ 把所有 task 的完整内容一次贴出来 —— 信息过载
- ❌ 恢复后立即开干 —— 必须等用户确认方向
- ❌ 跨项目搜索 in_progress task —— 用户选了"每项目独立",别污染上下文
