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

<rule name="django-version">
  <convention>Django 4.2 LTS+ 或 5.x</convention>
</rule>

<rule name="django-project-structure">
  <convention>App 划分按业务能力：users/, orders/, payments/</convention>
  <convention>每 app 有：models.py, views.py, urls.py, admin.py, tests/</convention>
  <convention>settings/ 目录按环境拆分：base.py, development.py, production.py</convention>
</rule>

<rule name="django-models">
  <pattern>
    <code language="python">
class User(models.Model):
    email = models.EmailField(unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        indexes = [models.Index(fields=['-created_at'])]
        ordering = ['-created_at']

    def __str__(self):
        return self.email
    </code>
  </pattern>
  <constraint severity="blocker">必定义 __str__（便于 admin / shell）</constraint>
  <convention>Meta 定义 index、ordering、permissions</convention>
  <constraint severity="blocker">关系字段 on_delete 必明确（CASCADE / PROTECT / SET_NULL）</constraint>
</rule>

<rule name="django-migrations">
  <constraint severity="blocker">禁止修改已提交的 migration 文件</constraint>
  <convention>数据迁移用 RunPython + reverse 函数</convention>
  <convention>破坏性变更分多步（先加列双写 -> 迁移 -> 切代码 -> 删旧列）</convention>
</rule>

<rule name="django-queries">
  <constraint severity="blocker">避免 N+1：select_related（外键）/ prefetch_related（多对多 / 反向）</constraint>
  <convention>only() / defer() 减少字段</convention>
  <convention>F() / Q() 表达式避免 race condition</convention>
  <convention>批量：bulk_create / bulk_update</convention>
  <convention>大数据量：iterator() 流式处理</convention>
</rule>

<rule name="django-views">
  <convention>类视图（CBV）优先于函数视图（可复用、扩展性好）</convention>
  <convention>DRF 用 ViewSet / GenericAPIView</convention>
  <convention>权限在 permission_classes 声明</convention>
  <constraint severity="blocker">不在 view 内写复杂业务（抽到 service 层）</constraint>
</rule>

<rule name="django-drf">
  <convention>Serializer 做输入验证和输出序列化</convention>
  <constraint severity="blocker">不直接暴露 Model 的所有字段（显式 fields = [...]）</constraint>
  <convention>ModelSerializer 方便但审查所有字段暴露</convention>
  <convention>分页：DEFAULT_PAGINATION_CLASS</convention>
</rule>

<rule name="django-urls">
  <convention>path() 代替旧 url()</convention>
  <convention>命名路由：path('users/', UserList.as_view(), name='user-list')</convention>
  <convention>URL namespace 按 app 划分</convention>
</rule>

<rule name="django-admin">
  <convention>限制生产环境 admin 访问（IP 白名单、2FA）</convention>
  <convention>list_display, list_filter, search_fields 提升可用性</convention>
  <convention>readonly_fields 保护关键字段</convention>
</rule>

<rule name="django-forms-validation">
  <convention>clean_field() 单字段验证</convention>
  <convention>clean() 跨字段验证</convention>
  <convention>Django Forms 或 DRF Serializer（按场景）</convention>
</rule>

<rule name="django-settings-security">
  <constraint severity="blocker">DEBUG = False 生产</constraint>
  <constraint severity="blocker">SECRET_KEY 环境变量</constraint>
  <constraint severity="blocker">ALLOWED_HOSTS 明确</constraint>
  <constraint severity="blocker">SECURE_SSL_REDIRECT = True</constraint>
  <constraint severity="blocker">CSRF_COOKIE_SECURE = True</constraint>
  <constraint severity="blocker">SESSION_COOKIE_SECURE = True</constraint>
  <convention>CSP（Content Security Policy）配置</convention>
</rule>

<rule name="django-security">
  <convention>CSRF 中间件启用</convention>
  <convention>XSS：模板自动 escape，不用 |safe 除非可控</convention>
  <constraint severity="blocker">SQL 注入：不拼接 raw SQL；必要时用参数化 raw() / extra()</constraint>
  <convention>密码：Django 默认 PBKDF2（足够）</convention>
  <convention>敏感字段：EncryptedField 或 app 层加密</convention>
</rule>

<rule name="django-cache">
  <convention>django.core.cache 后端（Redis / Memcached）</convention>
  <convention>细粒度：cache.get / cache.set</convention>
  <convention>视图级：@cache_page</convention>
  <convention>片段缓存：模板 {% cache %}</convention>
</rule>

<rule name="django-testing">
  <convention>django.test.TestCase 每测试事务回滚（快）</convention>
  <convention>pytest-django 更现代</convention>
  <convention>Factory Boy 造测试数据</convention>
  <convention>API 测试用 APIClient（DRF）</convention>
</rule>

<rule name="django-anti-patterns">
  <constraint severity="blocker">ORM 查询在 template（移到 view）</constraint>
  <constraint severity="warning">巨型 views.py（拆分为 views/ 目录）</constraint>
  <constraint severity="blocker">request.POST.get() 不经验证</constraint>
  <constraint severity="warning">save() 无 update_fields（全字段写入）</constraint>
  <constraint severity="warning">migration 合并时的冲突不处理</constraint>
</rule>
