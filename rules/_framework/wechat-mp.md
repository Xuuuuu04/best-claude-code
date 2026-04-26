---
paths:
  - "miniprogram/**"
  - "**/*.wxml"
  - "**/*.wxss"
  - "**/*.wxs"
  - "**/app.json"
  - "**/project.config.json"
  - "**/sitemap.json"
when_to_use: 仅当项目确认为微信小程序（存在 app.json、project.config.json、miniprogram 目录或 .wxml 文件）时启用。**不要**因为路径含 pages/ 或 components/ 而应用本规则——这两个目录在 Next.js / Vue / 任意前端项目都存在。
---

# 微信小程序规范

> **适用判定（主会话读到本规则后先检查）**：项目根是否存在 `project.config.json` 或 `app.json` 中有 `pages` 字段。若否，本规则不适用，以项目实际技术栈为准。

## 项目结构

- `app.js/ts`、`app.json`、`app.wxss`：入口
- `pages/`：页面（每个页面 4 个文件：js/wxml/wxss/json）
- `components/`：自定义组件
- `utils/`：工具
- 分包：`subpackages/` 配合 `app.json` 声明

## 包大小

- **主包 <2MB**
- 单个分包 <2MB
- 整包 <20MB（后续版本可能变化）
- 超限解决：分包、图片走 CDN、移除未使用依赖

## setData 性能

**关键陷阱**：

- `setData` 单次数据 <256KB
- 避免高频 `setData`（节流、批量）
- 只更新变化的路径：`setData({ 'list[0].name': 'new' })` 而非整个 list
- 避免在 `setData` 后立即读 data（异步更新）

## 生命周期

### 页面
- `onLoad`：初始化（只执行一次）
- `onShow`：每次显示
- `onHide`：离开但未销毁
- `onUnload`：销毁（释放资源）

### 组件
- `attached`：进入节点树
- `detached`：离开节点树
- `ready`：布局完成

## 网络

- `wx.request` 限制：同时最多 10 个（小程序平台）
- 使用请求库封装重试、超时、拦截器
- API URL 必须配置在后台白名单（否则开发模式可用，真机报错）

## 存储

- `wx.setStorageSync` / `wx.setStorage`：总大小限制 10MB
- 敏感数据**不明文存储**
- 清理策略：LRU / TTL

## 权限与用户信息

- 按需请求权限（授权）
- 用户拒绝后要降级体验
- `getUserProfile` 需在用户点击后触发（不能默认调用）
- `getPhoneNumber` 需要按钮 `open-type="getPhoneNumber"`

## 支付

- 严格按微信支付规范
- 服务端返回 `prepay_id` 再调 `wx.requestPayment`
- **不在前端计算金额**，由后端基于订单 ID 查询

## 订阅消息

- 模板消息已停用
- 使用订阅消息：`wx.requestSubscribeMessage`
- 模板需在后台审核通过

## 审核合规

- 内容安全：使用 `security.msgSecCheck` 过滤用户输入
- 苹果 IAP：虚拟商品可能要求走 iOS 内购
- 政策合规：隐私声明、用户协议必须齐全

## 组件化

- 抽取复用组件到 `components/`
- 组件 properties 显式类型声明
- 组件 methods 不直接访问父页面（通过事件）

### Input 密码隐藏（坑）

- ✗ `-webkit-text-security: disc` — 微信小程序原生 input 在 Android X5 内核**不支持**此 CSS（PC 调试器看着没问题，真机失效）
- ✓ `<input type="text" :password="!show" />` — 用原生 `password` 布尔属性切换显示/隐藏，PC 与真机表现一致

## 样式（WXSS）

- 单位：`rpx`（750 rpx = 屏幕宽度）
- `@import` 复用样式
- 避免 `*` 通配符（性能）
- 深色模式：`prefers-color-scheme` 或主题切换

## JavaScript

- ES6+（小程序支持良好）
- Promise 化 API（官方文档有 `Promise` 前缀方法）
- 避免全局变量污染（用 app.globalData 或模块）

## 分包加载

- 主包放启动必需的页面
- 非核心页面分包
- `usingComponents` 的组件必须在同一包内或预加载

## 测试

- 单元测试：miniprogram-simulate
- 真机调试必须覆盖主流机型（iOS / Android）
- 版本兼容：检查基础库版本

## 发布

- 体验版 → 审核 → 上线
- 灰度发布（版本管理）
- 线上问题用 A/B 流量切分或快速回滚
