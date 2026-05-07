---
name: academic-paper
description: >
  学术论文撰写与审查协议（v2，ARIS 增强版）。覆盖 LaTeX 撰写、文献管理、
  顶会顶刊审稿标准、5 维学术审计、论文写作阶段门控（Phase 0-6）、
  assurance 动态门控、四层证据审计栈引用、rebuttal 安全门控。
when_to_use: 当用户提到论文/paper/学术写作/毕业论文/期刊/会议/LaTeX/审稿/文献综述/rebuttal 时自动加载。
---

<skill name="academic-paper" domain="学术论文撰写与审查" max-review-rounds="3">

<knowledge type="workflow" id="research-pipeline">
## 完整科研流水线（ARIS W1→W3 适配）

```
Stage 1: Idea Discovery（可选）
  ├── 文献调研 /research-lit
  ├── 想法生成 /idea-creator
  ├── 新颖性验证 /novelty-check
  └── 输出: IDEA_REPORT.md

Stage 2: 实验实现（可选）
  ├── 实验计划 /experiment-plan
  ├── 代码实现
  └── 输出: EXPERIMENT_LOG.md

Stage 3: 论文写作（Workflow 3）
  ├── Phase 0: 解析 assurance + 加载模板
  ├── Phase 1: 大纲设计 paper-plan
  ├── Phase 2: 逐节写作 paper-write
  ├── Phase 3: 图表生成 paper-figure
  ├── Phase 4: 编译与格式检查 paper-compile
  ├── Phase 5: 内部审计（assurance 门控）
  │   ├── 5.1 定理证明审计员（如有定理）
  │   ├── 5.5 paper-claim-audit（数字审计）
  │   └── 5.8 citation-audit（引用审计）
  └── Phase 6: 最终报告 Final Report

Stage 4: Rebuttal（Workflow 4，审稿意见到达后）
  ├── Phase 0-3: 解析审稿意见 + 制定策略
  ├── Phase 4-7: 起草回应 + 安全门控
  └── 输出: PASTE_READY.txt + REBUTTAL_DRAFT_rich.md
```

</knowledge>

<knowledge type="assurance" id="assurance-integration">
## Assurance 动态门控

论文写作支持两档 assurance：

| 等级 | 审计行为 | 静默跳过 | 适用场景 |
|:-----|:---------|:---------|:---------|
| `draft`（默认） | 审计仅在内容检测器匹配时运行 | 允许 | 快速迭代、探索性草稿 |
| `submission` | 所有强制审计必须发出裁决 | 禁止 | 投稿/提交/毕业答辩 |

**六级裁决状态机**（每项强制审计必须发出其一）：

| 裁决 | 含义 | submission 阻塞？ |
|:-----|:-----|:------------------|
| PASS | 全部通过 | 否 |
| WARN | 发现问题，非取消资格 | 否 |
| FAIL | 取消资格问题 | **是** |
| NOT_APPLICABLE | 无内容可审计（已检查） | 否 |
| BLOCKED | 应运行但前提缺失 | **是** |
| ERROR | 审计调用失败 | **是** |

**默认映射**：effort=balanced/lite → draft；effort=max → submission。
可显式覆盖：`— effort: balanced, assurance: submission`
</knowledge>

<knowledge type="audit-stack" id="four-layer-audit">
## 四层证据审计栈

| 层级 | 审计对象 | 核心问题 | 输入 | 输出 |
|:-----|:---------|:---------|:-----|:-----|
| L1 实验审计 | 评估脚本 | 代码是否诚实？假 GT、分数自归一化、幽灵结果 | *eval*.py, *.json, *.csv | EXPERIMENT_AUDIT.md |
| L2 结果审计 | 结果→声明映射 | 数据是否科学支持此声明？ | 实验日志、基准数据 | findings.md 更新 |
| L3 数字审计 | 论文中的数字 | 论文是否如实精确报告数据？（零上下文新鲜审稿） | .tex + 原始结果 | PAPER_CLAIM_AUDIT.md |
| L4 引用审计 | 参考文献 | 每个 \cite 是否存在、元数据正确、上下文恰当？ | .bib + \cite{} 上下文 | CITATION_AUDIT.md |

**核心原则**：
- L3/L4 审计员必须**零上下文**——不接收 EXPERIMENT_LOG、NARRATIVE_REPORT 或任何执行者摘要
- 所有审计必须写入 JSON verdict artifact（含 `audited_input_hashes` SHA256）
- `submission` 模式下，Phase 6 调用 verifier；非零退出阻塞 Final Report
</knowledge>

<knowledge type="scoring" id="conference-review-standards">
## 顶会顶刊审稿标准

| 分数 | 含义 | 推荐 |
|:--|:--|:--|
| 9-10 | 杰出 | Strong Accept |
| 7-8 | 优秀 | Accept |
| 5-6 | 合格但有不足 | Borderline |
| 3-4 | 需重大修改 | Reject |
| 1-2 | 根本缺陷 | Strong Reject |
</knowledge>

