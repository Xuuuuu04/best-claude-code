---
name: xlsx-workflow
description: Excel/XLSX/CSV 工作流协议。用于读取、清洗、计算、格式化、制图和修复表格文件，强调公式正确、模板保真和重算验证。
when_to_use: 当用户提到 Excel、xlsx、xlsm、csv、tsv、表格、公式、图表、数据清洗、财务模型或 spreadsheet 文件时使用。
---

# XLSX 工作流协议

## 工作流

1. 判断输入/输出：现有表格编辑、新建 workbook、CSV 清洗、公式修复、图表/报表。
2. 识别 workbook：sheet、表头、公式、命名范围、数据验证、条件格式、图表、保护状态。
3. 修改公式时保持相对/绝对引用正确；财务模型遵循输入/计算/输出分区。
4. 清洗数据时保留原始数据副本或说明不可逆变更。
5. 完成后验证：公式错误、空引用、数值类型、总计一致性、图表数据范围、文件可打开。
6. 汇报修改范围、验证结果、残留异常行和用户需确认的数据假设。

## 约束

- 不把公式替换成静态值，除非用户明确要求。
- 不破坏已有模板、保护、格式和图表引用。
- 不在样例中暴露敏感财务/客户数据。

## 支持文件

- `references/quality-checklist.md`：quality checklist。
- `references/formula-rules.md`：formula rules。
- `references/excel-financial-discipline.md`：Show Your Work（每个数都是公式）+ 颜色编码 + 数字格式 + hardcoded 可见性 + 大数据集策略 + 敏感性表 + Web search 财务数据规范。综合自 Anthropic Excel agent 公开行为协议（已 attribution）。

需要细化检查、模板或失败分类时，按需读取这些 supporting files；不要把长参考默认塞入主上下文。
