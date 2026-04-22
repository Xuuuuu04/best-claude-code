---
name: project-knowledge
description: 漫展官网购票系统（Furry8）全局知识库。包含双端技术栈、31 个 API 端点、模块结构、共享代码、迭代进度与变更日志。由 /bcc-update-project 维护。
---

# 项目知识库：漫展官网购票系统（Furry8）

**最后更新**: 2026-04-23
**项目类型**: 纯前端外包（Web + 微信小程序）
**后端**: 客户自有团队（`https://api.furry8.cn`）

---

## 项目身份

- **名称**: 漫展官网购票系统（福瑞八奇物志 Furry8）
- **一句话描述**: 漫展活动购票平台，含 Web 响应式站点 + 微信小程序双端
- **业务领域**: 活动票务电商
- **当前阶段**: 二期交付中（已收开工款 ¥2000/¥6000）

---

## 技术栈详情

### 语言 & 运行时
- **主语言**: JavaScript（Web）、TypeScript 4.9（小程序）
- **Node.js**: 20+（开发环境）

### 框架 & 库
- **Web 端**: Vue 3.5 + Vue Router 4.6 + Pinia 3.0 + Axios 1.14
- **小程序端**: uni-app (Vue 3.4) + @dcloudio/vite-plugin-uni 3.0
- **加密**: crypto-js ^4.2.0（双端共享 AES）
- **二维码**: qrcode ^1.5.4（Web）、uqrcodejs ^4.0.7（小程序）
- **HTML 净化**: dompurify ^3.4.0（Web 端，当前由 richText.js 手写 sanitize 替代使用）
- **国际化**: vue-i18n ^9.1.9（小程序依赖，当前未使用）

### 构建工具
- **Web**: Vite 8.0 + @vitejs/plugin-vue 6.0
- **小程序**: Vite 5.2 + vue-tsc 1.0（类型检查）
- **包管理**: npm

### 测试 & CI/CD
- **无单元测试 / E2E**（本项目未配置）
- **无 CI/CD**（手动构建部署）
- **部署**: 手动上传 Web 产物至服务器；小程序通过微信开发者工具上传

### 数据存储
- **无数据库**（纯前端，数据全部来自后端 API）
- **前端持久化**: localStorage（Web）、uni.getStorageSync（小程序）

---

## 模块依赖关系

```
shared/                 # 双端共享（@shared 别名）
├── constants/          # 业务枚举
├── copy/               # 法律文案
├── crypto/             # AES 加解密
├── mock/               # Mock 数据（大部分已弃用）
└── utils/              # 工具函数
       │
       ├─── web/        # Vue 3 SPA（浏览器）
       │    ├── api/    # Axios + AES 封装
       │    ├── components/  # 7 个组件
       │    ├── router/      # 14 条路由
       │    ├── stores/      # Pinia x3
       │    ├── views/       # 14 个页面
       │    └── utils/       # richText, webToast
       │
       └─── miniapp/    # uni-app（微信小程序）
            ├── api/    # uni.request + AES 封装
            ├── components/  # 6 个组件
            ├── pages/       # 15 个页面
            └── utils/       # auth, richText, wx
```

### Web 端模块

| 目录 | 文件数 | 职责 |
|------|--------|------|
| `api/` | 4 | Axios 封装(request.js)、业务 API(index.js)、优惠券(coupon.js)、新闻(news.js) |
| `components/` | 7 | AppIcon、AppNavbar、CheckoutSheet、CouponPanel、MyTicketsSheet、TicketQrCode、UpgradeSheet |
| `router/` | 1 | 14 条路由定义 + 登录守卫 |
| `stores/` | 3 | auth.js(认证)、ticket.js(票务/SKU)、order.js(订单) |
| `views/` | 14 | 页面视图（auth/home/news/ticket/user/placeholder/scan） |

### 小程序端模块

| 目录 | 文件数 | 职责 |
|------|--------|------|
| `api/` | 4 | uni.request 封装(request.ts)、业务 API、优惠券、新闻 |
| `components/` | 6 | AppIcon、NavBar、CheckoutSheet、CouponPanel、TicketQrCode、UpgradeSheet |
| `pages/` | 15 | 小程序页面（4 Tab + 11 非 Tab） |
| `utils/` | 3 | auth.ts(登录态)、richText.ts、wx.ts(微信 code) |

### 共享代码

