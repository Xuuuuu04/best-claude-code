---
name: bcc-update-project
description: 扫描代码库当前状态，更新 CLAUDE.md 索引和 project-knowledge Skill 的详细内容。应定期运行或在重大变更后触发。
disable-model-invocation: true
---

# 项目知识更新

此 Skill 刷新项目状态快照。它应该在 `context: fork` 的隔离上下文中运行（因为要读大量文件），避免污染主会话。

---

## 运行条件

- `.claude/skills/_domain/project-knowledge/SKILL.md` 必须存在（由 `/bcc-init-project` 创建）
- 当前在 git 仓库中（用于提取近期提交作为变更日志素材）

---

## Phase 1: 扫描

派遣 explorer subagent 做全面扫描：

```
任务：扫描代码库当前状态，产出更新所需的信息。

对比项：读取现有的 .claude/skills/_domain/project-knowledge/SKILL.md，识别当前状态和已记录状态的差异。

请产出差异报告到 .claude/artifacts/update-analysis.md：

1. **技术栈变化**
   - 新增的依赖（对比 package.json/requirements.txt/go.mod 等）
   - 版本变化
   - 移除的依赖

2. **模块变化**
   - 新增的目录/模块
   - 重命名的模块
   - 移除的模块

3. **API 变化**
   - 新增的端点（扫描路由定义文件）
   - 签名变化的端点
   - 废弃的端点

4. **数据模型变化**
   - 新增的表/集合
   - schema 变化（扫描 migrations 或 schema 定义）

5. **变更日志素材**
   - 近 20 条 git commit（git log --oneline -20）
   - 主要变化归纳为 3-5 条

6. **废弃内容**
   - 现有 project-knowledge 中已不成立的信息
```

---

## Phase 2: 生成更新

基于 explorer 的分析，更新两个文件：

### 2.1 更新 `.claude/skills/_domain/project-knowledge/SKILL.md`

这是**详细版**项目知识，容量可达 200-500 行。更新规则：

- 保留未变化的区块
- 技术栈、模块、API、数据模型区块用最新信息覆盖
- 在变更日志顶部追加新的 3-5 条
- 废弃内容删除
- 更新"最后更新"时间戳

### 2.2 更新根 CLAUDE.md

这是**精练版**索引，容量应 <200 行。只更新：

- 技术栈区块（如有新增主要技术）
- 核心模块区块（如有模块新增/移除）
- 构建/测试命令（如 package.json 脚本有变化）
- `@imports`（如需引用新文件）

**不**更新到 CLAUDE.md 的内容：
- 详细 API 列表（那是 project-knowledge Skill 的责任）
- 具体进度和版本号（那是 project-knowledge Skill 的责任）
- 架构决策记录（那是 project-knowledge Skill 的责任）

---

## Phase 3: 校验

派遣 quality-guardian：

```
审查类型：architecture-review
审查对象：
- CLAUDE.md
- .claude/skills/_domain/project-knowledge/SKILL.md

请验证：
- CLAUDE.md 仍符合 rules/_global/claudemd-standard.md 规范
- CLAUDE.md 总行数未超过 200
- project-knowledge 的信息内部一致（例如提到的模块在模块列表中都存在）
- 没有明显遗漏的重大变更
```

---

## Phase 4: 向用户汇报

```markdown
## 项目知识已更新

**扫描时间**: {timestamp}
**对比基准**: 上次更新于 {prev_timestamp}

### 识别的变化
- **技术栈**: {+增加的 / -移除的 / ↑升级的}
- **模块**: {+新增 / -移除}
- **API**: {+新增 N / ✎修改 M / -废弃 K}
- **数据模型**: {变化描述}

### 近期关键变更（从 git log 归纳）
1. ...
2. ...

### 已更新的文件
- CLAUDE.md（精练索引）
- .claude/skills/_domain/project-knowledge/SKILL.md（详细知识）

### 建议
- {如果某些区块信息不足或过期严重，提醒用户手动补充}
- {如果发现了值得固化为 Rule 的模式，建议运行 /bcc-evolve}
```

---

## 自动运行触发

此 Skill 也可以由其他流水线自动调用：

- `/bcc-new-feature` 完成后静默调用（Phase 5.1）
- `/bcc-fix-bug` 完成后可选调用

自动调用时应简化汇报（不产出完整 Markdown 报告，只返回"已更新"状态）。

---

## 异常处理

- **project-knowledge 不存在**：提示用户先运行 `/bcc-init-project`
- **没有检测到变化**：仅更新时间戳，无需动用其他 Agent
- **Explorer 扫描超时**：限定扫描范围（如仅扫描 src/）并告知用户
