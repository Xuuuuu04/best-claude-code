# 前端动画引擎与性能纪律

> **来源 attribution**：本文档内容综合自以下 MIT 许可的开源 skill：
> - [MiniMax-AI/skills · frontend-dev](https://github.com/MiniMax-AI/skills/tree/main/skills/frontend-dev) — MIT
> - Framer Motion 官方文档
> - GSAP / GreenSock 官方文档
> - Three.js 官方文档
> - W3C `animation-timeline` / `prefers-reduced-motion` 规范
>
> 本文档保留方法论与代码模板，已根据 Agent Legion implementer-frontend 工作流改写。Framer Motion / GSAP / Three.js 是各自所有者的商标。

适用：implementer-frontend 接到含动画 / 滚动叙事 / 3D / 交互效果的任务时。

---

## 1. 工具选择矩阵

| 需求 | 工具 |
|:--|:--|
| UI enter / exit / layout | **Framer Motion** — `AnimatePresence` / `layoutId` / springs |
| 滚动叙事（pin / scrub） | **GSAP + ScrollTrigger** — 帧精度控制 |
| 循环图标 | **Lottie** — 懒加载（~50KB） |
| 3D / WebGL | **Three.js / R3F** — 隔离 `<Canvas>`，独立 `"use client"` 边界 |
| Hover / focus 状态 | **CSS only** — 零 JS 成本 |
| 原生滚动驱动 | **CSS** — `animation-timeline: scroll()` |

### 冲突规则（强约束）

- ❌ **绝不**在同一组件混用 GSAP + Framer Motion
- ❌ R3F **必须**在隔离的 Canvas wrapper 里
- ❌ Lottie / GSAP / Three.js **必须**懒加载

---

## 2. 动画强度等级（1-10）

| 等级 | 适用 | 技术 |
|:--|:--|:--|
| 1-2 Subtle | 内部工具页 / 表单 / dashboard | CSS transitions only, 150-300ms |
| 3-4 Smooth | 普通产品页 | CSS keyframes + Framer animate, stagger ≤3 items |
| 5-6 Fluid | 营销页 / landing | `whileInView` / 磁吸 hover / 视差 tilt |
| 7-8 Cinematic | 高端产品发布 | GSAP ScrollTrigger / pinned sections / horizontal hijack |
| 9-10 Immersive | 概念展示 / 艺术站 | Full scroll sequences / Three.js 粒子 / WebGL shader |

**项目类型 → 等级建议**：
- B 端 SaaS dashboard：1-3
- C 端 marketing：4-6
- 旗舰发布页：7-8
- 实验/概念站：9-10

不要错配——dashboard 用等级 8 让用户晕，marketing 用等级 1 显廉价。

---

## 3. 性能铁律（GPU only）

**只动这 4 个 CSS 属性**：

| 属性 | 用途 |
|:--|:--|
| `transform` | 移动 / 缩放 / 旋转（替代 top/left/width/height/font-size） |
| `opacity` | 淡入淡出 |
| `filter` | blur / brightness / saturate |
| `clip-path` | 形状变化 |

**绝不动**：`width` / `height` / `top` / `left` / `margin` / `padding` / `font-size`——这些会触发 layout reflow，60fps 立刻掉。

替代方案：
- 想改尺寸？→ `transform: scale()`
- 想做"高度展开"？→ `clip-path` + `transform`
- 想做字号变化？→ `transform: scale()` + `transform-origin`

---

## 4. 隔离与清理

### 永久动画用 `React.memo`

```tsx
// ✗ 永远在动的元素和业务组件混在一起 → 业务 re-render 时动画会重启
export function PageWithBreathingDot() {
  return <><BreathingDot /><BusinessLogic /></>;
}

// ✓ 用 React.memo 隔离
const BreathingDot = React.memo(() => <motion.div animate={...} />);
```

### `will-change` 仅在动画期间

```tsx
// ✗ <div style={{ willChange: 'transform' }}>  // 永久占 GPU 内存
// ✓ 在 onAnimationStart 时加，onAnimationEnd 时删
```

### `contain` 限制重绘

```css
.heavy-section {
  contain: layout style paint;   /* 改这里不影响其他段 */
}
```

### `useEffect` 必清

```tsx
useEffect(() => {
  const ctx = gsap.context(() => { /* ... */ });
  return () => ctx.revert();   // ← 必须！漏写就内存泄漏
}, []);
```

---

## 5. 移动端适配

### 必查 `prefers-reduced-motion`

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

```tsx
// JS 同样判断
const prefersReducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
if (!prefersReducedMotion) { /* 才跑动画 */ }
```

### `pointer: coarse` 关视差

触屏设备没有精确指针——视差 / 3D / 磁吸效果体验差，禁用：
```css
@media (pointer: coarse) {
  .parallax { transform: none !important; }
}
```

### 粒子上限分级

| 设备 | 粒子上限 |
|:--|:--|
| 桌面 | 800 |
| 平板 | 300 |
| 手机 | 100 |

### GSAP pin 移动端禁用

`< 768px` 时禁用 `ScrollTrigger.pin`——pinned 滚动在手机上经常卡死。

---

## 6. Springs & Easings 速查

### Framer Motion springs

| 感觉 | 配置 |
|:--|:--|
| Snappy（按钮反馈） | `stiffness: 300, damping: 30` |
| Smooth（页面入场） | `stiffness: 150, damping: 20` |
| Bouncy（亮眼元素） | `stiffness: 100, damping: 10` |
| Heavy（大块内容） | `stiffness: 60, damping: 20` |

### CSS Easings

| 用途 | 值 |
|:--|:--|
| 平滑减速（入场） | `cubic-bezier(0.16, 1, 0.3, 1)` |
| 平滑加速（出场） | `cubic-bezier(0.7, 0, 0.84, 0)` |
| 弹性 | `cubic-bezier(0.34, 1.56, 0.64, 1)` |

避免：`linear`（机器感）、`ease`（默认无个性）。

---

## 7. 可访问性硬约束

- ✅ 所有动画外层包 `prefers-reduced-motion` 检查
- ❌ **绝不**让内容每秒闪烁 > 3 次（光敏癫痫风险）
- ✅ 提供可见 focus ring（用 `outline`，不用 `box-shadow`——`box-shadow` 在背景上看不清）
- ✅ 动态显现的内容加 `aria-live="polite"`
- ✅ 自动播放动画必须有暂停按钮

---

## 8. 现成 Recipe 一句话目录

| Recipe | 工具 | 用途 |
|:--|:--|:--|
| Scroll Reveal | Framer | 进入 viewport 时 fade+slide |
| Stagger Grid | Framer | 列表序列入场 |
| Pinned Timeline | GSAP | 横向滚动 + pin |
| Tilt Card | Framer | 鼠标跟随 3D 透视 |
| Magnetic Button | Framer | 鼠标吸附按钮 |
| Text Scramble | Vanilla JS | Matrix 解码效果 |
| SVG Path Draw | CSS | 滚动联动路径动画 |
| Horizontal Scroll | GSAP | 纵向 → 横向劫持 |
| Particle Background | R3F | 装饰 WebGL 粒子 |
| Layout Morph | Framer | Card → Modal 展开 |

完整代码：参考 [MiniMax frontend-dev/references/motion-recipes.md](https://github.com/MiniMax-AI/skills/blob/main/skills/frontend-dev/references/motion-recipes.md)（MIT）。

---

## 9. 依赖管理

```bash
npm install framer-motion              # UI 顶层（不懒加载）
npm install gsap                        # 滚动叙事（懒加载）
npm install lottie-react                # 图标（懒加载）
npm install three @react-three/fiber @react-three/drei   # 3D（懒加载）
```

```tsx
// ✓ 懒加载示例
const Lottie = dynamic(() => import('lottie-react'), { ssr: false });
const Canvas = dynamic(() => import('@react-three/fiber').then(m => m.Canvas), { ssr: false });
```

---

## 10. 完成前 Checklist

- [ ] 强度等级与项目类型匹配
- [ ] 没在同一组件混 GSAP + Framer Motion
- [ ] 永久动画用 `React.memo` 隔离
- [ ] 只动 GPU 属性（transform / opacity / filter / clip-path）
- [ ] 所有 `useEffect` 中的 GSAP / observer 都有 cleanup
- [ ] `prefers-reduced-motion` 包了所有动画
- [ ] `pointer: coarse` 关闭视差 / 3D / 磁吸
- [ ] 粒子按设备分级上限
- [ ] GSAP pin 在 mobile < 768px 禁用
- [ ] focus ring 用 `outline`（不用 `box-shadow`）
- [ ] 自动播放动画有暂停按钮
- [ ] 内容闪烁 ≤ 3 次/秒
- [ ] 重型库懒加载（GSAP / Lottie / Three.js）
