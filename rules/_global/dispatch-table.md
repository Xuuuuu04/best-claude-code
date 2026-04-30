# Dispatch Table — 调度真源

本文件是 Agent Legion 的调度真源。主会话、`CLAUDE.md`、output style 和 `/bcc-*` 流水线若出现冲突，以本表为准。

目标：把“用户信号 → 首调 Agent → 产出 artifact → 下一跳 → 是否可并发”标准化，减少主会话临场判断。

---

## 并发等级

| 等级 | 含义 | 是否允许并发 | 要求 |
|:--|:--|:--|:--|
| `S0` | 决策 / 裁决 / 写入真源 | 禁止 | 必须串行，完成后再派下一跳 |
| `S1` | 只读研究 / 只读审查 | 允许 | 输入 artifact 固定，输出文件互不覆盖 |
| `S2` | 独立 scope-lock 实现 | 条件允许 | 文件白名单无交集，依赖图无前后关系，验证命令可独立运行 |
| `S3` | 测试 / 截图 / 验证 | 条件允许 | 共享环境不会互相污染；否则串行 |

## 并发硬规则

允许并发前必须同时满足：

- 每个 Agent 的输入 artifact 已经 `accepted` 或由调度器明确冻结
- 每个 Agent 的输出 artifact 路径唯一
- 写文件白名单无交集；若不确定，禁止并发
- 依赖图无前后关系；`scope-plan` 中同一 Batch 才可并发
- 不共享会被改写的运行环境、数据库、浏览器会话或部署目标
- 并发启动前向用户说明：并发对象、互不冲突依据、回收顺序

禁止并发的场景：

- `pm`、`architect`、`scope-planner`、`test-lead` 这类决策节点
- 数据库迁移、生产部署、依赖升级、全局配置修改
- 同一文件、同一目录生成物、同一测试数据库、同一浏览器 session
- 任何一个 Agent 需要根据另一个 Agent 的输出继续判断

---

## 快速路由表

| 用户信号 | 首调 Agent | Artifact | 下一跳 | 并发 |
|:--|:--|:--|:--|:--|
| 客户聊天记录 / 售后反馈 / 接单整理 | `client` | `client-brief-*` | `product-analyst` 或 `pm` | S0 |
| 取名 / Slogan / 品牌调性 / 文案方向 | `creative` | `creative-*` | `visual-designer` 或 `doc-writer` | S1 |
| 新功能 / 新页面 / 新接口 | `product-analyst` | `requirements-*` | `requirements-reviewer` | S0 |
| 需求是否完整 / 能不能开发 | `requirements-reviewer` | `review-requirements-*` | `architect` | S0 |
| 下一步 / 推进到哪 / 多阶段调度 | `pm` | `dispatch-*` | 单一推荐 Agent | S0 |
| 整体架构 / 技术方案 / 跨模块重构 | `architect` | `architecture-*` | `scope-planner` | S0 |
| 范围锁定 / 拆 scope / 执行批次 | `scope-planner` | `scope-lock-*`, `scope-plan-*` | `architecture-reviewer` | S0 |
| 架构方案审查 / scope 是否可执行 | `architecture-reviewer` | `review-architecture-*` | implementer / 专项域 | S0 |
| 仓库内定位 / 调用点 / 历史追溯 | `repo-researcher` | `repo-research-*` | 调度器判断 | S1 |
| 外部库 / API / 价格 / 兼容性调研 | `tech-researcher` | `tech-research-*` | `architect` 或调度器 | S1 |
| Web 前端 / UI 代码实现 | `implementer-frontend` | `impl-report-*` | `code-reviewer` | S2 |
| 后端 / API / 服务端逻辑实现 | `implementer-backend` | `impl-report-*` | `code-reviewer` | S2 |
| iOS / Android / Flutter / RN | `implementer-mobile` | `impl-report-*` | `code-reviewer` | S2 |
| 微信小程序 / uni-app / 微信登录支付 | `miniprogram-dev` | `impl-report-*` | `code-reviewer` | S2 |
| 加表 / 改字段 / 迁移 / 索引 | `database-engineer` | `schema-*` | `code-reviewer` + `security-auditor` | S0 |
| 训练模型 / fine-tune / 推理服务 | `ml-engineer` | `ml-report-*` | `code-reviewer` 或 `devops` | S0 |
| 代码审查 / diff 审查 | `code-reviewer` | `review-code-*` | `security-auditor` 或 `functional-tester` | S1 |
| 安全审计 / 上线前安全检查 | `security-auditor` | `review-security-*` | `functional-tester` 或 `test-lead` | S1 |
| 功能测试 / 回归验证 | `functional-tester` | `review-functional-*` | `visual-tester` 或 `test-lead` | S3 |
| UI 截图 / 视觉回归 / 交互可用性 | `visual-tester` | `review-visual-*` | `test-lead` | S3 |
| 能不能验收 / 能不能上线 / 最终裁决 | `test-lead` | `verdict-*` | `devops` 或完成 | S0 |
| API 文档 / 部署说明 / 用户手册 | `doc-writer` | `doc-*` | 用户确认 / 归档 | S1 |
| 设计系统 / tokens / UI 规范 | `visual-designer` | `design-*` | `implementer-frontend` 或 `visual-tester` | S0 |
| 改 agent / 改规则 / 调度跑偏 | `prompt-engineer` | `prompt-governance-*` | 用户确认 / 调度器执行 | S0 |
| 构建 / CI / 部署 / 回滚 | `devops` | `deploy-report-*` 或 `incident-*` | `test-lead` 或完成 | S0 |

