---
paths:
  - "**/*.cpp"
  - "**/*.cc"
  - "**/*.cxx"
  - "**/*.hpp"
  - "**/*.hh"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>C++17 最低基线，C++20/23 特性按项目允许</requirement>

  <!-- ====== Modern C++ 原则 ====== -->
  <constraint severity="blocker">RAII：资源在构造时获取，析构时释放</constraint>
  <constraint severity="blocker">Smart pointer 替代裸指针：`std::unique_ptr` / `std::shared_ptr` / `std::weak_ptr`</constraint>
  <constraint severity="blocker">禁止 `new` / `delete`（除非实现容器或极特殊场景）</constraint>
  <convention>`auto` 合理使用（类型长 / 明显场景）</convention>
  <convention>范围 for：`for (const auto& x : vec)`</convention>
  <convention>`const` 大量使用（变量、方法、参数）</convention>
  <convention>`constexpr` 编译期求值</convention>

  <!-- ====== 命名 ====== -->
  <convention>类、结构体、枚举：`PascalCase`</convention>
  <convention>函数、变量：`camelCase` 或 `snake_case`（项目约定）</convention>
  <convention>常量、枚举值：`kCamelCase` 或 `UPPER_SNAKE_CASE`</convention>
  <convention>成员变量：`m_` 前缀或 `_` 后缀（项目约定）</convention>
  <convention>宏：`UPPER_SNAKE_CASE`（慎用宏，优先 constexpr / inline）</convention>

  <!-- ====== 头文件 ====== -->
  <convention>`#pragma once` 或 include guard</convention>
  <convention>前向声明减少头文件依赖</convention>
  <constraint severity="warning">实现不放头文件（除 template 和 inline）</constraint>
  <convention>公开接口在 `.hpp`，实现细节在 `.cpp`</convention>

  <!-- ====== 值类别 ====== -->
  <convention>移动语义：返回大对象依靠 RVO / NRVO，参数用 `&&`（右值引用）</convention>
  <convention>`std::move` 表达"不再使用"，不是"移动操作本身"</convention>
  <convention>Rule of 0 / 3 / 5：要么都用默认，要么全部自定义</convention>

  <!-- ====== 异常 ====== -->
  <convention>按值抛出，按引用捕获：`throw MyError{...}` / `catch (const MyError& e)`</convention>
  <constraint severity="blocker">不从析构函数抛异常</constraint>
  <convention>`noexcept` 标注不抛异常的函数（帮助编译器优化）</convention>

  <!-- ====== 并发 ====== -->
  <constraint severity="blocker">`std::thread` 构造后必须 `join()` 或 `detach()`</constraint>
  <convention>`std::mutex` + `std::lock_guard` / `std::unique_lock`</convention>
  <convention>`std::atomic<T>` 用于原子操作</convention>
  <convention>`std::async` / `std::future`</convention>
  <convention>高级：协程（C++20）</convention>

  <!-- ====== 容器 ====== -->
  <convention>`std::vector` 默认选择</convention>
  <convention>`std::array` 编译期固定大小</convention>
  <convention>`std::string_view` 传递只读字符串</convention>
  <convention>`std::span` (C++20) 传递连续内存视图</convention>
  <convention>`std::optional<T>` 可能为空的值</convention>

  <!-- ====== 反模式 ====== -->
  <constraint severity="blocker">`using namespace std;` 在头文件（污染全局）</constraint>
  <constraint severity="blocker">C 风格类型转换：用 `static_cast` / `const_cast` / `dynamic_cast` / `reinterpret_cast`</constraint>
  <constraint severity="warning">生拷贝大对象</constraint>
  <constraint severity="blocker">悬挂引用（返回局部变量引用）</constraint>
  <constraint severity="blocker">未初始化的基本类型变量</constraint>

  <!-- ====== 工具 ====== -->
  <constraint severity="blocker">编译：开启 `-Wall -Wextra -Wpedantic`（或 MSVC `/W4`）</constraint>
  <convention>静态分析：clang-tidy、cppcheck</convention>
  <convention>格式化：clang-format</convention>
  <convention>Sanitizers：AddressSanitizer、ThreadSanitizer、UBSan</convention>

  <!-- ====== 安全 ====== -->
  <constraint severity="blocker">避免不安全的 C API：`strcpy` → `snprintf`；`gets` 禁用</constraint>
  <convention>数组边界检查：`.at()` 而非 `operator[]`（调试时）</convention>
  <constraint severity="warning">整数溢出：有符号溢出是 UB</constraint>

</rule>
