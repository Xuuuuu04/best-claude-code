# Excel 财务建模 / 数据分析纪律

> 灵感来源：Anthropic Excel agent 公开行为协议中的金融分析师工作模式。本文档提炼方法论，不复制原文。

适用：用户要求做财务模型、数据分析、表格审计、敏感性分析。

---

## 1. Show Your Work：每个用户看见的数字必须是 formula

**核心铁律**：用户能看见的任何"派生数字"都必须是引用源数据的公式，**禁止**外部计算后粘贴值。

错误：
- 在脚本里算 `total = 100 + 200 + 300 = 600`，把 `600` 写到单元格
- 从另一个 sheet "复制值"过来

正确：
- 在脚本里算用于决策（你自己的脑算），但**写到 sheet 的总是公式**
- `=SUM(A1:A10)` 不是 `55`
- 跨表引用：`='Source'!E3` 不是粘贴 `E3` 当前的值

为什么：用户能点任意数字看公式 → 知道数据从哪来 → 信任你的工作。

---

## 2. Hardcoded values 保持可见

每个**业务假设**都必须在带标签的单元格里，被公式引用。

错误：
- `=B5*0.21`（税率 21% 嵌在公式里——用户改不了）
- `=Revenue*1.05`（增长率 5% 嵌在里面）

正确：
```
A1: 税率   B1: 21.0%
A2: 增长率  B2: 5.0%
B5: =Revenue*B2
B6: =Revenue*B1
```

可以 hardcode 的：
- 真常数（12 个月、7 天）
- 单位换算（/ 100、/ 1000）
- 初始种子值（Year 1 收入）
- 结构性数字（行数）
- 小型 lookup 表

来自外部数据源的输入要在 cell comment 里标 `Source: [系统], [日期], [URL]`。

---

## 3. 颜色编码（金融模型标准约定）

| 颜色 | 含义 |
|:--|:--|
| **Blue** `#0000FF` | hardcoded 输入、scenario 切换 |
| **Black** `#000000` | 所有公式 |
| **Green** `#008000` | 跨表（同 workbook）链接 |
| **Red** `#FF0000` | 外部文件链接 |
| **Yellow bg** `#FFFF00` | 关键假设需要审视 |

新建模型时使用此约定，让审计者一眼看出数据流向。

---

## 4. 数字格式标准

| 类型 | 格式 |
|:--|:--|
| 年份 | 文本 `"2024"` 不是数字 `2,024` |
| 货币 | `$#,##0`（小写美元符号） |
| 单位放在表头 | "Revenue ($mm)" 而非每个 cell 加单位 |
| 零值显示为 dash | `$#,##0;($#,##0);-` |
| 百分比 | `0.0%` |
| 倍数 | `0.0x` |
| 负数 | 用括号 `(1,234)` 不是 `-1234` |

---

## 5. 公式简洁原则

复杂逻辑**拆到 helper cells**——不要写 deeply-nested IF/AND。

错误：
```
=IF(AND(A1>0, B1<10, OR(C1="A", D1>5)), B5*(1-IF(E1="prod",0.21,0.18)), 0)
```

正确（拆 helper）：
```
F1: =AND(A1>0, B1<10, OR(C1="A", D1>5))   ← 条件
G1: =IF(E1="prod", 0.21, 0.18)            ← 税率
H1: =IF(F1, B5*(1-G1), 0)                  ← 最终
```

理由：调试容易、审计容易、bug 减少。

---

## 6. 大数据集（>1000 行）处理

**不要**把上万行 dataframe 用 `set_cell_range` 直接写——超慢且容易超时。

**正确**：
- 用 code execution 处理（pandas / numpy）
- 输出汇总到 sheet（pivot / 聚合结果）
- 原始数据如要写 sheet，分批 ≤1000 行，`asyncio.gather()` 并行
- **绝不**把 raw dataframe 全 dump 给用户看（>50 项就停）

---

## 7. 敏感性表（Sensitivity Analysis）

用奇数网格（5×5 / 7×7），让 base case 落在**正中心**。

中心 cell 用黄色背景突出，让用户一眼看到 baseline。

不要用 `=TABLE()` data tables（Office.js 不支持）——直接用公式构建。

---

## 8. 验证陷阱（Gotchas）

### 行/列 insert 不可靠扩展现有公式

`AVERAGE(A1:A10)` 在中间插入新行后**未必**变成 `AVERAGE(A1:A11)`。

**对策**：插入后**手动验证**所有相邻公式范围。或预先用 `AVERAGE(A:A)` 整列引用。

### Pivot 源范围/目标 immutable

PivotTable 创建后无法改源范围或位置——必须 `pivotTable.delete()` 再重建。可以改的：fields、聚合函数、name。

### 行/列 insert 继承相邻格式

在带蓝色 header row 的下方插入新行 → 新行也变蓝色。**插入后检查并清理格式**。

---

## 9. Web search 财务数据：仅官方源

**允许**：
- 公司 IR 页面
- 公司 press release
- SEC EDGAR（10-K, 10-Q, 8-K, proxy）
- 官方 earnings 报告 / transcripts / decks
- 交易所 / 监管文件

**禁止**：
- Seeking Alpha / Motley Fool / Yahoo Finance / Macrotrends
- 聚合器
- 社交媒体 / Reddit
- 重新解读数字的新闻文章
- Wikipedia

如官方源拿不到 → 告知用户，列出可用替代，**等用户确认**才用非官方源。如同意，单元格 comment 标 `(unofficial)`。

每个 web-sourced cell 都需要 source comment（在数字上不在标签上），格式：`Source: [Name], [URL]`。

---

## 10. 行/列**不要**隐藏，要 group

隐藏（hide）= 没有视觉指示，数据消失感
Group（数据→分组）= 有 +/- 按钮，可见可逆

**禁止 hide**——除非用户明确要求。改用 group。

注意：图表锚定的源数据被 hide 时，图表也跟着消失。

---

## 11. Show Your Work 在跨表场景

错误：从 Sheet A 读 E3 = 100，把 100 hardcode 到 Sheet B 的 C5。

正确：Sheet B 的 C5 写 `='Sheet A'!E3`——保持 live link。

如 Sheet A 的 E3 改了，Sheet B 自动更新。这就是 spreadsheet 的核心价值。

---

## 12. 完成前检查清单

- 所有派生数字都是公式（不是粘贴值）
- 颜色编码一致（蓝输入 / 黑公式 / 绿跨表 / 红外部 / 黄关键）
- 数字格式合规（货币、零值、百分比、年份）
- 关键假设在带标签的 cell（不嵌公式里）
- Web 数据每个 cell 有 source comment
- Pivot/chart 源数据未被 hide
- 行/列插入未破坏公式范围
