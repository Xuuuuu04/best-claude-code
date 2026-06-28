---
name: bcc-review
description: '自动生成 review brief 并调度 reviewer agent 对当前 Task 的代码改动进行多维度量化评分。读 Task 的 Spec 段获取 Review Dimensions,读 git diff 获取改动范围,写 brief 到 outputs/,调度 reviewer,读结果,追加 Review History 到 Task 文件。也可用户显式 /bcc-review 调用。'
argument-hint: "[task-id（可选，默认当前活跃 task）]"
---

# /bcc-review

自动生成 review brief → 调度 reviewer agent → 读评分结果 → 追加 Review History。

## 何时调用

- Developer subagent 返回 `status: DONE` 后,主代理调用本 skill 发起 review
- 主代理自己写完代码后(fast path 小改动),调用本 skill
- 用户显式说 `/bcc-review`
- bcc-finish 检测到有 Spec 但没 review 记录时提示调用

## 当前环境（动态注入）

!`echo "- 项目根: $(pwd)"; echo "- 时间戳: $(date '+%Y-%m-%d %H:%M')"; echo ""; echo "### git diff --stat"; git diff --stat HEAD 2>/dev/null || echo "(无 git 改动)"; echo ""; echo "### 活跃 Task"; if [ -d ".claude/tasks" ]; then grep -l 'status: in_progress' .claude/tasks/*.md 2>/dev/null | while read f; do echo "- $(basename "$f" .md): $(grep -m1 '^# ' "$f" 2>/dev/null | sed 's/^# //')"; done; else echo "(无)"; fi; echo ""; echo "### 已有 review 记录"; ls .claude/tasks/outputs/review-*.json 2>/dev/null || echo "(无)"`

## 执行步骤

### 1. 定位 Task 和 Spec

读当前活跃 Task 文件,找到:
- `## Spec` 段 → Requirements 列表 + Review Dimensions 表
- `## Review History` 段 → 已有多少轮,最新分数是多少

如果 Task 没有 Spec 段(纯文档/配置任务),输出提示"该 Task 无 Spec,不需要量化 review"并退出。

### 2. 确定轮次

看 `outputs/` 下已有多少个 `review-{slug}-r{N}.json`:
- 没有 → 这是 Round 1
- 有 r1 → 这是 Round 2,brief 里要带上 r1 的路径让 reviewer 算 delta
- 有 r1+r2 → 这是 Round 3,如果上一轮 pass 还是 false,考虑是否该叫 judge

### 3. 收集改动范围

```bash
# 获取改动文件列表(相对路径)
git diff --name-only HEAD 2>/dev/null
# 如果有 dev-result JSON,从中读 files_changed
```

### 4. 生成 Review Brief

写到 `outputs/brief-review-{slug}-r{N}.md`:

```markdown
# Brief: Code Review Round {N} for {Task Title}

**Task**: {task-id}
**For**: reviewer
**Created**: {timestamp}
**Round**: {N}

## Activation Persona
(reviewer agent 有固定 persona,这段写"See agents/reviewer.md"即可)

## Mission
Review the code changes for Task {task-id} against the Spec requirements and score each dimension.

## Known Facts
- Task 目标: {从 Intent 复制}
- 改动范围: {files list}
- {如果 Round 2+: 上轮 weighted score 和 blocking dimensions}

## Files You Need
- {改动的文件路径,精确到行号}
- {相关测试文件}

## Review Dimensions (from Task Spec)
| Dimension | Weight | Threshold |
|---|---|---|
| {复制 Task 的 Review Dimensions 表} |

## Requirements (from Task Spec)
- FR-1: {复制}
- FR-2: {复制}

## Previous Reviews
{Round 1: 无}
{Round 2+: 列出前几轮 review JSON 路径,让 reviewer 读取算 delta}

## Acceptance Criteria
- [ ] 所有 Requirements 的 met 字段正确填写
- [ ] 每个 dimension 有 score + reasoning
- [ ] weighted_score 计算正确
- [ ] actionable_summary 具体可执行

## Output Format
写入 `outputs/review-{slug}-r{N}.json`,schema 见 agents/reviewer.md。

## Constraints
- 只 review 本次改动涉及的文件,不扩大范围
- 不能修改任何代码文件
```

### 5. 调度 Reviewer Agent

```
Agent(type: reviewer, prompt: "Read the briefing file at {brief path}, then execute. Write your output to the path specified in the brief.")
```

### 6. 读 Review 结果

Reviewer 完成后,Read `outputs/review-{slug}-r{N}.json`:
- 提取 `weighted_score` 和 `blocking_dimensions`
- 提取 `actionable_summary`

### 7. 追加 Review History 到 Task 文件

在 Task 文件的 `## Review History` 段追加:

```markdown
### Round {N} ({HH:MM})
- Weighted: {weighted_score} | {dim1}: {score1} {dim2}: {score2} ...
- Blocking: {blocking_dimensions or "无"}
- Action: {从 actionable_summary 提炼一句}
```

### 8. 报告结果

向用户/主代理输出:

如果 pass: true:
```
Review Round {N} 通过 (weighted: {score})
可以 /bcc-finish 了。
```

如果 pass: false:
```
Review Round {N} 未通过 (weighted: {score}, blocking: [{dims}])
下一步: {actionable_summary}
```

如果 Round ≥ 3 且仍 pass: false:
```
Review 已 {N} 轮未收敛。建议召唤 judge 裁决。
```

## 反例

- ❌ 没有 Spec 也强行 review — 没有 Review Dimensions 就没有评分标准
- ❌ 每轮都从头写 brief 不带前轮信息 — reviewer 需要 delta,必须带前轮 review JSON 路径
- ❌ review 结果只告诉用户 pass/fail 不说 actionable — 必须告诉下一步做什么
