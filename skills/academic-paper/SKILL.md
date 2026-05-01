---
name: academic-paper
description: 学术论文撰写与审查协议。覆盖 LaTeX 撰写、文献管理、顶会顶刊审稿标准、5 维学术审计（新颖性/方法论/实验/论证/文献）。
when_to_use: 当用户提到论文/paper/学术写作/毕业论文/期刊/会议/LaTeX/审稿/文献综述时自动加载。
---

<skill name="academic-paper" domain="学术论文撰写与审查" max-review-rounds="3">

<knowledge type="workflow" id="paper-review-loop">
## 论文撰写-审查闭环

```
用户需求 → 学术论文写作专家 产出初稿
  ↓
顶会顶刊审稿专家 5 维审查
  ↓ REVIEW_REJECT → 修订 → 再审查（max 3 轮）
REVIEW_PASS → 交付
```
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

</skill>
