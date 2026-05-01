# Ascend C 调试工具集

CANN 算子调试工具套件，含 cpu_debug（CPU 孪生调试）、npu_check（内存/同步错误检测）、msobjdump（ELF 解析）、show_kernel_debug_data（DumpTensor 离线解析）。Agent DEBUG 课题错误码体系的核心来源。

## 技术栈

- **语言**：C++、Python（npuchk 报告脚本）
- **构建**：`bash build.sh`
- **测试**：gtest（`tests/ut/`）+ pytest（`tests/py_ut/`）

## 构建/测试

```bash
bash build.sh
cd build && ctest
pytest tests/py_ut/
```

## 核心模块

| 目录 | 内容 |
|:--|:--|:--|
| `cpudebug/` | CPU 孪生调试库（`include/kernel_vectorized.h` + `src/`） |
| `npuchk/ascendc_npuchk_report.py` | npu_check 核心脚本 — 解析运行时错误日志 |
| `utils/msobjdump/` | 算子 ELF 文件解析 |
| `utils/show_kernel_debug_data/` | DumpTensor/printf 数据离线解析 |
| `docs/01_cpu_debug.md` | CPU 调试方法（GDB、`follow-fork-mode child`） |
| `docs/02_npu_check.md` | **npu_check 15 类错误码完整文档**（ErrorRead1-4 等） |
| `docs/04_show_kernel_debug_data.md` | 离线调试数据解析指南 |
| `examples/` | 工具使用样例 |
| `tests/ut/` + `tests/py_ut/` | 工具测试 |

## 核心铁律

1. `docs/02_npu_check.md` 的 15 类错误码是 Agent 错误分类的知识真源，不能凭记忆引用
2. npu_check 在 cpu 模式下同步运行 — 无需 NPU 即可获得完整错误日志
3. msobjdump 解析的是 bisheng 编译产出的 ELF，不是通用 ELF

## npu_check 错误码速查

ErrorRead(1-4) 非法/未写即读/越界/未对齐 | ErrorWrite(1-4) 非法/越界/重复/未对齐 | ErrorSync(1-4) 缺失/不配对/eventID重复 | ErrorLeak/ErrorFree 泄漏/重复释放 | ErrorBuffer(0-4) 初始化/类型/操作/地址/资源池。详参 `docs/02_npu_check.md`。

## Agent 调度指引

- **错误码体系查询** → 读 `docs/02_npu_check.md`（不凭记忆）
- **cpu_debug 工作流** → 读 `docs/01_cpu_debug.md` + `examples/02_cpudebug/`
- **npu_check 日志解析** → 参考 `npuchk/ascendc_npuchk_report.py` 的输出格式

## @imports

- `../CLAUDE.md` — 工作区根指令
- `../.claude/skills/project-knowledge/SKILL.md` — 完整仓库索引
