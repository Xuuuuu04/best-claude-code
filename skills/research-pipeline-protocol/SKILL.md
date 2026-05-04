---
name: research-pipeline-protocol
description: >
  科研流水线协议（ARIS W1→W3 适配）。覆盖 Idea Discovery → 实验实现 → 论文写作 → Rebuttal
  的完整 Stage 1-4 流程。定义每阶段的输入、输出、门控和 Agent 分配。
  供 学术论文写作专家、顶会顶刊审稿专家、技术调研专家 引用。
when_to_use: 当用户提到科研流水线、论文写作阶段、Idea Discovery、实验计划、rebuttal 流程时加载。
---

<skill name="research-pipeline-protocol" domain="科研流水线" version="1.0">

## 完整科研流水线（Stage 1-4）

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

## Stage 1: Idea Discovery

### 1.1 文献调研
- **输入**: 研究方向关键词、时间范围（默认近 5 年）
- **Agent**: 技术调研专家
- **输出**: 文献综述摘要（含关键论文、方法对比表、空白点识别）
- **门控**: 至少覆盖该方向 Top-3 会议近 2 年工作

### 1.2 想法生成
- **输入**: 文献综述 + 用户初步思路
- **Agent**: 学术论文写作专家（创意模式）
- **输出**: 3-5 个研究想法，每个含：问题定义、方法概述、预期贡献
- **门控**: 每个想法必须有明确的技术可行性和 novelty 方向

### 1.3 新颖性验证
- **输入**: 研究想法 + 文献库
- **Agent**: 顶会顶刊审稿专家（nightmare 难度预审）
- **输出**: novelty 评估报告（高/中/低 novelty + 风险点）
- **门控**: 至少有一个想法 novelty 评估为"高"才进入 Stage 2

### Stage 1 产出
| 文件 | 内容 |
|:-----|:-----|
| `IDEA_REPORT.md` | 选定想法、文献综述摘要、novelty 评估、风险评估 |

---

## Stage 2: 实验实现

### 2.1 实验计划
- **输入**: IDEA_REPORT + 可用资源（GPU/数据/时间）
- **Agent**: 机器学习工程师（如涉及模型）或 高级后端工程师（如涉及系统）
- **输出**: 实验计划书（baseline 列表、消融设计、评估指标、统计检验方法）
- **门控**: 必须包含至少 3 个 strong baseline 和完整消融实验设计

### 2.2 代码实现与运行
- **输入**: 实验计划书
- **Agent**: 对应领域 实现工程师
- **输出**: 实验代码 + 运行日志 + 结果数据
- **门控**: 代码审查（高级代码审查师）+ 安全审计（如涉及数据）

### 2.3 实验审计（L1）
- **输入**: 评估脚本、结果文件
- **Agent**: 高级代码审查师（专注实验诚实性）
- **输出**: EXPERIMENT_AUDIT.md
- **审计要点**:
  - 假 GT（ground truth 污染）
  - 分数自归一化（测试集泄露到训练）
  - 幽灵结果（无法复现的异常好成绩）
  - 统计检验正确性

### Stage 2 产出
| 文件 | 内容 |
|:-----|:-----|
| `EXPERIMENT_LOG.md` | 实验设置、超参数、结果表、消融结果、统计检验 |
| `EXPERIMENT_AUDIT.md` | L1 审计报告（代码诚实性） |

---

## Stage 3: 论文写作（Phase 0-6）

### Phase 0: 初始化
- 解析 assurance 等级（draft / submission）
- 加载 venue 模板（CVPR/NeurIPS/ACL/IEEE/毕业论文）
- 读取 IDEA_REPORT 和 EXPERIMENT_LOG（如有）
- **产出者**: 学术论文写作专家

### Phase 1: 大纲设计
- 结构化大纲（章节 + 每章核心论点）
- Claims matrix：每个 claim → 支撑实验/定理/引用
- 图表计划：每个图/表的位置、内容、预期传达信息
- **门控**: HUMAN_CHECKPOINT（可选）— 用户确认大纲方向
- **产出**: `paper-plan-{task-id}.md`

### Phase 2: 逐节撰写
- 按大纲顺序逐节撰写
- 每节完成后自检逻辑闭环
- Method 必须可复现（代码开源链接或伪算法）
- Experiment 必须可验证（结果精确到小数位、标准差、运行次数）
- **产出**: `.tex` 文件 + 配套 `.bib`

