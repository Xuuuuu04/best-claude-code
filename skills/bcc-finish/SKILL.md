---
name: bcc-finish
description: '当 Task 的所有 Plan 步骤做完、用户说"搞定了/完成了/可以了"、或主代理判断工作已完成时自动激活 —— 写 Completion 段(Files changed / Verification / HANDOVER)并标记 status: done。自动先跑 preflight 再 finish。'
argument-hint: "[task-id（可选，默认当前活跃 task）]"
---

# /bcc-finish

把当前 Task 文件从 `in_progress` 推进到 `done`,**强制写好 HANDOVER**(用户最痛的痛点)。

## 本次改动摘要（动态注入）

!`echo "### git diff --stat"; git diff --stat HEAD 2>/dev/null || echo "(无 git 改动或非 git 仓库)"; echo ""; echo "### 活跃 Task"; if [ -d ".claude/tasks" ]; then grep -l 'status: in_progress' .claude/tasks/*.md 2>/dev/null | while read f; do echo "- $(basename "$f" .md): $(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')"; done; else echo "(无)"; fi`

## 何时调用

- 主代理判断当前 task 的所有 Plan 步骤都做完了
- 用户说"完成了" / "搞定" / "可以了" / `/bcc-finish`
- ⚠️ **如果 verification 还没跑过,先 `/bcc-preflight`,再 `/bcc-finish`**

## 执行步骤

### 1. 定位当前 Task 文件

通常主代理已经知道当前在哪个 task。如果不确定,grep 找 in_progress 的最近一个;如果有多个,问用户哪个。

### 2. 验证完成度

回看当前 Task 文件的 Intent 段中的"验收"清单:

- 每条都打勾了吗?
- 有没有遗漏的验收项?
- 如果有验收项没满足:
  - 用户能接受不满足吗?(标记 `status: done` 但在 Completion 段说明)
  - 还是该改成 `status: paused` 等后续?
  - 还是该 `status: abandoned`?

### 3. 写 Completion 段

按下面格式追加到 Task 文件末尾:

```markdown
## Completion

### Files changed
- src/auth/refreshToken.ts (修复缺失 header)
- src/auth/__tests__/refresh.test.ts (新增 3 个用例)

### Verification
- typecheck: pass
- lint: pass
- 新增单测: 3 个用例全通过
- 手动验证: <如有,例:登录后等 30 分钟仍可用>

### 验收对照
- [x] 登录后 24h 持续可用 —— 单测覆盖到 expiry-1s 边界
- [x] 不改后端 —— 仅前端拦截器变化

### HANDOVER
<必填,一句到三句,给未来的自己/未来会话看>

例:已修 token refresh 失败问题。下次再有 auth 异常,先看 src/auth/index.ts 的拦截器,
那里还有个待办 TODO 是处理 401 跳登录页。修复方案见 src/auth/refreshToken.ts:42 附近。
```

### 4. 更新 frontmatter

把 frontmatter 中:
- `status: in_progress` → `status: done`
- `finished: null` → `finished: <当前时间,格式 2026-05-15 11:45>`

### 5. 重置 hook state

Task 完成了,把编辑计数器归零——不然老计数会误拦下一个 task:

```bash
# 清掉 hook 计数器(state 按 session 隔离,glob 把旧会话残留一起清)
rm -f "$(pwd)/.claude/tasks/.hook-state"*.json
```

### 6. (可选) 清理 outputs

brief 和 subagent 输出都在 `outputs/`,已被 .gitignore 忽略、不进版本库,放着也不影响仓库。想保持干净就把本 task 明显相关的文件挪进 `archive/`:

```bash
mkdir -p "$(pwd)/.claude/tasks/archive"
# 按主题手动挪相关文件,或整体留在 outputs/ —— 反正不进 git
```

简单任务没调过 subagent 时,跳过此步。

### 7. 报告并提示 commit

输出:
```
✓ Task 已封档:Task-2026-05-15-1030-fix-auth-bug

HANDOVER 摘要:<复述一行>

要 git commit 吗?
```

如果用户说要 → 用 Bash 执行 commit(遵循项目的提交规范),把 Task 文件 ID 写进 commit message,例:
```
fix(auth): token refresh missing Authorization header

Task: Task-2026-05-15-1030-fix-auth-bug
```

如果用户说不 → 不要自作主张去 commit,等他后续手动。

**注意**:归档目录 `archive/` 已被 `.gitignore` 忽略(如未忽略,请提醒用户加上),
Task 文件本身(`Task-xxx.md`)保留在 tasks/ 目录下;是否进 git 由各项目的 .gitignore 决定(本仓库 ~/.claude 就忽略了它们)。

## HANDOVER 质量要求(这是核心痛点)

HANDOVER 段是这个 skill 存在的根本理由。写得敷衍 = 这个 skill 白做。检查清单:

- ✓ **写了"我做了什么"** —— 一句话总结结果
- ✓ **写了"在哪里"** —— 关键文件 + 行号或函数名
- ✓ **写了"还有什么没动/待办"** —— 防止下次重复探索
- ✓ **写了"怎么验证"** —— 让未来的自己知道如何确认效果
- ✗ 不要只写"修了 bug"(信息密度为零)
- ✗ 不要复制 Files changed 段的内容(重复)
- ✗ 不要写未来计划(那是新 task 的事)

## 边缘情况

- **task 没有任何 Execution Log**:可能用户根本没干就 finish,提示"这个 task 似乎没开干,确定 finish 而不是 abandoned?"
- **验收清单一项都不满足**:建议改 status: abandoned 或 paused,而不是 done
- **多个 task 同时 in_progress**:本次只 finish 一个,其他保持
- **HANDOVER 写不出**:说明你没真做完,回去补完再 finish

## 反例(别这样做)

- ❌ 跳过 verification 直接 finish —— 必须先 preflight
- ❌ HANDOVER 写"已完成" —— 等于没写
- ❌ 自动 git commit —— 用户偏好"轻量确认",commit 也要问一下
- ❌ 用同一行 HANDOVER 应付所有 task —— 每个 task 的 HANDOVER 应该是独特的
- ❌ 改了 Decisions 段或 Prompt 段 —— 这两段 append-only,不能改写
