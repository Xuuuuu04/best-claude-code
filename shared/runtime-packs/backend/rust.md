> 源：core.md §Domain 1.x Rust Stack（新增 2026-04-21）

# 后端开发师 — Rust Stack

## 1.x Rust Stack

├── 1.x.1 Axum — 路由、提取器、中间件、错误处理、状态共享
├── 1.x.2 Tokio — async runtime、spawn、select、timeout、channel
├── 1.x.3 SeaORM / sqlx — 类型安全的数据库访问
└── 1.x.4 Rust 并发安全 — Send/Sync、Arc、RwLock、无数据竞争保证

---

## Axum 实现模式

**路由 + 提取器 + 处理器**

```rust
use axum::{
    routing::{get, post},
    extract::{State, Path, Json},
    http::StatusCode,
    Router,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;

#[derive(Deserialize)]
struct CreateUserRequest {
    email: String,
    password: String,
    display_name: String,
}

#[derive(Serialize)]
struct UserResponse {
    id: i64,
    email: String,
    display_name: String,
}

// State 共享模式
#[derive(Clone)]
struct AppState {
    db: DatabasePool,
    config: Arc<AppConfig>,
}

async fn create_user(
    State(state): State<AppState>,
    Json(req): Json<CreateUserRequest>,
) -> Result<(StatusCode, Json<UserResponse>), AppError> {
    // 输入验证
    if req.email.len() > 254 || !req.email.contains('@') {
        return Err(AppError::Validation("Invalid email format".to_string()));
    }
    if req.password.len() < 8 || req.password.len() > 128 {
        return Err(AppError::Validation("Password must be 8-128 characters".to_string()));
    }

    let user = user_service::create(&state.db, req).await?;
    Ok((StatusCode::CREATED, Json(UserResponse::from(user))))
}

async fn get_user(
    State(state): State<AppState>,
    Path(id): Path<i64>,
) -> Result<Json<UserResponse>, AppError> {
    let user = user_service::find_by_id(&state.db, id).await?;
    Ok(Json(UserResponse::from(user)))
}

// Router 组装
fn app_router(state: AppState) -> Router {
    Router::new()
        .route("/users", post(create_user))
        .route("/users/:id", get(get_user))
        .layer(axum::middleware::from_fn(logging_middleware))
        .with_state(state)
}
```

**自定义错误响应中间件**

```rust
use axum::response::{IntoResponse, Response};
use axum::Json;

#[derive(Debug)]
enum AppError {
    Validation(String),
    NotFound(String),
    Database(sqlx::Error),
    Unauthorized,
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code, message) = match &self {
            AppError::Validation(msg) => (StatusCode::BAD_REQUEST, "VALIDATION_ERROR", msg.clone()),
            AppError::NotFound(msg) => (StatusCode::NOT_FOUND, "NOT_FOUND", msg.clone()),
            AppError::Database(_) => (StatusCode::INTERNAL_SERVER_ERROR, "INTERNAL_ERROR", "Database error".to_string()),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, "UNAUTHORIZED", "Authentication required".to_string()),
        };

        let body = Json(serde_json::json!({
            "code": code,
            "message": message,
            "status": status.as_u16(),
        }));

        (status, body).into_response()
    }
}

// sqlx::Error 自动转换
impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        match err {
            sqlx::Error::RowNotFound => AppError::NotFound("Resource not found".to_string()),
            _ => AppError::Database(err),
        }
    }
}
```

---

## Tokio 并发模式

**spawn + JoinSet（并发任务管理）**

```rust
use tokio::task::JoinSet;

async fn send_notifications(user_ids: Vec<i64>) -> Result<Vec<()>, AppError> {
    let mut set = JoinSet::new();

    for id in user_ids {
        set.spawn(async move {
            notification_service::send(id).await
        });
    }

    while let Some(result) = set.join_next().await {
        result??; // 内部 Result + JoinError 双重解包
    }
    Ok(())
}
```

**timeout + select（超时控制）**

```rust
use tokio::time::{timeout, Duration};

async fn fetch_with_timeout(url: &str) -> Result<String, AppError> {
    match timeout(Duration::from_secs(5), http_client::get(url)).await {
        Ok(Ok(response)) => Ok(response),
        Ok(Err(e)) => Err(AppError::External(e.to_string())),
        Err(_) => Err(AppError::External("Request timeout".to_string())),
    }
}
```

**channel（生产者-消费者）**