| 目录 | 文件 | 导出 |
|------|------|------|
| `constants/` | enums.js | EVENT_STATUS, SKU_STATUS, ORDER_STATUS, PAY_STATUS, TICKET_STATUS, REFUND_STATUS, REFUND_TYPE |
| `constants/` | coupon.js | COUPON_TYPE, formatCouponValue, formatCouponAmount, formatMinAmount |
| `copy/` | aboutUs.js, legalTerms.js, ticketNotice.js | 文案内容 |
| `crypto/` | index.js | encrypt, decrypt（AES-128-ECB/PKCS7, key=v7X3n9q2wR4mK8pL） |
| `mock/` | mockData.js, newsMock.js, couponMock.js | Mock 数据（newsMock USE_MOCK=false） |
| `utils/` | date.js | safeDate, formatDate, formatDateRange |
| `utils/` | eventStatus.js | computeEventDisplayStatus |
| `utils/` | mask.js | isValidEmail, isValidPhone, maskPhone, maskEmail |
| `utils/` | price.js | formatPrice |
| `utils/` | stockLevel.js | formatStockLevel |
| `utils/` | ticketQr.js | buildQrPayload, buildUserQrPayload |

---

## API 端点索引（31 个）

### 认证
| 路径 | 方法 | 说明 |
|:--|:--|:--|
| `/ticket/login` | POST | Web 账号密码登录 |
| `/ticket/login/applet` | POST | 小程序微信登录（传 wx.login 的 code） |
| `/ticket/register/email/code` | POST | 发送注册验证码（兼容手机号） |
| `/ticket/register/email/verify` | POST | 验证并注册 |
| `/ticket/forget/send` | POST | 发送重置验证码 |
| `/ticket/forget/verify` | POST | 验证并重置密码 |

### 活动 & 商品
| 路径 | 方法 | 说明 |
|:--|:--|:--|
| `/ticket/event/list` | GET | 活动列表 |
| `/ticket/banner/list` | GET | 首页 Banner |
| `/ticket/sku/category` | GET | 商品类别（含规格） |
| `/ticket/sku/info` | GET | 商品 SKU 详情 |
| `/ticket/sku/info/:skuId` | GET | 商品 SKU 详情（按 ID） |
| `/ticket/sku/tag` | GET | 商品 Tag 列表 |

### 订单
| 路径 | 方法 | 说明 |
|:--|:--|:--|
| `/ticket/order/create` | POST | 下单 |
| `/ticket/order/pay` | POST | 支付 |
| `/ticket/order/cancel` | POST | 取消订单 |
| `/ticket/order/list` | GET | 订单列表 |
| `/ticket/order/detail/:orderNo` | GET | 订单详情 |
| `/ticket/order/refund` | POST | 退款申请 |
| `/ticket/order/refund/cancel` | POST | 取消退款 |
| `/ticket/order/refund/list/:orderNo` | GET | 退款历史 |

### 用户
| 路径 | 方法 | 说明 |
|:--|:--|:--|
| `/ticket/user/center` | GET | 个人中心数据 |
| `/ticket/user/info` | PUT | 更新昵称/头像 |
| `/ticket/user/authenticate` | POST | 实名认证 |
| `/ticket/user/bind/email/code` | POST | 发送绑定邮箱验证码 |
| `/ticket/user/bind/email` | POST | 绑定邮箱 |

### 优惠券
| 路径 | 方法 | 说明 |
|:--|:--|:--|
| `/ticket/user-coupon/coupon/available` | POST | 获取可用优惠方案 |
| `/ticket/user-coupon/discount` | POST | 选券试算优惠明细 |
| `/ticket/user-coupon` | GET | 我的优惠券列表 |

### 票码 & 升级
| 路径 | 方法 | 说明 |
|:--|:--|:--|
| `/ticket/code/list` | POST | 票码列表（含 ticketCode） |
| `/ticket/code/upgrade/versions` | POST | 可升级版本列表 |
| `/ticket/code/upgrade` | POST | 执行票码升级（返回支付信息） |

### 新闻 & 其他
| 路径 | 方法 | 说明 |
|:--|:--|:--|
| `/ticket/article/list` | GET | 新闻/公告列表 |
| `/ticket/article/detail` | GET | 新闻详情 |
| `/ticket/official/contact` | GET | 官方联系方式 |

### 范围外接口（客户未付款，不做）
| 路径 | 说明 |
|:--|:--|
| `/ticket/coupon/get` | 领券 |
| `/ticket/coupon/scope` | 券限品类 |
| `/ticket/coupon/list` | 公共券列表 |
| 兽装相关接口 x5 | 下次委托 |
| 展商相关接口 x5 | 下次委托 |

---

## 关键约定

