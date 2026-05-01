---
name: cangjie-language
description: 仓颉语言开发专家。覆盖类型系统、语法、并发、网络、宏、C互操作、标准库、扩展库、编译构建的完整知识。Use proactively for 仓颉/CangJie 开发、仓颉代码审查、仓颉项目架构设计。
when_to_use: 当用户提到仓颉/CangJie、仓颉代码、仓颉项目、cjpm 或华为自研编程语言时自动加载。
---

# 仓颉语言开发专家

## 语言速查

### 类型系统

| 类型 | 值/引用 | 关键特性 |
|:--|:--|:--|
| `struct` | 值类型（传参复制） | 不支持继承，轻量数据 |
| `class` | 引用类型 | 单继承（Object），OOP |
| `enum` | ADT | 代数数据类型，支持递归 |
| `interface` | — | 多继承，所有类型默认实现 Any |
| `Option<T>` | — | Some/None，空值安全，替代 null |

基础类型：`Int8-64/UInt8-64/IntNative/UIntNative` `Float16-64` `Bool` `Rune` `String` `Array<T>` `Tuple` `Range` `Unit` `Nothing`

### 并发
- M:N 用户态轻量级线程（原生协程），抢占式调度
- `spawn { ... }` 启动协程，返回 `Future<T>`
- `Atomic<T>` `Mutex<T>` `synchronized` `Condition` `ThreadLocal`

### 关键语法
- 插值字符串：`"hello ${name}"`
- 主构造函数：`class Foo(prop: Type) { ... }`
- 模式匹配：`match (x) { case pattern => expr }`
- 尾随 lambda、操作符重载、函数一等公民
- 宏系统：词法宏（macro package），编译时代码变换

### C 互操作
- `foreign func` / `@C` 声明外部 C 函数
- `CPointer<T>` `CString` `VArray<T>` `CFunc`
- `inout` 参数修饰符对应 C 指针语义
- `unsafe` 块包裹所有 FFI 调用

### 网络
- TCP/UDP/UnixDomain Socket（`net/socket.md`）
- HTTP 1.0/2.0 Client（`net/net_http.md`）
- WebSocket（`net/net_websocket.md`）
- TLS 支持

### 编译构建
- `cjc` 编译器，支持优化/LTO/PGO/交叉编译/条件编译
- `cjpm` 包管理器

### 标准库（std）
30+ 模块：`std/collection` `std/io` `std/fs` `std/os` `std/math` `std/time` `std/json` `std/regex` 等

### 扩展库（stdx）
`crypto` `encoding` `net` `compression` `logger` `serialization` `fuzz` `aspectCJ` `log` 等

## 完整参考

详细文档位于 `/Users/mumuxsy/Desktop/文档资料/cangJie_docs/`：
- `user_manual/` — 22 个子目录的完整语言手册
- `libs/` — 标准库文档
- `libs_stdx/` — 扩展库文档

知识点结构化摘要：`/tmp/cangjie-knowledge.md`（400 行，12 个知识域）

## 开发铁律

1. 空值用 `Option<T>` 的 Some/None 而非 null
2. 网络/IO 用协程 `spawn` 而非系统线程
3. FFI 必须 `unsafe` 包裹，`CPointer` 使用后手动管理生命周期
4. struct 赋值即复制，class 赋值共享引用——注意选择正确的类型形态
5. 模式匹配必须穷尽，否则编译错误
