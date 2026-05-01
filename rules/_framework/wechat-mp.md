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

<rule name="wechat-mp-applicability-check">
  <description>适用判定（主会话读到本规则后先检查）：项目根是否存在 project.config.json 或 app.json 中有 pages 字段。若否，本规则不适用，以项目实际技术栈为准。</description>
</rule>

<rule name="wechat-mp-project-structure">
  <convention>app.js/ts、app.json、app.wxss：入口</convention>
  <convention>pages/：页面（每个页面 4 个文件：js/wxml/wxss/json）</convention>
  <convention>components/：自定义组件</convention>
  <convention>utils/：工具</convention>
  <convention>分包：subpackages/ 配合 app.json 声明</convention>
</rule>

<rule name="wechat-mp-package-size">
  <constraint severity="blocker">主包小于 2MB</constraint>
  <constraint severity="blocker">单个分包小于 2MB</constraint>
  <constraint severity="blocker">整包小于 20MB（后续版本可能变化）</constraint>
  <convention>超限解决：分包、图片走 CDN、移除未使用依赖</convention>
</rule>

<rule name="wechat-mp-setdata-performance">
  <description>关键陷阱</description>
  <constraint severity="blocker">setData 单次数据小于 256KB</constraint>
  <constraint severity="blocker">避免高频 setData（节流、批量）</constraint>
  <convention>只更新变化的路径：setData({ 'list[0].name': 'new' }) 而非整个 list</convention>
  <constraint severity="warning">避免在 setData 后立即读 data（异步更新）</constraint>
</rule>

<rule name="wechat-mp-lifecycle">
  <description>页面</description>
  <convention>onLoad：初始化（只执行一次）</convention>
  <convention>onShow：每次显示</convention>
  <convention>onHide：离开但未销毁</convention>
  <convention>onUnload：销毁（释放资源）</convention>

  <description>组件</description>
  <convention>attached：进入节点树</convention>
  <convention>detached：离开节点树</convention>
  <convention>ready：布局完成</convention>
</rule>

<rule name="wechat-mp-network">
  <convention>wx.request 限制：同时最多 10 个（小程序平台）</convention>
  <convention>使用请求库封装重试、超时、拦截器</convention>
  <constraint severity="blocker">API URL 必须配置在后台白名单（否则开发模式可用，真机报错）</constraint>
</rule>

<rule name="wechat-mp-storage">
  <convention>wx.setStorageSync / wx.setStorage：总大小限制 10MB</convention>
  <constraint severity="blocker">敏感数据不明文存储</constraint>
  <convention>清理策略：LRU / TTL</convention>
</rule>

<rule name="wechat-mp-permissions">
  <convention>按需请求权限（授权）</convention>
  <convention>用户拒绝后要降级体验</convention>
  <convention>getUserProfile 需在用户点击后触发（不能默认调用）</convention>
  <convention>getPhoneNumber 需要按钮 open-type="getPhoneNumber"</convention>
</rule>

<rule name="wechat-mp-payment">
  <constraint severity="blocker">严格按微信支付规范</constraint>
  <convention>服务端返回 prepay_id 再调 wx.requestPayment</convention>
  <constraint severity="blocker">不在前端计算金额，由后端基于订单 ID 查询</constraint>
</rule>

<rule name="wechat-mp-subscribe-message">
  <convention>模板消息已停用</convention>
  <convention>使用订阅消息：wx.requestSubscribeMessage</convention>
  <convention>模板需在后台审核通过</convention>
</rule>

<rule name="wechat-mp-compliance">
  <convention>内容安全：使用 security.msgSecCheck 过滤用户输入</convention>
  <convention>苹果 IAP：虚拟商品可能要求走 iOS 内购</convention>
  <convention>政策合规：隐私声明、用户协议必须齐全</convention>
</rule>

<rule name="wechat-mp-componentization">
  <convention>抽取复用组件到 components/</convention>
  <convention>组件 properties 显式类型声明</convention>
  <convention>组件 methods 不直接访问父页面（通过事件）</convention>
</rule>

<rule name="wechat-mp-input-password-pitfall">
  <description>Input 密码隐藏（坑）</description>
  <example type="bad">
    <title>CSS 方案在真机失效</title>
    <code language="html">
<!-- -webkit-text-security: disc — 微信小程序原生 input 在 Android X5 内核不支持此 CSS（PC 调试器看着没问题，真机失效） -->
    </code>
  </example>
  <example type="good">
    <title>用原生 password 属性</title>
    <code language="html">
<input type="text" :password="!show" />  <!-- 用原生 password 布尔属性切换显示/隐藏，PC 与真机表现一致 -->
    </code>
  </example>
</rule>

<rule name="wechat-mp-styles-wxss">
  <convention>单位：rpx（750 rpx = 屏幕宽度）</convention>
  <convention>@import 复用样式</convention>
  <constraint severity="warning">避免 * 通配符（性能）</constraint>
  <convention>深色模式：prefers-color-scheme 或主题切换</convention>
</rule>

<rule name="wechat-mp-javascript">
  <convention>ES6+（小程序支持良好）</convention>
  <convention>Promise 化 API（官方文档有 Promise 前缀方法）</convention>
  <constraint severity="warning">避免全局变量污染（用 app.globalData 或模块）</constraint>
</rule>

<rule name="wechat-mp-subpackage-loading">
  <convention>主包放启动必需的页面</convention>
  <convention>非核心页面分包</convention>
  <convention>usingComponents 的组件必须在同一包内或预加载</convention>
</rule>

<rule name="wechat-mp-testing">
  <convention>单元测试：miniprogram-simulate</convention>
  <convention>真机调试必须覆盖主流机型（iOS / Android）</convention>
  <convention>版本兼容：检查基础库版本</convention>
</rule>

<rule name="wechat-mp-release">
  <convention>体验版 -> 审核 -> 上线</convention>
  <convention>灰度发布（版本管理）</convention>
  <convention>线上问题用 A/B 流量切分或快速回滚</convention>
</rule>
