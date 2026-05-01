---
paths:
  - "**/main.py"
  - "**/routers/**/*.py"
  - "**/api/**/*.py"
  - "**/dependencies.py"
  - "**/schemas.py"
when_to_use: 仅当项目确认为 FastAPI（pyproject.toml / requirements.txt 含 `fastapi`，或代码中 `from fastapi import`）。单独 main.py 不足以证明，非 FastAPI 项目也常用此文件名。
---

<rule name="fastapi-version">
  <convention>FastAPI 0.100+（Pydantic v2）</convention>
</rule>

<rule name="fastapi-project-structure">
  <description>适用判定（主会话读到本规则后先检查）：查找 from fastapi import 或 import fastapi；若未命中，本规则不适用，以项目实际技术栈为准（可能是 Flask / Django / 纯 Python 脚本）。</description>
  <pattern>
app/
├── main.py              # 入口
├── core/                # 配置、安全
├── api/
│   ├── deps.py          # 依赖注入
│   └── v1/
│       └── endpoints/
├── models/              # SQLAlchemy / SQLModel
├── schemas/             # Pydantic 模型（API I/O）
├── services/            # 业务逻辑
├── db/                  # 数据库会话
└── tests/
  </pattern>
</rule>

<rule name="fastapi-pydantic-schema">
  <convention>Schema 和 Model 分离：Schema 是 API 层，Model 是持久层</convention>
  <convention>Input / Output / Update 分别定义</convention>
  <pattern>
    <code language="python">
class UserCreate(BaseModel):
    email: EmailStr
    password: SecretStr

class UserOut(BaseModel):
    id: int
    email: EmailStr
    # 不暴露 password_hash
    model_config = ConfigDict(from_attributes=True)
    </code>
  </pattern>
  <convention>Pydantic v2：model_config 而非 class Config</convention>
</rule>

<rule name="fastapi-endpoint">
  <pattern>
    <code language="python">
@router.post("/users", response_model=UserOut, status_code=201)
async def create_user(
    user: UserCreate,
    db: AsyncSession = Depends(get_db),
    current: User = Depends(get_current_active_user),
) -> User:
    ...
    </code>
  </pattern>
  <constraint severity="blocker">显式 response_model 避免内部字段泄漏</constraint>
  <constraint severity="blocker">显式状态码（成功创建用 201）</constraint>
  <convention>类型注解完整（FastAPI 据此生成 OpenAPI）</convention>
</rule>

<rule name="fastapi-di">
  <convention>Depends() 做依赖（DB、当前用户、权限）</convention>
  <convention>层级依赖：依赖可依赖依赖</convention>
  <convention>带缓存的依赖：@lru_cache（配置类）</convention>
</rule>

<rule name="fastapi-async">
  <convention>async def 端点 + 异步 DB（SQLAlchemy 2 async / Tortoise / Motor）</convention>
  <constraint severity="warning">不在 async 函数做同步阻塞（用 run_in_threadpool）</constraint>
  <convention>需要纯同步的库：await asyncio.to_thread(...)</convention>
</rule>

<rule name="fastapi-database">
  <convention>SQLAlchemy 2.0 async 风格 或 SQLModel（按项目）</convention>
  <convention>session 在依赖中管理，自动关闭</convention>
  <convention>事务显式：async with db.begin():</convention>
  <constraint severity="warning">不在 endpoint 直接写 ORM 查询（放到 repository / service）</constraint>
</rule>

<rule name="fastapi-exception-handling">
  <convention>HTTPException 抛出标准 HTTP 错误</convention>
  <convention>自定义异常 + @app.exception_handler 统一处理</convention>
  <convention>错误响应遵循项目统一格式</convention>
  <pattern>
    <code language="python">
@app.exception_handler(BusinessError)
async def business_error_handler(request, exc):
    return JSONResponse(
        status_code=422,
        content={"error": {"code": exc.code, "message": exc.message}}
    )
    </code>
  </pattern>
</rule>

<rule name="fastapi-auth">
  <convention>OAuth2 Password Bearer / JWT</convention>
  <convention>fastapi-users 或自建</convention>
  <convention>依赖返回当前用户：Depends(get_current_user)</convention>
  <convention>权限检查作为二级依赖</convention>
</rule>

<rule name="fastapi-validation">
  <convention>Pydantic 校验自动（类型 + Field(...)）</convention>
  <convention>自定义校验：@field_validator</convention>
  <convention>跨字段：@model_validator(mode='after')</convention>
</rule>

<rule name="fastapi-docs">
  <convention>/docs Swagger、/redoc ReDoc</convention>
  <constraint severity="blocker">生产关闭（或加鉴权）：docs_url=None, redoc_url=None</constraint>
  <convention>端点用 docstring 丰富说明</convention>
</rule>

<rule name="fastapi-performance">
  <convention>uvicorn + uvloop + httptools</convention>
  <convention>生产用 gunicorn + uvicorn worker</convention>
  <convention>测量：/metrics（Prometheus 中间件）</convention>
  <convention>避免在启动时做长耗时（用 lifespan / 异步启动）</convention>
</rule>

<rule name="fastapi-testing">
  <convention>TestClient 同步测试（简单）</convention>
  <convention>httpx.AsyncClient + LifespanManager 异步测试</convention>
  <convention>测试数据库独立（TESTING=1 环境变量切换）</convention>
  <convention>pytest-asyncio</convention>
</rule>

<rule name="fastapi-security">
  <convention>CORS 中间件限定 origin</convention>
  <convention>速率限制：slowapi</convention>
  <convention>HTTPS 强制（反代层或中间件）</convention>
  <convention>密码：passlib[bcrypt]</convention>
  <constraint severity="blocker">不在 response 返回敏感字段（Schema 隔离）</constraint>
</rule>

<rule name="fastapi-anti-patterns">
  <constraint severity="blocker">Endpoint 直接操作 DB（违反分层）</constraint>
  <constraint severity="blocker">巨型 main.py（用 router 拆分）</constraint>
  <constraint severity="blocker">生产保留 /docs 暴露</constraint>
  <constraint severity="warning">同步阻塞在 async 端点</constraint>
</rule>
