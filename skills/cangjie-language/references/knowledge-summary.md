# 仓颉编程语言 — 知识点结构化摘要

**资料来源**：`/Users/mumuxsy/Desktop/文档资料/cangJie_docs/`
**生成时间**：2026-05-01
**状态**：draft（仅提取关键概念和文档索引，非全文复制）

---

## 一、语言概述

仓颉（CangJie）是面向全场景应用开发的通用编程语言，由华为推出。

| 特性 | 说明 |
|:--|:--|
| 后端 | CJNative（编译为原生二进制）、CJVM（字节码/VM，未发布） |
| 范式 | 函数式 + 命令式 + 面向对象，多范式融合 |
| 类型系统 | 静态强类型 + 编译时类型推断 |
| 内存管理 | 自动内存管理（GC），运行时数组越界检查、溢出检查 |
| 并发模型 | M:N 用户态轻量级线程（原生协程），抢占式调度 |
| 互操作 | 与 C 语言双向互操作（FFI） |
| 元编程 | 基于词法宏的编译时代码变换 |
| 语法亮点 | 插值字符串、主构造函数、Flow 表达式、match、尾随 lambda、属性、操作符重载 |

**参考文档**：`user_manual/first_understanding/basic.md`

---

## 二、类型系统

### 2.1 基础类型

| 仓颉类型 | 说明 | 参考文件 |
|:--|:--|:--|
| `Unit` | 空类型，类似 void | `basic_data_type/unit.md` |
| `Bool` | 布尔型，true/false | `basic_data_type/bool.md` |
| `Int8/16/32/64` | 有符号整数 | `basic_data_type/integer.md` |
| `UInt8/16/32/64` | 无符号整数 | `basic_data_type/integer.md` |
| `IntNative/UIntNative` | 平台相关整数（对应 ssize_t/size_t） | `basic_data_type/integer.md` |
| `Float16/32/64` | 浮点数 | — |
| `Rune` | Unicode 字符（类似 rune） | `basic_data_type/characters.md` |
| `String` | 字符串，支持插值 `${}` | `basic_data_type/strings.md` |
| `Nothing` | 底部类型，无值，用于永不返回的函数 | `basic_data_type/nothing.md` |
| `Range` | 范围类型（`0..100`） | `basic_data_type/range.md` |
| `Tuple (T1, T2, ...)` | 至少二元，不可变，固定长度，支持下标访问 | `basic_data_type/tuple.md` |
| `Array<T>` | 固定长度数组，元素可变 | `basic_data_type/array.md` |

### 2.2 复合类型

| 类型 | 值/引用 | 继承 | 用途 | 参考文件 |
|:--|:--|:--|:--|:--|
| `struct` | 值类型（赋值/传参时复制） | 不支持继承 | 轻量数据结构 | `struct/define_struct.md` |
| `class` | 引用类型（赋值/传参共享） | 单继承，所有类最终继承 `Object` | 面向对象编程 | `class_and_interface/class.md` |
| `enum` | — | — | 代数数据类型（ADT），支持递归定义 | `enum_and_pattern_match/enum.md` |
| `interface` | — | 可多继承接口 | 抽象行为定义 | `class_and_interface/interface.md` |

### 2.3 特殊类型

- **`Option<T>`** ：`Some(T) | None`，用于空值安全，替代 null。详见 `enum_and_pattern_match/option_type.md`
- **`Any`** ：内置接口，所有类型默认实现，所有接口默认继承。
- **`This`** ：类内部的类型占位符，代指当前类类型，用于返回 `This` 实现链式调用或协变返回。

---

## 三、核心语法特性

### 3.1 函数

- **一等公民**：函数可作为参数、返回值、赋值给变量。函数类型：`(T1, T2) -> R`
- **Lambda 表达式**：`{ a: Int64, b: Int64 => a + b }`，参数类型可省略（类型推断），不支持声明返回类型
- **尾随 lambda**：最后一个实参为 lambda 时可放在 `()` 外
- **闭包**：Lambda 可捕获外部变量
- **嵌套函数**：函数内可定义函数
- **函数重载**：同名函数不同参数列表（数量或类型不同）
- **操作符重载**：`operator func +(other: T): T`
- **const 函数**：编译期求值函数
- **命名参数**：`func f(a!: Int32)` 调用时 `f(a: 10)`

参考：`function/` 目录下所有文件。

### 3.2 主构造函数

```cangjie
struct Rectangle {
    public Rectangle(let width: Int64, let height: Int64) {}
}
// 等价于声明 width/height 两个成员变量 + 构造函数
```

支持于 `struct` 和 `class`。`let` 声明不可变成员，`var` 声明可变成员。

### 3.3 模式匹配

