---
paths:
  - "**/routes/**/*.php"
  - "**/app/Http/Controllers/**/*.php"
  - "**/app/Models/**/*.php"
  - "**/app/Services/**/*.php"
  - "**/database/migrations/**/*.php"
  - "**/config/**/*.php"
---

<rule name="laravel-version">
  <convention>Laravel 10+ / 11+（PHP 8.2+）</convention>
</rule>

<rule name="laravel-directory-structure">
  <convention>app/Models/：Eloquent 模型</convention>
  <convention>app/Http/Controllers/：控制器</convention>
  <convention>app/Http/Requests/：FormRequest 验证</convention>
  <convention>app/Services/：业务逻辑</convention>
  <convention>app/Jobs/：队列任务</convention>
  <convention>app/Events/ / app/Listeners/：事件</convention>
  <convention>app/Policies/：授权策略</convention>
</rule>

<rule name="laravel-controller">
  <convention>Thin Controller, Fat Service</convention>
  <convention>RESTful 资源控制器：php artisan make:controller UserController --resource</convention>
  <convention>Single Action Controller：__invoke 方法（单职责）</convention>
  <pattern>
    <code language="php">
public function store(StoreUserRequest $request, CreateUser $creator)
{
    $user = $creator->execute($request->validated());
    return new UserResource($user);
}
    </code>
  </pattern>
</rule>

<rule name="laravel-formrequest">
  <description>将验证从 Controller 抽出</description>
  <pattern>
    <code language="php">
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
    </code>
  </pattern>
</rule>

<rule name="laravel-eloquent">
  <convention>$fillable 或 $guarded（Mass Assignment 保护）</convention>
  <convention>$casts 类型转换：'is_admin' => 'boolean'</convention>
  <convention>关联：hasMany / belongsTo / hasOneThrough 等</convention>
  <convention>Scope：本地 scope 用 scopeXxx</convention>
  <constraint severity="blocker">避免 N+1：with() / load()</constraint>
  <constraint severity="blocker">Query Builder 不拼接 SQL</constraint>
</rule>

<rule name="laravel-migrations">
  <convention>php artisan make:migration</convention>
  <convention>up + down 都实现</convention>
  <constraint severity="blocker">不修改已部署的 migration</constraint>
  <convention>破坏性 schema 变更多步骤（添加、双写、切换、删除）</convention>
</rule>

<rule name="laravel-service-layer">
  <pattern>
    <code language="php">
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
    </code>
  </pattern>
  <convention>依赖注入（构造器）</convention>
  <convention>事务包裹原子操作</convention>
  <convention>领域事件代替耦合调用</convention>
</rule>

<rule name="laravel-routing">
  <convention>routes/web.php（Web）vs routes/api.php（API）</convention>
  <convention>Resource 路由：Route::resource('users', UserController::class);</convention>
  <convention>Route Model Binding 自动解析参数</convention>
  <convention>路由命名：->name('users.show')</convention>
</rule>

<rule name="laravel-middleware">
  <convention>认证：auth / auth:sanctum</convention>
  <convention>限流：throttle:api</convention>
  <convention>自定义中间件 php artisan make:middleware</convention>
</rule>

<rule name="laravel-authorization">
  <convention>Policy：php artisan make:policy UserPolicy --model=User</convention>
  <convention>Controller 中：$this->authorize('update', $user)</convention>
  <convention>Gate 做细粒度控制</convention>
</rule>

<rule name="laravel-queue">
  <convention>php artisan make:job</convention>
  <convention>dispatch(new Job) 入队</convention>
  <convention>失败重试 $tries = 3</convention>
  <convention>幂等考虑（可能重跑）</convention>
</rule>

<rule name="laravel-cache">
  <convention>Cache::remember('key', 3600, fn() => ...) 常用</convention>
  <convention>后端：Redis / Memcached 生产推荐</convention>
  <convention>清除：Cache::forget / Cache::tags</convention>
</rule>

<rule name="laravel-config-env">
  <convention>.env 本地</convention>
  <convention>config/ 配置分类</convention>
  <constraint severity="blocker">禁止代码中直接 env()（仅在 config/ 中用）</constraint>
  <convention>php artisan config:cache 生产</convention>
</rule>

<rule name="laravel-security">
  <convention>CSRF：Web 路由默认启用</convention>
  <constraint severity="blocker">SQL 注入：Eloquent / Query Builder 参数化</constraint>
  <convention>XSS：Blade {{ }} 自动 escape；{!! !!} 慎用</convention>
  <convention>密码：Hash::make / bcrypt</convention>
  <convention>认证：Sanctum（SPA / API）/ Breeze / Jetstream</convention>
</rule>

<rule name="laravel-testing">
  <convention>PHPUnit / Pest</convention>
  <convention>RefreshDatabase trait 每测试回滚</convention>
  <convention>Factory 造数据</convention>
  <convention>actingAs($user) 模拟登录</convention>
</rule>

<rule name="laravel-anti-patterns">
  <constraint severity="blocker">Controller 写业务逻辑（抽 Service）</constraint>
  <constraint severity="blocker">Model 里做 HTTP 调用</constraint>
  <constraint severity="blocker">在 view 查 DB</constraint>
  <constraint severity="blocker">Migration 删除再改（破坏历史）</constraint>
  <constraint severity="blocker">忽略 N+1</constraint>
  <constraint severity="blocker">用 DB::raw 拼用户输入</constraint>
</rule>
