---
paths:
  - "**/Program.cs"
  - "**/Startup.cs"
  - "**/Controllers/**/*.cs"
  - "**/*Controller.cs"
  - "**/appsettings.json"
  - "**/appsettings.*.json"
---

<rule name="aspnet-version">
  <convention>.NET 8 LTS+</convention>
  <convention>Minimal API 或 MVC Controller（按项目风格）</convention>
</rule>

<rule name="aspnet-project-structure">
  <convention>Controllers/：API 控制器</convention>
  <convention>Services/：业务逻辑</convention>
  <convention>Repositories/：数据访问（如未用 EF Core 直接用）</convention>
  <convention>Models/：领域 / DTO</convention>
  <convention>Data/：EF Core DbContext</convention>
  <convention>Middleware/：自定义中间件</convention>
</rule>

<rule name="aspnet-program-cs">
  <description>Minimal Hosting</description>
  <pattern>
    <code language="csharp">
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
    </code>
  </pattern>
</rule>

<rule name="aspnet-controller">
  <pattern>
    <code language="csharp">
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
    </code>
  </pattern>
  <convention>[ApiController] 自动模型验证 + 错误响应</convention>
  <convention>CancellationToken 每异步 action 都接受</convention>
  <convention>返回类型用 ActionResult<T> 保留状态码灵活性</convention>
</rule>

<rule name="aspnet-minimal-api">
  <description>简单场景</description>
  <pattern>
    <code language="csharp">
app.MapGet("/users/{id:int}", async (int id, IUserService users) =>
    await users.FindAsync(id) is {} user
        ? Results.Ok(user)
        : Results.NotFound());
    </code>
  </pattern>
</rule>

<rule name="aspnet-dto-entity-separation">
  <convention>API 层用 DTO（UserDto、CreateUserRequest）</convention>
  <convention>EF 层用 Entity</convention>
  <convention>AutoMapper 或手写映射</convention>
</rule>

<rule name="aspnet-validation">
  <convention>Data Annotations：[Required] / [EmailAddress] / [StringLength]</convention>
  <convention>FluentValidation（复杂场景）</convention>
  <convention>[ApiController] 自动 400 响应</convention>
</rule>

<rule name="aspnet-ef-core">
  <convention>DbContext Scoped 生命周期</convention>
  <convention>异步方法：.FirstOrDefaultAsync() / .ToListAsync()</convention>
  <convention>AsNoTracking() 只读查询</convention>
  <constraint severity="blocker">避免 N+1：.Include() / .ThenInclude()</constraint>
  <convention>Migration：dotnet ef migrations add / dotnet ef database update</convention>
</rule>

<rule name="aspnet-exception-handling">
  <convention>UseExceptionHandler 中间件 + 自定义错误响应</convention>
  <convention>Problem Details（RFC 7807）格式统一</convention>
  <constraint severity="blocker">不在生产暴露堆栈</constraint>
  <pattern>
    <code language="csharp">
app.UseExceptionHandler(errorApp =>
{
    errorApp.Run(async context =>
    {
        // 统一错误响应
    });
});
    </code>
  </pattern>
</rule>

<rule name="aspnet-auth">
  <convention>JWT / Cookie / OAuth2 / OpenID Connect</convention>
  <convention>[Authorize] 属性</convention>
  <convention>Policy-based：[Authorize(Policy = "AdminOnly")]</convention>
  <convention>services.AddAuthentication / AddAuthorization</convention>
</rule>

<rule name="aspnet-configuration">
  <convention>appsettings.json + appsettings.{Environment}.json</convention>
  <convention>IOptions<T> 类型安全</convention>
  <convention>敏感值：User Secrets（开发）/ Azure Key Vault / AWS Secrets Manager</convention>
</rule>

<rule name="aspnet-logging">
  <convention>ILogger<T> 注入</convention>
  <convention>结构化：logger.LogInformation("User {UserId} logged in", userId)</convention>
  <convention>Serilog 或 NLog 做高级日志</convention>
</rule>

<rule name="aspnet-health-checks">
  <pattern>
    <code language="csharp">
builder.Services.AddHealthChecks()
    .AddDbContextCheck<AppDbContext>();

app.MapHealthChecks("/health");
    </code>
  </pattern>
</rule>

<rule name="aspnet-anti-patterns">
  <constraint severity="blocker">Controller 做业务（抽 Service）</constraint>
  <constraint severity="blocker">同步 .Result / .Wait()（死锁）</constraint>
  <constraint severity="blocker">try/catch(Exception) 吞异常</constraint>
  <constraint severity="blocker">Entity 直接返回给客户端（字段泄漏）</constraint>
  <constraint severity="warning">不传递 CancellationToken</constraint>
  <constraint severity="blocker">密码明文 / 弱 hash</constraint>
</rule>
