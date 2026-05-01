# CANN 算子功能样例库

Ascend C 算子三级渐进式样例集：入门（0_Introduction）→ 特性专题（1_Features）→ 性能优化（2_Performance）。Agent DEBUG 课题从简单到复杂的错误样本递进来源。

## 技术栈

- **语言**：Ascend C（`.asc` + `.cpp` + `.h`）
- **编译器**：bisheng
- **构建**：CMake
- **测试**：手动执行生成的二进制

## 构建/测试

```bash
source /usr/local/Ascend/cann/set_env.sh
cmake -B build -DCMAKE_ASC_RUN_MODE=cpu -DCMAKE_ASC_ARCHITECTURES=dav-2201
cmake --build build
./build/vector_add  # 示例
```

## 核心模块

| 目录 | 内容 |
|:--|:--|:--|
| `Samples/0_Introduction/` | 入门算子：vector_add、matmul 等基础实现 |
| `Samples/1_Features/` | 特性专题：hardware_features、memory_optimization、tiling、multi_core |
| `Samples/2_Performance/` | 复杂融合算子：grouped_matmul、moe_dispatch、flash_attention 等 |
| `tests/` | 部分样例的测试脚本 |

## 核心铁律

1. 样例代码是"正确实现"的参考基准 — 改算子逻辑前先对照对应样例
2. 0_Introduction → 1_Features → 2_Performance 是从简到繁的递进路径
3. 每个样例目录含完整 Host+Kernel+CMakeLists，可独立构建运行

## Agent 调度指引

- **了解某个 API 用法** → 先 grep `Samples/` 找使用该 API 的样例，再对照 `asc-devkit/impl/` 头文件
- **构造错误样本** → 从 0_Introduction 的正确实现出发，引入典型错误（tiling 不对齐、同步缺失等）
- **性能算子 DEBUG** → 2_Performance 的融合算子是最复杂的错误场景

## @imports

- `../CLAUDE.md` — 工作区根指令
- `../.claude/skills/project-knowledge/SKILL.md` — 完整仓库索引
- `../asc-devkit/CLAUDE.md` — 核心 SDK（API 参考）
