---
paths:
  - "**/*.swift"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>Swift 5.9+（支持 macro、new concurrency）</requirement>
  <convention>Xcode 最新稳定版</convention>

  <!-- ====== 命名 ====== -->
  <convention>类型（class/struct/enum/protocol）：`PascalCase`</convention>
  <convention>变量、函数、方法：`camelCase`</convention>
  <convention>常量：`camelCase`（不用 `SHOUTY_CASE`）</convention>
  <convention>Protocol：描述能力用 `-able` / `-ible`（`Equatable`）；描述角色用名词（`Collection`）</convention>

  <!-- ====== 值类型优先 ====== -->
  <constraint severity="warning">struct > class：优先值类型</constraint>
  <convention>class 用于：需要引用语义、继承、`deinit`</convention>
  <convention>避免 `NSObject` 子类除非必要</convention>

  <!-- ====== Optional ====== -->
  <constraint severity="blocker">避免 force unwrap（`!`）：只在 100% 确定非空时</constraint>
  <convention>优先：`if let` / `guard let`、可选链 `?.`、空值合并 `??`</convention>
  <convention>Implicitly unwrapped optional（`Type!`）仅在 @IBOutlet 等场景</convention>

  <!-- ====== 错误处理 ====== -->
  <convention>`throws` 函数配合 `try` / `try?` / `try!`</convention>
  <constraint severity="blocker">`try!` 仅在 100% 确定不会失败</constraint>
  <convention>自定义错误 `enum` 实现 `Error`：</convention>
  <pattern>

```swift
enum NetworkError: Error {
    case timeout
    case invalidResponse(Int)
}
```

  </pattern>
  <convention>`do-catch` 精确匹配（模式匹配）</convention>

  <!-- ====== 并发 ====== -->
  <constraint severity="warning">Swift Concurrency（async/await、actor、Task）优先于 GCD</constraint>
  <constraint severity="blocker">`@MainActor` 标注 UI 代码</constraint>
  <convention>`actor` 保护共享可变状态</convention>
  <convention>取消：`Task.cancel()`，检查 `Task.isCancelled`</convention>
  <convention>`@Sendable` 闭包跨 actor 边界</convention>

  <!-- ====== 内存管理 ====== -->
  <constraint severity="blocker">ARC 不是万能：警惕循环引用
  - `weak self` 在闭包捕获 self 时
  - `[weak self] in ... guard let self = self else { return }`</constraint>
  <convention>`deinit` 释放非 ARC 资源（Core Foundation 对象等）</convention>

  <!-- ====== 访问控制 ====== -->
  <convention>最小公开：默认 `internal`，尽量 `private`</convention>
  <convention>`public` 只给明确的 API 边界</convention>
  <convention>`open` 仅当允许外部继承/重写</convention>

  <!-- ====== SwiftUI ====== -->
  <convention>单一数据源：`@State`（局部）、`@StateObject`（创建）、`@ObservedObject`（传入）、`@EnvironmentObject`（跨层）</convention>
  <convention>视图小而专：避免 100+ 行的 View</convention>
  <convention>`@ViewBuilder` 函数用于条件组合</convention>
  <convention>`.task` 用于异步副作用（自动取消）</convention>

  <!-- ====== UIKit ====== -->
  <convention>Auto Layout 优先，避免硬编码 frame</convention>
  <convention>`@IBOutlet weak var` 避免循环</convention>
  <convention>`prepareForReuse` 清理 cell 状态</convention>
  <convention>避免大 ViewController（拆分为 child controller / view）</convention>

  <!-- ====== 测试 ====== -->
  <convention>XCTest</convention>
  <convention>`@MainActor` 标注需要主线程的测试</convention>
  <convention>使用 `XCTExpectFailure` 标注已知失败（临时）</convention>

  <!-- ====== 通用 ====== -->
  <convention>`guard` 早返：减少嵌套</convention>
  <convention>`extension` 用于组织代码（按 protocol 拆分）</convention>
  <convention>`Codable` 处理 JSON</convention>
  <convention>`Result<Success, Failure>` 用于可失败操作的返回值</convention>

  <!-- ====== 性能 ====== -->
  <constraint severity="warning">大数组操作警惕 O(n2)</constraint>
  <convention>Value type 传递大对象用 `inout` 或引用包装</convention>
  <convention>`lazy` 属性延迟初始化</convention>
  <convention>避免在 ViewDidLoad 做耗时操作（用 async）</convention>

  <!-- ====== 安全 ====== -->
  <constraint severity="blocker">敏感数据用 Keychain</constraint>
  <constraint severity="blocker">不存储明文密码</constraint>
  <constraint severity="blocker">HTTPS 强制（App Transport Security）</constraint>
  <constraint severity="blocker">`NSAllowsArbitraryLoads` 不允许（或明确说明为什么）</constraint>

</rule>
