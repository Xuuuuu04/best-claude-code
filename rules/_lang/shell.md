---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
  - "!**/hooks/*.sh"
  - "!**/hooks/*.bash"
---

<rule>
  <!-- ====== 开头三件套 ====== -->
  <pattern>

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

  </pattern>
  <convention>`set -e`：错误立即退出</convention>
  <convention>`set -u`：未定义变量报错</convention>
  <convention>`set -o pipefail`：管道任一失败则失败</convention>
  <convention>`IFS` 明确，避免默认空格分割带来的意外</convention>

  <constraint severity="warning">例外：Hook 脚本不使用 `set -e`。Claude Code hook 脚本使用 `set -uo pipefail`（不加 `-e`）。在空 git 仓库、无 jq 环境等边界场景中，`git branch --show-current` 等诊断命令的非零退出会因 `set -e` 立即杀死脚本，使问题极难排查。详见 `rules/_global/hook-scripts-pattern.md`。</constraint>

  <!-- ====== 引号 ====== -->
  <constraint severity="blocker">始终引用变量：`"$var"`，除非刻意需要分词</constraint>
  <convention>数组引用：`"${arr[@]}"`</convention>
  <convention>命令替换：`"$(cmd)"` 而非反引号</convention>

  <!-- ====== 变量 ====== -->
  <convention>命名：`UPPER_CASE` 环境变量；`lower_case` 局部变量</convention>
  <convention>局部变量：`local var=...`（仅函数内）</convention>
  <convention>readonly：`readonly CONST=value`</convention>
  <convention>默认值：`${var:-default}`</convention>
  <convention>检查空：`[[ -z "$var" ]]` / `[[ -n "$var" ]]`</convention>

  <!-- ====== 条件 ====== -->
  <convention>优先 `[[ ]]` 而非 `[ ]`（bash 扩展，更安全）</convention>
  <convention>字符串比较：`[[ "$a" == "$b" ]]`</convention>
  <convention>数字比较：`(( a > b ))`</convention>
  <convention>文件检查：`[[ -f /path ]]`（存在）、`[[ -d /path ]]`（目录）、`[[ -x /path ]]`（可执行）</convention>

  <!-- ====== 命令替换与管道 ====== -->
  <convention>管道：一行不太长，否则反斜线续行</convention>
  <convention>临时文件：`mktemp` 而非固定路径</convention>
  <convention>清理：`trap` 注册退出时清理</convention>
  <pattern>

```bash
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
```

  </pattern>

  <!-- ====== 函数 ====== -->
  <convention>命名：`snake_case`</convention>
  <convention>参数：`$1` / `$2` / `$@` / `$#`</convention>
  <convention>返回值：`return N`（0-255，表示退出码）；复杂返回用 echo + command substitution</convention>
  <convention>局部变量：`local`</convention>

  <!-- ====== 错误处理 ====== -->
  <convention>检查 `$?` 或依赖 `set -e`</convention>
  <convention>重要步骤失败给明确错误到 stderr：`echo "Error: ..." >&2`</convention>
  <convention>退出码有意义：0 成功，非 0 失败（区分不同失败类型）</convention>

  <!-- ====== 外部命令 ====== -->
  <convention>检查命令是否存在：`command -v foo >/dev/null 2>&1`</convention>
  <convention>优先标准工具（POSIX），跨平台考虑（macOS 的 `sed` vs GNU `sed`）</convention>
  <convention>macOS `sed -i` 需要 `''` 空串参数</convention>

  <!-- ====== 安全 ====== -->
  <constraint severity="blocker">禁止 `eval "$user_input"`</constraint>
  <constraint severity="blocker">禁止 `curl ... | bash` 不经验证</constraint>
  <constraint severity="blocker">路径处理：用 `"$var"` 防止空格 / 特殊字符</constraint>
  <constraint severity="blocker">`rm -rf` 前检查变量：</constraint>
  <pattern>

```bash
[[ -n "${DIR:-}" ]] || { echo "DIR not set"; exit 1; }
rm -rf "$DIR"
```

  </pattern>

  <!-- ====== 并发 ====== -->
  <convention>`&` 后台 + `wait` 收集</convention>
  <convention>`xargs -P N` 并行</convention>
  <convention>竞态小心：共享文件用 `flock`</convention>

  <!-- ====== 工具 ====== -->
  <constraint severity="blocker">ShellCheck 必过：`shellcheck script.sh`</constraint>
  <convention>`shfmt` 格式化</convention>
  <convention>复杂逻辑考虑换语言（Python、Go）</convention>

  <!-- ====== 日志 ====== -->
  <convention>stderr 输出错误：`>&2`</convention>
  <convention>stdout 输出数据（可被管道消费）</convention>
  <convention>时间戳：`date +'%Y-%m-%d %H:%M:%S'`</convention>

  <!-- ====== 避免 ====== -->
  <constraint severity="warning">长脚本（大于 200 行考虑换语言）</constraint>
  <constraint severity="warning">复杂的字符串操作（用 awk / python）</constraint>
  <constraint severity="warning">`bash` 的高级特性在不保证 bash 的环境（如 Alpine Linux 默认 ash）</constraint>

</rule>
