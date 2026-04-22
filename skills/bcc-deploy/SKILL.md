---
name: bcc-deploy
description: 部署流水线。当用户要求部署、发布或上线时使用。
disable-model-invocation: true
---

# 部署流水线

`$ARGUMENTS` 可包含目标环境（`staging` / `production` / 指定环境名）和版本号。

---

## Phase 1: 部署前检查

### 1.1 调度器自检

在派任何 Agent 前，先自检：

- `git status`：工作树必须干净（无未提交的改动）
- `git log --oneline -5`：确认最近的提交
- 是否存在待完成的 artifact（`requirements-*.md` 没有对应的 `review-functional-*.md`）
- CI 状态（如可查询）

如有未完成的工作，**停止**并向用户汇报：
```
检测到未完成的工作：
- {未合入的 PR / 未审查的 artifact}

建议先完成这些，再发起部署。是否继续？
```

使用 AskUserQuestion 等待用户决策。

### 1.2 派遣 quality-guardian 做最终功能测试

```
审查类型：functional-test
审查对象：当前代码库完整测试套件

请运行完整测试套件、必要的集成测试、安全扫描。
将测试报告写入 .claude/artifacts/review-predeploy-{timestamp}.md。
```

如测试失败，**停止部署流水线**，向用户汇报。

---

## Phase 2: 部署执行

### 2.1 派遣 devops

```
任务：执行部署。
环境：{staging / production}
版本：{v_target}
预检报告：.claude/artifacts/review-predeploy-{timestamp}.md

步骤：
1. 读取项目的部署文档（CLAUDE.md 或 docs/deploy.md）
2. 记录当前生产版本（用于回滚）
3. 执行构建
4. 执行部署命令
5. 运行健康检查
6. 如健康检查失败，立即回滚
7. 产出 .claude/artifacts/deploy-report-{timestamp}.md

重要：任何不可逆或影响生产的操作前，使用 AskUserQuestion 请求用户确认。
```

### 2.2 处理部署结果

- **成功**：进入 Phase 3
- **失败回滚**：devops 自行执行回滚，向用户汇报失败原因
- **部分成功**（部署成功但健康检查未达标）：请用户决策继续观察还是回滚

---

## Phase 3: 部署后验证

### 3.1 人工验证节点

向用户展示部署报告，使用 AskUserQuestion 请求人工验证：

```
部署已完成。请人工验证以下关键路径：
- {路径 1}
- {路径 2}

验证无异常后回复"确认"，我将更新发布记录。
如有异常，回复问题描述，我将启动回滚。
```

### 3.2 监控观察期

建议用户至少观察 15 分钟监控指标，未出现异常再最终确认。

---

## Phase 4: 发布记录

### 4.1 打 tag

派遣 devops：

```
任务：打版本 tag 并推送。
版本：v{semver}
变更说明：{从最近提交归纳，或引用 CHANGELOG}
```

### 4.2 更新 CHANGELOG（如项目维护）

### 4.3 通知（如配置了通知 MCP）

发送部署完成通知到配置的 Slack/飞书等。

---

## Phase 5: 向用户汇报

```markdown
## 部署完成

**版本**: v{semver}（上一版本 v{prev_semver}）
**环境**: {staging / production}
**部署时间**: {timestamp}
**健康检查**: ✓ 全部通过
**人工验证**: ✓ 用户确认

### 本次发布包含
{从 git log 提取或引用 CHANGELOG}

### 回滚命令（备用）
```bash
{具体回滚命令}
```

### 监控建议
- 观察错误率指标 {链接}
- 观察核心业务指标 {链接}
```

---

## 异常和紧急回滚

如用户在观察期内报告异常：

1. 立即派 devops 执行回滚
2. 捕获异常日志和监控数据到 `.claude/artifacts/incident-{timestamp}.md`
3. 向用户汇报回滚完成
4. 建议运行 `/bcc-fix-bug` 处理发现的问题

---

## 权限边界

部署是**高风险操作**。即使 Claude Code 权限模式为 auto，部署流水线的以下步骤**必须**使用 AskUserQuestion 请求明确确认：

- Phase 2.1 开始执行部署命令前
- Phase 3.1 人工验证节点
- Phase 4.1 打 tag 前（对 production）
- 任何紧急回滚前（即使看起来必要）
