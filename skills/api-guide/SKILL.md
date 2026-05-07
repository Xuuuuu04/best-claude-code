---
name: api-guide
description: API 设计参考指南。在设计新 API 端点、修改已有 API 或审查 API 契约时提供查询的参考资料。
when_to_use: 仅当 资深系统架构师 / 高级后端工程师 / 高级代码审查师 在设计或审查 RESTful / GraphQL / RPC API 契约（路径、方法、状态码、错误格式、版本化）时加载。前端调用方、内部函数签名不应触发。
---

<skill name="api-guide">

<identity>
这是一份可供 Claude 在需要时查询的参考资料。不是规范（那是 Rules 的职责），而是决策辅助。
</identity>

<knowledge domain="url-naming">

<convention name="resource-naming">
  <item>**名词复数**：`/users` 而非 `/user` 或 `/getUsers`</item>
  <item>**层次清晰**：`/users/:id/orders` 表示"某用户的订单"</item>
  <item>**连字符**：多单词用 `-`（`/user-settings`）而非下划线或驼峰</item>
  <item>**小写**：路径全小写</item>
</convention>

<convention name="special-actions">
对于非 CRUD 的操作，可使用子路径：
<example>`POST /users/:id/actions/reset-password`</example>
<example>`POST /orders/:id/cancel`</example>
</convention>

</knowledge>

<knowledge domain="http-methods">
<reference>
| 方法 | 语义 | 幂等 | 安全 |
|:--|:--|:--|:--|
| GET | 读取 | ✓ | ✓ |
| POST | 创建或非幂等操作 | ✗ | ✗ |
| PUT | 全量替换 | ✓ | ✗ |
| PATCH | 部分更新 | ✗ | ✗ |
| DELETE | 删除 | ✓ | ✗ |
</reference>
<convention name="idempotent">多次调用效果与单次相同</convention>
<convention name="safe">不改变服务端状态</convention>
</knowledge>

<knowledge domain="status-codes">

<knowledge domain="2xx">
<item code="200">成功，有响应体</item>
<item code="201">创建成功，`Location` header 指向新资源</item>
<item code="202">接受但异步处理中</item>
<item code="204">成功，无响应体（常用于 DELETE）</item>
</knowledge>

<knowledge domain="3xx">
<item code="301">永久重定向</item>
<item code="304">缓存验证通过</item>
</knowledge>

<knowledge domain="4xx">
<item code="400">请求格式错误（JSON 解析失败等）</item>
<item code="401">未认证</item>
<item code="403">已认证但无权限</item>
<item code="404">资源不存在</item>
<item code="409">资源状态冲突（版本冲突）</item>
<item code="422">请求格式正确但业务校验失败</item>
<item code="429">限流</item>
</knowledge>

<knowledge domain="5xx">
<item code="500">通用服务端错误</item>
<item code="502">上游服务错误</item>
<item code="503">临时不可用</item>
<item code="504">上游超时</item>
</knowledge>

<rule>客户端错误不要返回 500，使其可诊断。</rule>

</knowledge>

<knowledge domain="response-format">

<knowledge domain="success">
<convention name="single-resource">
```json
{
  "id": "usr_123",
  "name": "Alice",
  "email": "alice@example.com"
}
```
</convention>
<convention name="list-resource">
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
</convention>
</knowledge>

<knowledge domain="error">
<convention name="unified-format">
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
</convention>
<convention name="field-semantics">
  <item>`code`：稳定的错误码（客户端可依赖）</item>
  <item>`message`：人类可读（可国际化，或返回 i18n key）</item>
  <item>`details`：可选的结构化信息</item>
</convention>
</knowledge>

</knowledge>

<knowledge domain="pagination">

<knowledge domain="cursor-pagination" recommended="true">
<example>`GET /users?cursor=eyJpZCI6MTB9&limit=20`</example>
<convention>优势：深翻页高效；插入/删除不影响结果一致性；适合无限滚动 UI</convention>
</knowledge>

<knowledge domain="offset-pagination">
<example>`GET /users?page=3&pageSize=20`</example>
<trap>劣势：深翻页慢；数据变化导致结果不一致</trap>
<convention>仅小数据集使用</convention>
</knowledge>

</knowledge>

<knowledge domain="filter-sort-fields">

