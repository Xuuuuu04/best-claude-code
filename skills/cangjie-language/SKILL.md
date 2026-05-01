---
name: cangjie-language
description: 仓颉语言开发专家。覆盖类型系统、语法、并发、网络、宏、C互操作、标准库、扩展库、编译构建的完整知识。Use proactively for 仓颉/CangJie 开发、仓颉代码审查、仓颉项目架构设计。
when_to_use: 当用户提到仓颉/CangJie、仓颉代码、仓颉项目、cjpm 或华为自研编程语言时自动加载。
---

# 仓颉语言开发专家

## 语言速查

### 类型系统
- **struct** (值类型/传参复制/不支持继承) · **class** (引用类型/单继承Object) · **enum** (ADT/支持递归) · **interface** (多继承)
- **Option\<T\>** (Some/None, 替代null) · **Any** (所有类型默认实现)
- 基础: `Int8-64/UInt8-64` `Float16-64` `Bool` `Rune` `String` `Array<T>` `Tuple` `Range` `Unit` `Nothing`

### 并发
- M:N 用户态协程, `spawn {}` → `Future<T>`, `Atomic<T>` `Mutex<T>` `synchronized` `Condition`

### C 互操作
- `foreign func` / `@C` / `CPointer<T>` `CString` `VArray<T>` `CFunc` / `unsafe` 块包裹

### 编译
- `cjc` (优化/LTO/PGO/交叉编译) · `cjpm` 包管理

## 完整文档索引（按需读取 references/ 下对应文件）

### 语言手册（user_manual/）
| 主题 | 参考文件 |
|:--|:--|
| 语言基础 | `user_manual/first_understanding/basic.md` |
| 整数类型 | `user_manual/basic_data_type/integer.md` |
| 字符串 | `user_manual/basic_data_type/strings.md` |
| 数组 | `user_manual/basic_data_type/array.md` |
| 元组 | `user_manual/basic_data_type/tuple.md` |
| struct 定义 | `user_manual/struct/define_struct.md` |
| class 与 OOP | `user_manual/class_and_interface/class.md` |
| enum 与模式匹配 | `user_manual/enum_and_pattern_match/enum.md` |
| Option 类型 | `user_manual/enum_and_pattern_match/option_type.md` |
| interface | `user_manual/class_and_interface/interface.md` |
| 函数 | `user_manual/function/` (全部子文件) |
| 宏系统 | `user_manual/macro/` |
| 并发 | `user_manual/concurrency/` |
| 网络编程 | `user_manual/Net/net_overview.md`, `net_http.md`, `net_socket.md`, `net_websocket.md` |
| C 互操作 | `user_manual/interop_c/` |
| 扩展 | `user_manual/extension/` |
| 附录 | `user_manual/Appendix/` (关键词/编译选项/操作符/运行时环境) |

### 标准库（libs/）
- `libs/index.md` — std 30+ 模块清单

### 扩展库（libs_stdx/）
- `libs_stdx/libs_overview.md` — 16 个扩展包 (crypto/encoding/net/compression/logger/serialization/fuzz/aspectCJ/log 等)

### 知识摘要
- `references/knowledge-summary.md` — 全语言 12 域结构化摘要 (400 行)

## 开发铁律
1. 空值用 `Option<T>` 而非 null
2. 网络/IO 用 `spawn` 协程
3. FFI 必须 `unsafe` 包裹
4. struct 赋值即复制, class 赋值共享引用
5. match 必须穷尽, 否则编译错误
