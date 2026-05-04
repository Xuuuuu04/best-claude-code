# 回滚与应急响应参考

按需读取。当 高级运维工程师 Agent 需要执行回滚或处理事故时加载。

---

## 回滚

### 代码回滚

```bash
# 查看发布的版本
git log --tags --simplify-by-decoration

# 切换到上一版本
git checkout v1.2.2
# 或 revert 具体 commit
git revert <commit>
```

部署时触发 CI 部署该版本。

### 数据库回滚

- Migration 必须有 down
- 破坏性 schema 变更分多步（见 backend-development Skill 的数据库部分）
- 数据回滚往往不可能：数据一旦写入新结构，回滚到旧结构会丢数据
- **预防 > 回滚**：重要 schema 变更先在 staging 验证

### 部分回滚

如果 feature flag 可用，关闭新功能而不回滚代码：
```
feature.newPayment.enabled = false
```

---

## 应急响应

### 发现问题

- 告警触发
- 或 用户反馈
- 或 监控异常

### 响应流程

1. **确认影响**：范围、严重性、受影响用户数
2. **止血**：回滚、关闭有问题的功能、隔离
3. **通知**：internal + 必要时 external
4. **诊断**：日志、指标、追踪
5. **修复**：临时修复或长期方案
6. **复盘**：不责怪的 postmortem（根因、时间线、改进项）

---

## 不可逆操作的铁律

**以下操作必须经用户明确确认**：

- 生产部署
- `git push --force` 到共享分支
- 删除分支 / tag
- 删除云资源（实例、卷、bucket、database）
- 修改生产 DB schema
- 修改 DNS
- 关闭 CI 检查
- 绕过 pre-commit/pre-push hooks

即使 Claude Code 权限为 auto mode，这些也**必须**用 AskUserQuestion 请求确认。
