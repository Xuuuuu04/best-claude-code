# Hook 脚本编写规范

适用于所有 Claude Code hook 脚本（位于 `.claude/hooks/` 或 `~/.claude/hooks/`）。这些规范来自 Agent Legion 实战中踩过的坑，每条都有过真实事故。

---

## 1. 脚本头部：用 `set -uo pipefail`，**不**用 `-e`

```bash
#!/bin/bash
set -uo pipefail
```

**为什么不用 `-e`**：Claude Code hook 接收一条 stdin JSON 后可能调用 git / jq / 其他命令。在空 git 仓库、无 jq 环境等常见边界场景，这些命令会非零退出。`set -e` 会**立即杀死脚本**，stderr 还没写入任何内容，UI 显示 `"Failed with non-blocking status code: No stderr output"` 让问题极难排查。

保留 `-u`（未定义变量报错）和 `-o pipefail`（管道任一失败则整管道失败）提供语法层安全网，而**不**强制终止正常的非零返回。

## 2. 每个可能失败的命令后加容错

```bash
# 好：允许失败，用 fallback
BRANCH="$(git branch --show-current 2>/dev/null || echo '')"
LIST="$(ls *.md 2>/dev/null | head -10 || true)"

# 坏：失败就炸
BRANCH="$(git branch --show-current)"
```

通用模式：
- 读取但不关键 → `|| true`
- 读取有 fallback → `|| echo "default"`
- stdout 不可为空 → `|| echo ""`

## 3. 末尾显式 `exit 0`

```bash
# ...
exit 0
```

即使前面所有命令都成功，也显式 exit 0。这让"hook 正常结束"和"某条中间命令意外失败但被 `|| true` 吞掉导致脚本走完"两种情况的退出码都是 0，行为一致。

## 4. 写 JSONL 文件必须用 `jq -c`

```bash
# 好：一行一条记录
jq -c -n --arg ts "$TIMESTAMP" --arg evt "$EVENT" \
  '{timestamp: $ts, event: $evt}' >> "$LOG" 2>/dev/null

# 坏：jq 默认 pretty-print，一条记录占 10+ 行，破坏 JSONL 格式
jq -n --arg ts "$TIMESTAMP" ... >> "$LOG"
```

破坏的 JSONL 无法用 `tail | jq` 或 `grep | jq` 流式处理。`jq -c` 强制紧凑单行输出，是 JSONL 格式的硬性要求。

## 5. 不在 `if:` 字段使用环境变量通配符

**settings.json 示例（错误）**：

```json
"if": "Bash(rm -rf $HOME*)"
```

`$HOME` 会被展开为 `/Users/<username>`，然后 glob `/Users/<username>*` 会匹配**所有** `cd /Users/username/...` 类合法命令，把整个会话卡死。

**正确做法**：
- 写具体路径：`Bash(rm -rf /)` / `Bash(rm -rf /usr/*)`
- 或在 hook 脚本内部做判断（通过 exit 2 阻止），不靠 `if:` 做复杂过滤

## 6. 测试时不要用 repo 本身作 `CLAUDE_PROJECT_DIR`

```bash
# 坏：在 repo 里测会把 runtime 文件写入 repo
cd ~/.claude && CLAUDE_PROJECT_DIR=$PWD bash hooks/some-hook.sh

# 好：在临时目录测
TEST_DIR="$(mktemp -d)"
mkdir -p "$TEST_DIR/.claude"
CLAUDE_PROJECT_DIR="$TEST_DIR" bash hooks/some-hook.sh
rm -rf "$TEST_DIR"
```

Hook 产出的 log 文件（cost-log.txt、hook-errors.log 等）若生成在 repo 目录，会被 git 捕获并在不经意间提交。`.gitignore` 是第二道防线，第一道是**测试时不要用 repo 目录**。

## 7. 测试用真实事件样本，不要用脑补的 mock

Claude Code 真实 hook 事件字段集可能与文档例子不同（文档示例常是"理论完整版"而实际事件字段更精简）。正确流程：

1. 让 hook 写一条原始 JSON 到日志（例如 `cat > /tmp/last-event.json`）
2. 跑一次真实事件（派遣一个 subagent 等）
3. 用捕获到的 JSON 作 test fixture
4. 然后再写处理逻辑

不要基于文档"假定"字段存在——直接验证。

---

## 审查要点

quality-guardian 在审查 hook 脚本修改时，除了通用代码审查，还要对照本规范：

- [ ] 脚本头部是 `set -uo pipefail`，没有单独的 `set -e`
- [ ] 每个 git / jq / 外部命令都有容错
- [ ] 末尾有 `exit 0`
- [ ] JSONL 写入用 `jq -c`
- [ ] 若涉及 settings.json `if:` 字段，模式精确、不含环境变量通配
- [ ] 测试脚本不在 repo 目录内跑
- [ ] 测试 fixture 来源于真实捕获，非手造 JSON
