---
paths:
  - "**/*.sh"
  - "**/*.bash"
  - "**/*.zsh"
---

# Shell 脚本规范

## 开头三件套

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- `set -e`：错误立即退出
- `set -u`：未定义变量报错
- `set -o pipefail`：管道任一失败则失败
- `IFS` 明确，避免默认空格分割带来的意外

## 引号

- **始终引用变量**：`"$var"`，除非刻意需要分词
- 数组引用：`"${arr[@]}"`
- 命令替换：`"$(cmd)"` 而非反引号

## 变量

- 命名：`UPPER_CASE` 环境变量；`lower_case` 局部变量
- 局部变量：`local var=...`（仅函数内）
- readonly：`readonly CONST=value`
- 默认值：`${var:-default}`
- 检查空：`[[ -z "$var" ]]` / `[[ -n "$var" ]]`

## 条件

- 优先 `[[ ]]` 而非 `[ ]`（bash 扩展，更安全）
- 字符串比较：`[[ "$a" == "$b" ]]`
- 数字比较：`(( a > b ))`
- 文件检查：`[[ -f /path ]]`（存在）、`[[ -d /path ]]`（目录）、`[[ -x /path ]]`（可执行）

## 命令替换与管道

- 管道：一行不太长，否则反斜线续行
- 临时文件：`mktemp` 而非固定路径
- 清理：`trap` 注册退出时清理

```bash
TMP=$(mktemp)
trap 'rm -f "$TMP"' EXIT
```

## 函数

- 命名：`snake_case`
- 参数：`$1` / `$2` / `$@` / `$#`
- 返回值：`return N`（0-255，表示退出码）；复杂返回用 echo + command substitution
- 局部变量：`local`

## 错误处理

- 检查 `$?` 或依赖 `set -e`
- 重要步骤失败给明确错误到 stderr：`echo "Error: ..." >&2`
- 退出码有意义：0 成功，非 0 失败（区分不同失败类型）

## 外部命令

- 检查命令是否存在：`command -v foo >/dev/null 2>&1`
- 优先标准工具（POSIX），跨平台考虑（macOS 的 `sed` vs GNU `sed`）
- macOS `sed -i` 需要 `''` 空串参数

## 安全

- **禁止** `eval "$user_input"`
- 禁止 `curl ... | bash` 不经验证
- 路径处理：用 `"$var"` 防止空格 / 特殊字符
- `rm -rf` 前检查变量：
  ```bash
  [[ -n "${DIR:-}" ]] || { echo "DIR not set"; exit 1; }
  rm -rf "$DIR"
  ```

## 并发

- `&` 后台 + `wait` 收集
- `xargs -P N` 并行
- 竞态小心：共享文件用 `flock`

## 工具

- **ShellCheck** 必过：`shellcheck script.sh`
- `shfmt` 格式化
- 复杂逻辑考虑换语言（Python、Go）

## 日志

- stderr 输出错误：`>&2`
- stdout 输出数据（可被管道消费）
- 时间戳：`date +'%Y-%m-%d %H:%M:%S'`

## 避免

- 长脚本（>200 行考虑换语言）
- 复杂的字符串操作（用 awk / python）
- `bash` 的高级特性在不保证 bash 的环境（如 Alpine Linux 默认 ash）