`match` 表达式（两种形式）：
- **含匹配值**：`match (x) { case 1 => ... case _ => ... }`，穷尽性校验
- **无匹配值**：`match { case x > 0 => ... case _ => ... }`

支持模式：常量、通配符（`_`）、绑定（`id`）、Tuple、类型（`id: Type`）、enum（`Some(x)`），以及 `pattern guard`（`where cond`）。

参考：`enum_and_pattern_match/pattern_overview.md`

### 3.4 错误处理

- 异常层次：`Error`（系统/资源错误，不可手动 throw）和 `Exception`（逻辑/IO 错误）
- `try-catch-finally` 表达式有类型（除 finally 外各分支的最小公共父类型）
- `Option<T>` 类型用于可恢复的"无值"场景

参考：`error_handle/` 目录。

### 3.5 面向对象

- **类继承**：`class B <: A`，单继承。`open` 修饰允许继承，`sealed` 限制包内继承
- **抽象类**：`abstract class`，含抽象函数
- **重写**：`override func`（实例函数，动态派发），`redef static func`（静态函数）
- **接口**：`class C <: I1 & I2`，支持多实现和默认实现
- **属性**：`prop` 关键字定义成员属性
- **终结器**：`~init()` 在 GC 回收时调用，有限制条件

### 3.6 泛型

function、class、interface、struct、enum 均可泛型化。支持约束：`where T <: SomeInterface`。

类型别名：`typealias`。

参考：`generic/` 目录下所有文件。

### 3.7 扩展（Extension）

为已有类型（除函数、元组、接口外）添加：
- 成员函数、操作符重载函数、成员属性、接口实现

限制：不能增加成员变量，不能使用 `open/override/redef`，不能访问 `private` 成员。

两种形式：直接扩展（无接口）、接口扩展（含接口）。

参考：`extension/` 目录。

---

## 四、并发编程

### 线程模型
- M:N 用户态轻量级线程（仓颉线程），底层由 native 线程调度
- 抢占式调度

### 创建线程
`spawn { ... }` 返回 `Future<T>`。通过 `Future.get()` 获取结果或等待完成。

### 同步机制

| 机制 | 说明 |
|:--|:--|
| `AtomicInt*` / `AtomicUInt*` | 整数原子操作（load/store/swap/CAS/fetchAdd...） |
| `AtomicBool` / `AtomicReference` | 布尔/引用原子操作（仅读写和 CAS） |
| `Mutex` | 可重入互斥锁（lock/unlock/tryLock） |
| `synchronized(mtx) { }` | 自动加锁/解锁作用域（含异常安全） |
| `Condition` | 条件变量（wait/notify/notifyAll/waitUntil） |
| `ThreadLocal<T>` | 线程局部变量 |
| `sleep(Duration)` | 线程休眠 |

### 阻塞式 I/O 注意事项
网络编程是阻塞式的，但被阻塞的是仓颉线程（会将系统线程让渡），不会真正阻塞系统线程。跨语言调用 foreign 函数中阻塞的系统调用会阻塞 native 线程，降低吞吐。

参考：`concurrency/` 目录。

---

## 五、网络编程

### 分层
- **传输层**：`std.socket` — `DatagramSocket`（UDP）、`StreamSocket`（TCP）、`UnixDomain`
- **应用层**：`stdx.net.http` — HTTP/1.0、HTTP/1.1、HTTP/2.0
- **WebSocket**：`stdx.net.http`，支持 HTTP 协议升级
- **TLS**：`stdx.net.tls`

### 关键类型
`TcpSocket`、`UdpSocket`、`HttpRequest`/`HttpResponse`、`WebSocket`、`ClientBuilder`/`ServerBuilder`、`TlsClientConfig`/`TlsServerConfig`

参考：`user_manual/Net/` 目录。

---

## 六、宏（宏编程 / 元编程）

### 核心概念
- **宏包**：`macro package` 声明，宏只能定义在独立宏包中
- **Tokens**：宏的输入/输出类型，代表程序片段
- **quote 表达式**：`quote(...)` 构造 Tokens，使用 `$(...)` 插值
- **语法节点**：`std.ast` 包提供 AST 操作能力

### 两种宏
- **非属性宏**：`public macro name(input: Tokens): Tokens`
- **属性宏**：可作用于声明节点（类、函数、变量等）

### 编译
```bash
cjc macro_pkg/*.cj --compile-macro    # 编译宏包
cjc main.cj -o main                   # 编译使用宏的代码
```

编译选项：`--debug-macro`（查看宏展开）、`--parallel-macro-expansion`（并行展开）

参考：`user_manual/Macro/` 目录。

---

## 七、C 语言互操作（FFI）

### 仓颉调用 C

