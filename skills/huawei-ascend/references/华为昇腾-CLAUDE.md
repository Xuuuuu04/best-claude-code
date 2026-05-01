# 华为昇腾 CANN 生态 — 多仓库工作区

Ascend C 算子开发与 Agent DEBUG 课题研究环境。9 个并列子仓库覆盖 CANN 核心 SDK、调试工具、Python 前端、样例教程和鸿蒙端侧推理。

---

## 实验环境（NPU 实测唯一入口）

**主机**：华为云 ModelArts Notebook（SSH 别名 `ascendyun` / `modelarts` / `ma-notebook`）
- `ssh ascendyun` → `ma-user@dev-modelarts.cn-southwest-2.huaweicloud.com:32521`
- 密钥 `~/.ssh/KeyPair-b6d9.pem`，1 张昇腾 NPU（`/dev/davinci0`），EulerOS aarch64

**激活**：`source ~/work/i-ma` → 进 `(pypto)` conda env
（Python 3.11 + torch 2.7.1 + torch_npu 2.7.1.post2 + CANN 8.5.2 + Node 24 + Cangjie 1.1）

**铁律**：**只有 `~/work` 持久化**，其他目录（含 `~/`、`/tmp`）重启即丢。所有代码/数据/conda env 必须放 `~/work` 下。

> 详细字典与 i-ma 内容见 memory `dev-environment.md`；旧 ECS（1.95.82.88）已弃用。

---

## 技术栈

| 层 | 技术 |
|:--|:--|
| 算子语言 | Ascend C（C++ 方言，含 `.asc` 扩展名） |
| 编译器 | bisheng（华为定制 Clang-based） |
| 运行时 | CANN toolkit（`source set_env.sh`） |
| Python 前端 | pyasc（MLIR-based）/ pypto（Tile-based） |
| 构建 | CMake + `build.sh` 封装 |
| 目标硬件 | Ascend 910B/C、Ascend 950PR、鸿蒙端侧（Atlas A2/A3） |
| 调试工具 | cpu_debug / npu_check / msobjdump / msSanitizer / msprof |

---

## 子仓库

| 仓库 | 定位 | 规模 |
|:--|:--|:--|
| `asc-devkit` | Ascend C 核心开发套件（API、样例、测试） | ~4838 cpp/h/asc |
| `asc-tools` | 调试工具集（cpu_debug / npu_check / msobjdump） | ~156 cpp/h |
| `cann-samples` | 算子功能样例（入门/特性/性能三级） | ~319 cpp/h |
| `pyasc` | Ascend C Python 前端（MLIR 后端） | ~255 py/cpp |
| `pypto` | Tile-based 高层编程框架（大模型样例） | ~561 py |
| `cann-learning-hub` | Jupyter Notebook 教程（8 章 + 排错专题） | 文档为主 |
| `cann-recipes-harmony-infer` | 鸿蒙端侧推理算子案例 | ~10 算子 |
| `cann-cmake` | 多仓联合编译框架（CMake/Shell） | 工具仓 |
| `community` | 社区治理文档（SIG、CLA） | 纯文档 |

---

## 构建/测试命令

### asc-devkit（核心仓）
```bash
source /usr/local/Ascend/cann/set_env.sh
cmake -B build -DCMAKE_ASC_RUN_MODE=cpu -DCMAKE_ASC_ARCHITECTURES=dav-2201
cmake --build build
cd build && ctest
```

### asc-tools
```bash
bash build.sh
cd build && ctest
```

### cann-samples
```bash
cmake -B build && cmake --build build
```

### pyasc
```bash
cmake -B build && cmake --build build
cd python && pip install -e .
pytest python/test/
```

### pypto
```bash
pip install -e .
pytest python/tests/
```

**CPU 调试模式**无需 NPU 硬件。通过 `-DCMAKE_ASC_RUN_MODE=cpu` 启用，npu_check 同步运行并输出结构化错误日志。

---

## 核心铁律

1. **CPU 调试先行** — 所有算子先在 `cpu` 模式验证通过，再上 NPU
2. **npu_check 必须过** — 每次算子改动后跑 npu_check，ErrorRead/Write/Sync 零容忍
3. **Tiling 32 字节对齐** — tiling 参数计算必须满足 32B 对齐，否则必出 ErrorRead3/ErrorWrite2
4. **不越过 Agent 直接改算子代码** — 中高复杂度改动走流水线（product-analyst → implementer → code-reviewer）
5. **bisheng 编译错误 ≠ 代码错误** — 先查 Ascend C API 约束文档，再改代码
6. **枚举/状态字段必须对账** — 涉及 API 字段判断时，先 grep 已有代码确认方向与类型（见接口字段对账规则）
7. **不提交 `.env` / credentials / token** — 已在 `.gitignore` 覆盖

---

## Agent 调度指引

### 课题方向
为 Ascend C 算子开发构建 **Agent DEBUG 系统**。5 个候选切入方向：

- **A（推荐）**：npu_check 错误自动修复 Agent — 解析结构化错误码 → 定位源码 → 生成修复
- **B**：Tiling 参数静态检查 Agent — 编译前发现对齐 bug
- **C**：编译错误 → 修复建议 Agent — bisheng stderr + API 文档 RAG
- **D**：精度 DEBUG Agent（PyPTO/PyAsc）— golden vs actual 对比定位
- **E**：典型错误 Pair 数据集 + 评测基准 — buggy/fixed pair 构建

### 流水线命令
| 场景 | 命令 |
|:--|:--|
| 新功能/新算子 | `/bcc-new-feature` |
| Bug 修复 | `/bcc-fix-bug` |
| 研究调研 | 派 `repo-researcher` 或 `tech-researcher` |
| 代码审查 | 派 `code-reviewer` |

### 派遣原则
- **仓库内问题** → `repo-researcher`（先在 asc-devkit/asc-tools/cann-samples 中定位）
- **外部资料/API 文档** → `tech-researcher`
- **算子代码实现** → `implementer-backend`（Ascend C = C++ 方言）
- **Python 前端/框架** → `implementer-backend`（pyasc/pypto）
- **小程序/鸿蒙端侧** → `miniprogram-dev`（cann-recipes-harmony-infer）

### 关键知识入口
- Ascend C API 约束 → `asc-devkit/impl/` 头文件 + `asc-devkit/docs/`
- npu_check 错误类型体系 → `asc-tools/docs/02_npu_check.md`（15 类错误码）
- 典型错误 Pair → `cann-learning-hub/tutorials/.../07_Troubleshooting/answer/`
- Debug 工具方法 → `asc-tools/docs/` 系列 + `pypto/docs/tutorials/debug/`

---

## @imports

- `.claude/skills/project-knowledge/SKILL.md` — 完整仓库索引与 debug 课题详情
- `.claude/artifacts/init-analysis-audit-20260428-01-cann-workspace.md` — 初始化扫描报告
- `.claude/artifacts/research-audit-20260428-01-cann-workspace.md` — 算子 debug 课题研究备忘
