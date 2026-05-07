# Anti-Slop Checklist

避免"AI generated"那种千篇一律的视觉。每条都要在交付前自检。

## 视觉禁区

### 颜色
- ❌ 紫蓝渐变 + glassmorphism（一眼 AI）
- ❌ 默认 `from-purple-600 to-blue-600`
- ❌ 凭直觉造新色，不沿用 brand / design system
- ❌ 半透明 + backdrop-blur 万能套用
- ✅ 复用品牌色板；用 `oklch()` 在已有色板内派生
- ✅ Primary 色克制使用（不超过 5% 视觉占比）

### 字体
- ❌ Inter / Roboto / system-ui / Arial（默认 AI 选项）
- ❌ Fraunces 当万能 serif（被滥用）
- ❌ 同时混搭 3+ 字体家族
- ✅ 1 sans + 1 mono，或 1 sans + 1 serif
- ✅ 用字号 + 字重 + tracking 而非换字体来制造层级

### 布局
- ❌ "鼓鼓的卡片"：`rounded-2xl shadow-lg p-8`（一眼 ChatGPT）
- ❌ 左侧 4px 彩色边框 + 圆角容器（badge/notice 套路）
- ❌ Hero 居中文字 + CTA + "trusted by" logo 灰色一排
- ❌ Bento grid 当万能布局
- ✅ 真实信息密度优先；不要为对称而留白
- ✅ 关键内容打破网格

### 图标
- ❌ Lucide 全套铺满（每段都配图标）
- ❌ Emoji 当装饰
- ❌ 用 SVG 自画图像 / 插画
- ✅ 占位符（灰底 + 标签）告知"等真实图"
- ✅ 仅在功能必需时用图标

### 文案
- ❌ "Empower your..."、"Unlock the power of..."、"Transform your..."
- ❌ "Built with ❤️ by..."
- ❌ slogan 中堆叠形容词："fast, secure, scalable, modern"
- ❌ 用 emoji 强调（🚀✨💡）
- ✅ 具体动词 + 用户实际收益 + 可量化数字

## 替代清单

| 廉价手法 | 专业替代 |
|:--|:--|
| 紫蓝渐变 | 品牌色 + 中性色 95% + 强调色 5% |
| 玻璃拟态 | 实色 + 微阴影 |
| 圆角 + shadow | 边框 + 留白 |
| 居中 hero + CTA | 左对齐 + 真实截图/数据 |
| 图标列表 | 截图证据 / 真实数据 |

## A11y 量化基线（硬下限）

- 文字对比度 ≥ 4.5:1（正文），3:1（大文字 ≥ 24px）
- 触发区 ≥ 44×44px（移动端）
- 文字 ≥ 14px（PC），≥ 16px（移动端）
- 1920×1080 slides 文字 ≥ 24px
- 焦点环可见且对比度 ≥ 3:1
- 不依赖颜色单独传递信息

## 状态矩阵（必须全覆盖）

每个交互组件都要设计：
default / hover / focus / active / disabled / loading / empty / error / success

缺少任一状态视为未完工。

## 自检 6 问

1. 这个设计删除"AI 默认装饰"（渐变/glass/emoji）后还成立吗？
2. 颜色全部来自 design tokens 吗？
3. 字体选择有理由（不是"看起来现代"）吗？
4. 文案讲清"做什么"吗？
5. 信息密度匹配实际内容吗？
6. 在低带宽 / 高对比度 / 屏幕阅读器下能用吗？

## 来源

综合自 Anthropic Claude Design 公开行为准则 + Anthropic skills 仓库 frontend-design SKILL.md（已 attribution）。详见 `anti-slop-deeper.md`。
