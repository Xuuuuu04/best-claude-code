# 华为昇腾 CANN 生态核心知识点摘要

**数据采集时间**: 2026-05-01  
**数据来源**: `/Users/mumuxsy/Desktop/华为昇腾/` 下 9 个子仓库 + 1 个工具仓  
**本地实验环境**: 华为云 ModelArts Notebook (1 NPU, EulerOS aarch64, CANN 8.5.2)

---

## 1. Ascend NPU 硬件架构

### 芯片代际与架构版本

| NPU 架构版本 | 对应产品 | NPU_ARCH 参数 |
|:--|:--|:--|
| 200x | — | — |
| 220x | Ascend 910B / Ascend 910C (Atlas A2) | `dav-2201` |
| 300x | — | — |
| 351x | Ascend 950PR / Ascend 950DT (Atlas A3) | `dav-3510` |
| KirinX90 / Kirin9030 | 鸿蒙端侧麒麟芯片 | SoC 版本 |

### AI Core 内部结构

- **计算单元**: SCALAR（标量）/ VECTOR（向量）/ CUBE（矩阵乘）
- **数据搬运流水**: MTE1 (L1->L0A/L0B/UBUF) / MTE2 (GM->L1/L0/UBUF) / MTE3 (UBUF->GM/L1) / FIXP (L0C->OUT/L1)
- **内存层级**: Global Memory (GM, 外部) -> L2 Cache -> L1 Buffer -> L0A/L0B/UBUF (Local Memory，内部)
- **编程模型**: SIMD（单指令多数据）与 SIMT（单指令多线程），Ascend 950PR 起支持混合编程
- **Reg 编程**: Ascend 950PR 新增，90+ Reg 编程接口，直接操作 Vector 寄存器

### 关键约束

- Tiling 参数 **32 字节对齐** 是硬约束（否则必出 ErrorRead3/ErrorWrite2）
- GM 地址建议 **512B 对齐** 以获得最佳性能
- Unified Buffer bank 冲突需避免（220x 和 351x 有不同优化策略）

> 详细规格文档: `asc-devkit-docs/docs/guide/编程指南/硬件实现/架构规格/`

---

## 2. CANN 工具链

### 核心组件

| 工具 | 仓库路径 | 功能 |
|:--|:--|:--|
| **bisheng** 编译器 | 系统安装 | 华为定制 Clang-based 编译器，将 Ascend C 编译为 NPU 二进制 |
| **ATC** | CANN 内置 | 模型转换工具：ONNX/Ascend IR JSON → 离线模型 (.om)，支持 KirinX90/Kirin9030 |
| **cpu_debug** | `asc-tools/cpudebug/` | CPU 孪生调试库，GDB 调试时需设置 `follow-fork-mode child` |
| **npu_check** | `asc-tools/npuchk/` | CPU 模式同步运行，检测 15 类内存/同步错误 |
| **msprof** | CANN 内置 | 性能采集工具，`msprof op simulator --soc-version=KirinX90 ./app` 生成流水图（trace.json） |
| **msobjdump** | `asc-tools/utils/msobjdump/` | 解析 bisheng 编译产出的算子 ELF 文件 |
| **show_kernel_debug_data** | `asc-tools/utils/show_kernel_debug_data/` | DumpTensor/printf 数据离线解析 |

### 环境激活

```bash
source /usr/local/Ascend/cann/set_env.sh   # 标准 CANN 环境
# 或
source ${install_path}/ascend-toolkit/set_env.sh
```

### npu_check 15 类错误码速查

| 类别 | 错误码 | 含义 |
|:--|:--|:--|
| 读错误 | ErrorRead1 | 非法内存读取（未 alloc 或已 free） |
| | ErrorRead2 | [可疑] 读取从未被写过的无效数据 |
| | ErrorRead3 | 读取越界 |
| | ErrorRead4 | 读取地址非 32B 对齐 |
| 写错误 | ErrorWrite1 | 非法内存写入 |
| | ErrorWrite2 | 写入越界 |
| | ErrorWrite3 | [可疑] 重复写入（前次未被取走） |
| | ErrorWrite4 | 写入地址非 32B 对齐 |
| 同步错误 | ErrorSync1-4 | 缺少 barrier/set/wait / 不配对 / eventID 重复 |
| 泄漏/释放 | ErrorLeak / ErrorFree | 内存泄漏 / 重复释放 |
| Buffer 错误 | ErrorBuffer0-4 | 未初始化 / que 类型不一致 / 操作不合规 / 内存不合法 / 资源池未初始化 |