### 接口协议
- 成功码：`code === 200`
- Token 过期：`code === 4` → 清除登录态并跳转登录页
- AES 加密：POST body 全链路加密（AES-128-ECB/PKCS7Padding）
- 响应解密：去掉首字符（随机前缀）后解密 JSON
- 密钥：`v7X3n9q2wR4mK8pL`（硬编码）

### 订单状态（7 值）
`0=待支付`, `1=待发放`, `2=已发放`, `3=已完成`, `4=已取消`, `5=退款中`, `6=已退款`

### 金额单位
后端返回「元」（非分），前端直接展示，无需 /100

### 测试约束
- **测试 SKU 只有"否+否"规格组合有数据**（¥0.02），其他规格后端未录入
- Web 开发走 `/api` 代理，勿直连 `api.furry8.cn`（CORS）

---

## 当前迭代进度

### 二期（¥6000，已收 ¥2000）
- [x] TASK-007: 新闻/公告页双端
- [x] TASK-008: 购票优惠券下单确认弹窗
- [x] TASK-009: 用户端票据 QR 出示
- [x] TASK-010: 票码升级
- [x] TASK-011: 客户反馈 14 条全闭环
- [ ] TASK-002: Logo/吉祥物素材替换（Logo 已换，吉祥物待客户提供）

### 范围外（另案委托）
- [ ] 扫码核销（2026-04-19 二次裁决移出本期）
- [ ] 兽装相关接口（5 个）
- [ ] 展商相关接口（5 个）
- [ ] 兽牌上传 + P 图合成

---

## 变更日志

- **2026-04-23**: 修改密码按绑定状态选邮箱/手机号（双端）；取消订单去掉原因 prompt；iOS 强密码覆盖层修复
- **2026-04-20~22**: 活动状态按时间计算 + badge 统一；头像上传 loading 反馈；眼睛图标逻辑修正；X-Platform 回滚 applet
- **2026-04-19~20**: 注册页合规改造（三链接协议 + checkbox @click.prevent）；法律文案全量更新；Logo 双端替换
- **2026-04-18**: 票码升级功能双端完成；生产部署至 furry8.codermumu.top；nginx 代理修复
- **2026-04-16**: 二期全部代码完成；优惠券 4 个真接口对接；ORDER_STATUS 枚举修正为 7 值
- **2026-04-15**: 新增"我的优惠券"列表（双端）
- **2026-04-14**: 票券快捷入口 + 加载稳定性修复
- **2026-04-13**: 新闻接口对接真接口（USE_MOCK=false）

---

## 已知问题与技术债

- [ ] `dompurify` 已安装但 `richText.js` 用手写 sanitize，未实际使用 DOMPurify
- [ ] `vue-i18n` 已安装但代码中无 import，待清理或启用
- [ ] `miniapp/src/static/logo.png` 754KB，占主包约 37%，建议 pngquant 压至 <150KB
- [ ] 小程序 AppSecret 未配置，登录仍临时走 web 平台规避 wxCode 校验
- [ ] 根目录 `jsencrypt.js` 为早期遗留，key 错误，勿引用
- [ ] Web 端 Vue 3.5 vs 小程序 Vue 3.4，版本不一致（暂未引发问题）

---

## 外部服务依赖

- **后端 API**: `https://api.furry8.cn`
- **Web 代理**: `https://1317241373-io0nv7qgxq.ap-chengdu.tencentscf.com`（开发时）
- **生产部署**: `https://furry8.codermumu.top`（nginx + Let's Encrypt）
- **微信小程序**: AppID `wx57cc0c50308f9dc2`

---

## 路由/页面清单

### Web 端（14 条路由）
`/`(首页), `/login`, `/register`, `/tickets`, `/tickets/:eventId`, `/user`, `/user/orders/:orderNo`, `/user/orders/:orderNo/refund`, `/scan`, `/furry-exhibit`, `/vendor-exhibit`, `/news`, `/news/:id`, `/apply`

### 小程序端（15 页，4 Tab）
Tab: `home/index`, `ticket/list`, `user/tickets`, `user/center`
非 Tab: `ticket/detail`, `auth/login`, `auth/register`, `user/coupons`, `user/orders`, `user/orderDetail`, `user/profile`, `user/about`, `placeholder/index`, `news/list`, `news/detail`

---

## 使用说明

- 此文件**不应手动编辑结构**——运行 `/bcc-update-project` 刷新
- 手动编辑仅用于修正自动生成的错误
- Agent（product-analyst, architect）会自动阅读此文件以了解项目全局