---

## 标准流水线

### 新功能

```text
client（如有客户原话）
→ product-analyst
→ requirements-reviewer
→ architect
→ scope-planner
→ architecture-reviewer
→ implementer / 专项域（同 Batch 可并发）
→ code-reviewer（可按 impl-report 并发）
→ security-auditor（见下方强制条件）
→ functional-tester（medium 以上必须）
→ visual-tester（如有 UI）
→ test-lead（见下方强制条件）
```

#### 门控强制条件（基于实战数据 v3.8 新增）

**以下条件命中任一，对应 agent 必须执行，不得跳过：**

| Agent | 强制触发条件 | 数据依据 |
|:--|:--|:--|
| `security-auditor` | 涉及后端 API / 认证 / 支付 / 数据库迁移 / 环境变量 / 敏感数据 | 实战 0 次调用但角色关键 |
| `functional-tester` | 任务档位 medium 或以上 | 4/5 项目无 verdict |
| `test-lead` | scope-lock 总数 ≥ 3，或涉及上线/交付/里程碑 | 4/5 项目无最终裁决 |
| `test-lead`（跨 scope 一致性） | scope-lock 总数 ≥ 3 → 裁决前强制执行跨 scope 接口契约交叉比对 | v3.10 新增：跨 scope 签名不一致是最隐蔽的集成 bug |
| `visual-tester` | 涉及用户可见 UI 变更（页面/组件/样式） | 仅 1/5 项目有视觉测试 |

**不触发的唯一理由**：用户显式说"跳过 XX 测试"。AI 不得自行判断"不适用"而省略。

#### 问题分级标准（v3.9 新增，所有 reviewer/tester 统一使用）

**每个 reviewer/tester 必须按此三级框架判定，不得自定义分级体系：**

| 级别 | 含义 | 对通过的影响 | 示例 |
|:--|:--|:--|:--|
| **严重（Blocker）** | 不可行、不可上线、安全漏洞、scope 越界、关键证据缺失 | **任何 1 项 → 驳回** | SQL 注入、密钥泄露、scope 白名单外修改、无截图证据给 PASS |
| **一般（Issue）** | 设计缺陷、逻辑矛盾、关键遗漏、契约不一致 | **累计 ≥3 项 → 驳回** | 接口字段类型不匹配、缺错误处理、验收标准不可测 |
| **轻微（Nit）** | 可改进但不阻塞 | 不阻塞通过 | 命名建议、注释补充、代码风格优化 |

**判定规则**：
- `APPROVED / PASS`：无严重 AND 一般 < 3
- `REJECTED / BLOCKED`：存在严重 OR 一般 ≥ 3
- 各 reviewer 的审查维度中使用 `[严重]` / `[一般]` / `[轻微]` 标记，不得使用旧的 `Critical` / `Warning` 等模糊标签
- test-lead 最终裁决时，累计所有 reviewer 的严重和一般数量作为裁决依据

