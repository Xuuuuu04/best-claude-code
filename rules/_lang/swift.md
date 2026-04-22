---
paths:
  - "**/*.swift"
---

# Swift 编码规范

## 版本

- Swift 5.9+（支持 macro、new concurrency）
- Xcode 最新稳定版

## 命名

- 类型（class/struct/enum/protocol）：`PascalCase`
- 变量、函数、方法：`camelCase`
- 常量：`camelCase`（不用 `SHOUTY_CASE`）
- Protocol：描述能力用 `-able` / `-ible`（`Equatable`）；描述角色用名词（`Collection`）

## 值类型优先

- **struct > class**：优先值类型
- class 用于：需要引用语义、继承、`deinit`
- 避免 `NSObject` 子类除非必要

## Optional

- **避免** force unwrap（`!`）：只在 100% 确定非空时
- 优先：
  - `if let` / `guard let`
  - 可选链 `?.`
  - 空值合并 `??`
- Implicitly unwrapped optional（`Type!`）仅在 @IBOutlet 等场景

## 错误处理

- `throws` 函数配合 `try` / `try?` / `try!`
- `try!` 仅在 100% 确定不会失败
- 自定义错误 `enum` 实现 `Error`：
  ```swift
  enum NetworkError: Error {
      case timeout
      case invalidResponse(Int)
  }
  ```
- `do-catch` 精确匹配（模式匹配）

## 并发

- **Swift Concurrency**（async/await、actor、Task）优先于 GCD
- `@MainActor` 标注 UI 代码
- `actor` 保护共享可变状态
- 取消：`Task.cancel()`，检查 `Task.isCancelled`
- `@Sendable` 闭包跨 actor 边界

## 内存管理

- ARC 不是万能：警惕循环引用
  - `weak self` 在闭包捕获 self 时
  - `[weak self] in ... guard let self = self else { return }`
- `deinit` 释放非 ARC 资源（Core Foundation 对象等）

## 访问控制

- 最小公开：默认 `internal`，尽量 `private`
- `public` 只给明确的 API 边界
- `open` 仅当允许外部继承/重写

## SwiftUI

- 单一数据源：`@State`（局部）、`@StateObject`（创建）、`@ObservedObject`（传入）、`@EnvironmentObject`（跨层）
- 视图小而专：避免 100+ 行的 View
- `@ViewBuilder` 函数用于条件组合
- `.task` 用于异步副作用（自动取消）

## UIKit

- Auto Layout 优先，避免硬编码 frame
- `@IBOutlet weak var` 避免循环
- `prepareForReuse` 清理 cell 状态
- 避免大 ViewController（拆分为 child controller / view）

## 测试

- XCTest
- `@MainActor` 标注需要主线程的测试
- 使用 `XCTExpectFailure` 标注已知失败（临时）

## 通用

- `guard` 早返：减少嵌套
- `extension` 用于组织代码（按 protocol 拆分）
- `Codable` 处理 JSON
- `Result<Success, Failure>` 用于可失败操作的返回值

## 性能

- 大数组操作警惕 O(n²)
- Value type 传递大对象用 `inout` 或引用包装
- `lazy` 属性延迟初始化
- 避免在 ViewDidLoad 做耗时操作（用 async）

## 安全

- 敏感数据用 Keychain
- 不存储明文密码
- HTTPS 强制（App Transport Security）
- `NSAllowsArbitraryLoads` 不允许（或明确说明为什么）
