# 工程纪律深化清单

> 灵感来源：Anthropic Word/Excel/PowerPoint agent 系统 prompt 公开模式 + Codex/Jules agent 公开行为协议。本文档不复制任何原文，只把方法论用我们的语言重述并适配 Agent Legion 的 scope-lock 体系。

适用：所有 实现工程师-* / 小程序开发专家 / 资深数据库工程师 / 机器学习工程师。在执行 scope-lock 时遵守。

---

## 1. 读回验证（最高优先级）

每次写文件后，**必须**用读取工具重新读受影响的范围，确认实际落地的内容。

为什么：
- LLM 工具调用并非原子——bash 错误、IDE 状态、字符编码、行尾差异都可能导致"看似成功"
- 工具返回成功 ≠ 任务正确
- 不读回就报告"完成" = 把验证责任甩给下一个 agent / 用户

读回什么：
- **代码改动**：被改函数 + 上下文行（避免 indent 漂移）
- **配置改动**：JSON / YAML 整文件（语法合法 + 字段位置正确）
- **新文件**：第一行（确保不是空文件 / 编码错乱）
- **多处编辑**：每处都读回，不是只读最后一处

读回失败时禁止重试。

---

## 2. Non-atomic 错误处理

**核心规则**：写操作抛错 → 不要立即重试。

工具调用不是原子的。一次失败的 `Edit/Write` 可能已经部分落地（特别是多行替换、bash 脚本中途失败、jq pipe 中断）。盲目重跑会**追加重复**或**冲突写入**。

正确流程：

1. **读回当前状态**——看 diff vs 你的目标
2. **从观察到的状态继续**——删除已部分写入的残留 / 只补缺失部分
3. **绝对禁止**：从头跑一遍原始脚本

示例：
- 错误：`Write` 失败 → 重跑同样 `Write` → 文件可能变成原内容 + 你的内容拼接
- 正确：失败 → `Read` 看实际状态 → `Edit` 精修

---

## 3. 编辑源文件，不编辑构建产物

如果文件位于 `dist/` `build/` `target/` `__pycache__/` `node_modules/`：

- **几乎必然是构建产物**
- 改它无效——下次 build 会被覆盖
- 用 `grep`/`rg` 找到对应**源文件**，改源
- 改完后跑 build 重新生成产物（如果 scope-lock 允许）

例外：scope-lock 明确列出某 dist 文件——少数项目把生成结果 commit 到仓库。看 scope-lock。

---

## 4. 诊断先于环境改动

build/test/依赖失败时，**第一反应不是 `npm install` / `pip install`**。

按顺序：
1. **读 error 完整堆栈**——常常根因写在第三行
2. **看配置文件**：`package.json` `requirements.txt` `go.mod` `Cargo.toml`
3. **看 lock 文件**——版本冲突常在这
4. **看 README / AGENTS.md**——可能写了特殊步骤
5. **优先改代码或测试**，再考虑改环境
6. **环境改动需经用户确认**（升降级、删依赖）

---

## 5. 端到端坚持

接到清晰任务后：探索 → 计划 → 实现 → 验证 → 报告。**不要在"分析阶段"或"部分修复"停下来等用户确认**——除非：

- 用户明确要求计划审批
- 任务边界明显出现分叉
- 触发了 unclear 触发条件
- scope-lock 自相矛盾

正常情况：直到验证通过为止持续推进。报告时已经是"已完成"，不是"我打算这么做"。

例外：scope-lock 明确把任务限定为"只分析不修复"。

---

## 6. 并行工具调用

独立的、互不依赖的工具调用应在**同一消息**中并发发起：

- 多个 `Read` 不同文件
- `grep` + `Read` 没有依赖关系
- `Bash` 跑测试 + `Read` 看代码

不并发：
- 一个调用的输出是另一个的输入
- 写操作（Edit/Write）——除非在不同文件且互不依赖
- 用户明确要求串行

---

## 7. AGENTS.md 遵守

仓库可能在任意目录有 `AGENTS.md`。规则：

- 一个 `AGENTS.md` 的 scope = 它所在目录的整个子树
- 改文件时遵守 scope 内最近的 `AGENTS.md`
- 嵌套优先级：更深的覆盖更浅的
- 用户明确指令 > AGENTS.md
- AGENTS.md 含 programmatic check 时**必须跑**

发现 AGENTS.md 与 scope-lock 冲突 → 停止，向调度器汇报。

---

## 8. 不做 destructive git

未经用户明确请求或批准，**禁止**：

- `git reset --hard`
- `git checkout --` 丢弃改动
- `git push --force` / `--force-with-lease` 到任何分支
- `git clean -fd`
- `git rebase -i` 已 push 的分支
- 删除分支或 tag

允许：
- `git status` `git diff` `git log`（只读）
- `git add` / `git commit`（用户明确要求时）
- 创建新分支 / 切换分支

---

## 9. 不 amend 已 push 的 commit

`git commit --amend` 仅在用户明确要求时使用。

理由：amend 改写历史，已 push 的 commit 被 amend 后会强制其他人变基，破坏协作。

正确做法：创建新 commit 修复，commit message 写明"fix typo in PREVIOUS_COMMIT_HASH"。

---

## 10. Verify before report

报告任务完成前：

- 把 scope-lock 的 Definition of Done 逐条对照
- 跑 lint / typecheck / 关键测试（scope-lock 指定的）
- 读回每个改动文件的关键段
- 列出未完成项 / 遗留问题（如有）
- **绝不**说"all/every/全部"除非真的逐个确认了
- 工具成功 ≠ 任务正确

---

## 关于"读回验证"在不同语言的具体方法

| 文件类 | 读回检查项 |
|:--|:--|
| Markdown | 章节结构 + frontmatter 字段 |
| JSON / YAML | 用 `python3 -c "import json;json.load(open(...))"` 或 `yq` 验证语法 |
| Python | `python3 -m py_compile` 或 `ruff check` |
| TypeScript / JS | `tsc --noEmit` 或 ESLint |
| Bash | `bash -n` 语法检查 |
| SQL migration | 用 dryrun 工具或在测试库跑 |
| Office (.docx/.xlsx/.pptx) | 不要在编辑后直接报告——重新打开看渲染 |
