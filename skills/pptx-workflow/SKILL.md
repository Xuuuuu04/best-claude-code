---
name: pptx-workflow
description: PowerPoint/PPTX 工作流协议。用于创建、读取、编辑、合并、拆分、审查演示文稿，强调模板保真、版式验证和导出检查。
when_to_use: 当用户提到 PPT、PowerPoint、slides、deck、presentation、母版、演讲稿、路演材料或 .pptx 文件时使用。
---

# PPTX 工作流协议

## 适用场景

用户要求处理 deck、slides、presentation、`.pptx`、演讲稿、路演材料或模板套用时使用。

## 工作流

1. 明确目标：新建、编辑、提取、合并、拆分、视觉优化或导出。
2. 读取现有文件或模板，识别母版、布局、字体、配色、图表、备注和评论。
3. 先给结构大纲，再生成/修改页面；不要破坏现有模板体系。
4. 图表与数据必须有来源；不要把无法验证的数据做成确定结论。
5. 完成后做 QA：页数、标题、溢出文本、图片缺失、字体、对齐、导出预览。
6. 汇报文件路径、修改摘要、验证结果和需要人工确认的视觉问题。

## 约束

- 保真优先于花哨；模板已有设计语言时必须复用。
- 不用截图假装可编辑 PPTX。
- 不复制外部品牌资产，除非用户提供或许可明确。

## 支持文件

- `references/quality-checklist.md`：quality checklist。
- `references/workflow-notes.md`：workflow notes。
- `references/powerpoint-fidelity.md`：字号 floor + slide master 5 项配齐 + chart 必含项 + 调色板 archetype + AI slop 避免清单 + plan-first 流程。综合自 Anthropic PowerPoint agent 公开行为协议（已 attribution）。

需要细化检查、模板或失败分类时，按需读取这些 supporting files；不要把长参考默认塞入主上下文。