> 完整说明: `asc-tools/docs/02_npu_check.md`

### ATC 模型转换

```bash
# ONNX → 离线模型
atc --model=model.onnx --framework=5 --output=out/model --soc_version=KirinX90

# Ascend IR 单算子 JSON → 离线模型
atc --singleop=op.json --output=out/op --soc_version=KirinX90
```

---

## 3. Ascend C (AscendCL) API

### 多层级 API 体系

| 层级 | 语言 | 编程模型 | 目标用户 | 来源 |
|:--|:--|:--|:--|:--|
| **语言扩展层 C API (SIMD & SIMT)** | C | 指针编程，`[]` 分配内存，自主管理同步 | 算子库开发者 | `asc-devkit/include/c_api/` + `simt_api/` |
| **基础 API** | C++ | Tensor 编程，`MakeTensor/LocalMemoryAllocator` | 算子库开发者 | `asc-devkit/impl/basic_api/` |
| **Tpipe/Tque 框架 API** | C++ | Tensor 编程，框架自动管理同步与内存 | 算子库开发者 | `asc-devkit/impl/adv_api/` |
| **高阶 API** (Matmul/Softmax 等) | C++ | 封装通用单核算法 | 算法开发人员 | `asc-devkit/impl/adv_api/` |
| **算子模板库** (CATLASS/ATVOSS) | C++ | 典型算子端到端参考实现 | 算法开发人员 | 独立仓库 |

### API 选择决策

- **极致性能 + 指针编程** -> SIMD C API / SIMT API
- **极致性能 + C++ Tensor** -> 基础 API (自主管理) 或 Tpipe/Tque (自动管理)
- **快速验证 + 泛化性** -> 高阶 API 或算子模板库
- **离散矢量算子** -> SIMT API（匹配业界 GPU 编程习惯）
- **Python 开发** -> PyAsc（完备能力）或 PyPTO（易用性优先）

### 算子核心编程模型: 三级流水

```
CopyIn (GM→Local) → Compute (计算) → CopyOut (Local→GM)
```

- 使用 `TQue<TPosition::VECIN>` / `TQue<TPosition::VECOUT>` 管理流水队列
- `AllocTensor` / `EnQue` / `DeQue` / `FreeTensor` 管理 Tensor 生命周期
- `SetFlag` / `WaitFlag` 管理并行流水同步

### Kernel 函数特征

- `extern "C" __global__ __aicore__ void kernel_func(GM_ADDR x, ...)`
- Device 侧函数必须标注 `__aicore__ inline`
- `GET_TILING_DATA(tiling_data, tiling)` 获取 Host 侧传入的 Tiling 参数

> API 完整列表: `asc-devkit-docs/docs/api/README.md` (393KB, 涵盖基础数据结构、基础 API、高阶 API、SIMT API、Utils API)  
> API 选择指南: `asc-devkit-docs/docs/asc_how_to_choose_api.md`

---

## 4. Python 前端: PyAsc 与 PyPTO

### PyAsc — MLIR-based Python 前端

- **仓库**: `pyasc/` (v1.1.x, 255 py/cpp 文件)
- **原理**: Python 源码 → AST 解析 → ASC-IR (MLIR Dialect) → Ascend C 代码生成 → bisheng 编译 → NPU 执行
- **JIT 编译**: `@asc.jit` 装饰器，`kernel_func[core_num, stream](params)` 方式调用
- **API 1:1 映射**: PyAsc 接口与 Ascend C 类库接口一一对应
- **硬件支持**: Atlas A2/A3 (Ascend 910C/910B)
- **语法限制**: 不支持 str/tuple/list/dict 作为运行时参数，仅支持 Python 原生内置函数

**关键文档**:
- 架构: `pyasc/docs/architecture_introduction.md`
- 算子开发指南: `pyasc/docs/pyasc_op_develop_guide.md`
- API 列表: `pyasc/docs/python-api/index.md`
- 语法支持: `pyasc/docs/python_syntax_support.md`

### PyPTO — Tile-based 高层编程框架

- **仓库**: `pypto/` (v0.2.0, 561 py 文件)
- **核心范式**: PTO (Parallel Tensor/Tile Operation)，基于 Tile 的编程模型
- **编译流程**: Tensor Graph → Tile Graph → Block Graph → Execution Graph → CodeGen → PTO 虚拟指令 → 硬件
- **目标**: 简化复杂融合算子乃至整个模型网络的开发
- **分层抽象**: 算法开发者用 Tensor 层，性能专家用 Tile 层，系统开发者用 Block 层
- **已有大模型样例**: DeepSeek V3.2 (SFA/MLA)、GLM V4.5 (Attention/ExpertSelector)、Qwen3 Next、Arctic
- **调试**: `compile_debug_mode=1` 开启图可视化，golden vs actual 对比定位精度问题

