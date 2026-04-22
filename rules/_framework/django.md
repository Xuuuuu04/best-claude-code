---
paths:
  - "**/settings.py"
  - "**/urls.py"
  - "**/models.py"
  - "**/views.py"
  - "**/serializers.py"
  - "**/admin.py"
  - "**/migrations/**/*.py"
  - "**/manage.py"
---

# Django 规范

## 版本
- Django 4.2 LTS+ 或 5.x

## 项目结构

- App 划分按业务能力：`users/`, `orders/`, `payments/`
- 每 app 有：`models.py`, `views.py`, `urls.py`, `admin.py`, `tests/`
- `settings/` 目录按环境拆分：`base.py`, `development.py`, `production.py`

## Models

```python
class User(models.Model):
    email = models.EmailField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        indexes = [models.Index(fields=['-created_at'])]
        ordering = ['-created_at']
    
    def __str__(self):
        return self.email
```

- **必定义** `__str__`（便于 admin / shell）
- `Meta` 定义 index、ordering、permissions
- 关系字段 `on_delete` 必明确（`CASCADE` / `PROTECT` / `SET_NULL`）

## Migration

- **禁止** 修改已提交的 migration 文件
- 数据迁移用 `RunPython` + reverse 函数
- 破坏性变更分多步（先加列双写 → 迁移 → 切代码 → 删旧列）

## 查询

- 避免 N+1：`select_related`（外键）/ `prefetch_related`（多对多 / 反向）
- `only()` / `defer()` 减少字段
- `F()` / `Q()` 表达式避免 race condition
- 批量：`bulk_create` / `bulk_update`
- 大数据量：`iterator()` 流式处理

## Views

- **类视图（CBV）** 优先于函数视图（可复用、扩展性好）
- DRF 用 `ViewSet` / `GenericAPIView`
- 权限在 `permission_classes` 声明
- 不在 view 内写复杂业务（抽到 service 层）

## DRF（REST Framework）

- `Serializer` 做输入验证和输出序列化
- **不直接** 暴露 Model 的所有字段（显式 `fields = [...]`）
- `ModelSerializer` 方便但审查所有字段暴露
- 分页：`DEFAULT_PAGINATION_CLASS`

## URL

- `path()` 代替旧 `url()`
- 命名路由：`path('users/', UserList.as_view(), name='user-list')`
- URL namespace 按 app 划分

## Admin

- 限制生产环境 admin 访问（IP 白名单、2FA）
- `list_display`, `list_filter`, `search_fields` 提升可用性
- `readonly_fields` 保护关键字段

## Forms & 验证

- `clean_<field>()` 单字段验证
- `clean()` 跨字段验证
- Django Forms 或 DRF Serializer（按场景）

## Settings 安全

- `DEBUG = False` 生产
- `SECRET_KEY` 环境变量
- `ALLOWED_HOSTS` 明确
- `SECURE_SSL_REDIRECT = True`
- `CSRF_COOKIE_SECURE = True`
- `SESSION_COOKIE_SECURE = True`
- `CSP`（Content Security Policy）配置

## 安全

- CSRF 中间件启用
- XSS：模板自动 escape，不用 `|safe` 除非可控
- SQL 注入：不拼接 raw SQL；必要时用参数化 `raw()` / `extra()`
- 密码：Django 默认 PBKDF2（足够）
- 敏感字段：`EncryptedField` 或 app 层加密

## 缓存

- `django.core.cache` 后端（Redis / Memcached）
- 细粒度：`cache.get` / `cache.set`
- 视图级：`@cache_page`
- 片段缓存：模板 `{% cache %}`

## 测试

- `django.test.TestCase` 每测试事务回滚（快）
- `pytest-django` 更现代
- Factory Boy 造测试数据
- API 测试用 `APIClient`（DRF）

## 反模式

- ORM 查询在 template（移到 view）
- 巨型 views.py（拆分为 `views/` 目录）
- `request.POST.get()` 不经验证
- `save()` 无 `update_fields`（全字段写入）
- migration 合并时的冲突不处理
