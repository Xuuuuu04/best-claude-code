---
paths:
  - "**/routes/**/*.php"
  - "**/app/Http/Controllers/**/*.php"
  - "**/app/Models/**/*.php"
  - "**/app/Services/**/*.php"
  - "**/database/migrations/**/*.php"
  - "**/config/**/*.php"
---

# Laravel 规范

## 版本
- Laravel 10+ / 11+（PHP 8.2+）

## 目录结构

- `app/Models/`：Eloquent 模型
- `app/Http/Controllers/`：控制器
- `app/Http/Requests/`：FormRequest 验证
- `app/Services/`：业务逻辑
- `app/Jobs/`：队列任务
- `app/Events/` / `app/Listeners/`：事件
- `app/Policies/`：授权策略

## 控制器

- **Thin Controller, Fat Service**
- RESTful 资源控制器：`php artisan make:controller UserController --resource`
- Single Action Controller：`__invoke` 方法（单职责）

```php
public function store(StoreUserRequest $request, CreateUser $creator)
{
    $user = $creator->execute($request->validated());
    return new UserResource($user);
}
```

## FormRequest

将验证从 Controller 抽出：

```php
class StoreUserRequest extends FormRequest
{
    public function authorize(): bool { return true; }
    
    public function rules(): array
    {
        return [
            'email' => 'required|email|unique:users',
            'password' => 'required|min:8',
        ];
    }
}
```

## Eloquent

- `$fillable` 或 `$guarded`（Mass Assignment 保护）
- `$casts` 类型转换：`'is_admin' => 'boolean'`
- 关联：`hasMany` / `belongsTo` / `hasOneThrough` 等
- Scope：本地 scope 用 `scopeXxx`
- **避免 N+1**：`with()` / `load()`
- Query Builder 不拼接 SQL

## Migration

- `php artisan make:migration`
- `up` + `down` 都实现
- 不修改已部署的 migration
- 破坏性 schema 变更多步骤（添加、双写、切换、删除）

## Service Layer

```php
class CreateUser
{
    public function __construct(private UserRepository $users) {}

    public function execute(array $data): User
    {
        return DB::transaction(function () use ($data) {
            $user = $this->users->create($data);
            event(new UserRegistered($user));
            return $user;
        });
    }
}
```

- 依赖注入（构造器）
- 事务包裹原子操作
- 领域事件代替耦合调用

## 路由

- `routes/web.php`（Web）vs `routes/api.php`（API）
- Resource 路由：`Route::resource('users', UserController::class);`
- Route Model Binding 自动解析参数
- 路由命名：`->name('users.show')`

## 中间件

- 认证：`auth` / `auth:sanctum`
- 限流：`throttle:api`
- 自定义中间件 `php artisan make:middleware`

## 授权

- Policy：`php artisan make:policy UserPolicy --model=User`
- Controller 中：`$this->authorize('update', $user)`
- Gate 做细粒度控制

## 队列

- `php artisan make:job`
- `dispatch(new Job)` 入队
- 失败重试 `$tries = 3`
- 幂等考虑（可能重跑）

## 缓存

- `Cache::remember('key', 3600, fn() => ...)` 常用
- 后端：Redis / Memcached 生产推荐
- 清除：`Cache::forget` / `Cache::tags`

## 配置与环境

- `.env` 本地
- `config/` 配置分类
- **禁止** 代码中直接 `env()`（仅在 config/ 中用）
- `php artisan config:cache` 生产

## 安全

- CSRF：Web 路由默认启用
- SQL 注入：Eloquent / Query Builder 参数化
- XSS：Blade `{{ }}` 自动 escape；`{!! !!}` 慎用
- 密码：`Hash::make` / `bcrypt`
- 认证：Sanctum（SPA / API）/ Breeze / Jetstream

## 测试

- PHPUnit / Pest
- `RefreshDatabase` trait 每测试回滚
- Factory 造数据
- `actingAs($user)` 模拟登录

## 反模式

- Controller 写业务逻辑（抽 Service）
- Model 里做 HTTP 调用
- 在 view 查 DB
- Migration 删除再改（破坏历史）
- 忽略 N+1
- 用 `DB::raw` 拼用户输入
