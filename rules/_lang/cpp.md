---
paths:
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.cxx"
  - "**/*.hpp"
  - "**/*.hh"
---

# C++ 编码规范

## 版本
- C++17 最低基线，C++20/23 特性按项目允许

## Modern C++ 原则
- **RAII**：资源在构造时获取，析构时释放
- **Smart pointer** 替代裸指针：`std::unique_ptr` / `std::shared_ptr` / `std::weak_ptr`
- **禁止** `new` / `delete`（除非实现容器或极特殊场景）
- `auto` 合理使用（类型长 / 明显场景）
- 范围 for：`for (const auto& x : vec)`
- `const` 大量使用（变量、方法、参数）
- `constexpr` 编译期求值

## 命名
- 类、结构体、枚举：`PascalCase`
- 函数、变量：`camelCase` 或 `snake_case`（项目约定）
- 常量、枚举值：`kCamelCase` 或 `UPPER_SNAKE_CASE`
- 成员变量：`m_` 前缀或 `_` 后缀（项目约定）
- 宏：`UPPER_SNAKE_CASE`（慎用宏，优先 constexpr / inline）

## 头文件
- `#pragma once` 或 include guard
- 前向声明减少头文件依赖
- 实现不放头文件（除 template 和 inline）
- 公开接口在 `.hpp`，实现细节在 `.cpp`

## 值类别
- 移动语义：返回大对象依靠 RVO / NRVO，参数用 `&&`（右值引用）
- `std::move` 表达"不再使用"，不是"移动操作本身"
- Rule of 0 / 3 / 5：要么都用默认，要么全部自定义

## 异常
- 按值抛出，按引用捕获：`throw MyError{...}` / `catch (const MyError& e)`
- 不从析构函数抛异常
- `noexcept` 标注不抛异常的函数（帮助编译器优化）

## 并发
- `std::thread` 构造后必须 `join()` 或 `detach()`
- `std::mutex` + `std::lock_guard` / `std::unique_lock`
- `std::atomic<T>` 用于原子操作
- `std::async` / `std::future`
- 高级：协程（C++20）

## 容器
- `std::vector` 默认选择
- `std::array` 编译期固定大小
- `std::string_view` 传递只读字符串
- `std::span` (C++20) 传递连续内存视图
- `std::optional<T>` 可能为空的值

## 反模式
- `using namespace std;` 在头文件（污染全局）
- C 风格类型转换：用 `static_cast` / `const_cast` / `dynamic_cast` / `reinterpret_cast`
- 生拷贝大对象
- 悬挂引用（返回局部变量引用）
- 未初始化的基本类型变量

## 工具
- 编译：开启 `-Wall -Wextra -Wpedantic`（或 MSVC `/W4`）
- 静态分析：clang-tidy、cppcheck
- 格式化：clang-format
- Sanitizers：AddressSanitizer、ThreadSanitizer、UBSan

## 安全
- 避免不安全的 C API：`strcpy` → `snprintf`；`gets` 禁用
- 数组边界检查：`.at()` 而非 `operator[]`（调试时）
- 整数溢出：有符号溢出是 UB
