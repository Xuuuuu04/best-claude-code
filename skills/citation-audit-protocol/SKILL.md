---
name: citation-audit-protocol
description: >
  L4 引用审计协议。定义 引用审计员 的审计流程、检查清单和 verdict 格式。
  核心原则：零上下文输入，只读取 .tex 和 .bib 文件，独立判断引用完整性。
  供 引用审计员 Agent 引用。
when_to_use: 当论文进入 Phase 5 内部审计、或需要验证引用完整性时加载。
---

<skill name="citation-audit-protocol" domain="引用审计" version="1.0">

## L4 引用审计 — 核心问题

**每个 \cite 是否存在、元数据正确、上下文恰当？**

审计员以**零上下文**方式运行：不接收作者的文献说明或引用建议。只接收文件路径，独立读取判断。

---

## 审计输入

| 输入 | 类型 | 说明 |
|:-----|:-----|:-----|
| `paper.tex` | .tex 文件 | 论文正文，含所有 \cite 调用 |
| `references.bib` | .bib 文件 | 参考文献数据库 |

**禁止输入**：
- 作者的文献综述摘要
- "这些是我觉得相关的论文"
- 其他 Agent 的审查意见

---

## 审计步骤

### Step 1: 提取引用调用
从 .tex 中提取所有引用：
- `\cite{key}` / `\citep{key}` / `\citet{key}`
- `\cite{key1,key2}`（多引用）
- 注意 `\cite*` 变体

### Step 2: 建立 .bib 索引
读取 .bib 文件，建立 cite key → 条目的映射表。

### Step 3: 逐条核对

| 检查项 | 通过标准 | 失败示例 |
|:-------|:---------|:---------|
| 存在性 | 每个 cite key 在 .bib 中有条目 | `\cite{smith2020}` 但 .bib 中无此 key |
| 无 unresolved | 编译无 `??` 引用 | LaTeX 编译日志中有 `Citation 'xxx' undefined` |
| 元数据完整 | 条目含 title, author, year, venue | 条目缺少 year 或 venue |
| 上下文恰当 | 引用支持所在句子的论断 | 引用说"该方法有效"但原论文说的是"该方法在 X 场景下失效" |
| 格式正确 | \citep 用于括号引用，\citet 用于文本引用 | 文本中说"Smith et al. (2020) show..."但用了 `\citep` |
| 无占位 | 无 title="TODO" 或 author="Unknown" | .bib 中有个条目全是占位符 |
| 无重复 | .bib 中无重复 key | 同一个 key 出现两次 |
| Venue 正确 | 会议/期刊名称拼写正确 | `NIPS` 应为 `NeurIPS`，`ICML` 不应写成 `I.C.M.L.` |

### Step 4: 上下文恰当性检查（抽样）

对高风险引用进行上下文审查：
- 作者是否误读了被引用论文的结论？
- 引用是否支持作者所在的论断？
- 是否存在"引用堆砌"——引用了不直接相关的论文来撑门面？

**注意**：上下文检查是抽样而非穷尽，重点检查：
- Introduction 中的关键引用
- Related Work 中的对比引用
- Method 中的基础方法引用

---

## 裁决标准

| 裁决 | 条件 |
|:-----|:-----|
| **PASS** | 所有引用存在、元数据完整、格式正确、无 unresolved |
| **WARN** | 少量元数据不完整、venue 拼写不规范、少量格式混用 |
| **FAIL** | 存在 unresolved citation、占位条目、引用上下文严重不匹配 |
| **NOT_APPLICABLE** | 纯数学推导论文，无任何引用 |
| **BLOCKED** | .bib 文件缺失或无法解析 |
| **ERROR** | 审计过程中出现未预期错误 |

---

## Verdict Artifact Schema

```json
{
  "audit_skill": "引用审计员",
  "verdict": "PASS",
  "reason_code": "all_checks_passed",
  "summary": "审计了 47 个引用，全部通过。",
  "findings": [
    {
      "cite_key": "smith2020neural",
      "location": "Section 2, paragraph 3",
      "issue": null,
      "context": "Recent advances in neural architectures [Smith et al., 2020] have enabled..."
    }
  ],
  "audited_input_hashes": {
    "paper.tex": "sha256:a3f8...",
    "references.bib": "sha256:b2d1..."
  },
  "generated_at": "2026-05-01T14:23:01Z"
}
```

---

## 与 assurance 的接口

- `draft`：此审计仅在检测到论文含引用时运行，允许静默跳过
- `submission`：必须运行并发出六级裁决之一，禁止静默跳过

</skill>
