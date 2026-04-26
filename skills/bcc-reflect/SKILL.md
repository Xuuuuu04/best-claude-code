---
name: bcc-reflect
description: 当前会话学习总结。在重要工作会话结束时手动触发，将值得记忆的发现写入 Auto Memory。
argument-hint: "[focus-topic?: bug-pattern | architecture-decision | tooling-tip]"
disable-model-invocation: true
---

# 会话反思

这是 Auto Memory 之上的结构化学习 Skill。Auto Memory 是"被动兜底"——你做什么它记什么。`/bcc-reflect` 是"主动总结"——你有意识地提炼有价值的洞察。

---

## Phase 1: 回顾会话

扫描当前会话的关键事件（从会话记录或你自己的记忆中）：

1. **被用户纠正的错误**
   - 用户说过"不是这样"、"应该"、"不要"的地方
   - 哪些行为需要以后避免？
   - 哪些偏好被显式声明？

2. **成功解决的复杂问题**
   - 遇到了什么棘手问题
   - 是如何解决的
   - 这个方法是否可复用？

3. **项目架构的新发现**
   - 在阅读代码中学到的新模式
   - 未写入 project-knowledge 的重要事实
   - 需要以后避免踩坑的地方

4. **用户工作偏好**
   - 用户倾向的沟通风格
   - 用户关注的重点
   - 用户不喜欢的提议类型

---

## Phase 2: 分类

将发现分类到以下四类之一：

- **user 类**：关于用户的信息 → 写入 `~/.claude/projects/<project>/memory/user-preferences.md`
- **feedback 类**：关于工作方式的纠正 → 写入 `~/.claude/projects/<project>/memory/feedback.md`
- **project 类**：关于项目的事实 → 写入 `~/.claude/projects/<project>/memory/project-notes.md`
- **reference 类**：外部资源指针 → 写入 `~/.claude/projects/<project>/memory/references.md`

---

## Phase 3: 写入

### 3.1 写入主题文件

对每条发现，追加到对应主题文件。格式：

```markdown
## {简短标题}

**记录时间**: {timestamp}
**类型**: user / feedback / project / reference
**触发上下文**: {一句话说明在什么场景下学到的}

**规则/事实**: {具体内容}

**为什么**: {如果是 feedback 类，解释原因)
**如何应用**: {如果是 feedback/project 类，说明何时该想起这条记忆}
```

### 3.2 更新 MEMORY.md 索引

确保 `~/.claude/projects/<project>/memory/MEMORY.md` 的前 200 行包含指向新主题文件的精简索引：

```markdown
# Memory Index

## user
- [sidebar-preference](user-preferences.md#sidebar-preference) — 用户偏好详细而非简短的 PR 描述

## feedback
- [no-mock-db-in-tests](feedback.md#no-mock-db-in-tests) — 集成测试用真实 DB，不 mock（有踩坑史）

## project
- [auth-refresh-race](project-notes.md#auth-refresh-race) — token 刷新有竞态条件，使用分布式锁
- [...]

## 待深入学习
- {你注意到但本次未深入的知识缺口}
```

---

## Phase 4: 触发进化（可选）

扫描 MEMORY.md 的条目密度。如果某一主题的条目数 ≥5 条，建议：

```
本次反思发现 {主题} 已积累 {N} 条笔记。建议运行 /bcc-evolve 将其固化为 Rule 或 Skill。
```

---

## Phase 5: 向用户汇报

```markdown
## 本次会话反思完成

**识别的发现**: {N} 条
- user: {k}
- feedback: {k}
- project: {k}
- reference: {k}

**已更新的文件**:
- {列出}

**Memory 容量**: MEMORY.md 当前 {M} 行（上限 200 行）

**建议**:
- {如果接近 200 行，建议运行 /bcc-evolve 做瘦身}
- {如果某主题积累足够，建议固化}
```

---

## 判断标准

只记录有价值的发现，不要为了记而记。一条记忆值得记住，当且仅当：

- **非显而易见**：不是常识，不是通过读代码就能推断
- **跨会话有用**：下次对话可能需要这条信息
- **具体可行**：能指导具体决策，而非空泛口号

不要记录：
- 本次任务的中间状态（那是会话本身的职责）
- 代码实现细节（那是代码本身的职责）
- 文档中已明确的规范（那是 Rules/Skills 的职责）
- 可以通过 `git log` 查到的信息

---

## 异常

- **本次会话无值得记录的发现**：坦白汇报"本次反思未识别到需记录的新发现"，不要强行制造内容
- **MEMORY.md 接近上限**：在汇报中提示用户运行 `/bcc-evolve`
