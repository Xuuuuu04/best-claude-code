---
paths:
  - "**/Program.cs"
  - "**/Startup.cs"
  - "**/Controllers/**/*.cs"
  - "**/*Controller.cs"
  - "**/appsettings.json"
  - "**/appsettings.*.json"
---

# ASP.NET Core 规范

## 版本
- .NET 8 LTS+
- Minimal API 或 MVC Controller（按项目风格）

## 项目结构

- `Controllers/`：API 控制器
- `Services/`：业务逻辑
- `Repositories/`：数据访问（如未用 EF Core 直接用）
- `Models/`：领域 / DTO
- `Data/`：EF Core DbContext
- `Middleware/`：自定义中间件

## Program.cs（Minimal Hosting）

```csharp
var builder = WebApplication.CreateBuilder(args);

builder.Services.AddControllers();
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseNpgsql(builder.Configuration.GetConnectionString("Default")));
builder.Services.AddScoped<IUserService, UserService>();

var app = builder.Build();

if (app.Environment.IsDevelopment()) app.UseSwagger().UseSwaggerUI();

app.UseHttpsRedirection();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

app.Run();
```

## Controller

```csharp
[ApiController]
[Route("api/[controller]")]
public class UsersController : ControllerBase
{
    private readonly IUserService _users;

    public UsersController(IUserService users) => _users = users;

    [HttpGet("{id:int}")]
    public async Task<ActionResult<UserDto>> GetAsync(int id, CancellationToken ct)
    {
        var user = await _users.FindAsync(id, ct);
        return user is null ? NotFound() : Ok(user);
    }

    [HttpPost]
    public async Task<ActionResult<UserDto>> CreateAsync([FromBody] CreateUserRequest req, CancellationToken ct)
    {
        var user = await _users.CreateAsync(req, ct);
        return CreatedAtAction(nameof(GetAsync), new { id = user.Id }, user);
    }
}
```

- `[ApiController]` 自动模型验证 + 错误响应
- `CancellationToken` 每异步 action 都接受
- 返回类型用 `ActionResult<T>` 保留状态码灵活性

## Minimal API（简单场景）

```csharp
app.MapGet("/users/{id:int}", async (int id, IUserService users) =>
    await users.FindAsync(id) is {} user
        ? Results.Ok(user)
        : Results.NotFound());
```

## DTO 与 Entity 分离

- API 层用 DTO（`UserDto`、`CreateUserRequest`）
- EF 层用 Entity
- AutoMapper 或手写映射

## 验证

- Data Annotations：`[Required]` / `[EmailAddress]` / `[StringLength]`
- FluentValidation（复杂场景）
- `[ApiController]` 自动 400 响应

## EF Core

- `DbContext` Scoped 生命周期
- 异步方法：`.FirstOrDefaultAsync()` / `.ToListAsync()`
- `AsNoTracking()` 只读查询
- 避免 N+1：`.Include()` / `.ThenInclude()`
- Migration：`dotnet ef migrations add` / `dotnet ef database update`

## 异常处理

- `UseExceptionHandler` 中间件 + 自定义错误响应
- Problem Details（RFC 7807）格式统一
- 不在生产暴露堆栈

```csharp
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        // 统一错误响应
    });
});
```

## 认证与授权

- JWT / Cookie / OAuth2 / OpenID Connect
- `[Authorize]` 属性
- Policy-based：`[Authorize(Policy = "AdminOnly")]`
- `services.AddAuthentication` / `AddAuthorization`

## 配置

- `appsettings.json` + `appsettings.{Environment}.json`
- `IOptions<T>` 类型安全
- 敏感值：User Secrets（开发）/ Azure Key Vault / AWS Secrets Manager

## 日志

- `ILogger<T>` 注入
- 结构化：`logger.LogInformation("User {UserId} logged in", userId)`
- Serilog 或 NLog 做高级日志

## 健康检查

```csharp
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>();

app.MapHealthChecks("/health");
```

## 反模式

- Controller 做业务（抽 Service）
- 同步 `.Result` / `.Wait()`（死锁）
- `try/catch(Exception)` 吞异常
- Entity 直接返回给客户端（字段泄漏）
- 不传递 `CancellationToken`
- 密码明文 / 弱 hash
