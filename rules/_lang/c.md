---
paths:
  - "**/*.c"
  - "**/*.h"
---

# C 编码规范

## 版本
- C11 / C17 基线，嵌入式项目按硬件支持

## 命名
- 函数、变量：`snake_case`
- 类型：`snake_case_t`（typedef）或 `CamelCase`（项目约定）
- 宏：`UPPER_SNAKE_CASE`
- 全局变量：`g_` 前缀（便于识别）
- 静态变量：`s_` 前缀

## 头文件
- Include guard：
  ```c
  #ifndef MYPROJECT_FOO_H
  #define MYPROJECT_FOO_H
  // ...
  #endif
  ```
- 只 include 必须的头（最小依赖）
- 不在头文件中定义非 inline 函数
- `static` 限定仅本文件可见的函数和变量

## 内存安全（C 的头号痛点）

- 每个 `malloc` 都要有对应的 `free`
- 释放后指针置 NULL，避免 double-free
- 不返回局部变量指针（栈变量生命周期）
- 不访问已释放的内存
- 缓冲区操作前**先算长度**
- **禁止** `strcpy`、`strcat`、`sprintf`、`gets`：用 `strncpy`、`snprintf`、`fgets`
- 数组大小传参必须伴随长度

## 错误处理

- 返回值表示错误（通常 0 成功、负值失败）
- 或用 `errno` + 返回值哨兵（`-1` / `NULL`）
- 不忽略 errno（检查 IO / 系统调用后立即读）
- 释放资源用 goto cleanup 模式：
  ```c
  int func() {
      FILE *f = NULL;
      char *buf = NULL;
      int ret = -1;
      
      f = fopen(...);
      if (!f) goto cleanup;
      buf = malloc(...);
      if (!buf) goto cleanup;
      // ...
      ret = 0;
  cleanup:
      free(buf);
      if (f) fclose(f);
      return ret;
  }
  ```

## 类型

- `int` 平台相关：明确宽度用 `<stdint.h>`（`int32_t`, `uint64_t`）
- `size_t` 表示大小、索引（`sizeof` 返回）
- `ssize_t` 表示有符号大小
- 布尔：`<stdbool.h>` 的 `bool` / `true` / `false`

## 宏

- 宏带参数用括号：
  ```c
  #define SQUARE(x) ((x) * (x))
  ```
- 多语句宏用 `do { ... } while(0)`
- 优先用 `inline` 函数替代宏（类型安全）
- 优先用 `const` / `enum` 替代 `#define` 常量

## 并发

- pthread 或 C11 threads
- 互斥锁：`pthread_mutex_t`
- 原子操作：C11 `<stdatomic.h>`
- 信号处理：异步信号安全函数集极小，避免在信号处理器中做复杂事

## 反模式

- 魔数：用 const 或 enum 命名
- 返回内部静态缓冲区（非线程安全）
- `void*` 类型指针过度使用
- 过长函数（>100 行）
- 忽略编译器 warning

## 工具

- 编译：`-Wall -Wextra -Wpedantic -Werror`
- 静态分析：cppcheck、clang analyzer
- 动态：Valgrind、AddressSanitizer、UBSan
- 格式化：clang-format

## 嵌入式特别

- 栈大小有限：避免大数组局部变量
- 中断上下文：不调用 `malloc`、浮点、长操作
- `volatile` 用于内存映射寄存器、中断共享变量
- 固定整数宽度强制使用（`uint8_t` 等）
