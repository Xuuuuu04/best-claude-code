---
name: preflight
description: 提交代码前的必跑检查 —— 读项目 CLAUDE.md 的 ## Preflight Commands 段,依次执行(typecheck / lint / 可选 e2e),任一失败立即停并报告。全过则在当前 Task 的 Execution Log 加一行"preflight pass"。
disable-model-invocation: true
allowed-tools: Bash(npm *) Bash(npx *) Bash(mvn *) Bash(go *) Bash(mypy *) Bash(ruff *) Bash(markdownlint *)
argument-hint: "[子目录（可选，多端项目指定）]"
---

# /preflight

提交代码前的最后一道门。强制实施项目纪律,不靠主代理记得。

## 何时调用

- 主代理准备 `git commit` / `git push` 之前(主动)
- 用户说"提交一下" / "推一下" / `/preflight` 时
- `/finish-task` 之前(让 verification 段有真实数据填)
- 任何重大改动后,主代理主动跑一次确认没坏

## 执行步骤

### 1. 找项目的 Preflight Commands 段

```bash
PROJECT_CLAUDE_MD=$(find . -maxdepth 2 -name "CLAUDE.md" -type f | head -1)
if [ -z "$PROJECT_CLAUDE_MD" ]; then
  echo "⚠️ 没找到项目 CLAUDE.md。跳过 preflight 还是手动指定命令?"
  exit 1
fi
```

读该文件,提取 `## Preflight Commands` 段下面的命令列表。命令格式约定:
```markdown
## Preflight Commands
- npm run typecheck
- npm run lint
- (可选) npm run test:unit
```

如果项目 CLAUDE.md 里没这段,引导用户添加:

```
项目 CLAUDE.md 里没有 ## Preflight Commands 段。
建议添加(基于这个项目的技术栈):
  npm run typecheck
  npm run lint

要现在加吗?
```

### 2. 顺序执行(不并行)

为什么不并行:第一条失败时,后面的没必要跑(typecheck 挂了 lint 也大概率挂),输出干净。

```bash
for CMD in <提取出的命令列表>; do
  echo "▶ $CMD"
  $CMD
  if [ $? -ne 0 ]; then
    echo "✗ FAILED: $CMD"
    echo "preflight 失败,停在这一步。后续命令未执行。"
    exit 1
  fi
  echo "✓ pass: $CMD"
done
```

### 3. 失败处理

输出:
```
✗ preflight 失败:`npm run typecheck` 退出码 1

错误摘要:
<最后 20 行输出,聚焦报错部分>

接下来:
1. 修这个错误 → 再 /preflight
2. 或者:把这个错误的原因记到当前 Task 的 Decisions 段
3. 别想着 --no-verify 绕过 —— 提示词里禁止
```

**不要自动尝试修复** —— 让用户/主代理在下一轮决定怎么处理。preflight 只做检测和报告。

### 4. 全通过

输出:
```
✓ preflight 全通过:typecheck / lint / test
```

并在当前活跃 Task 文件的 Execution Log 段追加一行:
```markdown
- HH:MM preflight pass(typecheck / lint / test 全通过)
```

如果当前没有活跃 Task,跳过这一步,只输出到对话。

## 多端项目处理

如果项目 CLAUDE.md 在多个子目录下有(例如 `web/CLAUDE.md`、`miniapp/CLAUDE.md`、`backend/CLAUDE.md`),preflight 应在哪里跑?

判断规则:
1. **看用户改动的范围**:`git diff --name-only` 列出动过哪些目录
2. **只在相关子项目的目录跑 preflight**,例如改了 `web/src/*`,就 `cd web && <preflight commands>`
3. 全部相关子项目都跑过才算 pass

例如改动跨 web 和 backend → 都跑;只改了 web → 只跑 web。

## 反例(别这样做)

- ❌ 用 `--no-verify` 或 `--allow-empty` 跳过失败 —— 这违反 harness engineer 精神
- ❌ 自动尝试修复(npm run lint:fix 之类)—— preflight 只检测,不改代码
- ❌ 并行跑多个命令 —— 输出会乱,定位失败困难
- ❌ 第一条 pass 就 commit 了 —— 必须全跑完
- ❌ 失败时把所有错误输出贴出来 —— 只贴最后 20 行的关键报错

## 给项目 CLAUDE.md 添加 Preflight Commands 的模板

帮用户加段时用这个格式:

```markdown
## Preflight Commands(被 /preflight skill 读取)

提交前必跑,顺序执行,任一失败即停:
- npm run typecheck
- npm run lint

(可选,大型改动时跑):
- npm run test:unit
```

对不同项目类型的建议:

| 项目类型 | 推荐 Preflight Commands |
|---|---|
| Next.js / Vue / React | `npm run typecheck`, `npm run lint` |
| Vue + uni-app 多端 | 各端目录分别跑 `npm run lint` |
| Spring Boot | `mvn compile`, `mvn checkstyle:check` |
| FastAPI / Python | `mypy .`, `ruff check .` |
| Go | `go vet ./...`, `go build ./...` |
| 纯文档项目 | `markdownlint **/*.md`(如果装了) |