**与返回 token 的映射**：
- `REVIEW_REJECT:...:{严重数}blocker:{一般数}issue` — 驳回时附带计数
- `SECURITY_REJECT:...:{严重数}blocker:{一般数}issue` — 安全驳回附带计数
- test-lead 收到 `REVIEW_REJECT` 且 blocker≥1 时直接 BLOCKED，无需再读文件

### Bug 修复

```text
repo-researcher
→ product-analyst（复现与验收边界）
→ requirements-reviewer
→ scope-planner（小 bug 可跳过 architect）
→ implementer / 专项域
→ code-reviewer
→ security-auditor（涉及认证/权限/数据/支付时强制）
→ functional-tester
→ visual-tester（UI bug）
```

### 迁移 / 数据库

```text
repo-researcher
→ tech-researcher（版本升级时）
→ architect
→ scope-planner
→ database-engineer（schema / migration）
→ implementer-backend（业务适配）
→ code-reviewer
→ security-auditor
→ functional-tester
→ devops（staging / production）
→ test-lead（生产前）
```

### 小程序

```text
product-analyst
→ requirements-reviewer
→ architect
→ scope-planner
→ miniprogram-dev
→ code-reviewer
→ functional-tester
→ visual-tester（必须有截图 / 交互证据）
→ test-lead（发布前）
```

### ML

```text
tech-researcher（方法 / 框架调研，按需）
→ product-analyst（业务指标）
→ architect（系统接入方案）
→ ml-engineer
→ code-reviewer
→ security-auditor（数据 / 模型服务风险）
→ functional-tester
→ devops（推理部署）
→ test-lead（上线前）
```

---

## 中断恢复

| 用户信号 | 首调 Agent | Artifact | 下一跳 | 并发 |
|:--|:--|:--|:--|:--|
| 恢复 / 续跑 / resume / 中断了 | 调度器读 artifact 状态 | 同原流水线 | 从断点续跑 | S0 |

使用 `/bcc-resume {task-id}` 自动执行断点检测和续跑。

---

## 并发模板

并发前，调度器输出：

```text
并发批次：Batch {n}
对象：{agent-a} / {agent-b}
依据：scope-lock 白名单无交集；无依赖关系；输出 artifact 不冲突
回收：全部完成后进入 {next-agent}
风险：共享环境 {无 / 有，处理方式}
```

并发回收后，调度器必须汇总：

```text
Batch {n} 回收：{完成数}/{总数}
失败项：{无 / 列表}
下一跳：{agent}
```

---

## 回退规则

- 路由不明 → `pm`
- 技术路线不明 → `architect`
- 外部事实不明 → `tech-researcher`
- 仓库事实不明 → `repo-researcher`
- 质量是否能放行不明 → `test-lead`
- Agent 边界冲突 → `prompt-engineer`

## 跨子项目任务

| 用户信号 | 首调 Agent | Artifact | 下一跳 | 并发 |
|:--|:--|:--|:--|:--|
| 跨子项目 / monorepo 多服务 | `product-analyst`（拆子项目边界） | `requirements-*` | `architect`（跨模块设计）→ 按子项目分别 scope-lock | S0 |

---

## Rule 层叠处理（常见误解）

同一个文件可能激活多条 rule，例如编辑 `app/page.tsx`：

- `rules/_lang/typescript.md`（TS 通用）
- `rules/_framework/react.md`（.tsx 激活）
- `rules/_framework/nextjs.md`（App Router 路径激活）

**这是正常的层叠，不是 bug**。层级关系：语言 ⊂ 库 ⊂ 元框架，每层约束不冲突时全部生效；冲突时外层（元框架）优先。

**但某些 rule 的 `paths` 可能过宽并误激活**（比如一条 Python 框架 rule 匹配通用文件名 `main.py`）。发现此情况时：

1. 主会话在应用该 rule 前，**先读 rule 的 `when_to_use` 字段**
2. 如该字段要求"确认项目为 X 才应用"，则主会话需用 `Grep` / `Read` 做快速验证
3. 验证不通过则视为不适用，不引用该 rule
4. 发现 rule 长期误激活 → 派 `prompt-engineer` 收紧其 paths 或 when_to_use

## Router 分档（v3 新增）

