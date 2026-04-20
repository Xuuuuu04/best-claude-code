> 源：shared/code-standards/api-design.md (migrated 2026-04-20)

# 后端开发师 — API 设计规范

## URL 设计

### 基本规则

- 使用小写字母和横线 `-` 分隔：`/user-profiles`
- 资源名使用复数名词：`/users`、`/orders`、`/projects`
- 避免动词（动作由 HTTP 方法表达）：`POST /users` 而非 `POST /create-user`
- 嵌套资源最多两层：`/users/{id}/orders`，再深则提升为顶层资源
- 版本号放在 URL 前缀：`/api/v1/users`

### HTTP 方法语义

| 方法 | 语义 | 幂等 | 示例 |
|------|------|------|------|
| GET | 获取资源 | 是 | `GET /users/1` |
| POST | 创建资源 | 否 | `POST /users` |
| PUT | 全量替换资源 | 是 | `PUT /users/1` |
| PATCH | 部分更新资源 | 是 | `PATCH /users/1` |
| DELETE | 删除资源 | 是 | `DELETE /users/1` |

---

## 统一响应格式

### 成功响应

```json
{
  "code": 200,
  "message": "success",
  "data": { }
}
```

### 列表响应（带分页）

```json
{
  "code": 200,
  "message": "success",
  "data": {
    "items": [ ],
    "total": 100,
    "page": 1,
    "page_size": 20,
    "total_pages": 5
  }
}
```

### 错误响应

```json
{
  "code": 400,
  "message": "Validation failed",
  "errors": [
    {
      "field": "email",
      "message": "Invalid email format"
    }
  ]
}
```

---

## 状态码使用

| 状态码 | 含义 | 使用场景 |
|--------|------|---------|
| 200 | OK | 查询/更新成功 |
| 201 | Created | 创建资源成功 |
| 204 | No Content | 删除成功 |
| 400 | Bad Request | 请求参数校验失败 |
| 401 | Unauthorized | 未认证（未登录或 token 过期） |
| 403 | Forbidden | 已认证但无权限 |
| 404 | Not Found | 资源不存在 |
| 409 | Conflict | 资源冲突（如唯一键重复） |
| 422 | Unprocessable Entity | 请求格式正确但语义错误 |
| 500 | Internal Server Error | 服务器内部错误 |

---

## 分页规范

### 请求参数

- `page`: 页码，从 1 开始，默认 1
- `page_size`: 每页条数，默认 20，上限 100
- `sort`: 排序字段，如 `created_at`
- `order`: 排序方向，`asc` 或 `desc`，默认 `desc`

```
GET /api/v1/users?page=2&page_size=10&sort=created_at&order=desc
```

---

## 过滤与搜索

- 简单过滤使用查询参数：`GET /users?role=admin&status=active`
- 关键词搜索使用 `q` 参数：`GET /users?q=john`
- 日期范围使用 `_from` 和 `_to` 后缀：`GET /orders?created_at_from=2025-01-01&created_at_to=2025-12-31`

---

## 认证与授权

- 使用 Bearer Token（JWT）放在 `Authorization` 头中
- Token 格式：`Authorization: Bearer <token>`
- 敏感操作需要额外验证（如二次密码确认）
- Token 过期时间建议：access_token 2 小时，refresh_token 7 天

---

## 版本控制

- 当 API 有不兼容变更时才升级版本号
- 旧版本至少保持兼容 3 个月
- 使用 URL 前缀方式：`/api/v1/`、`/api/v2/`
- 同一版本内的变更通过新增字段实现向后兼容