### Phase 3: 图表生成
- 从实验数据生成图表
- PDF 矢量图优先
- 图表自解释（不依赖正文即可理解）
- **产出**: `fig/` 目录下的 `.pdf`/`.png` 文件

### Phase 4: 编译检查
- `latexmk -pdf main.tex` 多遍编译
- 修复 overfull hbox、引用断裂、未解析引用
- **门控**: 编译必须零错误
- **产出**: 编译日志 + 修复记录

### Phase 5: 内部审计（assurance 触发）

assurance = draft 时：审计仅在内容检测器匹配时运行，允许静默跳过。

assurance = submission 时：以下审计必须全部执行并发出六级裁决：

| 审计 | 输入 | 输出 | 裁决要求 |
|:-----|:-----|:-----|:---------|
| 定理证明审计员（如有定理）| .tex 中的定理/证明 | proof-verdict.json | PASS/WARN/NOT_APPLICABLE |
| paper-claim-audit（L3）| .tex + 原始结果 | PAPER_CLAIM_AUDIT.md | PASS/WARN/FAIL/NOT_APPLICABLE |
| citation-audit（L4）| .bib + \cite{} 上下文 | CITATION_AUDIT.md | PASS/WARN/FAIL/NOT_APPLICABLE |

**关键原则**:
- L3/L4 审计员必须**零上下文**——不接收 EXPERIMENT_LOG、NARRATIVE_REPORT 或任何执行者摘要
- 所有审计必须写入 JSON verdict artifact（含 `audited_input_hashes` SHA256）

### Phase 6: 最终报告
- Final Report：论文摘要 + 关键贡献 + 局限性 + 未来方向
- submission-ready 标记
- assurance=submission 时：verifier 通过才最终化
- **产出**: `final-report-{task-id}.md`

### Stage 3 产出
| 文件 | 内容 |
|:-----|:-----|
| `paper-plan-{task-id}.md` | 大纲 + claims matrix + 图表计划 |
| `main.tex` + `*.bib` | 论文正文 |
| `fig/*.pdf` | 图表 |
| `proof-verdict.json` | 定理审计（如有）|
| `PAPER_CLAIM_AUDIT.md` | L3 数字审计 |
| `CITATION_AUDIT.md` | L4 引用审计 |
| `final-report-{task-id}.md` | 最终报告 |

---

## Stage 4: Rebuttal（Workflow 4）

### Phase 0-3: 解析审稿意见 + 制定策略
- 逐条解析审稿意见（按审稿人分组）
- 分类：事实错误 / 方法质疑 / 实验不足 / 文献遗漏 / 写作问题
- 制定回应策略：接受 / 反驳 / 补充实验

### Phase 4-7: 起草回应 + 安全门控

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

### Stage 4 产出
| 文件 | 内容 |
|:-----|:-----|
| `PASTE_READY.txt` | 精确字数，直接粘贴到投稿系统 |
| `REBUTTAL_DRAFT_rich.md` | 详细版，含出处/承诺/覆盖标注，供用户自行修改 |

---

## Agent 分配表

| Stage | 主要 Agent | 审查 Agent | 产出 artifact |
|:--|:--|:--|:--|
| 1.1 文献调研 | 技术调研专家 | 高级调研审查师 | `tech-research-*` |
| 1.2 想法生成 | 学术论文写作专家 | — | `IDEA_REPORT.md` |
| 1.3 新颖性验证 | 顶会顶刊审稿专家 | — | novelty 评估 |
| 2.1 实验计划 | 机器学习工程师 / 资深系统架构师 | — | 实验计划书 |
| 2.2 代码实现 | 实现工程师-* | 高级代码审查师 | `impl-report-*` |
| 2.3 实验审计 | 高级代码审查师 | — | `EXPERIMENT_AUDIT.md` |
| 3.0-3.6 论文写作 | 学术论文写作专家 | 顶会顶刊审稿专家 | `.tex`, `.bib`, audit reports |
| 4.0-4.7 Rebuttal | 学术论文写作专家 | 顶会顶刊审稿专家 | `PASTE_READY.txt` |

</skill>