**关键文档**:
- 文档中心: `pypto/docs/`
- 入门样例: `pypto/examples/01_beginner/` / `02_intermediate/` / `03_advanced/`
- 大模型: `pypto/models/deepseek_v32_exp/` / `glm_v4_5/`
- 调试指南: `pypto/docs/tutorials/debug/`
- Agent Skills: `pypto/.agents/skills/` (pypto-op-lint / pypto-precision-debug)

---

## 5. 模型推理部署

### 推理技术栈（基于 cann-learning-hub blogs）

| 技术 | 说明 | 文档 |
|:--|:--|:--|
| **vLLM-Ascend** | vLLM 在昇腾上的推理优化 | `blogs/inference/vllm_ascend_inference_optimization/` |
| **SGLang + Mooncake + HIXL** | PD 分离 D2D 部署方案 | `blogs/inference/sglang_mooncake_hixl_pd_separation_d2d/` |
| **HIXL KV Cache** | KV Cache 池化与跨节点传输 | `blogs/inference/hixl_mooncake_vllm_kv_cache_pooling/` |
| **SuperKernel** | 算子融合加速推理 | `blogs/inference/superkernel_inference_acceleration/` |
| **npugraph_ex** | 图模式优化（aclgraph 封装） | `blogs/inference/npugraph_ex_aclgraph_graph_mode/` |
| **TorchAir** | 自定义 FX Pass 多流并发 | `blogs/inference/torchair_fx_pass_multi_stream/` |
| **DeepSeek R1 SuperPoD** | Atlas 900 A3 超节点推理 | `blogs/inference/deepseek_r1_superpod_inference_optimization/` |
| **LongCat-Flash** | 长序列 Flash Attention 推理 | `blogs/inference/longcat_flash_superpod_inference_optimization/` |
| **Overlap Scheduling** | 计算与通信重叠吞吐优化 | `blogs/inference/overlap_scheduling_throughput_optimization/` |

### 大模型训练（blogs）

- **AReaL**: 全异步 RL 训练框架
- **SAM 投机解码**: 长序列 RL 训练
- **FlashRecovery**: 训练故障快速恢复方案

### 算子级技术

- **NDDMA**: 多维数据搬运（性能优化利器）
- **RTC (Runtime Compilation)**: 即时编译
- **Tiling 模板编程**: TilingKey 常量化优化
- **HCCL**: 集合通信（ReduceScatter/AllReduce/AllGather/AlltoAll）
- **AICPU Tiling 下沉**: 将 Tiling 计算下放到 AICPU 引擎
- **Kernel 直调**: 跳过框架直接调用 Kernel

---

## 6. MindSpore 对接

- MindSpore 模型可通过 ATC 工具转换为昇腾离线模型
- ATC `--framework` 参数支持 MindSpore（`.air` 格式，framework=1）
- 算子适配指南见 `asc-devkit-docs/docs/guide/编程指南/附录/AI框架算子适配/`

**注意**: 当前 9 个仓库中 MindSpore 的直接集成文档较少，主要通过在 `asc-devkit-docs` 的框架适配章节和 ATC 工具路径体现。独立 MindSpore 对接文档需查阅昇腾社区主站。

---

## 7. HarmonyOS AI 推理

### cann-recipes-harmony-infer 仓

- **定位**: 鸿蒙开发者技术实践库，CANN 平台端侧推理部署
- **目标硬件**: KirinX90 / Kirin9030 麒麟芯片

### 已落地实践案例

| 算子 | 应用场景 | 设备 |
|:--|:--|:--|
| QuantMatmul | 支付宝端侧大模型量化推理 | Kirin9030 |
| BandNorm | QQ 音乐声伴分离 | 鸿蒙设备 |
| RmsNorm | 智谱 GLM-Edge-1.5b-Chat 大模型 | KirinX90 |
| SliceGelu (融合算子) | 悟空图像 SDXL 大模型 | KirinX90 |
| SobelCustom | 边缘检测 CV 处理 | KirinX90 |

### 鸿蒙端侧开发流程

1. **算子开发**: 基于 Ascend C 编写 Kernel (.asc/.cpp) + Host 侧 Tiling
2. **编译**: `./build.sh` → 生成算子包
3. **部署**: 算子安装到 `opp/vendors/` 目录结构
4. **模型转换**: `atc --model=xxx.onnx --soc_version=KirinX90`
5. **算子入图 (GE)**: 算子注册 → Shape/DataType 推导 → 图编译执行
6. **调试**: NPU 仿真模式 (`msprof op simulator`)

