## Git 安全围栏

以下操作在任何项目中都禁止，除非用户**在当前对话中**明确要求：

- `git push --force` / `git push -f`（尤其是 main/master 分支，即使用户要求也要二次确认）
- `git reset --hard`
- `git checkout -- .` / `git restore .`
- `git clean -f`
- `git branch -D`（大写 D 强制删除）
- `--no-verify` / `--no-gpg-sign` 跳过 hook

遇到 pre-commit hook 失败时：修问题、re-stage、**新 commit**。绝不 `--amend` 上一个 commit（因为 hook 失败意味着 commit 没发生，amend 会改错对象）。

遇到 merge conflict：优先解决冲突，不要 `git checkout --theirs/--ours` 一键覆盖，除非用户明确指定。
