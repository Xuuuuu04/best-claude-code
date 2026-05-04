# iOS 开发速查与检查清单

> **来源 attribution**：本文档内容综合自以下 MIT 许可的开源 skill 与 Apple 官方文档：
> - [MiniMax-AI/skills · ios-application-dev](https://github.com/MiniMax-AI/skills/tree/main/skills/ios-application-dev) — MIT
> - Apple Human Interface Guidelines（公开文档）
> - Apple Developer Documentation（公开文档）
>
> 本文档保留方法论结构，已根据 Agent Legion 的 高级移动端工程师 工作流改写。Swift / SwiftUI / UIKit / SF Symbols 是 Apple Inc. 商标。

适用：高级移动端工程师 接到 iOS 任务时。

---

## Quick Reference：意图 → 组件

### UIKit

| 用途 | 组件 |
|:--|:--|
| 主分区 | `UITabBarController` |
| 钻取式导航 | `UINavigationController` |
| 专注任务 | Sheet presentation |
| 关键决策 | `UIAlertController` |
| 次要操作 | `UIContextMenuInteraction` |
| 列表内容 | `UICollectionView` + `DiffableDataSource` |
| 分组列表 | `DiffableDataSource` + `headerMode` |
| 网格布局 | `UICollectionViewCompositionalLayout` |
| 搜索 | `UISearchController` |
| 分享 | `UIActivityViewController` |
| 单次定位 | `CLLocationButton` |
| 触感反馈 | `UIImpactFeedbackGenerator` |
| 线性布局 | `UIStackView` |
| 自定义形状 | `CAShapeLayer` + `UIBezierPath` |
| 渐变 | `CAGradientLayer` |
| 现代按钮 | `UIButton.Configuration` |
| 动态字体 | `UIFontMetrics` + `preferredFont` |
| 暗色模式 | 语义色 (`.systemBackground`, `.label`) |

### SwiftUI

| 用途 | 组件 |
|:--|:--|
| 主分区 | `TabView` + `tabItem` |
| 钻取式导航 | `NavigationStack` + `NavigationPath` |
| 专注任务 | `.sheet` + `presentationDetents` |
| 关键决策 | `.alert` |
| 次要操作 | `.contextMenu` |
| 列表内容 | `List` + `.insetGrouped` |
| 搜索 | `.searchable` |
| 分享 | `ShareLink` |
| 单次定位 | `LocationButton` |
| 进度（已知） | `ProgressView(value:total:)` |
| 进度（未知） | `ProgressView()` |
| 动态字体 | `.font(.body)` 语义样式 |
| 暗色模式 | `.primary`, `.secondary`, `Color(.systemBackground)` |
| 场景生命周期 | `@Environment(\.scenePhase)` |
| 减弱动画偏好 | `@Environment(\.accessibilityReduceMotion)` |
| 动态字体偏好 | `@Environment(\.dynamicTypeSize)` |

---

## 6 大维度核心原则

### Layout
- Touch target ≥ **44pt**
- 内容在 Safe Area 内（SwiftUI 默认尊重，仅装饰背景用 `.ignoresSafeArea()`）
- 8pt 间距增量（8, 16, 24, 32, 40, 48）
- 主操作放在拇指可达区（屏幕下半部）
- 支持 iPhone SE 375pt 到 Pro Max 430pt 全尺寸

### Typography
- UIKit: `preferredFont(forTextStyle:)` + `adjustsFontForContentSizeCategory = true`
- SwiftUI: 语义样式 `.headline`, `.body`, `.caption`
- 自定义字体: `UIFontMetrics` / `Font.custom(_:size:relativeTo:)`
- 在 accessibility 字号下布局自适应（最小 11pt）

### Colors
- 语义系统色（`.systemBackground`, `.label`, `.primary`, `.secondary`）
- 自定义色用 Asset Catalog Any/Dark Appearance 变体
- 不仅靠颜色传达信息（配 icon 或文字）
- 对比度 ≥ 4.5:1（正文）/ 3:1（大字）

### Accessibility
- icon 按钮加 label（`.accessibilityLabel()`）
- 尊重 reduce motion（`@Environment(\.accessibilityReduceMotion)`）
- 阅读顺序符合逻辑（`.accessibilitySortPriority()`）
- 支持 Bold Text、Increase Contrast 偏好

### Navigation
- Tab Bar（3-5 个分区）在导航过程中保持可见
- 系统右滑返回手势必须可用（绝不重写）
- 跨 Tab 状态保留（`@SceneStorage`、`@State`）
- **绝不**用汉堡菜单 / 抽屉

### Privacy & Permissions
- 权限按上下文请求（不在启动时弹）
- 系统弹框前给自定义解释
- 提供 Sign in with Apple
- 尊重 ATT 拒绝

---

## 完成前 Checklist

### Layout
- [ ] Touch target ≥ 44pt
- [ ] 内容在 safe area 内
- [ ] 主操作在拇指区（下半部）
- [ ] 弹性宽度适配 SE→Pro Max
- [ ] 间距对齐 8pt 网格

### Typography
- [ ] 用语义样式或 UIFontMetrics 缩放的自定义字体
- [ ] Dynamic Type 支持到 accessibility 字号
- [ ] 大字号下布局重排（无截断）
- [ ] 最小字号 11pt

### Colors
- [ ] 语义系统色或 light/dark asset 变体
- [ ] Dark Mode 是有意设计（不是单纯反色）
- [ ] 不仅靠颜色传达信息
- [ ] 文字对比度 ≥ 4.5:1（普通）/ 3:1（大字）
- [ ] 单一 accent 色用于交互元素

### Accessibility
- [ ] VoiceOver label 在所有交互元素
- [ ] 阅读顺序合逻辑
- [ ] 尊重 Bold Text 偏好
- [ ] Reduce Motion 关闭装饰动画
- [ ] 所有手势有替代访问路径

### Navigation
- [ ] 3-5 个顶级分区用 Tab Bar
- [ ] 没有汉堡菜单 / 抽屉
- [ ] Tab Bar 导航时保持可见
- [ ] 全程支持系统右滑返回
- [ ] 跨 Tab 保留状态

### Components
- [ ] Alert 仅用于关键决策
- [ ] Sheet 有 dismiss 路径（按钮 + 滑动）
- [ ] List row ≥ 44pt 高
- [ ] 破坏性按钮用 `.destructive` role

### Privacy
- [ ] 按上下文请求权限（不在启动时）
- [ ] 系统弹框前给自定义解释
- [ ] Sign in with Apple 与其他登录方式并列
- [ ] 基础功能可不登录使用
- [ ] 如果追踪 → 弹 ATT，尊重拒绝

### System Integration
- [ ] 优雅处理打断（来电、后台、Siri）
- [ ] 内容索引到 Spotlight
- [ ] 可分享内容用 Share Sheet

---

## 反模式（拒绝列表）

- ✗ 汉堡菜单 / 抽屉式导航
- ✗ 重写系统返回手势
- ✗ Touch target < 44pt
- ✗ 启动时立即请求所有权限
- ✗ 仅用颜色传达信息
- ✗ 暗色模式直接反色（应有意设计）
- ✗ 在 viewDidLoad 阻塞 UI 做长任务
- ✗ 强制锁屏方向（除非游戏 / 视频）
