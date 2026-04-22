---
paths:
  - "**/main.py"
  - "**/routers/**/*.py"
  - "**/api/**/*.py"
  - "**/dependencies.py"
  - "**/schemas.py"
---

# FastAPI 规范

## 版本
- FastAPI 0.100+（Pydantic v2）

## 项目结构

```
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
```

## Pydantic Schema

- Schema 和 Model 分离：Schema 是 API 层，Model 是持久层
- Input / Output / Update 分别定义：
  ```python
  class UserCreate(BaseModel):
      email: EmailStr
      password: SecretStr
  
  class UserOut(BaseModel):
      id: int
      email: EmailStr
      # 不暴露 password_hash
      model_config = ConfigDict(from_attributes=True)
  ```
- Pydantic v2：`model_config` 而非 `class Config`

## Endpoint

```python
@router.post("/users", response_model=UserOut, status_code=201)
async def create_user(
    user: UserCreate,
    db: AsyncSession = Depends(get_db),
    current: User = Depends(get_current_active_user),
) -> User:
    ...
```

- **显式** `response_model` 避免内部字段泄漏
- **显式** 状态码（成功创建用 201）
- 类型注解完整（FastAPI 据此生成 OpenAPI）

## 依赖注入

- `Depends()` 做依赖（DB、当前用户、权限）
- 层级依赖：依赖可依赖依赖
- 带缓存的依赖：`@lru_cache`（配置类）

## 异步

- `async def` 端点 + 异步 DB（SQLAlchemy 2 async / Tortoise / Motor）
- **不**在 async 函数做同步阻塞（用 `run_in_threadpool`）
- 需要纯同步的库：`await asyncio.to_thread(...)`

## 数据库

- SQLAlchemy 2.0 async 风格 或 SQLModel（按项目）
- session 在依赖中管理，自动关闭
- 事务显式：`async with db.begin():`
- 不在 endpoint 直接写 ORM 查询（放到 repository / service）

## 异常处理

- `HTTPException` 抛出标准 HTTP 错误
- 自定义异常 + `@app.exception_handler` 统一处理
- 错误响应遵循项目统一格式

```python
@app.exception_handler(BusinessError)
async def business_error_handler(request, exc):
    return JSONResponse(
        status_code=422,
        content={"error": {"code": exc.code, "message": exc.message}}
    )
```

## 认证

- OAuth2 Password Bearer / JWT
- `fastapi-users` 或自建
- 依赖返回当前用户：`Depends(get_current_user)`
- 权限检查作为二级依赖

## 验证

- Pydantic 校验自动（类型 + `Field(...)`）
- 自定义校验：`@field_validator`
- 跨字段：`@model_validator(mode='after')`

## 文档

- `/docs` Swagger、`/redoc` ReDoc
- 生产关闭（或加鉴权）：`docs_url=None, redoc_url=None`
- 端点用 docstring 丰富说明

## 性能

- `uvicorn` + `uvloop` + `httptools`
- 生产用 gunicorn + uvicorn worker
- 测量：`/metrics`（Prometheus 中间件）
- 避免在启动时做长耗时（用 lifespan / 异步启动）

## 测试

- `TestClient` 同步测试（简单）
- `httpx.AsyncClient` + `LifespanManager` 异步测试
- 测试数据库独立（`TESTING=1` 环境变量切换）
- `pytest-asyncio`

## 安全

- CORS 中间件限定 origin
- 速率限制：`slowapi`
- HTTPS 强制（反代层或中间件）
- 密码：`passlib[bcrypt]`
- 不在 response 返回敏感字段（Schema 隔离）

## 反模式

- Endpoint 直接操作 DB（违反分层）
- 巨型 `main.py`（用 router 拆分）
- 生产保留 `/docs` 暴露
- 同步阻塞在 async 端点