| 概念 | 说明 |
|:--|:--|
| `foreign func name(...)` | 声明外部 C 函数，无函数体 |
| `@C func name(...)` | 仓颉函数以 C 调用约定暴露 |
| `unsafe { ... }` | 调用 foreign/@C 函数必须包裹在 unsafe 块 |
| `CPointer<T>` | 对应 C 指针类型，支持 read/write/偏移/类型转换 |
| `CString` | 对应 C 字符串，提供 size/equals/compare/substr 等方法 |
| `VArray<T, $N>` | 对应 C 定长数组，作函数参数或 @C struct 成员 |
| `CFunc<T>` | 对应 C 函数指针类型，可从 CPointer 转换 |
| `CType` | 接口，所有 C 互操作类型的父类型，用于泛型约束 |
| `inout` | 引用传值表达式，调用 CFunc 时按引用传递变量 |
| `sizeOf<T>()` / `alignOf<T>()` | 获取 C 互操作类型大小/对齐 |

### 类型映射表

| 仓颉 | C | 字节 |
|:--|:--|:--|
| `Unit` | `void` | 0 |
| `Bool` | `bool` | 1 |
| `Int8/UInt8` | `int8_t/uint8_t` | 1 |
| `Int16/UInt16` | `int16_t/uint16_t` | 2 |
| `Int32/UInt32` | `int32_t/uint32_t` | 4 |
| `Int64/UInt64` | `int64_t/uint64_t` | 8 |
| `Float32/Float64` | `float/double` | 4/8 |

`@C struct` 对应 C 结构体。不支持柔性数组成员。

### 编译链接
```bash
cjc -L . -l mylib main.cj -o main
```

参考：`user_manual/FFI/cangjie-c.md`。

---

## 八、标准库（std）概览

**位置**：`libs/std/`

| 模块 | 功能 |
|:--|:--|
| `std.core` | 核心类型（Int64/String/Bool）、异常体系、基础接口（Any/ToString/Equatable/Comparable/Hashable） |
| `std.collection` | Array、ArrayList、HashSet、HashMap、Iterable |
| `std.collection_concurrent` | 并发集合 |
| `std.io` | 输入输出流 |
| `std.net` | 传输层网络（Socket） |
| `std.time` | 时间日期处理 |
| `std.convert` | 类型转换 |
| `std.math` / `std.math_numeric` | 数学/数值计算 |
| `std.sync` | 并发同步（Atomic/Mutex/Condition/ThreadLocal） |
| `std.fs` | 文件系统操作 |
| `std.process` | 进程管理 |
| `std.regex` | 正则表达式 |
| `std.crypto` | 基础加密 |
| `std.random` | 随机数生成 |
| `std.sort` | 排序算法 |
| `std.unicode` | Unicode 处理 |
| `std.unittest` | 单元测试框架（@Test/@TestCase/@Expect） |
| `std.reflect` | 反射 |
| `std.runtime` | 运行时（GC、栈大小等） |
| `std.database_sql` | SQL 数据库访问 |
| `std.ast` | AST 操作（供宏使用） |
| `std.argopt` | 命令行参数解析 |
| `std.binary` | 二进制数据处理 |
| `std.console` | 控制台 I/O |
| `std.env` | 环境变量 |
| `std.overflow` | 溢出控制 |
| `std.ref` | 引用类型工具 |

参考：`libs/CLAUDE.md`、`libs/index.md`。

---

## 九、扩展库（stdx）概览

**位置**：`libs_stdx/`
**依赖**：部分模块依赖 OpenSSL 3

| 包 | 功能 |
|:--|:--|
| `stdx.crypto.crypto` | SM4 对称加密、安全随机数 |
| `stdx.crypto.digest` | 消息摘要算法 |
| `stdx.crypto.keys` | 非对称加密和签名 |
| `stdx.crypto.x509` | 数字证书处理 |
| `stdx.encoding.base64` | Base64 编解码 |
| `stdx.encoding.hex` | Hex 编解码 |
| `stdx.encoding.json` | JSON 数据处理 |
| `stdx.encoding.json_stream` | JSON 流式处理 |
| `stdx.encoding.url` | URL 解析处理 |
| `stdx.net.http` | HTTP/1.1、HTTP/2、WebSocket |
| `stdx.net.tls` | TLS 安全传输 |
| `stdx.compress.zlib` | zlib 压缩解压 |
| `stdx.log` / `stdx.logger` | 结构化日志 |
| `stdx.fuzz` | 模糊测试引擎 |
| `stdx.serialization` | 序列化/反序列化 |
| `stdx.aspectCJ` | 面向切面编程 |
| `stdx.unittest` | 单元测试扩展 |

参考：`libs_stdx/CLAUDE.md`。

---

## 十、包管理与编译

### 包（package）
- 编译的最小单元，每个包独立输出 AST/静态库/动态库
- 每个包有独立命名空间，可含多个源文件
- `import pakcageName.*` 导入

