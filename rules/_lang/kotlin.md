---
paths:
  - "**/*.kt"
  - "**/*.kts"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>Kotlin 1.9+ / 2.0+（新特性：K2 编译器、数据类改进）</requirement>

  <!-- ====== 命名 ====== -->
  <convention>类、对象：`PascalCase`</convention>
  <convention>函数、变量：`camelCase`</convention>
  <convention>常量：`UPPER_SNAKE_CASE`</convention>
  <convention>包名：小写 `com.example`</convention>

  <!-- ====== 空安全 ====== -->
  <constraint severity="blocker">不 `!!`（非空断言）除非 100% 确定</constraint>
  <convention>`?.` 可选链、`?:` Elvis、`let` / `also`</convention>
  <convention>`lateinit` vs `by lazy`：按语义选</convention>
  <constraint severity="warning">平台类型（从 Java 来的）：显式标注</constraint>

  <!-- ====== 不可变优先 ====== -->
  <convention>`val` 优先于 `var`</convention>
  <convention>`List` 而非 `MutableList`（除非需要修改）</convention>
  <convention>`data class` 的 `copy` 而非修改</convention>

  <!-- ====== 作用域函数 ====== -->
  <convention>`let`：可空对象 + 转换</convention>
  <convention>`also`：副作用 + 返回 this</convention>
  <convention>`apply`：配置对象</convention>
  <convention>`run`：执行块返回值</convention>
  <convention>`with`：非扩展版的 run</convention>
  <constraint severity="warning">避免嵌套作用域函数（可读性下降）</constraint>

  <!-- ====== 协程 ====== -->
  <convention>`suspend` 函数 + 结构化并发</convention>
  <convention>`CoroutineScope` 绑定生命周期</convention>
  <convention>`viewModelScope` / `lifecycleScope`（Android）</convention>
  <convention>`withContext(Dispatchers.IO)` 切换线程</convention>
  <convention>Flow 用于流式数据</convention>

  <!-- ====== 错误处理 ====== -->
  <convention>异常：与 Java 类似</convention>
  <convention>`Result<T>` 或 sealed class 建模可失败操作</convention>
  <convention>`runCatching { }` 捕获所有异常</convention>

  <!-- ====== 函数 ====== -->
  <convention>默认参数替代重载</convention>
  <convention>单表达式函数：`fun double(x: Int) = x * 2`</convention>
  <convention>顶层函数允许（不强求类包装）</convention>
  <convention>扩展函数：合理使用（避免滥用污染标准类型）</convention>

  <!-- ====== Sealed & Enum ====== -->
  <convention>`sealed class` / `sealed interface` 封闭类型层次（when 穷尽）</convention>
  <convention>`enum` 用于简单枚举</convention>
  <convention>`object` 用于单例、伴生对象</convention>

  <!-- ====== Android 专项 ====== -->
  <convention>ViewModel + StateFlow / SharedFlow</convention>
  <convention>Jetpack Compose：`remember`、`LaunchedEffect`</convention>
  <constraint severity="blocker">不在 ViewModel 持有 Context / View</constraint>

  <!-- ====== 测试 ====== -->
  <convention>JUnit 5 / Kotest</convention>
  <convention>MockK（Kotlin 友好的 mock）</convention>
  <convention>协程测试用 `runTest` + `TestDispatcher`</convention>

  <!-- ====== 工具 ====== -->
  <convention>ktlint / detekt</convention>
  <convention>ktfmt 格式化</convention>

</rule>