```rust
use tokio::sync::mpsc;

async fn process_queue() {
    let (tx, mut rx) = mpsc::channel::<Job>(100);

    // 生产者
    tokio::spawn(async move {
        for job in job_generator() {
            if tx.send(job).await.is_err() {
                break; // 接收端已关闭
            }
        }
    });

    // 消费者（可扩展为多个）
    while let Some(job) = rx.recv().await {
        process_job(job).await;
    }
}
```

---

## SeaORM / sqlx 数据访问

**sqlx — 编译时检查 SQL**

```rust
use sqlx::{PgPool, query_as, query};

// 编译时检查 SQL 语法和类型（需要 sqlx-cli migrate + sqlx prepare）
async fn get_user_by_email(pool: &PgPool, email: &str) -> Result<Option<User>, sqlx::Error> {
    let user = query_as!(User,
        r#"SELECT id, email, display_name, created_at FROM users WHERE email = $1"#,
        email
    )
    .fetch_optional(pool)
    .await?;
    Ok(user)
}

// 参数化查询 — 天然防 SQL 注入
async fn create_user(pool: &PgPool, req: &CreateUserRequest) -> Result<i64, sqlx::Error> {
    let record = query!(
        r#"INSERT INTO users (email, password_hash, display_name) VALUES ($1, $2, $3) RETURNING id"#,
        req.email,
        hash_password(&req.password),
        req.display_name
    )
    .fetch_one(pool)
    .await?;
    Ok(record.id)
}
```

**SeaORM — 类型安全 ORM**

```rust
use sea_orm::{EntityTrait, QueryFilter, ColumnTrait, Set, TransactionTrait};

// 查询
let user = User::find()
    .filter(user::Column::Email.eq(email))
    .one(&db)
    .await?;

// 事务
let txn = db.begin().await?;
let invitation = Invitation::ActiveModel {
    email: Set(req.email.clone()),
    status: Set("pending".to_string()),
    ..Default::default()
};
let invitation = invitation.insert(&txn).await?;

AuditLog::ActiveModel {
    action: Set("INVITATION_CREATED".to_string()),
    user_id: Set(current_user_id),
    ..Default::default()
}.insert(&txn).await?;

txn.commit().await?;
```

---

## Rust 安全编码规范

### 所有权与生命周期

```rust
// BAD: 悬垂引用
fn bad_example() -> &String {
    let s = String::from("hello");
    &s // 编译错误：s 在函数结束时被释放
}

// GOOD: 转移所有权
fn good_example() -> String {
    let s = String::from("hello");
    s // 所有权转移给调用者
}

// GOOD: 使用 Arc 共享不可变数据
use std::sync::Arc;
let config = Arc::new(AppConfig::load());
let config_clone = Arc::clone(&config); // 引用计数 +1，无数据拷贝
```

### Send + Sync 并发安全

```rust
// Rust 编译器自动保证：如果类型实现了 Send，可以跨线程传递
// 如果实现了 Sync，可以跨线程共享引用
// 大多数类型自动实现，包含内部可变性的类型（RefCell）不实现

// BAD: RefCell 不能跨线程
use std::cell::RefCell;
let data = RefCell::new(vec![1, 2, 3]);
// tokio::spawn(async move { data.borrow_mut().push(4); }); // 编译错误

// GOOD: 使用 RwLock 或 Mutex
use std::sync::RwLock;
let data = Arc::new(RwLock::new(vec![1, 2, 3]));
tokio::spawn(async move {
    data.write().unwrap().push(4);
});
```

### 错误处理：? 运算符 + thiserror

```rust
use thiserror::Error;

#[derive(Error, Debug)]
enum ServiceError {
    #[error("Database error: {0}")]
    Database(#[from] sqlx::Error),

    #[error("Validation failed: {0}")]
    Validation(String),

    #[error("External service error: {0}")]
    External(String),
}

// ? 自动转换错误类型（需要 From 实现）
async fn business_logic() -> Result<(), ServiceError> {
    let user = get_user(&pool).await?; // sqlx::Error -> ServiceError
    validate_user(&user)?; // Validation 错误
    Ok(())
}
```

### 项目布局

```
project/
├── Cargo.toml
├── src/
│   ├── main.rs           # 入口：路由组装、中间件、启动
│   ├── lib.rs            # 库入口
│   ├── handlers/         # HTTP 处理器（仅解析请求、调用 service、返回响应）
│   ├── services/         # 业务逻辑层
│   ├── repositories/     # 数据访问层
│   ├── models/           # 数据模型（DTO、Entity）
│   ├── middleware/       # 自定义中间件
│   └── error.rs          # 错误类型定义
├── migrations/           # sqlx migrate 文件
└── .env                  # 本地环境变量（不提交到 git）
```