<checklist type="audit" id="5-dim-academic-audit" problem-tags="严重,一般,轻微">
### 5 维学术审计

| 维度 | 权重 | 关键检查 |
|:--|:--|:--|
| 贡献新颖性 | 25% | 与前人本质区别、增量之嫌 |
| 方法论合理性 | 25% | 逻辑正确性、隐藏假设 |
| 实验严谨性 | 20% | Baseline/消融/统计检验 |
| 论证链完整性 | 15% | 结论由实验支撑 |
| 文献覆盖 | 15% | 关键相关工作、最新进展 |

每个问题标记 `[严重]`/`[一般]`/`[轻微]`。
</checklist>

<knowledge type="rebuttal" id="rebuttal-safety">
## Rebuttal 安全门控（Workflow 4）

三道硬门控——任一失败则**不最终化**：

1. **Provenance Gate（出处门控）**
   - 每个事实陈述必须映射到：`paper` / `review` / `user_confirmed_result` / `user_confirmed_derivation` / `future_work`
   - 无来源 = 阻塞

2. **Commitment Gate（承诺门控）**
   - 每个承诺必须映射到：`already_done` / `approved_for_rebuttal` / `future_work_only`
   - 未批准 = 阻塞

3. **Coverage Gate（覆盖门控）**
   - 每个审稿人关切必须归属：`answered` / `deferred_intentionally` / `needs_user_input`
   - 无 issue 可消失

**两版输出**：
- `PASTE_READY.txt`：精确字数，直接粘贴到投稿系统
- `REBUTTAL_DRAFT_rich.md`：详细版，供用户自行修改
</knowledge>

<knowledge type="paper-writing-phases" id="phase-gates">
## 论文写作阶段门控（Phase 0-6）

| Phase | 名称 | 内容 | Gate |
|:--|:--|:--|:--|
| 0 | 初始化 | 解析 assurance + 加载 venue 模板 + 读取 IDEA_REPORT / EXPERIMENT_LOG | — |
| 1 | 大纲设计 | 结构化大纲 + claims matrix + 图表计划 | HUMAN_CHECKPOINT（可选） |
| 2 | 逐节写作 | 按大纲逐节撰写，每节自检逻辑闭环 | — |
| 3 | 图表生成 | 从实验数据生成图表（figure-spec / paper-figure） | — |
| 4 | 编译检查 | latexmk 多遍编译 + 修复 overfull / 引用断裂 | 编译必须零错误 |
| 5 | 内部审计 | 按 assurance 等级触发审计栈 | submission 强制 |
| 6 | 最终报告 | Final Report + submission-ready 标记 | verifier 通过 |
</knowledge>

<reference type="latex-norms" id="latex-standards" activates="rules/_lang/latex.md">
## LaTeX 规范

编辑 .tex 文件时自动激活 `rules/_lang/latex.md` Rule。核心要求：

- **模板**：CVPR/ICCV (cvpr.sty)、NeurIPS/ICML (neurips_20xx.sty)、ACL (acl.sty)、IEEE (IEEEtran)
- **图片**：PDF 矢量图优先，`\includegraphics[width=\linewidth]{fig.pdf}`
- **表格**：booktabs，不显示竖线
- **引用**：natbib `\citep{}` `\citet{}`，所有 cite 在 .bib 有对应
- **数学**：`\begin{equation}` 编号，行内 `$...$`，不用 `$$`
- **交叉引用**：`\label{}` + `\ref{}` / `\cref{}`
- **编译**：`latexmk -pdf main.tex`
- **盲审**：删除 `\author{}`、致谢、机构信息
- **页数**：严格遵守目标会议/期刊限制
</reference>

<reference type="paper-templates" id="paper-type-matrix">
## 论文类型与模板

| 类型 | 模板 | 页数 |
|:--|:--|:--|
| CV 顶会 | CVPR/ICCV 官方模板 | 8 |
| ML 顶会 | NeurIPS/ICML 官方模板 | 8-9 |
| NLP 顶会 | ACL/EMNLP 官方模板 | 8 |
| 毕业论文 | 学校模板 | 按学校要求 |
| 课程论文 | IEEE/ACM 通用 | 4-6 |
</reference>

<knowledge type="reviewer-difficulty" id="difficulty-levels">
## 审稿难度分级（ARIS 适配）

| 等级 | 特征 | 适用场景 |
|:-----|:-----|:---------|
| `medium` | 标准审稿，按 5 维审计清单打分 | 常规审查 |
| `hard` | 增加 Reviewer Memory（跨轮追踪怀疑点）+ Debate Protocol（作者可反驳，审稿人裁决） | 重要投稿前 |
| `nightmare` | hard + 审稿人直接读取原始文件（不受作者过滤）+ Adversarial Verification | 最终 stress test |

**Debate Protocol**：
- 作者对审稿意见提交 rebuttal
- 审稿人裁决：SUSTAINED / OVERRULED / PARTIALLY SUSTAINED
- 最多 3 轮辩论
</knowledge>

</skill>
