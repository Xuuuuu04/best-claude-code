---
name: bcc-doctor
description: Agent Legion 系统健康检查。扫描配置合法性、hook 可执行性、Agent/Skill/Rule 一致性、Memory 容量、artifact 堆积、日志大小、近期错误。建议每周跑一次。
disable-model-invocation: true
---

# 系统健康检查

运行一次全面扫描，找出 Agent Legion 系统中潜在的问题。整个过程由一个 bash 脚本完成，不派遣任何 subagent——诊断必须是确定性的。

## 执行

```bash
bash ~/.claude/bin/doctor.sh
```

## 报告解读

输出分为 10 个章节：

1. **Configuration** — settings.json 合法性、CLAUDE.md 行数
2. **Hooks** — 脚本可执行、bash 语法、是否有危险的 `set -e` 陷阱
3. **Agents** — 每个 Agent 定义的 frontmatter 合规性
4. **Skills** — 扁平结构检查（不允许嵌套）+ description 长度
5. **Rules** — 调用 `validate-rules.sh`（检查死 glob、重复名）
6. **Memory** — Auto Memory 和 Agent Memory 容量接近 200 行告警
7. **Artifacts** — 当前项目堆积的 artifact 数量和过期项
8. **Logs** — 所有日志文件大小，超阈值提示轮转
9. **Recent Hook Errors** — 近期 hook 失败事件摘要
10. **MCP** — 服务器数量 + PAT 占位符检查

## 何时跑

- **每周一次**定期体检
- 系统行为异常时（比如某个 Rule 不生效）
- 配置大改后（新增 Agent / Skill / Rule）
- 升级 Claude Code 版本后

## 退出码

- `0` — 全部健康 或 仅警告
- `1` — 有失败项（FAIL），需要立即修复

## 相关

- 详细 Rule 检查：`bash ~/.claude/bin/validate-rules.sh`
- 成本汇总：`bash ~/.claude/bin/cost-summary.sh`
- 日志轮转：`bash ~/.claude/bin/rotate-logs.sh`
