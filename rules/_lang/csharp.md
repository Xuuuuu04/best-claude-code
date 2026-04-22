---
paths:
  - "**/*.cs"
  - "**/*.csproj"
---

# C# / .NET 编码规范

## 版本
- .NET 8 LTS 或更新
- C# 12+ 特性（collection expressions、primary constructors）

## 命名
- 类、接口、枚举、方法、属性：`PascalCase`
- 接口前缀 `I`：`IUserRepository`
- 私有字段：`_camelCase` 或 `camelCase`
- 参数、局部变量：`camelCase`
- 常量：`PascalCase`（现代）或 `UPPER_SNAKE_CASE`（老代码）

## 可空引用类型
- **启用** `<Nullable>enable</Nullable>`
- 清晰区分 `string` 和 `string?`
- 不滥用 `!`（null-forgiving）

## async/await
- IO 操作用 `async Task<T>`
- 不 `.Result` / `.Wait()`（死锁风险）
- `ConfigureAwait(false)` 在库代码（ASP.NET Core 后不必要）
- `CancellationToken` 传递取消
- `async void` 仅用于事件处理器

## 记录类型
- `record` 用于不可变数据：`record User(int Id, string Name);`
- `record class` vs `record struct`：按值拷贝需求选择
- `with` 表达式派生新实例

## LINQ
- 可读性 > 一行化
- 复杂查询拆分为多个步骤
- `ToList()` / `ToArray()` 实体化时机注意（延迟执行）
- IQueryable vs IEnumerable：数据库查询用 IQueryable

## 集合
- `List<T>` 默认
- `Dictionary<K,V>` 键值映射
- `HashSet<T>` 去重
- `ImmutableList<T>` / `IReadOnlyList<T>` 只读场景

## 异常
- 具体异常类型
- 不抛 `Exception` / `SystemException`
- `throw;` 保留原堆栈（不是 `throw ex;`）
- `using` 语句或 `using` 声明释放资源（`IDisposable`）

## 依赖注入
- 构造器注入 > 字段/属性注入
- 生命周期：`Transient` / `Scoped` / `Singleton` 按场景
- 不在 Singleton 中依赖 Scoped 服务

## 属性
- 自动属性：`public string Name { get; init; }`
- `init` 替代 private set 实现不可变
- 计算属性用 `=>` 表达式体

## 模式匹配
- `switch` 表达式：
  ```csharp
  var result = shape switch {
      Circle c => Math.PI * c.Radius * c.Radius,
      Square s => s.Side * s.Side,
      _ => throw new ArgumentException()
  };
  ```
- `is` 模式：`if (obj is User user) { ... }`

## 工具
- EditorConfig 统一格式
- StyleCop / Roslynator 代码分析
- dotnet format 自动修复
- `<TreatWarningsAsErrors>true</TreatWarningsAsErrors>`

## 测试
- xUnit / NUnit / MSTest（项目选一）
- Moq / NSubstitute 做 mock
- `[Theory]` + `[InlineData]` 参数化

## 反模式
- `.Result` 阻塞异步
- 捕获 `Exception` 吞异常
- `static` 可变状态（并发风险）
- DTO 继承 Entity（职责混淆）
