# PPTX Workflow Notes

PPTX 编辑的标准流程与常见陷阱。配合 `quality-checklist.md` 使用。

## 工作流四步

### Step 1：理解上下文（开始前必做）

询问 / 确认：

- 演讲场景（讲台 / 投屏 / 阅读）→ 决定字号与信息密度
- 受众（高管 / 工程师 / 客户 / 公众）→ 决定语调与术语
- 时长（10 / 30 / 60 分钟）→ 决定 slide 数量
- 模板来源（公司模板 / 客户提供 / 从零开始）
- 输出格式（仅 .pptx / 同时要 PDF）

不要假设。模糊就 AskUserQuestion。

### Step 2：探索资源

```python
from pptx import Presentation
prs = Presentation('template.pptx')

# 列出所有可用版式
for layout in prs.slide_layouts:
    print(layout.name)

# 检查主题字体与色彩
print(prs.slide_width, prs.slide_height)  # 决定 1080p / 4K / 自定义
```

复用现有版式优先于造新版式。常用版式与场景：

| 版式 | 用途 |
|:--|:--|
| Title Slide | 封面 |
| Section Header | 分章 |
| Title and Content | 单要点 + 列表 |
| Two Content | 对比 / 并列 |
| Comparison | 优劣表 |
| Title Only | 大字突出 |
| Blank | 自由布局（慎用） |

### Step 3：写大纲（slide-by-slide）

不要直接动 .pptx。先写 markdown 大纲：

```markdown
## Slide 1：封面
- 标题：项目名 + 副标题
- 日期 + 演讲者

## Slide 2：议程
- 三个章节标题

## Slide 3：背景
- 1 句话 + 1 张图
- speaker notes：完整开场白
```

让用户确认大纲后再生产 .pptx。这一步省后期返工 90%。

### Step 4：生产与验证

```python
from pptx import Presentation
from pptx.util import Inches, Pt

prs = Presentation('template.pptx')

slide_layout = prs.slide_layouts[1]  # Title and Content
slide = prs.slides.add_slide(slide_layout)

title = slide.shapes.title
title.text = "本月业绩总结"

content = slide.placeholders[1]
content.text = "..."

prs.save('output.pptx')
```

验证清单见 `quality-checklist.md`。

## 常见陷阱

### 陷阱 1：直接 add_textbox 而不用 placeholder

```python
# ❌ 错误：自己加 textbox，破坏模板继承
left = top = Inches(1)
txBox = slide.shapes.add_textbox(left, top, Inches(8), Inches(2))

# ✅ 正确：用版式占位框，继承字体 / 颜色
slide.placeholders[1].text = "..."
```

### 陷阱 2：硬编码字体颜色

```python
# ❌ 错误：硬编码 RGB
from pptx.dml.color import RGBColor
run.font.color.rgb = RGBColor(0xFF, 0x00, 0x00)

# ✅ 正确：用 Theme Color
from pptx.enum.dml import MSO_THEME_COLOR
run.font.color.theme_color = MSO_THEME_COLOR.ACCENT_1
```

### 陷阱 3：图表用图片代替

```python
# ❌ 错误：把 matplotlib 输出 PNG 嵌入
fig.savefig('chart.png')
slide.shapes.add_picture('chart.png', Inches(1), Inches(2))

# ✅ 正确：用 python-pptx 的原生图表（数据可编辑）
from pptx.chart.data import CategoryChartData
chart_data = CategoryChartData()
chart_data.categories = ['Q1', 'Q2', 'Q3', 'Q4']
chart_data.add_series('Sales', (10, 20, 15, 30))
slide.shapes.add_chart(
    XL_CHART_TYPE.COLUMN_CLUSTERED,
    Inches(1), Inches(2), Inches(6), Inches(4),
    chart_data,
)
```

### 陷阱 4：忘记母版字体回退

```bash
# 如使用非标字体，必须嵌入：
# PowerPoint > File > Options > Save > Embed fonts in the file
```

## Speaker Notes 模式

```python
notes = slide.notes_slide.notes_text_frame
notes.text = """
开场：今天我们看一下 Q4 业绩。

关键数据：
- 营收增长 23%
- 新客户 +120

要强调：转化率提升来自新功能，不是预算增加。
"""
```

完整脚本式 notes（不是 bullet 速记）让演讲流畅。

## 与设计师协作

- 设计师交付 Figma → 用截图占位（不要在 .pptx 里画矢量）
- 客户改字 → 直接改 .pptx，保留版式
- 客户改设计 → 回到 Figma，重新导出截图

不要在 PowerPoint 里做精细图形设计。
