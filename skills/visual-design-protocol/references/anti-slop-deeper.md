# 前端设计 · AI Slop 深度避免清单

> 灵感来源：Claude Design / frontend-design 公开行为协议 + 社区 frontend agent 公开模式。本文档提炼方法论，不复制原文。

适用：高级前端工程师 / 视觉设计专家 在做 web UI、landing page、dashboard、组件视觉时。

---

## 1. AI Slop 反模式清单（拒绝列表）

以下都是大模型默认会生成的"安全平庸"模式，必须主动避开：

### 视觉
- **激进渐变背景**——尤其是紫色到蓝色的"AI 紫"
- **左边框 4px accent + 圆角容器**——过度使用变成 AI 风
- **emoji 堆砌**——除非品牌明确允许，否则用 placeholder
- **SVG 自画 imagery**——用 placeholder + 标注"待真实素材"
- **整页统一深色背景配亮 accent**——电子产品发布会风
- **磨砂玻璃 (frosted glass) 全屏使用**

### 字体
- **过度 overused**：Inter / Roboto / Arial / Fraunces / system-ui
- **多字体堆叠**——一个 deck/页面用 3+ 字体家族
- **字重对比不足**——只有 400 + 600

### 布局
- **三列等宽 hero / features / cta**——SaaS 默认
- **居中对齐一切**——缺少视觉重心
- **每个 section 都用 card**——卡片地狱

### 内容
- **数据 slop**：为填空塞 stats（"99% 满意度"无来源）
- **icon slop**：每个 bullet 必加 icon
- **空话 hero copy**："Build the future with X"

---

## 2. 替代方案（建设性原则）

### 颜色
- **从品牌/设计系统借色**——不发明新色
- 限制太死时用 `oklch()` 调和现有色
- 1-2 种 background colors per deck/page，最多
- 优先 archetype：corporate neutral / warm editorial / bold startup / academic muted / playful bright

### 字体
- 选不"AI 默认"的——比如 Geist / IBM Plex / Söhne / Cooper / Spectral
- Heading + body 字体对（**不是 3 个**）
- 字号系统：12 / 14 / 16 / 20 / 24 / 32 / 48 / 64（modular scale）
- 行高：标题 1.1，正文 1.5-1.6

### 布局
- 用 CSS Grid + asymmetric grid，不是只 flex 三列
- 故意打破对齐——单一 hero 元素 offset
- 用 `text-wrap: pretty`、`hanging-punctuation` 等高级 CSS
- 留白比 card 重要

### 视觉冲击
- 大尺度 typography（hero 字号 80-120px）
- 真照片 / 真素材 > AI 生成图
- 一个动作元素，不是动画堆砌

---

## 3. 占位符 > 假装的真实物

设计 hi-fi 时，没有真 icon / 真 asset / 真组件 → 用 placeholder（灰底框 + 标注），**不要**自己 SVG 画一个低质量近似品。

理由：
- placeholder 让用户清楚"这里需要补"
- 假货低质量近似品让审阅者以为这是最终效果
- 节省你的时间也节省 review 时间

格式：
```html
<div class="placeholder" data-asset="hero-illustration">
  <span>插图位 — 需提供 1200×800 PNG</span>
</div>
```

---

## 4. Design system / UI kit 优先

好的 hi-fi 设计 **不从零开始**——基于既有设计上下文。

执行顺序：
1. **问用户**有没有 codebase / UI kit / Figma 链接 / 截图
2. 没有 → 引导用户提供（Import 菜单）
3. 仍没有 → 列已知 design system / 寻找近似 → 用户确认
4. **最后兜底**才从零设计

从零设计 = 最后手段，会导致泛 AI slop。

---

## 5. 字号 floor

| 场景 | 最小 | 推荐 |
|:--|:--|:--|
| 1920×1080 slide | 24px | 28-40px |
| Web 桌面正文 | 16px | 16-18px |
| Web 移动端正文 | 14px | 16px |
| 移动端 hit target | **44×44px** | 48×48px |
| 打印文档 | 12pt | 11-13pt |

---

## 6. 颜色对比度

WCAG AA：
- 普通文本：≥ 4.5:1
- 大文本（≥18pt 或 ≥14pt 加粗）：≥ 3:1
- 非文本（图标、按钮边框）：≥ 3:1

**不要靠"看起来够"判断**——用工具量。`getComputedStyle` + 对比度算法 / 浏览器 dev tools 的 contrast checker。

---

## 7. 多变体探索原则

用户要"做一个 X"时，**默认给 3+ 变体**——不是 1 个"完美"答案：

- 维度：视觉风格 / 颜色处理 / 信息密度 / 交互模式
- 起点：一个 by-the-book 按既有 pattern 做
- 渐进：往后越来越大胆 / 实验 / novel
- **目标不是给完美答案，是探索 atomic 变体让用户混搭**

工具：用 design_canvas（多个并列）或 Tweaks（toggle 切换）。

---

## 8. CSS 是被低估的

不要把 CSS 当作 "把 figma 翻译过来" 的工具。CSS 现代特性能创造惊喜：

- `text-wrap: pretty` / `text-wrap: balance`
- `mask-image` / `background-clip: text`
- `scroll-driven-animations`
- `backdrop-filter`
- `container queries`（响应组件级）
- `:has()` 选择器
- `@supports` feature queries
- `accent-color` / `color-scheme`

用户经常不知道 CSS 能做什么——主动用上。

---

## 9. 不加 title screen

prototype 不要硬塞"标题屏"——直接给作品本身。让设计在 viewport 里居中或 responsively 填满。

例外：用户明确要求 deck/演示形态。

---

## 10. Tweaks panel 设计

提供 tweaks 时：

- 标题就叫 **"Tweaks"**（与工具栏 toggle 名一致）
- 浮动面板在右下角
- toggle off 时**完全隐藏**（设计应该看起来 final）
- 用户没要求也默认提供 1-2 个 tweaks（暴露可能性）

JSON marker block 可写：
```html
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "primaryColor": "#D97757",
  "fontSize": 16,
  "dark": false
}/*EDITMODE-END*/;
```

---

## 11. 完成前自检

- 字号符合 floor
- 对比度过 WCAG AA
- 没有禁用列表里的反模式（紫色渐变 / emoji 滥用 / 默认字体）
- 用了 design system 的 token，没发明新色
- 占位符是占位符（标注清楚），不是低质量 SVG
- 至少 3 个变体（如用户要选项）
- 字号在不同 viewport 不溢出
- 移动端 hit target ≥44px

---

## 12. "数据 slop" 警惕信号

写 hero copy 时不要这样：

✗ "1000+ companies trust us · 99.9% uptime · 5x faster"

如果数据**没真实来源**，宁可不写。空白 > 编造数字。

宁可：
✓ "Used by teams at Stripe, Linear, Vercel"（如果属实）
✓ "Built for engineers who [具体问题]"（具体描述）
