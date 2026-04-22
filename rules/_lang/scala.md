---
paths:
  - "**/*.scala"
  - "**/*.sbt"
---

# Scala 编码规范

## 版本
- Scala 3 新项目，Scala 2.13 稳定项目
- 项目内统一版本

## 命名
- 类、trait、object：`PascalCase`
- 方法、变量：`camelCase`
- 常量：`UPPER_SNAKE_CASE` 或 `PascalCase`
- 包名：全小写

## 不可变优先
- `val` > `var`（`var` 仅在有充分理由）
- 不可变集合：`List` / `Vector` / `Map`（默认）
- `case class` 数据类天然不可变

## 函数式风格
- `map` / `filter` / `foldLeft` 替代可变循环
- `Option[T]` 替代 `null`
- `Either[E, T]` / `Try[T]` 处理可能失败
- 纯函数优先（无副作用）

## Pattern Matching
- `match` 表达式大量使用
- Exhaustive matching：使用 `sealed trait` + case class 让编译器检查穷尽性
  ```scala
  sealed trait Result
  case class Success(value: String) extends Result
  case class Failure(error: Throwable) extends Result
  
  def handle(r: Result) = r match
    case Success(v) => println(v)
    case Failure(e) => e.printStackTrace()
  ```

## Option 处理
- `Option#map` / `flatMap` 链式处理
- `Option#getOrElse(default)` 提供默认
- 避免 `.get`（可能抛 NoSuchElementException）

## For Comprehension
- 链式 monad 操作可读性提升：
  ```scala
  for
    user <- findUser(id)
    profile <- user.profile
    photo <- profile.photo
  yield photo.url
  ```

## 隐式（implicit / given）
- Scala 3: `given` / `using`（更明确）
- Scala 2: `implicit`
- 谨慎使用：隐式转换难追踪
- 类型类模式（type class）常见

## 并发
- `Future[T]` + ExecutionContext
- `Await.result` 仅测试 / 程序末端
- ZIO / Cats Effect / Akka 高级并发框架（按项目）

## 集合操作
- 视图 `.view` 延迟求值大集合
- `par` 并行集合（Scala 2）/ 或 Future 并行
- 高频操作优化：`Vector` 随机访问；`List` head 操作

## 错误处理
- `Try { ... }` 包装可抛异常的代码
- `Either[Error, Value]` 纯函数式错误
- 不 `throw` 作为正常控制流

## 工具
- sbt 或 Mill 构建
- Scalafmt 格式化
- Scalafix 自动重构
- WartRemover / ScalaStyle 代码质量

## 测试
- ScalaTest / MUnit / Weaver
- Property-based：ScalaCheck

## 反模式
- `null` 使用
- 未处理的 `Option.get` / `head`
- 可变全局状态
- 过度使用 implicit 魔法
- 函数签名过于泛型（失去类型指导）
