# Ascend C Python 前端

Ascend C 的 Python 语言前端，与 C++ API 一一对应，基于 MLIR 后端。提供 `asc.printf` / `asc.dump_tensor` 等 Python 原生调试接口，是精度 DEBUG 方向的核心平台。

## 技术栈

- **语言**：Python（前端用户 API）+ C++（pybind 绑定）+ MLIR（后端方言）
- **构建**：CMake + `pip install`
- **测试**：pytest（`python/test/`）+ gtest（`test/` 后端）

## 构建/测试

```bash
cmake -B build && cmake --build build
cd python && pip install -e .
pytest python/test/
```

## 核心模块

| 目录 | 内容 |
|:--|:--|:--|
| `python/asc/` | 用户 API 包（与 C++ API 一一对应） |
| `python/src/` | pybind 绑定代码 |
| `python/tutorials/` | Python 算子教程 |
| `python/test/` | pytest 测试 + `python/test/kernels/` kernel 级测试 |
| `lib/` | MLIR 方言实现 |
| `include/` | 后端头文件和 .td 定义 |
| `docs/op_debug_prof.md` | Python 算子调试调优指南（printf / dump_tensor） |
| `bin/` | 工具脚本 |

## 核心铁律

1. Python API 与 C++ API 语义一一对应 — 查 API 行为时优先对照 `asc-devkit/impl/` 或 `asc-devkit/include/`
2. `asc.printf` / `asc.dump_tensor` 是 Python 侧核心调试手段
3. 精度对比用 `golden` vs `actual` 模式（参考 `pypto/docs/tutorials/debug/precision.md`）

## Agent 调度指引

- **Python 算子写法** → 读 `python/tutorials/` 教程
- **调试技巧** → 读 `docs/op_debug_prof.md`
- **MLIR 方言理解** → `lib/` + `include/`（MS 方言 / 后端 pattern）
- **精度 DEBUG** → 配合 `pypto` 的精度调试工具链

## @imports

- `../CLAUDE.md` — 工作区根指令
- `../.claude/skills/project-knowledge/SKILL.md` — 完整仓库索引
- `../asc-devkit/CLAUDE.md` — C++ API 参考（Python 绑定对应）
- `../pypto/CLAUDE.md` — 高层框架（精度调试工具链互补）
