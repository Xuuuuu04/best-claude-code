# PPTX Quality Checklist

每次 .pptx 交付前自检。配合 `workflow-notes.md` 看完整流程。

## 1. 模板保真

- [ ] 主题（slide master）未被破坏
- [ ] 字体使用模板定义的（Theme Fonts）而非硬编码
- [ ] 颜色使用 Theme Colors 而非 RGB 硬码
- [ ] 版式（layouts）使用现有，不滥造新版式
- [ ] 母版 logo 位置未被本页移动
- [ ] 母版、布局、字体、配色没有被意外替换

## 2. 内容质量

- [ ] 每页有明确主标题
- [ ] 每页 ≤ 6 行 / ≤ 30 字 / 行（演讲场景）
- [ ] 关键数据有图表支持（不是纯数字罗列）
- [ ] 无占位符（`Click to add text` / `Lorem ipsum`）残留
- [ ] 标题、正文、页脚、页码无溢出

## 3. 字号与可读性

- [ ] 标题字号 ≥ 32pt（1920×1080 屏幕）
- [ ] 正文字号 ≥ 24pt（演讲场景），≥ 18pt（阅读场景）
- [ ] 字号 < 18pt 仅限 footer / 注释
- [ ] 行高 1.2-1.5

## 4. 视觉一致性

- [ ] 同类元素位置一致（标题 / 页码 / logo）
- [ ] 配色 ≤ 3 种主色 + 中性
- [ ] 图标风格统一（线 / 面 / 立体三选一）
- [ ] 图片裁切方式一致

## 5. 图表与数据

- [ ] 图表数据源准确（不是手画）
- [ ] 坐标轴有标签 + 单位
- [ ] 数据系列颜色与品牌色一致
- [ ] 图例位置不遮挡数据
- [ ] 无法验证的数据标为待确认

## 6. 演讲者笔记

- [ ] 关键页有 speaker notes（除非客户明确不需要）
- [ ] notes 是完整脚本（不是 bullet 速记）
- [ ] 时间预估清晰（每页 X 分钟）
- [ ] speaker notes / comments 保留或按要求处理

## 7. 切换与动画

- [ ] 切换动画 ≤ 1 种
- [ ] 动画用于强调而非装饰
- [ ] 自动播放计时正确（如有）

## 8. 链接与超链接

- [ ] 内部跳转（"返回目录"）正确
- [ ] 外部 URL 可用（生产环境，不是 localhost）
- [ ] 嵌入视频 / 音频可正确播放

## 9. 导出验证

- [ ] PowerPoint 中打开正常
- [ ] PDF 导出正确（保留矢量、文字可选）
- [ ] 缩略图正常显示
- [ ] 文件大小合理（< 50MB，除非含视频）
- [ ] 导出预览无裁切、错位、遮挡

## 10. 元数据与汇报

- [ ] 作者、标题正确
- [ ] 修订记录已清理
- [ ] 隐藏幻灯片已删除（除非有意保留）
- [ ] 汇报中列出文件路径、验证方式、需人工确认的视觉项

## 自动化辅助

```python
from pptx import Presentation
prs = Presentation('file.pptx')

# 列出所有 slide 与 layout
for i, slide in enumerate(prs.slides):
    print(f"Slide {i+1}: layout = {slide.slide_layout.name}")

# 检查字号是否符合要求
for slide in prs.slides:
    for shape in slide.shapes:
        if shape.has_text_frame:
            for para in shape.text_frame.paragraphs:
                for run in para.runs:
                    if run.font.size and run.font.size.pt < 18:
                        print(f"Small font: {run.text[:40]}")
```

## 失败模式

- ❌ 用错版式：内容溢出占位框 → 切到匹配版式
- ❌ 字体回退：客户机器没装 → 嵌入字体或用系统字体
- ❌ 图表数据丢失：保存为旧版 → 用 .pptx 不用 .ppt
- ❌ 动画过多：分散注意力 → 1 种切换 + 关键强调
