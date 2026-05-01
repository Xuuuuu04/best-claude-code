---
name: huawei-ascend
description: 华为昇腾 NPU 生态开发专家。覆盖 Ascend NPU 架构、CANN 工具链、Ascend C 多级 API、Python 前端(PyPTO/PyAsc)、推理部署、鸿蒙端侧推理、npu_check 调试。
when_to_use: 当用户提到华为昇腾/Ascend/CANN/NPU/Ascend C/PyPTO/PyAsc/鸿蒙AI推理/atb Models/大模型芯片部署时自动加载。
---

# 华为昇腾 NPU 生态开发专家

## 环境速查

实验环境：华为云 ModelArts Notebook（1 NPU, CANN 8.5.2, EulerOS aarch64）
- `~/work` 唯一持久化目录，其余重启即丢
- PyPTO conda env 已配置：`~/work/i-ma`

## CANN 核心概念

### 硬件架构
- **Ascend NPU**：华为自研 AI 处理器（910B/310P 等）
- **Da Vinci 架构**：Cube 单元（矩阵乘）+ Vector 单元（向量计算）
- **AI Core / AI CPU / Control CPU** 三级计算单元

### 软件栈
```
Application → MindSpore/PyTorch(torch_npu)/ONNX Runtime
    ↓
CANN (异构计算架构)
  ├── Ascend C (算子开发语言) → 编译为 NPU 二进制
  ├── ATC (模型转换工具)
  ├── ACL (Ascend Computing Language，运行时 API)
  └── GE (Graph Engine)
    ↓
Ascend NPU 硬件
```

## Ascend C API 分类（6 大类）

| 类别 | 说明 |
|:--|:--|
| 基础数据结构 | LocalTensor / GlobalTensor / Layout |
| 语言扩展层 C API | 计算原语 |
| 基础 API | 数据搬运、内存管理 |
| 高阶 API | Matmul / Conv / Pool 等 |
| SIMT API | 细粒度并行 |
| Utils API | 调试/性能分析 |

## PyPTO / PyAsc（Python 前端）

- **PyPTO**：v0.2.0，已包含 DeepSeek V3.2 / GLM V4.5 / Qwen3 Next / Arctic 等大模型算子实现
- **PyAsc**：基于 MLIR（Python AST → ASC-IR → Ascend C），接口与 Ascend C 1:1 对应
- **PyAsc 限制**：不支持 str/tuple/list/dict 作为运行时参数

## 推理部署

### 标准部署路径
```
PyTorch模型 → torch_npu → ATC转换 → om模型 → Ascend NPU推理
```

### 鸿蒙端侧推理（5 个商业案例）
| 客户 | 模型 | 关键算子 | 芯片 |
|:--|:--|:--|:--|
| 支付宝 | 端侧大模型 | QuantMatmul | Kirin9030 |
| QQ音乐 | 声伴分离 | BandNorm | — |
| 智谱 | GLM-Edge-1.5b | RmsNorm | KirinX90 |
| 悟空图像 | 图像处理 | SliceGelu | KirinX90 |
| CV | 边缘检测 | SobelCustom | — |

## npu_check 调试工具（15 类错误码）

```
ErrorRead(1-4)  ErrorWrite(1-4)  ErrorSync(1-4)
ErrorLeak  ErrorFree  ErrorBuffer(0-4)
```
所有错误在 CPU 模式下同步检测，无需 NPU 硬件。

## 学习资源

| 资源 | 路径 |
|:--|:--|
| CANN 学习中心 | `~/Desktop/华为昇腾/cann-learning-hub/` — 8 章 Jupyter 教程 |
| CANN 样例 | `~/Desktop/华为昇腾/cann-samples/` — 三级样例 |
| Ascend 开发文档 | `~/Desktop/华为昇腾/asc-devkit-docs/` — 完整 API 文档 |
| CANN Recipes | `~/Desktop/华为昇腾/cann-recipes-harmony-infer/` — 推理部署案例 |
| 环境配置 | `~/Desktop/华为昇腾/asc-tools/` + `~/Desktop/华为昇腾/asc-devkit/` |

知识点结构化摘要：`/tmp/ascend-knowledge.md`（298 行，9 个章节）

## 开发铁律

1. `~/work` 唯一持久化——所有产出写到这里
2. 算子开发优先 Ascend C（原生性能），其次 PyAsc（快速原型）
3. 模型部署前必过 ATC 转换检查
4. 内存管理：NPU 显存有限，大模型需分片/量化
5. 调试先用 CPU 模式 npu_check，通过后再上 NPU 硬件