<knowledge domain="filtering">
<example>`GET /users?status=active&role=admin`</example>
<example>复杂过滤：`GET /users?filter[status]=active&filter[createdAt][gt]=2026-01-01`</example>
</knowledge>

<knowledge domain="sorting">
<example>`GET /users?sort=name`              # 升序</example>
<example>`GET /users?sort=-createdAt`        # 降序（- 前缀）</example>
<example>`GET /users?sort=name,-createdAt`   # 多字段</example>
</knowledge>

<knowledge domain="field-selection">
<example>`GET /users/:id?fields=id,name,email`</example>
<convention>降低响应体积，但不是 GraphQL 的替代。</convention>
</knowledge>

</knowledge>

<knowledge domain="versioning">

<reference>
| 方式 | 示例 | 优 | 劣 |
|:--|:--|:--|:--|
| URL | `/v1/users` | 直观 | URL 变脏 |
| Header | `Accept: application/vnd.api+json;version=1` | 干净 | 不便调试 |
| Query | `/users?v=1` | 简单 | 被缓存干扰 |
</reference>

<convention recommended="true">推荐：**URL 前缀**，因为可读性和可调试性最强。</convention>

<knowledge domain="breaking-change-principles">
<checklist>
  <item>**不要**在旧版本上做破坏性变更</item>
  <item>**新版本**并存，给客户端迁移时间</item>
  <item>旧版本 deprecation 公告 + 日志告警</item>
  <item>最终删除旧版本</item>
</checklist>
</knowledge>

</knowledge>

<knowledge domain="authentication">

<knowledge domain="bearer-token">
<example>`Authorization: Bearer <token>`</example>
</knowledge>

<knowledge domain="api-key">
<example>`X-API-Key: <key>`</example>
<convention>或在 query（不推荐，会进日志）</convention>
</knowledge>

<knowledge domain="session-cookie">
<example>`Cookie: session_id=...`</example>
<convention>配合 CSRF token</convention>
</knowledge>

</knowledge>

<knowledge domain="rate-limiting">

<knowledge domain="response-headers">
<example>
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
</example>
</knowledge>

<knowledge domain="granularity">
<item>按 IP（匿名用户）</item>
<item>按用户（已登录）</item>
<item>按 API Key（服务端调用）</item>
<item>按端点（敏感端点更严）</item>
</knowledge>

</knowledge>

<knowledge domain="hateoas">
<convention name="Level-0">HTTP 仅作传输（SOAP 风格）</convention>
<convention name="Level-1">多资源</convention>
<convention name="Level-2">正确使用 HTTP 方法和状态码（**大多数 REST API 在此**）</convention>
<convention name="Level-3">HATEOAS，响应中包含相关资源链接</convention>
<principle>L2 是实用的目标；L3 在特定场景（浏览器式 API）有价值。</principle>
</knowledge>

<knowledge domain="graphql">

<knowledge domain="when-to-use">
<convention name="pros">
  <item>前端需要灵活的字段组合</item>
  <item>多端（Web / iOS / Android）需求差异大</item>
  <item>避免多次往返（复杂聚合）</item>
</convention>
<convention name="cons">
  <item>简单 CRUD（REST 更合适）</item>
  <item>公开 API（学习曲线）</item>
  <item>缓存和 CDN 友好度要求高（REST 更容易）</item>
</convention>
</knowledge>

<knowledge domain="key-points">
<item name="n-plus-one">使用 DataLoader</item>
<item name="auth">在 resolver 层检查</item>
<item name="depth-limit">防止恶意嵌套查询</item>
<item name="complexity">查询复杂度评分：防止滥用</item>
</knowledge>

</knowledge>

<checklist name="api-design-checklist">
<principle>设计新 API 时问自己</principle>
  <item>URL 符合命名规范</item>
  <item>HTTP 方法正确</item>
  <item>状态码语义清晰</item>
  <item>响应格式与项目其他 API 一致</item>
  <item>错误码定义且文档化</item>
  <item>认证和授权机制明确</item>
  <item>输入验证充分</item>
  <item>限流策略考虑</item>
  <item>分页策略考虑</item>
  <item>向后兼容性考虑</item>
  <item>日志和监控点设计</item>
  <item>文档（OpenAPI / GraphQL schema）更新</item>
</checklist>

</skill>
