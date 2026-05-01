---
paths:
  - "**/*.c"
  - "**/*.h"
---

<rule>
  <!-- ====== 版本 ====== -->
  <requirement>C11 / C17 基线，嵌入式项目按硬件支持</requirement>

  <!-- ====== 命名 ====== -->
  <convention>函数、变量：`snake_case`</convention>
  <convention>类型：`snake_case_t`（typedef）或 `CamelCase`（项目约定）</convention>
  <convention>宏：`UPPER_SNAKE_CASE`</convention>
  <convention>全局变量：`g_` 前缀（便于识别）</convention>
  <convention>静态变量：`s_` 前缀</convention>

  <!-- ====== 头文件 ====== -->
  <convention>Include guard：</convention>
  <pattern>

```c
#ifndef MYPROJECT_FOO_H
#define MYPROJECT_FOO_H
// ...
#endif
```

  </pattern>
  <convention>只 include 必须的头（最小依赖）</convention>
  <constraint severity="warning">不在头文件中定义非 inline 函数</constraint>
  <convention>`static` 限定仅本文件可见的函数和变量</convention>

  <!-- ====== 内存安全（C 的头号痛点） ====== -->
  <constraint severity="blocker">每个 `malloc` 都要有对应的 `free`</constraint>
  <constraint severity="blocker">释放后指针置 NULL，避免 double-free</constraint>
  <constraint severity="blocker">不返回局部变量指针（栈变量生命周期）</constraint>
  <constraint severity="blocker">不访问已释放的内存</constraint>
  <constraint severity="blocker">缓冲区操作前先算长度</constraint>
  <constraint severity="blocker">禁止 `strcpy`、`strcat`、`sprintf`、`gets`：用 `strncpy`、`snprintf`、`fgets`</constraint>
  <constraint severity="blocker">数组大小传参必须伴随长度</constraint>

  <!-- ====== 错误处理 ====== -->
  <convention>返回值表示错误（通常 0 成功、负值失败）</convention>
  <convention>或用 `errno` + 返回值哨兵（`-1` / `NULL`）</convention>
  <constraint severity="blocker">不忽略 errno（检查 IO / 系统调用后立即读）</constraint>
  <convention>释放资源用 goto cleanup 模式：</convention>
  <pattern>

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

  </pattern>

  <!-- ====== 类型 ====== -->
  <constraint severity="warning">`int` 平台相关：明确宽度用 `<stdint.h>`（`int32_t`, `uint64_t`）</constraint>
  <convention>`size_t` 表示大小、索引（`sizeof` 返回）</convention>
  <convention>`ssize_t` 表示有符号大小</convention>
  <convention>布尔：`<stdbool.h>` 的 `bool` / `true` / `false`</convention>

  <!-- ====== 宏 ====== -->
  <convention>宏带参数用括号：</convention>
  <pattern>

```c
#define SQUARE(x) ((x) * (x))
```

  </pattern>
  <convention>多语句宏用 `do { ... } while(0)`</convention>
  <convention>优先用 `inline` 函数替代宏（类型安全）</convention>
  <convention>优先用 `const` / `enum` 替代 `#define` 常量</convention>

  <!-- ====== 并发 ====== -->
  <convention>pthread 或 C11 threads</convention>
  <convention>互斥锁：`pthread_mutex_t`</convention>
  <convention>原子操作：C11 `<stdatomic.h>`</convention>
  <constraint severity="warning">信号处理：异步信号安全函数集极小，避免在信号处理器中做复杂事</constraint>

  <!-- ====== 反模式 ====== -->
  <constraint severity="warning">魔数：用 const 或 enum 命名</constraint>
  <constraint severity="warning">返回内部静态缓冲区（非线程安全）</constraint>
  <constraint severity="warning">`void*` 类型指针过度使用</constraint>
  <constraint severity="warning">过长函数（大于 100 行）</constraint>
  <constraint severity="blocker">忽略编译器 warning</constraint>

  <!-- ====== 工具 ====== -->
  <constraint severity="blocker">编译：`-Wall -Wextra -Wpedantic -Werror`</constraint>
  <convention>静态分析：cppcheck、clang analyzer</convention>
  <convention>动态：Valgrind、AddressSanitizer、UBSan</convention>
  <convention>格式化：clang-format</convention>

  <!-- ====== 嵌入式特别 ====== -->
  <constraint severity="blocker">栈大小有限：避免大数组局部变量</constraint>
  <constraint severity="blocker">中断上下文：不调用 `malloc`、浮点、长操作</constraint>
  <convention>`volatile` 用于内存映射寄存器、中断共享变量</convention>
  <constraint severity="blocker">固定整数宽度强制使用（`uint8_t` 等）</constraint>

</rule>
