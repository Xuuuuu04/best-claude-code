---
paths:
  - "**/*.scala"
  - "**/*.sbt"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>Scala 3 新项目，Scala 2.13 稳定项目</requirement>
  <convention>项目内统一版本</convention>

  <!-- ====== 命名 ====== -->
  <convention>类、trait、object：`PascalCase`</convention>
  <convention>方法、变量：`camelCase`</convention>
  <convention>常量：`UPPER_SNAKE_CASE` 或 `PascalCase`</convention>
  <convention>包名：全小写</convention>

  <!-- ====== 不可变优先 ====== -->
  <convention>`val` > `var`（`var` 仅在有充分理由）</convention>
  <convention>不可变集合：`List` / `Vector` / `Map`（默认）</convention>
  <convention>`case class` 数据类天然不可变</convention>

  <!-- ====== 函数式风格 ====== -->
  <convention>`map` / `filter` / `foldLeft` 替代可变循环</convention>
  <convention>`Option[T]` 替代 `null`</convention>
  <convention>`Either[E, T]` / `Try[T]` 处理可能失败</convention>
  <convention>纯函数优先（无副作用）</convention>

  <!-- ====== Pattern Matching ====== -->
  <convention>`match` 表达式大量使用</convention>
  <convention>Exhaustive matching：使用 `sealed trait` + case class 让编译器检查穷尽性</convention>
  <pattern>

```scala
sealed trait Result
case class Success(value: String) extends Result
case class Failure(error: Throwable) extends Result

def handle(r: Result) = r match
  case Success(v) => println(v)
  case Failure(e) => e.printStackTrace()
```

  </pattern>

  <!-- ====== Option 处理 ====== -->
  <convention>`Option#map` / `flatMap` 链式处理</convention>
  <convention>`Option#getOrElse(default)` 提供默认</convention>
  <constraint severity="blocker">避免 `.get`（可能抛 NoSuchElementException）</constraint>

  <!-- ====== For Comprehension ====== -->
  <convention>链式 monad 操作可读性提升：</convention>
  <pattern>

```scala
for
  user <- findUser(id)
  profile <- user.profile
  photo <- profile.photo
yield photo.url
```

  </pattern>

  <!-- ====== 隐式（implicit / given） ====== -->
  <convention>Scala 3: `given` / `using`（更明确）</convention>
  <convention>Scala 2: `implicit`</convention>
  <constraint severity="warning">谨慎使用：隐式转换难追踪</constraint>
  <convention>类型类模式（type class）常见</convention>

  <!-- ====== 并发 ====== -->
  <convention>`Future[T]` + ExecutionContext</convention>
  <constraint severity="blocker">`Await.result` 仅测试 / 程序末端</constraint>
  <convention>ZIO / Cats Effect / Akka 高级并发框架（按项目）</convention>

  <!-- ====== 集合操作 ====== -->
  <convention>视图 `.view` 延迟求值大集合</convention>
  <convention>`par` 并行集合（Scala 2）/ 或 Future 并行</convention>
  <convention>高频操作优化：`Vector` 随机访问；`List` head 操作</convention>

  <!-- ====== 错误处理 ====== -->
  <convention>`Try { ... }` 包装可抛异常的代码</convention>
  <convention>`Either[Error, Value]` 纯函数式错误</convention>
  <constraint severity="warning">不 `throw` 作为正常控制流</constraint>

  <!-- ====== 工具 ====== -->
  <convention>sbt 或 Mill 构建</convention>
  <convention>Scalafmt 格式化</convention>
  <convention>Scalafix 自动重构</convention>
  <convention>WartRemover / ScalaStyle 代码质量</convention>

  <!-- ====== 测试 ====== -->
  <convention>ScalaTest / MUnit / Weaver</convention>
  <convention>Property-based：ScalaCheck</convention>

  <!-- ====== 反模式 ====== -->
  <constraint severity="blocker">`null` 使用</constraint>
  <constraint severity="blocker">未处理的 `Option.get` / `head`</constraint>
  <constraint severity="blocker">可变全局状态</constraint>
  <constraint severity="warning">过度使用 implicit 魔法</constraint>
  <constraint severity="warning">函数签名过于泛型（失去类型指导）</constraint>

</rule>
