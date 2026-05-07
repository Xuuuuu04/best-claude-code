# XLSX Quality Checklist

每次 Excel 交付前**必走**。详细公式规则见 `formula-rules.md`。

## 1. 公式完整性（最高优先级）

- [ ] 所有原有公式仍是公式（**未被静默替换为静态值**）
- [ ] 引用类型（绝对 `$A$1` / 相对 `A1` / 混合 `A$1`）符合原意
- [ ] 跨表引用未失效（重命名 Sheet 后特别注意）
- [ ] 命名区域（`Tax_Rate`）正确
- [ ] 无硬编码"魔法数"（应在 Inputs 区）
- [ ] 公式无 `#REF!` / `#VALUE!` / `#DIV/0!` / `#NAME?` 错误

## 2. 重算与对比

- [ ] 修改后已用 LibreOffice 命令行触发重算：
  ```bash
  soffice --headless --calc --convert-to xlsx file.xlsx
  ```
- [ ] 关键输出与改动前对比，差异有合理解释
- [ ] 数据透视表已 refresh
- [ ] 图表数据源仍正确
- [ ] 汇总数与明细一致

## 3. 财务模型三区分离

- [ ] **Inputs**（手填）— 灰底，用户可改
- [ ] **Calculations**（公式）— 白底，公式区
- [ ] **Outputs**（汇总）— 强调色，引用计算区
- [ ] 修改财务模型时不在 Calculations 区直接覆盖数字

## 4. 版本兼容

- [ ] 已确认目标 Excel 版本
- [ ] Excel 2019 用户：避免 `XLOOKUP` / `LET` / `LAMBDA`
- [ ] Excel 365 可用：现代函数（`XLOOKUP` / `FILTER` / `LET`）
- [ ] CSV 导出时已告知用户：公式被替换为值

## 5. 数据完整性

- [ ] 数字格式正确（货币 / 百分比 / 日期）
- [ ] 日期格式与区域设置一致（避免 02/03/2026 歧义）
- [ ] 数据校验（Data Validation）规则保留
- [ ] 条件格式正确
- [ ] 命名范围未被破坏

## 6. 大数据集处理

- [ ] > 10K 行：用整列引用（`SUM(A:A)` 而非 `SUM(A1:A1000)`）避免新行被遗漏
- [ ] 公式不重复计算（`SUMIFS` 优于多个 `SUMIF`）
- [ ] 慢公式（`INDIRECT` / 数组公式）已优化

## 7. 元数据

- [ ] 作者、标题、关键字已设置
- [ ] 修订记录已清理（如客户要求）
- [ ] Document Properties 无内部信息泄露

## 8. 保护与权限

- [ ] Sheet 保护（如适用）：解锁 Inputs 区，锁住 Calculations
- [ ] 工作簿密码（如交付保密文件）
- [ ] 隐藏 sheet 已 unhidden（避免遗忘）

## 9. A11y

- [ ] 表格有标题行
- [ ] 列宽允许内容完整可见
- [ ] 颜色不是唯一信息载体（屏幕阅读器友好）

## 10. 交付包

- [ ] 文件名规范（版本 + 日期）
- [ ] 关联文件（如 macro / addin）一并交付
- [ ] 交付说明（变更摘要）
- [ ] 列出假设、异常行、验证方式

## 自动化辅助

```python
import openpyxl
wb = openpyxl.load_workbook('file.xlsx', data_only=False)

# 检查所有公式
for sheet in wb.sheetnames:
    ws = wb[sheet]
    for row in ws.iter_rows():
        for cell in row:
            if cell.data_type == 'f':
                print(f"{sheet}!{cell.coordinate}: {cell.value}")

# 列出命名区域
for name in wb.defined_names.definedName:
    print(name.name, "=", name.value)
```

## 失败模式

- ❌ 修改后 SUM 全是 0：新插入行未纳入引用范围 → 用 `SUM(A:A)` 整列
- ❌ 客户报"循环引用"：命名区域指向自身 → 检查 `wb.defined_names`
- ❌ 数据透视表数据失效：源表行数变了 → 必须 refresh

详细 anti-pattern 与修复见 `formula-rules.md`。
