# PyPTO — Tile-based 高层编程框架

基于 Tile 抽象的高层 Ascend C 编程框架，编译到昇腾硬件。含 DeepSeek V3.2 / GLM V4.5 等大模型算子样例。自带 lint 规则和 precision-debug skill 骨架，是精度 DEBUG Agent 方向的主战场。

## 技术栈

- **语言**：Python
- **编译**：图编译框架（Tensor Graph → Tile Graph → Block Graph → 硬件）
- **测试**：pytest（`python/tests/ut/` + `python/tests/st/` + `models/`）

## 构建/测试

```bash
pip install -e .
pytest python/tests/
```

- CPU 模式通过 model simulation 运行，无需 NPU
- NPU 模式设置 `export TILE_FWK_DEVICE_ID=0`

## 核心模块

| 目录 | 内容 |
|:--|:--|:--|
| `examples/00_hello_world/` | 入门：hello_world |
| `examples/01_beginner/` | 初级：基础算子 |
| `examples/02_intermediate/` | 中级：融合算子 |
| `examples/03_advanced/` | 高级：复杂模式 |
| `models/deepseek_v32_exp/` | DeepSeek V3.2 大模型算子 |
| `models/glm_v4_5/` | GLM V4.5 大模型算子 |
| `framework/` | 编译框架（Pass、图优化） |
| `python/` | PyPTO Python 包 |
| `docs/tutorials/debug/debug.md` | 图编译调试（`compile_debug_mode=1`） |
| `docs/tutorials/debug/precision.md` | 精度调试指南 |
| `docs/tutorials/debug/debug_case_ffn.md` | FFN 算子精度 DEBUG 真实案例 |
| `.agents/skills/` | 已有 pypto-op-lint / pypto-precision-debug skill 骨架 |

## 核心铁律

1. 精度问题逐层定位：Tensor Graph → Tile Graph → Block Graph（不跳层）
2. `compile_debug_mode=1` 开启图可视化，是精度 DEBUG 的入口开关
3. golden vs actual 对比是精度定位的标准方法
4. `.agents/skills/` 中的 lint 和 precision-debug skill 可作为 Agent 设计参考

## Agent 调度指引

- **精度 DEBUG 入门** → 读 `docs/tutorials/debug/precision.md` + `debug_case_ffn.md`
- **算子实现参考** → `examples/` 三级样例 + `models/` 大模型算子
- **已有 Agent skill 参考** → `.agents/skills/pypto-precision-debug/` + `pypto-op-lint/`
- **编译流程理解** → `framework/` 源码 + `docs/tutorials/debug/debug.md`

## @imports

- `../CLAUDE.md` — 工作区根指令
- `../.claude/skills/project-knowledge/SKILL.md` — 完整仓库索引
- `../asc-devkit/CLAUDE.md` — C++ 层 API（底层对照）
- `../pyasc/CLAUDE.md` — Python 前端（算子编写层互补）
