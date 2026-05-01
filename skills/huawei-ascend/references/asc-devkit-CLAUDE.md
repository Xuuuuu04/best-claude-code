# Ascend C 核心开发套件

Ascend C 算子开发的核心 SDK，含 API 头文件、样例代码（268 个 .asc/.cpp/.h）、API 文档和测试套件。工作区最大仓（~4838 文件），Agent DEBUG 课题的算子代码主战场。

## 技术栈

- **语言**：Ascend C（C++ 方言，`.asc` / `.cpp` / `.h`）
- **编译器**：bisheng（华为定制 Clang-based）
- **运行时**：CANN toolkit
- **构建**：CMake + `scripts/` 打包
- **测试**：gtest（`tests/test_parts.sh` 分片运行）

## 构建/测试

```bash
source /usr/local/Ascend/cann/set_env.sh
cmake -B build -DCMAKE_ASC_RUN_MODE=cpu -DCMAKE_ASC_ARCHITECTURES=dav-2201
cmake --build build
cd build && ctest
```

- `-DCMAKE_ASC_RUN_MODE=cpu` — 无需 NPU，CPU 仿真
- `-DCMAKE_ASC_RUN_MODE=npu` — 需 NPU 硬件
- `-DCMAKE_ASC_ARCHITECTURES=dav-2201` — 目标架构

## 核心模块

| 目录 | 内容 |
|:--|:--|
| `examples/01_simd_cpp_api/` | 按功能分类的算子样例（Utilities / Features） |
| `impl/` | 高阶 API + 基础 API 实现头文件 |
| `include/` | 公开头文件（c_api / simt_api / adv_api） |
| `tests/` | gtest 单元测试 |
| `docs/` | API 文档、快速入门 |
| `cmake/` | CMake 编译支持 |

## 核心铁律

1. Kernel 三段流水中断任何一段都属错误 — CopyIn / Compute / CopyOut 缺一不可
2. `__aicore__ inline` 必须标注所有 device 侧函数
3. Tiling 参数 32 字节对齐是硬约束
4. `#ifdef ASCENDC_CPU_DEBUG` 条件编译 CPU 调试路径不可省略
5. 不绕过 gtest 直接提交算子代码 — 改动必须有测试覆盖

## Agent 调度指引

- **算子代码定位** → `repo-researcher` 扫 `examples/` + `impl/` + `include/`
- **API 约束查询** → 先查 `impl/` 头文件 + `docs/`，再查 `include/` 公开 API
- **错误样本构造** → 从 `tests/` 的 gtest 用例反推错误模式
- **Sanitizer 演示** → `examples/01_simd_cpp_api/01_utilities/05_sanitizer/`

## @imports

- `../CLAUDE.md` — 工作区根指令
- `../.claude/skills/project-knowledge/SKILL.md` — 完整仓库索引
