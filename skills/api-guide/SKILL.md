---
name: api-guide
description: API 设计参考指南。在设计新 API 端点、修改已有 API 或审查 API 契约时提供查询的参考资料。
disable-model-invocation: true
---

# API 设计参考指南

这是一份可供 Claude 在需要时查询的参考资料。不是规范（那是 Rules 的职责），而是决策辅助。

---

## URL 命名

### 资源命名

- **名词复数**：`/users` 而非 `/user` 或 `/getUsers`
- **层次清晰**：`/users/:id/orders` 表示"某用户的订单"
- **连字符**：多单词用 `-`（`/user-settings`）而非下划线或驼峰
- **小写**：路径全小写

### 特殊操作

对于非 CRUD 的操作，可使用子路径：
- `POST /users/:id/actions/reset-password`
- `POST /orders/:id/cancel`

---

## HTTP 方法

| 方法 | 语义 | 幂等 | 安全 |
|:--|:--|:--|:--|
| GET | 读取 | ✓ | ✓ |
| POST | 创建或非幂等操作 | ✗ | ✗ |
| PUT | 全量替换 | ✓ | ✗ |
| PATCH | 部分更新 | ✗ | ✗ |
| DELETE | 删除 | ✓ | ✗ |

**幂等**：多次调用效果与单次相同
**安全**：不改变服务端状态

---

## 状态码

### 2xx 成功
- **200 OK**：成功，有响应体
- **201 Created**：创建成功，`Location` header 指向新资源
- **202 Accepted**：接受但异步处理中
- **204 No Content**：成功，无响应体（常用于 DELETE）

### 3xx 重定向
- **301 Moved Permanently**：永久重定向
- **304 Not Modified**：缓存验证通过

### 4xx 客户端错误
- **400 Bad Request**：请求格式错误（JSON 解析失败等）
- **401 Unauthorized**：未认证
- **403 Forbidden**：已认证但无权限
- **404 Not Found**：资源不存在
- **409 Conflict**：资源状态冲突（版本冲突）
- **422 Unprocessable Entity**：请求格式正确但业务校验失败
- **429 Too Many Requests**：限流

### 5xx 服务端错误
- **500 Internal Server Error**：通用服务端错误
- **502 Bad Gateway**：上游服务错误
- **503 Service Unavailable**：临时不可用
- **504 Gateway Timeout**：上游超时

**重要**：客户端错误不要返回 500，使其可诊断。

---

## 响应格式

### 成功响应

**单个资源**：
```json
{
  "id": "usr_123",
  "name": "Alice",
  "email": "alice@example.com"
}
```

**列表资源**（带分页）：
```json
{
  "data": [...],
  "pagination": {
    "cursor": "eyJpZCI6MTB9",
    "hasMore": true,
    "total": 150
  }
}
```

### 错误响应（统一格式）

```json
{
  "error": {
    "code": "USER_NOT_FOUND",
    "message": "User with id usr_123 does not exist",
    "details": {
      "userId": "usr_123"
    }
  }
}
```

**字段语义**：
- `code`：稳定的错误码（客户端可依赖）
- `message`：人类可读（可国际化，或返回 i18n key）
- `details`：可选的结构化信息

---

## 分页

### 游标分页（推荐）
```
GET /users?cursor=eyJpZCI6MTB9&limit=20
```

**优势**：
- 深翻页高效
- 插入/删除不影响结果一致性
- 适合无限滚动 UI

### Offset 分页（仅小数据集）
```
GET /users?page=3&pageSize=20
```

**劣势**：
- 深翻页慢
- 数据变化导致结果不一致

---

## 过滤、排序、字段选择

### 过滤
```
GET /users?status=active&role=admin
```
复杂过滤用 query 或 JSON：
```
GET /users?filter[status]=active&filter[createdAt][gt]=2026-01-01
```

### 排序
```
GET /users?sort=name              # 升序
GET /users?sort=-createdAt        # 降序（- 前缀）
GET /users?sort=name,-createdAt   # 多字段
```

### 字段选择
```
GET /users/:id?fields=id,name,email
```
降低响应体积，但不是 GraphQL 的替代。

---

## 版本化

### 选项对比

| 方式 | 示例 | 优 | 劣 |
|:--|:--|:--|:--|
| URL | `/v1/users` | 直观 | URL 变脏 |
| Header | `Accept: application/vnd.api+json;version=1` | 干净 | 不便调试 |
| Query | `/users?v=1` | 简单 | 被缓存干扰 |

推荐：**URL 前缀**，因为可读性和可调试性最强。

### 破坏性变更原则

- **不要**在旧版本上做破坏性变更
- **新版本**并存，给客户端迁移时间
- 旧版本 deprecation 公告 + 日志告警
- 最终删除旧版本

---

## 认证与授权

### Bearer Token
```
Authorization: Bearer <token>
```

### API Key
```
X-API-Key: <key>
```
或在 query（不推荐，会进日志）

### Session Cookie
```
Cookie: session_id=...
```
配合 CSRF token

---

## 限流

### 响应头

成功响应：
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 42
X-RateLimit-Reset: 1682234567
```

被限流时（429）：
```
Retry-After: 30
```

### 限流粒度

- 按 IP（匿名用户）
- 按用户（已登录）
- 按 API Key（服务端调用）
- 按端点（敏感端点更严）

---

## HATEOAS / REST 成熟度

- Level 0：HTTP 仅作传输（SOAP 风格）
- Level 1：多资源
- Level 2：正确使用 HTTP 方法和状态码（**大多数 REST API 在此**）
- Level 3：HATEOAS，响应中包含相关资源链接

L2 是实用的目标；L3 在特定场景（浏览器式 API）有价值。

---

## GraphQL 要点

### 何时考虑 GraphQL

✓ 前端需要灵活的字段组合
✓ 多端（Web / iOS / Android）需求差异大
✓ 避免多次往返（复杂聚合）

✗ 简单 CRUD（REST 更合适）
✗ 公开 API（学习曲线）
✗ 缓存和 CDN 友好度要求高（REST 更容易）

### 要点

- N+1：使用 DataLoader
- 权限：在 resolver 层检查
- 深度限制：防止恶意嵌套查询
- 查询复杂度评分：防止滥用

---

## 实用清单

设计新 API 时问自己：

- [ ] URL 符合命名规范
- [ ] HTTP 方法正确
- [ ] 状态码语义清晰
- [ ] 响应格式与项目其他 API 一致
- [ ] 错误码定义且文档化
- [ ] 认证和授权机制明确
- [ ] 输入验证充分
- [ ] 限流策略考虑
- [ ] 分页策略考虑
- [ ] 向后兼容性考虑
- [ ] 日志和监控点设计
- [ ] 文档（OpenAPI / GraphQL schema）更新