### 关键文档

- Ascend C 鸿蒙开发指南: `cann-recipes-harmony-infer/docs/ascendc_develop_guide.md`
- ATC 工具指南: `cann-recipes-harmony-infer/docs/atc_tools_guide.md`
- 快速安装: `cann-recipes-harmony-infer/docs/quick_install.md`

### 鸿蒙与昇腾兼容性

- 从昇腾平台迁移到麒麟平台需参考 [迁移指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/cannkit-ascend-kirin-compatibility)
- 使用 `NPU_ARCH` 编译宏隔离不同架构
- 使用 `SocVersion` 在 Host 侧判断目标平台

---

## 8. 学习资源索引

### cann-learning-hub — 系统化教程

| 章节 | 内容 | 路径 |
|:--|:--|:--|
| 01 | 基础概述 (AI/算子基础 + CANN 架构 + NPU 原理) | `tutorials/.../01_basic_overview/` |
| 02 | Ascend C 基础 (HelloWorld + 编程范式 + Add 算子) | `tutorials/.../02_AscendC_basic/` |
| 03 | 中级矢量算子 (工程结构 + ACL/Pybind 调用 + Tiling) | `tutorials/.../03_intermediate_vector_operator_development/` |
| 04 | 矩阵乘基础 (Matmul + 高阶 API) | `tutorials/.../04_matmul_basic/` |
| 05 | 融合算子开发 | `tutorials/.../05_fused_operator_development/` |
| 07 | 排错专题 (CPU 调试 + NPU 上板 + 典型问题) | `tutorials/.../07_Troubleshooting/` |
| 08 | 性能优化 (profiling + 仿真分析 + 实践) | `tutorials/.../08_performance_optimization/` |

### 技术博客 (blogs/)

- **算子类** (12 篇): RegBase 编程、NDDMA、RTC 编译、HCCL 通信、TilingKey 模板、msSanitizer、Kernel 直调、矩阵乘选型、AICPU Tiling 下沉、CrossEntropyLoss 融合等
- **推理类** (10 篇): vLLM Ascend、HIXL、SuperKernel、npugraph_ex、SGLang/Mooncake、DeepSeek R1 SuperPoD、LongCat-Flash、TorchAir、Overlap Scheduling、torch_npu IPC
- **训练类** (3 篇): SAM 投机解码、AReaL 异步 RL、FlashRecovery

### cann-samples — 实战样例

```
Samples/0_Introduction/   # 入门样例 (vector_add, matmul 等)
Samples/1_Features/       # 功能特性 (memory/instruction/system_optimization, hardware_features)
Samples/2_Performance/    # 性能调优
```

### asc-devkit-docs/docs/guide/ — 完整编程指南

涵盖: 入门教程 / 编程模型(SIMD/SIMT/AICPU) / 编译运行 / 语言扩展层 / C++类库 API / 硬件实现 / 调试调优 / 兼容性迁移 / 算子实践参考 / 优秀实践案例 / FAQ

---

## 9. 仓库文件索引速查

| 仓库 | 本地路径 | 远程 (GitCode) | 核心内容 |
|:--|:--|:--|:--|
| asc-devkit | `asc-devkit/` | `cann/asc-devkit` | Ascend C SDK: API 头文件 + 实现 + 样例 + 测试 |
| asc-devkit-docs | `asc-devkit-docs/` | `cann/asc-devkit` (docs 分支) | 编程指南 + API 文档 + 样例说明 |
| asc-tools | `asc-tools/` | `cann/asc-tools` | 调试工具: cpu_debug/npu_check/msobjdump |
| cann-samples | `cann-samples/` | `cann/cann-samples` | 算子实战样例 (入门/特性/性能三级) |
| pyasc | `pyasc/` | `cann/pyasc` | Ascend C Python 前端 (MLIR) |
| pypto | `pypto/` | `cann/pypto` | Tile-based 高层编程框架 + 大模型样例 |
| cann-learning-hub | `cann-learning-hub/` | `cann/cann-learning-hub` | Jupyter Notebook 教程 + 技术博客 |
| cann-recipes-harmony-infer | `cann-recipes-harmony-infer/` | `cann/cann-recipes-harmony-infer` | 鸿蒙端侧推理实践 |
| cann-cmake | `cann-cmake/` | — | 多仓联合编译框架 |
| community | `community/` | `cann/community` | 社区治理 (SIG/TSC/PMC) |
