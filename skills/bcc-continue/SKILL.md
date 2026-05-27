---
name: bcc-continue
description: 列出当前项目所有 in_progress 的 Task,让用户选一个继续。用于跨会话恢复、上次/compact 后的恢复、或用户主动切回某个未完成的任务。
argument-hint: "[task-id（可选，不填则展示列表选择）]"
---

# /bcc-continue

跨会话/跨 compact 捡回一个没做完的 Task,把状态 load 进来继续。

## 何时调用

- 用户说"继续上一个" / "接着昨天那个 X" / `/bcc-continue`
- `SessionStart` hook 检测到 in_progress task 并建议恢复时(用户同意)
- `/compact` 后主代理意识到要继续之前的工作

## 当前项目活跃 Task（动态注入）

!`if [ -d ".claude/tasks" ]; then grep -l 'status: in_progress' .claude/tasks/*.md 2>/dev/null | while read f; do echo "---"; echo "文件: $f"; echo "ID: $(basename "$f" .md)"; grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^/标题: /'; grep -m1 '^started:' "$f" 2>/dev/null | sed 's/^/  /'; grep -E '^- [0-9]{2}:[0-9]{2} ' "$f" 2>/dev/null | tail -1 | sed 's/^/最近: /'; echo ""; done; else echo "(当前项目无 .claude/tasks/ 目录)"; fi`

## 执行步骤

### 1. 展示上方注入的列表

如果上方动态注入的内容为空或只有"无 .claude/tasks/ 目录" → 输出"当前没有进行中的 task,要不要 `/bcc-start` 开新的?"并退出。

否则,按上方注入的列表编号展示给用户:

```
找到 N 个进行中的 task:

[1] Task-2026-05-15-1030-fix-auth-bug
    标题: Fix auth token refresh bug
    开始: 2026-05-15 10:30
    最近: 10:55 定位根因 refreshToken.ts:42

[2] ...

选哪个继续?(回数字,或说"都不要,开新的")
```

### 2. 加载选中的 Task

用户选 [N] 后:
1. Read 整个 Task 文件
2. 把文件内容作为当前工作上下文,主代理"心理上"认为这是当前活跃任务
3. 在 Execution Log 段追加一行:`- HH:MM 会话恢复(/bcc-continue)`
4. 主代理输出一段简短的状态总结:

```
✓ 已恢复 Task-2026-05-15-1030-fix-auth-bug

当前状态:
- Plan 第 1-2 步已完成(已定位根因)
- 第 3 步待做:实施修复
- 上次决策:选择"补 header"方案

继续?(说"继续",或给新指令)
```

### 3. 等待用户的下一步指令

不要自动开始执行 —— 让用户确认或调整方向。

## 边缘情况

- **超过 10 个 in_progress task**:只展示最近 10 个,提示"还有 N 个更早的,需要看全部用 `ls .claude/tasks/`"
- **某个 Task 文件损坏**(没有 frontmatter):跳过它,提示"Task-xxx 文件格式异常,已跳过"
- **当前不在项目根目录**:警告"看起来你不在项目根,建议 `cd` 到项目根再 /bcc-continue"
- **多个项目都有 in_progress task**:只列当前 pwd 的,不跨项目

## 反例(别这样做)

- ❌ 自动选择"最近的那个" —— 必须用户明确选
- ❌ 把所有 task 的完整内容一次贴出来 —— 信息过载
- ❌ 恢复后立即开干 —— 必须等用户确认方向
- ❌ 跨项目搜索 in_progress task —— 用户选了"每项目独立",别污染上下文
