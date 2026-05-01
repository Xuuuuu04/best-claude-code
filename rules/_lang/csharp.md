---
paths:
  - "**/*.cs"
  - "**/*.csproj"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>.NET 8 LTS 或更新</requirement>
  <requirement>C# 12+ 特性（collection expressions、primary constructors）</requirement>

  <!-- ====== 命名 ====== -->
  <convention>类、接口、枚举、方法、属性：`PascalCase`</convention>
  <convention>接口前缀 `I`：`IUserRepository`</convention>
  <convention>私有字段：`_camelCase` 或 `camelCase`</convention>
  <convention>参数、局部变量：`camelCase`</convention>
  <convention>常量：`PascalCase`（现代）或 `UPPER_SNAKE_CASE`（老代码）</convention>

  <!-- ====== 可空引用类型 ====== -->
  <constraint severity="blocker">启用 `<Nullable>enable</Nullable>`</constraint>
  <convention>清晰区分 `string` 和 `string?`</convention>
  <constraint severity="warning">不滥用 `!`（null-forgiving）</constraint>

  <!-- ====== async/await ====== -->
  <convention>IO 操作用 `async Task<T>`</convention>
  <constraint severity="blocker">不 `.Result` / `.Wait()`（死锁风险）</constraint>
  <convention>`ConfigureAwait(false)` 在库代码（ASP.NET Core 后不必要）</convention>
  <convention>`CancellationToken` 传递取消</convention>
  <constraint severity="blocker">`async void` 仅用于事件处理器</constraint>

  <!-- ====== 记录类型 ====== -->
  <convention>`record` 用于不可变数据：`record User(int Id, string Name);`</convention>
  <convention>`record class` vs `record struct`：按值拷贝需求选择</convention>
  <convention>`with` 表达式派生新实例</convention>

  <!-- ====== LINQ ====== -->
  <convention>可读性 > 一行化</convention>
  <convention>复杂查询拆分为多个步骤</convention>
  <convention>`ToList()` / `ToArray()` 实体化时机注意（延迟执行）</convention>
  <convention>IQueryable vs IEnumerable：数据库查询用 IQueryable</convention>

  <!-- ====== 集合 ====== -->
  <convention>`List<T>` 默认</convention>
  <convention>`Dictionary<K,V>` 键值映射</convention>
  <convention>`HashSet<T>` 去重</convention>
  <convention>`ImmutableList<T>` / `IReadOnlyList<T>` 只读场景</convention>

  <!-- ====== 异常 ====== -->
  <constraint severity="blocker">具体异常类型</constraint>
  <constraint severity="blocker">不抛 `Exception` / `SystemException`</constraint>
  <constraint severity="blocker">`throw;` 保留原堆栈（不是 `throw ex;`）</constraint>
  <convention>`using` 语句或 `using` 声明释放资源（`IDisposable`）</convention>

  <!-- ====== 依赖注入 ====== -->
  <constraint severity="blocker">构造器注入 > 字段/属性注入</constraint>
  <convention>生命周期：`Transient` / `Scoped` / `Singleton` 按场景</convention>
  <constraint severity="blocker">不在 Singleton 中依赖 Scoped 服务</constraint>

  <!-- ====== 属性 ====== -->
  <convention>自动属性：`public string Name { get; init; }`</convention>
  <convention>`init` 替代 private set 实现不可变</convention>
  <convention>计算属性用 `=>` 表达式体</convention>

  <!-- ====== 模式匹配 ====== -->
  <convention>`switch` 表达式：</convention>
  <pattern>

```csharp
var result = shape switch {
    Circle c => Math.PI * c.Radius * c.Radius,
    Square s => s.Side * s.Side,
    _ => throw new ArgumentException()
};
```

  </pattern>
  <convention>`is` 模式：`if (obj is User user) { ... }`</convention>

  <!-- ====== 工具 ====== -->
  <convention>EditorConfig 统一格式</convention>
  <convention>StyleCop / Roslynator 代码分析</convention>
  <convention>dotnet format 自动修复</convention>
  <convention>`<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`</convention>

  <!-- ====== 测试 ====== -->
  <convention>xUnit / NUnit / MSTest（项目选一）</convention>
  <convention>Moq / NSubstitute 做 mock</convention>
  <convention>`[Theory]` + `[InlineData]` 参数化</convention>

  <!-- ====== 反模式 ====== -->
  <constraint severity="blocker">`.Result` 阻塞异步</constraint>
  <constraint severity="blocker">捕获 `Exception` 吞异常</constraint>
  <constraint severity="blocker">`static` 可变状态（并发风险）</constraint>
  <constraint severity="warning">DTO 继承 Entity（职责混淆）</constraint>

</rule>
