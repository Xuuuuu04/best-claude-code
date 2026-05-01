---
name: huawei-ascend
description: 华为昇腾 NPU 生态开发专家。覆盖 Ascend NPU 架构、CANN 工具链、Ascend C 多级 API、Python 前端(PyPTO/PyAsc)、推理部署、鸿蒙端侧推理、npu_check 调试。
when_to_use: 当用户提到华为昇腾/Ascend/CANN/NPU/Ascend C/PyPTO/PyAsc/鸿蒙AI推理/atb Models/大模型芯片部署时自动加载。
---

# 华为昇腾 NPU 生态开发专家

## 环境
华为云 ModelArts Notebook (1 NPU, CANN 8.5.2, EulerOS aarch64), `~/work` 唯一持久化目录。

## 软件栈
```
MindSpore/PyTorch(torch_npu)/ONNX Runtime → CANN
  ├── Ascend C (算子开发) → NPU 二进制
  ├── ATC (模型转换) → om 模型
  ├── ACL (运行时 API)
  └── GE (图引擎)
    → Ascend NPU (Da Vinci: Cube+Vector)
```

## Ascend C API (6 类)
基础数据结构 (LocalTensor/GlobalTensor) · 语言扩展层 C API · 基础 API · 高阶 API (Matmul/Conv) · SIMT API · Utils API

## Python 前端
- **PyPTO** v0.2.0: DeepSeek V3.2/GLM V4.5/Qwen3 Next/Arctic 大模型算子
- **PyAsc**: MLIR 架构 (Python AST → ASC-IR → Ascend C), 与 Ascend C 1:1 对应

## 推理部署
`PyTorch→torch_npu→ATC→om→ACL→NPU` · 鸿蒙端侧: 支付宝/QQ音乐/智谱/悟空/CV 5 个商业案例

## npu_check (15 类错误码)
`ErrorRead(1-4) ErrorWrite(1-4) ErrorSync(1-4) ErrorLeak ErrorFree ErrorBuffer(0-4)` — CPU 模式同步检测

## 完整文档索引（按需读取 references/）

### 子仓库概要
| 仓库 | 核心文档 |
|:--|:--|
| asc-devkit | `asc-devkit-CLAUDE.md` `asc-devkit-README.md` |
| asc-devkit-docs | `asc-devkit-docs-README.md` + `asc-docs-*` (完整 API 文档) |
| asc-tools | `asc-tools-CLAUDE.md` `asc-tools-README.md` + `asctools-*` (npu_check 等) |
| pypto | `pypto-AGENTS.md` `pypto-CLAUDE.md` `pypto-README.md` (PyPTO 算子编排) |
| pyasc | `pyasc-CLAUDE.md` `pyasc-README.md` (Python Ascend C 前端) |
| cann-samples | `cann-samples-CLAUDE.md` `cann-samples-README.md` |
| cann-learning-hub | `cann-learning-hub-README.md` + `learnhub-*` (8 章 Jupyter 教程) |
| cann-recipes | `cann-recipes-harmony-infer-README.md` + `recipe-*` (推理案例) |
| cann-cmake | `cann-cmake-README.md` |
| community | `community-README.md` |
| ClaudeCodeWorkflow | `ClaudeCodeWorkflow-CLAUDE.md` `ClaudeCodeWorkflow-README.md` |

### 知识摘要
- `references/knowledge-summary.md` — 全生态 9 章结构化摘要 (298 行)

## 开发铁律
1. `~/work` 唯一持久化——所有产出写到这里
2. 算子优先 Ascend C (原生性能), PyAsc 用于快速原型
3. 模型部署前必过 ATC 转换检查
4. NPU 显存有限, 大模型需分片/量化
5. 调试先用 CPU 模式 npu_check, 通过后再上 NPU
