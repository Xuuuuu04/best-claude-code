# Git 工作流规范

适用于所有项目的 Git 操作规范。

---

## Commit Message 规范

遵循 Conventional Commits：

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Type

- `feat`: 新功能
- `fix`: Bug 修复
- `docs`: 文档改动
- `style`: 代码格式化（不影响行为）
- `refactor`: 重构（不改功能不修 bug）
- `perf`: 性能优化
- `test`: 测试相关
- `build`: 构建系统或依赖变更
- `ci`: CI 配置变更
- `chore`: 其他杂项

### Scope（可选）

模块名或影响范围：`auth`、`api`、`ui` 等。

### Subject

- 现在时、命令式（"add" 而非 "added" 或 "adds"）
- 首字母小写
- 不以句号结尾
- ≤ 50 字符

### Body

- 解释**为什么**，不只是**做了什么**
- 每行 ≤ 72 字符
- 段落间空行

### Footer

- `BREAKING CHANGE:` 破坏性变更
- `Refs:` 相关 issue / PR / artifact
- `Co-authored-by:` 协作者

---

## 分支策略

### 命名

- `main` / `master`：主分支
- `feature/{task-id}-{short-desc}`：功能分支
- `fix/{issue-id}-{short-desc}`：修复分支
- `release/v{semver}`：发布分支
- `hotfix/{issue-id}`：紧急修复

### 保护

- `main` 不允许直接 push
- 所有变更通过 PR / MR
- PR 必须通过 CI + 至少 1 次 review

---

## 提交原则

- **小而专注**：一个 commit 做一件事
- **可构建**：每个 commit 应该可以 build、可以 run
- **可读**：历史对未来的你和队友有意义
- **可搜索**：commit message 包含关键词便于 `git log --grep`

## Push 前门控（强制）

`git push` 前**必须**：

- 本地编译通过（如 `npm run build` / `cargo build` / `go build` 项目对应命令）
- 类型检查通过（如 `npm run type-check` / `tsc --noEmit` / `mypy`）
- Lint 通过（如 `npm run lint` / `eslint .` / `ruff`）

**禁止**："改完直接 push 让 CI 当编译器"。CI 失败会污染 commit 历史、阻塞团队，且让客户在测试环境看到 broken build。

**双产物项目**（如 uni-app 同时输出 H5 + mp-weixin）：每个产物都要单独编译验证，不能只跑其中一个就推。

---

## 禁止操作

### 绝对禁止

- `git push --force` 到 `main` / `master` / 已发布的 release 分支
- `git commit --amend` 已 push 的 commit
- `git rebase -i` 已共享的分支
- 使用 `--no-verify` 跳过 pre-commit hook（除非明确需要且评估风险）
- `git reset --hard HEAD~N` 未 stash 的改动
- 提交包含密钥、密码、token 的文件

### 需要用户确认才能做

- `git push --force-with-lease`（安全的强推）到个人分支
- `git filter-branch` / `git filter-repo` 历史重写
- 删除分支（本地或远程）
- 删除 tag

---

## PR / MR 规范

### 标题
- 遵循 commit message 的 type 规范
- 简洁清晰

### 描述
- 引用相关 issue / artifact
- 说明"做了什么 + 为什么"
- 列出测试方式
- 截图（如 UI 变更）

### Review
- 至少 1 人 approve
- 所有评论响应或解决
- CI 全部通过

---

## 敏感信息处理

### 已提交的秘密立即处理

1. **立即轮换**（假设已泄露）
2. 使用 `git filter-repo` 或 BFG 清除历史
3. Force push（经团队同意）
4. 通知可能受影响的方

### 预防

- `.gitignore` 覆盖 `.env`、credentials.json、*.pem
- `git-secrets` / `truffleHog` 扫描
- pre-commit hook 自动检查
- 代码审查关注新增的 config 文件

---

## Tag 与发布

- Tag 用 annotated（`-a`）而非 lightweight
- 版本遵循 SemVer
- 发布前更新 CHANGELOG
- 推送 tag：`git push origin v1.2.3`

---

## 撤销操作

### 撤销本地未 push 的 commit
```bash
git reset --soft HEAD~1   # 保留改动
git reset --hard HEAD~1   # 丢弃改动（谨慎）
```

### 撤销已 push 的 commit
```bash
git revert <commit>       # 创建新 commit 撤销
```
**不要**用 `reset + force push` 撤销公共提交。

### 恢复误删
```bash
git reflog                # 查找丢失的 commit
git cherry-pick <hash>    # 恢复
```

`.git/objects` 中保留的内容可通过 reflog 恢复 ~30 天。