### 模块（module）
- 若干包的集合，第三方发布的最小单元
- 顶层最多一个 `main` 作为程序入口

### 编译器 cjc

| 类别 | 关键选项 |
|:--|:--|
| 输出类型 | `--output-type=[exe\|staticlib\|dylib]` |
| 包编译 | `-p` / `--package` |
| 输出文件 | `-o` / `--output` |
| 优化级别 | `-O0`（默认）/ `-O1` / `-O2` / `-Os` / `-Oz` |
| 链接库 | `-L <path>` / `-l <name>` |
| 调试 | `-g` |
| 溢出策略 | `--int-overflow=[throwing\|wrapping\|saturating]` |
| 交叉编译 | `--target <triple>` |
| LTO | `--lto=[full\|thin]`（仅 Linux） |
| PGO | `--pgo-instr-gen` / `--pgo-instr-use` |
| 并行 | `--jobs <N>` / `--aggressive-parallel-compile` |
| 混淆 | `--fobf-string/const/layout/cf-flatten/cf-bogus` |
| 安全 | `--trimpath` / `--strip-all` / `--link-options` |
| 条件编译 | `--cfg "key=value"` |
| 宏 | `--compile-macro` / `--debug-macro` |
| 测试 | `--test` / `--test-only` / `--mock` |
| 覆盖率 | `--coverage` / `--sanitizer-coverage-*` |
| 实验性 | `--experimental` |

### cjpm（包管理器）
- 类似 npm/cargo 的仓颉包管理工具
- 支持 OpenHarmony 平台

### 条件编译
使用 `@When[condition]` 注解，内置条件变量：`os`（Windows/Linux/macOS）、`backend`（cjnative/cjvm）、`arch`（x86_64/aarch64）、`cjc_version`、`debug`、`test`。支持自定义变量和逻辑组合。

参考：`user_manual/compile_and_build/`、`user_manual/Appendix/compile_options.md`（cjc 编译选项完整文档）。

---

## 十一、文档目录索引

### user_manual/ 完整目录

| 目录 | 内容 |
|:--|:--|
| `first_understanding/` | 初识仓颉、Hello World、环境安装 |
| `basic_data_type/` | Unit, Int, Float, Bool, String, Rune, Tuple, Array, Range, Nothing |
| `basic_programming_concepts/` | 标识符、表达式、函数基础 |
| `function/` | 函数定义、调用、重载、一等公民、闭包、Lambda、操作符重载、const 函数 |
| `struct/` | struct 定义、实例创建、mut |
| `class_and_interface/` | class、interface、属性、子类型、类型转换 |
| `enum_and_pattern_match/` | enum、Option、match、各类模式 |
| `generic/` | 泛型函数/类/接口/struct/enum、约束、子类型、类型别名 |
| `extension/` | 直接扩展、接口扩展、访问规则 |
| `collections/` | Array、ArrayList、HashSet、HashMap、Iterable |
| `package/` | 包概述、包名、导入、顶层访问控制、程序入口 |
| `error_handle/` | 异常定义、throw/try-catch、Option 使用、常见运行时异常 |
| `concurrency/` | 线程概述、创建线程、同步机制、sleep、线程终止 |
| `Basic_IO/` | I/O 概述、节点流、处理流 |
| `Net/` | 网络概述、Socket、HTTP、WebSocket |
| `Macro/` | 宏简介、Tokens/quote、语法节点、宏实现、案例、内置编译标记 |
| `reflect_and_annotation/` | 注解（@Overflow*）、反射动态特性 |
| `compile_and_build/` | cjc 使用、cjpm 使用、条件编译 |
| `deploy_and_run/` | 运行程序、运行时部署 |
| `FFI/` | 仓颉-C 互操作 |
| `Appendix/` | 关键字、操作符、编译选项完整文档、工具链安装、运行时环境 |

### CLAUDE.md 索引

| 路径 | 说明 |
|:--|:--|
| `user_manual/CLAUDE.md` | 用户手册模块导航，含学习路径、所有子模块摘要 |
| `libs/CLAUDE.md` | 标准库模块导航，含 std 全部模块 API 概述 |
| `libs_stdx/CLAUDE.md` | 扩展库模块导航，含 stdx 全部包概述与依赖说明 |

---

## 十二、负结果

- 经搜索，`libs/` 和 `libs_stdx/` 下不存在名为 `overview*` 的文件（与 `libs/` 中的 index.md 不同，该 index.md 内容为 API 文档爬取产物，包含大量格式异常内容）
- `libs_stdx/` 目录下无独立的 index.md 文件，入口为 CLAUDE.md
- `user_manual/` 根目录下无 `index.md`（index.md 实际内容为 cjc 编译选项文档）
