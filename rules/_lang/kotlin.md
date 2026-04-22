---
paths:
  - "**/*.kt"
  - "**/*.kts"
---

# Kotlin 编码规范

## 版本
- Kotlin 1.9+ / 2.0+（新特性：K2 编译器、数据类改进）

## 命名
- 类、对象：`PascalCase`
- 函数、变量：`camelCase`
- 常量：`UPPER_SNAKE_CASE`
- 包名：小写 `com.example`

## 空安全
- **不 `!!`**（非空断言）除非 100% 确定
- `?.` 可选链、`?:` Elvis、`let` / `also`
- `lateinit` vs `by lazy`：按语义选
- 平台类型（从 Java 来的）：显式标注

## 不可变优先
- `val` 优先于 `var`
- `List` 而非 `MutableList`（除非需要修改）
- `data class` 的 `copy` 而非修改

## 作用域函数
- `let`：可空对象 + 转换
- `also`：副作用 + 返回 this
- `apply`：配置对象
- `run`：执行块返回值
- `with`：非扩展版的 run

避免嵌套作用域函数（可读性下降）。

## 协程
- `suspend` 函数 + 结构化并发
- `CoroutineScope` 绑定生命周期
- `viewModelScope` / `lifecycleScope`（Android）
- `withContext(Dispatchers.IO)` 切换线程
- Flow 用于流式数据

## 错误处理
- 异常：与 Java 类似
- `Result<T>` 或 sealed class 建模可失败操作
- `runCatching { }` 捕获所有异常

## 函数
- 默认参数替代重载
- 单表达式函数：`fun double(x: Int) = x * 2`
- 顶层函数允许（不强求类包装）
- 扩展函数：合理使用（避免滥用污染标准类型）

## Sealed & Enum
- `sealed class` / `sealed interface` 封闭类型层次（when 穷尽）
- `enum` 用于简单枚举
- `object` 用于单例、伴生对象

## Android 专项
- ViewModel + StateFlow / SharedFlow
- Jetpack Compose：`remember`、`LaunchedEffect`
- 不在 ViewModel 持有 Context / View

## 测试
- JUnit 5 / Kotest
- MockK（Kotlin 友好的 mock）
- 协程测试用 `runTest` + `TestDispatcher`

## 工具
- ktlint / detekt
- ktfmt 格式化