`UserPromptSubmit` hook 会注入 `[LEGION-INTENT] tier=...` 标记。主会话必须按 `output-styles/legion-dispatch.md` 的调度映射表执行：

| tier | 调度 |
|:--|:--|
| `trivial` | 主会话直接答 |
| `small` | 快路径 / 单 implementer；code-reviewer 建议但非强制 |
| `medium` | product-analyst → implementer → **code-reviewer 必经** + **接口字段对账必经**（见下） |
| `large` | 完整流水线 + 全门控 |
| `unclear` | 已被 `clarification-gate` 拦截或追问，禁止假设推进 |

`[REVIEW-PENDING]` 标记出现时：本会话有未 review 的 implementer 改动，medium/large 档必须派 code-reviewer 或经用户明确跳过。

## 接口字段对账（medium 及以上 mandatory）

**触发条件**：任务涉及前端调用后端 endpoint、判断接口枚举字段（payType / orderStatus / status 等）、或新增/修改 API 调用。

**强制步骤**（任一缺失视为流水线违规）：

1. implementer 写代码前，**先 grep 项目内已上线 work 的同字段使用点**：
   ```bash
   grep -rn "{fieldName}" --include="*.vue" --include="*.ts" --include="*.js"
   ```
2. 找到 `shared/constants/enums.js` / 类似字典文件 / OAS 真值表，**对照确认枚举方向与类型**
3. 当心"同名不同义"：同一字段在不同 endpoint/上下文取值可能不同（int vs string、不同语义集合）
4. code-reviewer 审查时，**枚举判断必须有参考代码或 OAS 真值证据**，凭直觉的 `=== 1`、`=== '2'` 视为可疑

**为什么 mandatory**：本协议增加是因为客户因接口字段方向反、字段缺漏类 bug 反复返工到不满意状态（feedback memory `enum-field-direction-cross-check`）。这是已知低级错误，必须用机制堵住。

### Few-shot：错误 vs 正确

#### 反例：凭直觉判断 payType（最常见返工根因）

```typescript
// ❌ 错误：implementer 凭直觉假设 1=微信 2=支付宝
if (order.payType === 1) {
  showWechatIcon();
} else if (order.payType === 2) {
  showAlipayIcon();
}
```

**为什么错**：
- 同一 `payType` 字段在不同 endpoint 取值可能不同
- 没有看 OAS/字典文件就假设方向
- code-reviewer 看到 `=== 1` `=== 2` 没有引用应判 Critical

#### 正例：先对账，再实现

```typescript
// ✅ 步骤 1：grep 已上线代码
// $ grep -rn "payType" --include="*.vue" --include="*.ts"
// → src/shared/constants/payType.js:3
//
// 步骤 2：读字典
// export const PAY_TYPE = {
//   ALIPAY: 1,        // 注意：支付宝是 1，不是 2
//   WECHAT: 2,
//   APPLE_PAY: 3,
// } as const;
//
// 步骤 3：引用常量，不用 magic number

import { PAY_TYPE } from '@/shared/constants/payType';

if (order.payType === PAY_TYPE.WECHAT) {
  showWechatIcon();
} else if (order.payType === PAY_TYPE.ALIPAY) {
  showAlipayIcon();
}
```

#### 反例：同名不同义陷阱

```typescript
// ❌ 错误：在 /order/detail 和 /order/list 共用 status 判断
function isCompleted(order) {
  return order.status === 3;  // 危险：两个 endpoint 的 3 含义不同
}
```

```typescript
// ✅ 正确：明确 endpoint 上下文
import { ORDER_DETAIL_STATUS, ORDER_LIST_STATUS } from '@/types/order';

function isCompletedInDetail(order: OrderDetailResponse) {
  return order.status === ORDER_DETAIL_STATUS.COMPLETED;
}
function isCompletedInList(order: OrderListItem) {
  return order.status === ORDER_LIST_STATUS.DONE;  // list 用的是 'DONE' 不是 'COMPLETED'
}
```

#### code-reviewer 审查模板

```markdown
## 接口字段对账审查

| 字段 | 用法 | 引用证据 | 判定 |
|:--|:--|:--|:--|
| order.payType | === PAY_TYPE.WECHAT | shared/constants/payType.js:3 | ✅ |
| order.status | === 3 | （无引用） | ❌ Critical：magic number 无证据 |
```

