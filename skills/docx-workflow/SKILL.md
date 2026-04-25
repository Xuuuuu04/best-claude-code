---
name: docx-workflow
description: Word/DOCX 工作流协议。用于创建、编辑、审阅、重排和格式化 .docx 文档，强调样式继承、目录、批注和修订保真。
when_to_use: 当用户提到 Word、docx、报告、合同、提案、备忘录、文档模板、批注、修订或目录样式时使用。
---

# DOCX 工作流协议

## 工作流

1. 判断任务类型：阅读提取、内容改写、格式整理、模板填充、批注/修订、导出。
2. 先识别文档结构：标题层级、样式、页眉页脚、目录、表格、图片、批注、修订状态。
3. 编辑时继承现有样式，不手写相似但不同的格式。
4. 内容性改动先保留原意和事实来源；不确定事实标注待确认。
5. 完成后验证：目录、页码、标题层级、表格断页、图片锚点、批注/修订状态。
6. 汇报路径、主要改动、验证结果、无法自动确认的版式问题。

## 约束

- 不把 `.docx` 当纯文本处理后丢失结构。
- 不在未确认时接受/拒绝修订。
- 不泄露文档中的隐私或客户信息到日志/示例。

## 支持文件

- `references/quality-checklist.md`：quality checklist。
- `references/style-inheritance.md`：style inheritance。
- `references/word-fidelity-traps.md`：12 类 Word/DOCX 保真陷阱（style inheritance / Track Changes / comment ID / inline refs / tables / lists / 错误恢复）。综合自 Anthropic Word agent 公开行为协议（已 attribution）。

需要细化检查、模板或失败分类时，按需读取这些 supporting files；不要把长参考默认塞入主上下文。
