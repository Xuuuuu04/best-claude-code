# Failure Taxonomy

Agent / Skill 失败时**必须**按以下分类报告。这是 quality-verdict 和 pm 路由判断的输入信号。

## 五种失败类型

### 1. BLOCKED — 缺前置条件，无法开始

| 触发场景 | 处理 |
|:--|:--|
| 缺输入 artifact（如 implementer 没拿到 scope-lock） | 上报上游 Agent 名 + 缺失文件路径 |
| 权限不足（无法读/写指定路径） | 上报缺失的权限或工具 |
| 环境不可达（DB / API / 服务未启动） | 上报具体不可达项 + 复现命令 |
| 等待用户拍板（不可逆动作） | 上报具体待决问题 + 选项 |

**报告格式**：
```
状态: BLOCKED
原因: {一句话说明}
缺失项: {具体文件 / 权限 / 环境}
解决方所需动作: {上游 Agent 重做 / 用户授权 / 环境配置}
```

### 2. FAILED — 已执行但结果不达标

| 触发场景 | 处理 |
|:--|:--|
| 实现完成但测试不过 | 上报失败用例 + 期望 vs 实际 |
| 审查不通过（review 给出 Critical） | 上报 Critical 项 + 退回上游 |
| 安全审计发现可被利用漏洞 | 上报漏洞类型 + 影响 + Critical 阻断 |
| 部署失败 | 上报 stage + 错误日志摘要 |

**报告格式**：
```
状态: FAILED
失败点: {具体步骤}
证据: {命令输出 / 测试报告路径 / 错误信息}
修复路径: {重做哪个 Agent / 改哪个文件}
```

### 3. NEEDS_USER — 边界 / 风险 / 不可逆动作需用户确认

| 触发场景 | 处理 |
|:--|:--|
| 需求在两个合理解读间摆动 | AskUserQuestion 二选一 |
| 即将做不可逆动作（删除、生产部署、强推） | 显式确认 |
| 接口变更可能影响其他模块 | 列出影响面让用户决策 |
| 选型权衡（性能 vs 简洁 vs 成本） | 列优劣给用户拍板 |

**报告格式**：
```
状态: NEEDS_USER
问题: {具体决策点}
选项:
  A) {选项 A，权衡}
  B) {选项 B，权衡}
建议: {Agent 推荐项 + 理由}
```

### 4. OUT_OF_SCOPE — 请求不属于该 Agent 职责

| 触发场景 | 处理 |
|:--|:--|
| product-analyst 被要求写代码 | 拒绝，建议改派 implementer |
| code-reviewer 被要求实现修复 | 拒绝，建议派 implementer 后再 review |
| visual-tester 被要求做安全审查 | 拒绝，建议派 security-auditor |

**报告格式**：
```
状态: OUT_OF_SCOPE
请求内容: {一句话}
本 Agent 边界: {简述职责}
建议派遣: {正确 Agent 名}
```

### 5. PARTIAL — 部分完成，剩余可以独立分发

适用于大任务被发现可拆分时。

| 触发场景 | 处理 |
|:--|:--|
| 多文件 scope-lock，部分完成后发现剩余依赖于未来决策 | 完成可做的，拆出 sub-task |
| 测试 50% 通过，50% 因环境问题阻塞 | 报告通过部分 + BLOCKED 部分 |

**报告格式**：
```
状态: PARTIAL
已完成: {列表 + artifact 路径}
未完成: {列表 + 类型（BLOCKED / NEEDS_USER / FAILED）}
建议: {后续派遣计划}
```

## 严禁的反模式

- ❌ 静默失败（什么都不报告就退出）
- ❌ 用 PASS 掩盖失败（"基本可用"不算 PASS）
- ❌ 把 NEEDS_USER 误报为 FAILED（造成无效返工）
- ❌ 把 OUT_OF_SCOPE 误报为 BLOCKED（应该拒绝接单而不是等输入）
- ❌ FAILED 不带证据（"测试失败"无具体用例）

## pm / test-lead 的下一跳判断

- BLOCKED → 找上游 Agent 或用户
- FAILED → 退回产出 Agent 重做（同 task-id 续跑）
- NEEDS_USER → 暂停流水线，等用户回复
- OUT_OF_SCOPE → 重新选 Agent 派遣
- PARTIAL → 已完成部分进入下一阶段；剩余按其类型路由
