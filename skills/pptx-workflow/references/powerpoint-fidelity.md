# PowerPoint 保真与设计纪律

> 灵感来源：Anthropic PowerPoint agent 公开行为协议 + Claude Design 公开设计原则。本文档提炼方法论，不复制原文。

适用：用户要求做 deck、改 deck、生成图表、做演示。

---

## 1. 字号 floor（绝不破例）

| 元素 | 最小字号 | 推荐字号 |
|:--|:--|:--|
| Title | 32pt | 32–40pt **加粗** |
| Section header | 24pt | 24–28pt **加粗** |
| Body / 正文 | 16pt | 16–18pt |
| Caption / 注脚 | 14pt | 14pt |
| **绝对下限** | **10pt** | 仅当模板 master bodyStyle 已设更小时让步 |

理由：投影上要从房间后排读——sub-14pt 在距离下变模糊。

**层级比例**：title 必须 ≥ 1.75× body 字号——否则视觉层级塌陷。

---

## 2. Slide Master 一次性配齐

新建 deck 时（特别是空白 deck）一次性配齐这 5 项：

1. **Theme colors** — 完整 `<a:clrScheme>`（6 个 accent + 2 个文本 + 2 个背景）
2. **Theme fonts** — heading + body 字体对
3. **Master background** — `<p:bg>` 在 slide master 上
4. **Default text colors** — master 的 `<p:txStyles>`
5. **至少一个装饰元素** —— logo / 角标 / 装饰线

**禁止默认深蓝**——按 deck 类型选 archetype：
- Corporate neutral：浅灰 / 海军蓝
- Warm editorial：奶白 / 暖灰 / 焦糖
- Bold startup：电光蓝 / 番茄红 / 黑
- Academic muted：象牙白 / 橄榄 / 焦褐
- Playful bright：薄荷绿 / 桃粉 / 柠檬黄

每个 deck 选 1-2 个背景色，不要超过。

---

## 3. Chart 必含项

任何数据可视化用真 chart（OOXML `<c:chart>`），**禁止**用 shape 拼凑近似柱状图。

每个 chart 必含：

- `<c:title>`（图表标题）
- `<c:legend>`（位置 top）
- `<c:dLbls>`（showVal=true 显示数值）
- 字号 ≥ 14pt
- 不混 XML/HTML 注释（破坏 OOXML 解析）
- 正确的轴定义（cat / val）
- 在 Content_Types 注册

---

## 4. Slide ID 不索引

**禁止**：用"第 5 张"这种 positional 索引调用 API。

**正确**：用 `slidesMetadata` 的 `slideId`（稳定不变）。`position` 只在 mapping 时用。

理由：插入新 slide 后所有 position 都变，旧 position 引用全错。slideId 不变。

---

## 5. 文字居中要全套设置

文字在 shape 里居中，**不是只设 alignment**——一次性设：
- `alignment: center`（水平）
- `verticalAlignment: middle`（垂直）
- `autoSizeSetting: shape` / `text`
- `wordWrap: true`
- 4 个方向 margins 全设 0

漏一个就会出现"文字跑边、居中不准"。

---

## 6. 图表化优先于 shape 拼接

需求："画一个流程图 / 时间线 / 循环图 / 组织架构"

**正确**：用 OOXML 写 SmartArt-like 结构（`edit_slide_xml`），escape 文本。

**禁止**：用一堆 rectangle + line + textbox 拼。理由：
- 修改困难（动一个 shape 全乱）
- 字体不一致
- 无法复用

---

## 7. Auto-size 后必须更新

文字内容变了 → shape 大小可能不再合适。`edit_slide_xml` 后传 `autosize_shape_ids`，让 shape 重新适应文本。

漏掉这一步 → 文字溢出 / shape 留白。

---

## 8. Verify 三步流程

完成 deck 后**必须**：

1. `verify_slides`——结构性检查（重叠 / 溢出 / 空 placeholder）
2. `verify_slide_visual`——视觉客观验证（截图）
3. **修问题再 re-verify**

绝不"自我感觉良好"就报告完成。

修必须修的：
- contrast warnings（对比度过低）
- unused placeholders（空 placeholder 显得草率）
- unused images（多余图片）

---

## 9. 多 slide deck 的 plan-first 流程

3+ slide 任务：

1. **Storyline 先**——在 chat 列出 slide 标题（叙事弧）+ 关键点
2. **等用户批准** —— 不要直接画 10 张
3. **Layout 原型** —— 多张共用 layout 时先做 1 张样品
4. **样品获用户反馈** → 复制
5. **逐 slide 推进**，不要单次 generate 全 deck（用户看不到进度）

---

## 10. AI Slop 避免清单

避免：
- **激进渐变背景**——廉价感
- **emoji**——除非品牌明确允许
- **左边框圆角容器加 accent color**——AI 风
- **SVG 画 imagery**——用 placeholder 等真材料
- **过度 overused 字体** Inter / Roboto / Arial / Fraunces / system fonts
- **数据 slop**——为填空硬塞 stats / icons

少胜于多：1000 个 no 换 1 个 yes。空白也是设计。

---

## 11. Speaker Notes（演讲者备注）

仅在用户**明确要求**时加。语法：

```html
<script type="application/json" id="speaker-notes">
[
  "Slide 1 备注：...",
  "Slide 2 备注：...",
  ...
]
</script>
```

写完整脚本不是要点——演讲者照着念都流畅。

注：用 speaker notes 时 slide 上文字可以更少，让视觉冲击更强。

---

## 12. Slide 标签（comment 上下文）

为 slide 加 `data-screen-label`：

```html
<section data-screen-label="01 Title">...</section>
<section data-screen-label="02 Agenda">...</section>
```

**1-indexed**——用户说"第 5 张"指的是 label "05"，不是数组 [4]。

---

## 13. 完成前检查清单

- 每张 slide 字号 ≥ 14pt（标题 32-40 / body 16-18）
- 每个 chart 有 title / legend / 数值 label
- slide master 配齐 5 项
- 调色板不是默认深蓝
- 没有 unused placeholder
- 跑过 `verify_slides` + `verify_slide_visual`
- 修了所有 contrast warning
- 没用 emoji（除非品牌允许）
- speaker notes 仅在用户要求时存在
