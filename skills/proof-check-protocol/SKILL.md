---
name: proof-check-protocol
description: >
  定理与证明审计协议。定义 proof-checker 的审计流程、检查清单和 verdict 格式。
  核心原则：零上下文输入，只读取 .tex 文件，独立判断数学严谨性。
  供 proof-checker Agent 引用。
when_to_use: 当论文含定理/证明/引理、进入 Phase 5 内部审计时加载。
---

<skill name="proof-check-protocol" domain="定理证明审计" version="1.0">

## 定理证明审计 — 核心问题

**定理陈述是否自洽？证明步骤是否逻辑严密？符号定义是否一致？**

审计员以**零上下文**方式运行：不接收作者对证明的说明或推导摘要。只接收 .tex 文件路径，独立读取判断。

---

## 审计输入

| 输入 | 类型 | 说明 |
|:-----|:-----|:-----|
| `paper.tex` | .tex 文件 | 论文正文（含 theorem/lemma/proof/definition 环境） |

**禁止输入**：
- 作者对证明思路的解释
- "证明的关键步骤是..."之类的提示

---

## 审计步骤

### Step 1: 提取定理结构
扫描 .tex 中的数学环境：
- `\begin{theorem}` / `\begin{lemma}` / `\begin{proposition}` / `\begin{corollary}`
- 记录每个环境的编号、标题、内容位置

### Step 2: 提取证明
- `\begin{proof}` 环境
- 建立 定理/引理 → 证明 的映射
- 标记"无证明"的定理（可能依赖"见附录"或"显然"）

### Step 3: 提取符号定义
- `\begin{definition}` 环境
- 行间公式中的首次出现符号
- 建立符号表：符号 → 定义位置 → 含义

### Step 4: 逐定理审查

| 检查项 | 通过标准 | 失败示例 |
|:-------|:---------|:---------|
| 自洽性 | 假设条件完整，结论可由假设逻辑推出 | 假设缺少"函数可微"但结论用了导数 |
| 证明完整 | 每个定理有证明或明确标注 | Theorem 3.2 无证明且无标注 |
| 步骤有据 | 每一步引用引理/定义/已知定理或显式推导 | "显然可得"但跳跃了 3 个代数步骤 |
| 无逻辑跳跃 | A → B → C，中间无断层 | 从式 (2) 直接到式 (5)，缺少 (3)(4) |
| 符号一致 | 同一符号全文含义不变 | `N` 在 Section 2 是样本数，在 Section 4 变成迭代次数 |
| 先定义后使用 | 新符号在首次使用前已定义 | `\mathcal{L}_{adv}` 突然出现，无前置定义 |
| 依赖完整 | 引理已被证明，无循环依赖 | Lemma 2.1 依赖 Lemma 2.3，而 2.3 又依赖 2.1 |
| 边界情况 | 退化情形被考虑 | 证明中除以 `\sigma^2` 但未说明 `\sigma \neq 0` |
| 量词正确 | ∀, ∃ 的绑定范围无歧义 | "∀x ∃y P(x,y)" 和 "∃y ∀x P(x,y)" 混用 |

---

## 裁决标准

| 裁决 | 条件 |
|:-----|:-----|
| **PASS** | 所有定理自洽、证明完整、步骤有据、符号一致、依赖完整 |
| **WARN** | 存在逻辑跳跃（需补充中间步骤）、符号定义可更清晰、边界情况未考虑 |
| **FAIL** | 定理陈述自相矛盾、证明存在根本性逻辑错误、关键步骤无依据、循环依赖 |
| **NOT_APPLICABLE** | 纯实验论文，无定理/证明 |
| **BLOCKED** | .tex 文件无法解析或无数学环境 |
| **ERROR** | 审计过程中出现未预期错误 |

---

## 符号表规范

审计产出中必须包含符号表摘要：
```json
{
  "symbol_table": {
    "N": {
      "defined_at": "Definition 2.1, Section 2.1",
      "meaning": "样本总数",
      "type": "scalar (positive integer)"
    },
    "\mathcal{L}": {
      "defined_at": "Equation (3), Section 3.1",
      "meaning": "损失函数",
      "type": "function: \Theta \to \mathbb{R}"
    }
  }
}
```

---

## 依赖图规范

审计产出中必须包含定理依赖图：
```json
{
  "dependency_graph": {
    "Theorem 3.1": ["Lemma 2.3", "Definition 2.1", "Assumption 1"],
    "Lemma 2.3": ["Definition 2.1"],
    "Theorem 3.2": ["Theorem 3.1", "Lemma 2.5"]
  }
}
```

---

## Verdict Artifact Schema

```json
{
  "audit_skill": "proof-checker",
  "verdict": "PASS",
  "reason_code": "all_checks_passed",
  "summary": "审计了 3 个定理、2 个引理、5 个定义，全部通过。",
  "findings": [],
  "symbol_table": { ... },
  "dependency_graph": { ... },
  "audited_input_hashes": {
    "paper.tex": "sha256:..."
  },
  "generated_at": "2026-05-01T14:23:01Z"
}
```

---

## 与 assurance 的接口

- `draft`：此审计仅在检测到论文含 theorem/lemma/proof 环境时运行，允许静默跳过
- `submission`：含定理的论文必须运行并发出六级裁决之一，禁止静默跳过

---

## 限制声明

**本审计员不做形式化验证**。它不调用 Lean/Coq/Isabelle 等定理证明器，而是以"人类审稿人"的标准进行逻辑审查：检查证明的可读性、逻辑链的完整性、符号的一致性。对于需要机器验证的关键系统（如密码学协议、安全证明），建议在论文完成后使用专门的形式化工具进行额外验证。

</skill>
