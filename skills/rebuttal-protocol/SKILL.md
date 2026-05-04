---
name: rebuttal-protocol
description: >
  Rebuttal 安全门控协议（ARIS Workflow 4 适配）。定义审稿意见回应的三道硬门控：
  Provenance Gate（出处）、Commitment Gate（承诺）、Coverage Gate（覆盖）。
  产出 PASTE_READY.txt（直接粘贴）和 REBUTTAL_DRAFT_rich.md（详细版）。
  供 学术论文写作专家 在 Stage 4 Rebuttal 阶段引用。
when_to_use: 当用户提到 rebuttal、审稿意见回应、response letter、revision 时加载。
---

<skill name="rebuttal-protocol" domain="学术 Rebuttal" version="1.0">

## Rebuttal 安全门控

三道硬门控——任一失败则**不最终化** rebuttal。

---

### Gate 1: Provenance Gate（出处门控）

**规则**：每个事实陈述必须映射到明确来源。

**有效来源标签**：
| 标签 | 含义 | 使用场景 |
|:-----|:-----|:---------|
| `paper` | 来自论文原文 | 回应"实验设置"类问题时引用论文章节 |
| `review` | 来自审稿意见 | 复述审稿人关切时标注 |
| `user_confirmed_result` | 用户确认的实验/计算结果 | 补充实验数据 |
| `user_confirmed_derivation` | 用户确认的推导/证明 | 补充理论推导 |
| `future_work` | 未来工作计划 | 承认当前未做但计划做 |

**阻塞条件**：任何事实陈述无来源标签 → 阻塞

**检查方法**：逐条扫描 rebuttal 文本，每句含事实断言的必须能找到对应来源标签。

---

### Gate 2: Commitment Gate（承诺门控）

**规则**：每个承诺必须映射到明确状态。

**有效承诺标签**：
| 标签 | 含义 | 使用场景 |
|:-----|:-----|:---------|
| `already_done` | 已完成，无需额外工作 | 审稿人要求的实验其实已做 |
| `approved_for_rebuttal` | 已获批准，将在本轮 rebuttal 中补充 | 需要补充实验/分析 |
| `future_work_only` | 仅作为未来方向，不在本轮完成 | 超出论文范围的建议 |

**阻塞条件**：任何承诺未标注状态或标注为 `approved_for_rebuttal` 但未获用户确认 → 阻塞

**检查方法**：扫描所有"we will" / "we plan to" / "in the revised version" 等承诺句式，确认有标签。

---

### Gate 3: Coverage Gate（覆盖门控）

**规则**：每个审稿人关切必须被处理，无 issue 可消失。

**有效覆盖标签**：
| 标签 | 含义 | 使用场景 |
|:-----|:-----|:---------|
| `answered` | 已直接回应 |  majority of issues |
| `deferred_intentionally` | 故意推迟，有明确理由 | 超出范围或需要额外实验周期 |
| `needs_user_input` | 需要用户决策 | 涉及重大修改方向时 |

**阻塞条件**：任何审稿人原始关切无覆盖标签 → 阻塞

**检查方法**：建立审稿意见索引表，逐条核对 rebuttal 中是否有对应回应。

---

## Rebuttal 起草流程

### Phase 0: 解析审稿意见
1. 按审稿人分组（Reviewer 1, Reviewer 2, ...）
2. 逐条提取：关切类型、严重程度、涉及章节
3. 分类：
   - **事实错误**：审稿人误解了论文内容
   - **方法质疑**：对方法合理性的质疑
   - **实验不足**：要求补充实验/分析
   - **文献遗漏**：要求补充引用
   - **写作问题**：表述不清、结构问题

### Phase 1: 制定回应策略
| 关切类型 | 推荐策略 | 示例措辞 |
|:---------|:---------|:---------|
| 事实错误 | 礼貌澄清 + 引用论文具体位置 | "We appreciate the reviewer's concern. In Section 3.2, we explicitly state that..." |
| 方法质疑 | 解释设计 rationale + 补充直觉 | "We chose X over Y because..." |
| 实验不足 | 承诺补充实验（需用户批准）或解释为何不需要 | "We will add ablation experiments on Z." |
| 文献遗漏 | 补充引用 + 简要说明与本文关系 | "We thank the reviewer for pointing this out. We have added [XX] to Section 2." |
| 写作问题 | 承认并承诺修改 + 说明修改位置 | "We agree and have clarified this in the revised Section 4.1." |

### Phase 2: 起草详细回应
- 对每个审稿人的每条意见写回应
- 在回应旁标注来源标签（Provenance）
- 对涉及承诺的句子标注承诺标签（Commitment）
- 在索引表中更新覆盖状态（Coverage）

### Phase 3: 安全门控检查
- 运行 Provenance Gate：所有事实有来源？
- 运行 Commitment Gate：所有承诺有状态？
- 运行 Coverage Gate：所有关切有覆盖？
- 任一失败 → 返回 Phase 2 修正

### Phase 4: 生成双版本输出

**版本 A: PASTE_READY.txt**
- 精确字数（多数投稿系统有字数限制）
- 纯文本格式，可直接粘贴
- 不含标注标签（门控已内化）
- 结构：按审稿人分组 → 逐条回应

**版本 B: REBUTTAL_DRAFT_rich.md**
- Markdown 格式，含完整标注
- 保留 Provenance/Commitment/Coverage 标签
- 供用户自行修改和存档
- 含修改对照表（原文 vs 修改后）

---

## Rebuttal 格式规范

### PASTE_READY.txt 结构
```
Response to Reviewer 1

Q1: {审稿人原文关切，精简概括}
A: {回应，≤150词/条}

Q2: ...
A: ...

Response to Reviewer 2
...
```

### REBUTTAL_DRAFT_rich.md 结构
```markdown
# Rebuttal Draft: {paper-title}
**Task ID**: {task-id}
**生成时间**: {timestamp}
**总字数**: {count}

## 审稿意见索引表
| # | 审稿人 | 关切 | 类型 | 策略 | 覆盖状态 |
|:--|:--|:--|:--|:--|:--|
| 1 | R1 | ... | 实验不足 | 补充消融 | answered |

## Response to Reviewer 1

### Q1: {原文}
**来源**: review
**策略**: 补充实验
**承诺**: approved_for_rebuttal [用户已确认]

{详细回应...}

### Q2: {原文}
**来源**: review
**策略**: 澄清事实
**承诺**: already_done

{详细回应...}
```

---

## 常见错误

| 错误 | 后果 | 修正 |
|:-----|:-----|:-----|
| 遗漏审稿人某条意见 | Coverage Gate 失败 | 建立索引表逐条核对 |
| 承诺补充实验但未获用户确认 | Commitment Gate 失败 | 标注 `needs_user_input` 或删除承诺 |
| 引用未发表的实验结果无来源 | Provenance Gate 失败 | 标注 `user_confirmed_result` 或删除 |
| 语气防御性过强 | 审稿人反感 | 保持礼貌，聚焦事实 |
| 回应过长 | 投稿系统截断 | 控制在字数限制内 |

---

## 与 顶会顶刊审稿专家 的接口

Rebuttal 起草完成后，可派 顶会顶刊审稿专家 审查：
- 检查 rebuttal 是否充分回应了所有关切
- 评估语气是否恰当
- 验证承诺是否现实可行
- 裁决：SUSTAINED（原关切仍成立）/ OVERRULED（已充分回应）/ PARTIALLY SUSTAINED

审查产出：`review-rebuttal-{task-id}.md`

</skill>
