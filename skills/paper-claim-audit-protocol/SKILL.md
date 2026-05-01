---
name: paper-claim-audit-protocol
description: >
  L3 论文数字审计协议。定义 paper-claim-auditor 的审计流程、检查清单和 verdict 格式。
  核心原则：零上下文输入，只读取 .tex 和原始结果文件，独立判断数字精确性。
  供 paper-claim-auditor Agent 引用。
when_to_use: 当论文进入 Phase 5 内部审计、或需要验证论文数字与原始数据一致性时加载。
---

<skill name="paper-claim-audit-protocol" domain="论文数字审计" version="1.0">

## L3 数字审计 — 核心问题

**论文是否如实精确报告了数据？**

审计员以**零上下文**方式运行：不接收 EXPERIMENT_LOG、NARRATIVE_REPORT 或任何作者摘要。只接收文件路径，独立读取判断。

---

## 审计输入

| 输入 | 类型 | 说明 |
|:-----|:-----|:-----|
| `paper.tex` | .tex 文件 | 论文正文 |
| `results/*.json` | JSON/CSV/TXT | 原始实验结果 |

**禁止输入**：
- 作者对结果的解释
- EXPERIMENT_LOG
- 其他 Agent 的审查意见

---

## 审计步骤

### Step 1: 提取数字声明
从 .tex 中提取所有数值声明：
- 主结果（准确率、F1、BLEU、mAP 等）
- 消融实验结果
- 统计检验（p-value、t-test、ANOVA）
- 标准差、置信区间
- 百分比、比率

### Step 2: 定位原始数据
在原始结果文件中定位对应数据：
- 按指标名称匹配
- 按实验设置匹配（数据集、模型、超参数）
- 注意同名不同义陷阱

### Step 3: 逐条比对

| 检查项 | 通过标准 | 失败示例 |
|:-------|:---------|:---------|
| 精确匹配 | 论文值 ≈ 原始值（考虑 rounding） | 论文说 94.5%，原始是 94.47% → 需确认 rounding 规则 |
| 单位一致 | 论文和原始数据单位相同 | 论文说 %，原始是小数 → 不一致 |
| 方差报告 | 多次运行报告了 std 或 CI | 只报告一次运行的结果 |
| 无幽灵结果 | 论文中的每个数字都有来源 | 论文中有个数字在原始结果中找不到 |
| 无选择性报告 | 没有隐藏负面结果 | 只报告 5 次运行中最好的一次 |
| Baseline 一致 | Baseline 数值与原始一致 | Baseline 数字被悄悄调高了 |
| 消融一致 | 消融实验数值与原始一致 | 消融结果与原始不符 |

### Step 4: 处理 Rounding

Rounding 规则不一致**不自动视为 FAIL**，需标注：
- 论文整体 rounding 策略是否一致？
- 如果论文统一保留 1 位小数，94.47% → 94.5% 是合理的
- 但如果同一表格中有些保留 1 位、有些保留 2 位，需 WARN

---

## 裁决标准

| 裁决 | 条件 |
|:-----|:-----|
| **PASS** | 所有数字与原始结果一致，rounding 策略一致，方差信息完整 |
| **WARN** | Rounding 不一致、单位标注模糊、缺少部分方差信息 |
| **FAIL** | 数字与原始结果不符、存在幽灵结果、选择性报告、Baseline 被篡改 |
| **NOT_APPLICABLE** | 纯理论论文，无实验数字 |
| **BLOCKED** | 原始结果文件缺失或无法解析 |
| **ERROR** | 审计过程中出现未预期错误 |

---

## Verdict Artifact Schema

```json
{
  "audit_skill": "paper-claim-auditor",
  "verdict": "PASS",
  "reason_code": "all_checks_passed",
  "summary": "审计了 23 个数字声明，全部与原始结果一致。",
  "findings": [
    {
      "location": "Table 2, Row 3",
      "claim": "Accuracy = 94.5%",
      "source": "results/main_exp.json:accuracy",
      "source_value": 0.9447,
      "status": "match",
      "note": "Rounding: 保留 1 位小数，一致"
    }
  ],
  "audited_input_hashes": {
    "paper.tex": "sha256:a3f8...",
    "results/main_exp.json": "sha256:b2d1..."
  },
  "generated_at": "2026-05-01T14:23:01Z"
}
```

---

## 与 assurance 的接口

- `draft`：此审计仅在检测到论文含数字时运行，允许静默跳过
- `submission`：必须运行并发出六级裁决之一，禁止静默跳过

</skill>