无证据的枚举判断 = Critical，退回 implementer 重做。

#### 反例：阈值判断的"中间态"陷阱（v3.5 新增）

来自漫展项目实测：`orderStatus >= 2` 漏掉 `status=1`「待发放」中间态，导致用户刚付完款立即点「已完成支付」时被错判未支付。

```typescript
// ❌ 错误：直觉认为 "已支付" = status >= 2
if (order.orderStatus >= 2) {
  showPaidUI()
}

// 真实定义（@shared/constants/enums.js）：
//   0 = 待支付
//   1 = 待发放（**支付到账后、票券生成中的中间态**）  ← 容易漏
//   2 = 已发放
//   3 = 已完成
//   4/5/6 = 取消/退款
```

```typescript
// ✅ 正确：精确包含中间态
if (order.orderStatus !== ORDER_STATUS.PENDING_PAYMENT) {
  showPaidUI()
}
// 或语义化辅助函数
function isOrderPaid(s: number) { return s >= ORDER_STATUS.PROCESSING; }  // >=1
```

**判据**：状态机字段判断的边界（`>=` / `>` / `!==`）必须基于完整状态枚举表，不能凭直觉。

#### 反例：同名字段跨 endpoint 类型不同（v3.5 实测案例）

漫展项目真实情况——`payType` 在不同 API 取值类型与含义都不同：

| 出处 | 类型 | 取值 |
|:--|:--|:--|
| `payOrder` 响应 | `int` | `1=微信`, `2=聚合（微信+支付宝）` |
| 订单详情 `PAY_TYPE` | `string` | `'0'=支付宝`, `'2'=微信支付` |
| 前端 QR 弹窗 `payQRType` | `int` | `1=仅微信`, `2=双通道` |

```typescript
// ❌ 错误：implementer 看到 payType 复用之前的判断
if (orderDetail.payType === 1) {  // 这是订单详情，1 不存在！(只有 '0'/'2')
  // 永远不进
}

// ✅ 正确：每个调用点独立查 OAS
import { PAY_TYPE_DETAIL } from '@/types/order-detail'  // string union
import { PAY_TYPE_ORDER } from '@/types/pay-order'       // int enum

if (orderDetail.payType === PAY_TYPE_DETAIL.WECHAT) { ... }   // '2'
if (payOrderRes.payType === PAY_TYPE_ORDER.WECHAT) { ... }    // 1
```

**判据**：跨 endpoint 复用同名字段 = Critical。每个 endpoint 的字段都是独立类型空间。

---

## 用户态信号（v3.5 新增 — 客户压力下的强制门控）

**触发条件**：用户对话中出现以下任一信号，立即升级为强制完整门控（无论 hook 标什么 tier）：

| 信号词 | 含义 |
|:--|:--|
| "返工"、"反复修"、"又错了" | 累积失败 — 客户耐心耗尽 |
| "客户不满"、"客户怒了"、"客户多次反馈" | 客户态恶化 |
| "低级错误"、"这种 bug"、"又犯" | 已被识别为 implementer 失误 |
| "终极摸排"、"全面审查"、"逐一核对" | 用户已要求最高严肃度 |

**强制规则**：

1. 改动节奏放慢——禁止一次完成多文件，必经 scope-planner 拆 ≤3 个 scope-lock
2. **强制走完整门控**：product-analyst → architect → scope-planner → implementer → code-reviewer + security-auditor + functional-tester
3. **禁止 implementer 自报通过**——code-reviewer 不点头不允许 commit
4. **接口字段对账升级为 mandatory**（无论是否枚举判断），先 grep 所有相关字段
5. **每个 commit message 必须含**："已通过 code-reviewer 审查"

**为什么 mandatory**：来自漫展项目 feedback `client-rework-fatigue-state` + `never-skip-code-review-medium`。客户因 implementer 长上下文写出"字段方向反"等低级 bug 反复返工到不满意状态。implementer 无 review 直接推 = 让客户当 reviewer。

**code-reviewer 不可省略的硬规则**：medium 及以上档位（多文件 / 跨模块 / 接口字段判断 / 状态机判断），即使 implementer 自己说"build 通过"也**不算合规**，必须经 code-reviewer。
