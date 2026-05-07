# MCP Security Checklist

MCP server 是 Agent 与外部世界的桥梁，是最常见的越权和数据泄露入口。本清单覆盖 OWASP-LLM 与 MCP 特有风险。

## 一、凭据与权限

### 1.1 最小权限凭据

每个 MCP server 应使用**专用、可撤销**的凭据，权限只覆盖必要工具：

```
✅ 正确：GitHub MCP 用 PAT，scope 仅 `repo:read`
❌ 错误：GitHub MCP 用账户主 token，scope 含 `admin:org`
```

凭据来源优先级：
1. 短期 OAuth token（有 expiration）
2. 范围受限的 PAT / API key
3. **禁止**：root token / admin 凭据 / 共享密码

### 1.2 凭据存储

| 来源 | 评级 |
|:--|:--|
| `env`（process env） | ✅ |
| Keychain / credential manager | ✅ |
| `.env` 文件（gitignored） | ✅ 但小心拷贝 |
| MCP config JSON 明文 | ⚠️ 仅本地开发 |
| 代码硬编码 | ❌ 立即拒绝 |
| 提交到 git | ❌ 立即轮换 |

### 1.3 凭据轮换

- 文档中说明轮换周期（推荐 90 天）
- 提供 `revoke_credential` 工具或文档
- 检测到泄露时立即假定已被滥用

## 二、Secret 泄露防护

### 2.1 不进输出

工具返回值**绝不**包含完整凭据：

```python
# ❌ 错误
return {"status": "ok", "token_used": api_key}

# ✅ 正确
return {"status": "ok", "token_hint": api_key[:4] + "***"}
```

### 2.2 不进日志

- 日志写入前用正则脱敏：`token=xxx`、`Bearer xxx`、`password=xxx`
- 异常 stack trace 中可能包含完整 URL，URL 中可能含 token
- 第三方 SDK 的 debug log 默认会打印 headers——必须显式关闭

### 2.3 不进错误消息

```python
# ❌ 错误
raise Exception(f"GitHub API failed: {response.text}")  # text 可能含 PAT
# ✅ 正确
raise Exception(f"GitHub API failed: status={response.status_code}")
```

## 三、危险操作控制

### 3.1 写操作必须可审计

所有 mutation 工具（create/update/delete/send）应：

- 记录调用方 + 时间 + 参数（脱敏后）
- 返回操作 ID 便于回溯
- 提供 dry-run 模式

### 3.2 不可逆操作支持确认

| 操作 | 处理 |
|:--|:--|
| 删除资源 | 必须 dry-run + 二次确认参数 |
| 发送外部消息（邮件/Slack/SMS） | 必须 dry-run + recipient 校验 |
| 生产数据库写 | 必须支持 transaction + rollback |
| 强推 git / 删除分支 | 拒绝实现或要求 explicit 标志 |

### 3.3 工具描述不诱导越权

```
❌ 错误描述："Delete any file the user mentions"
   （诱导 agent 越权删除用户没明确同意的文件）
✅ 正确描述："Delete the specified file path. Requires explicit absolute path. Will reject paths outside project root."
```

工具 description 是 agent 决策依据。诱导性 / 模糊的 description 是漏洞源头。

## 四、输入验证

### 4.1 路径遍历

文件类工具必须拒绝：
- `../` 路径分量
- 绝对路径越过 sandbox（用 `os.path.realpath()` 检查）
- Symlink 指向 sandbox 外
- Windows UNC 路径 `\\server\share`

### 4.2 命令注入

`run_command` 类工具必须：
- **绝不**用 `shell=True` + 字符串拼接
- 用 `subprocess.run([cmd, arg1, arg2])` 数组形式
- 维护命令白名单
- 拒绝 `;` `&&` `|` `$()` 等元字符（除非显式支持）

### 4.3 SQL 注入

数据库工具必须用参数化查询：
```python
# ❌ 错误
cursor.execute(f"SELECT * FROM users WHERE id = {user_id}")
# ✅ 正确
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))
```

## 五、可观测性

### 5.1 工具调用日志

每次工具调用记录（脱敏后）：
- 工具名
- 入参
- 调用方（agent / user）
- 时间戳
- 返回状态（success / error）
- 耗时

### 5.2 异常告警

- 短时间内大量失败 → 告警
- 高权限工具被调用 → 告警
- 同一资源被多次修改 → 告警

## 六、依赖与供应链

- MCP server 依赖必须固定版本（lockfile）
- 定期 `npm audit` / `pip-audit` / `cargo audit`
- 不引入未维护超过 1 年的包
- 启动时验证依赖完整性（如有签名）

## 验证清单（每个 MCP server 上线前）

- [ ] 凭据使用专用、范围受限、可撤销
- [ ] 所有输出与日志已脱敏
- [ ] 危险操作支持 dry-run 与确认
- [ ] 工具 description 不诱导越权
- [ ] 路径 / 命令 / SQL 输入有验证
- [ ] 调用日志可审计
- [ ] 依赖无已知高危 CVE
- [ ] 文档说明凭据轮换流程

## 失败模式

- ❌ 工具描述写"do anything user wants"——agent 会真的尝试
- ❌ 错误日志含完整 token URL
- ❌ 工具同时支持读写但没区分 scope
- ❌ MCP server 跑在 root 用户下
- ❌ 写操作无回滚 / 无 audit log
