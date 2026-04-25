---
name: 架构审查样品（feat-20260425-08 实时通知系统）
description: 标准 review-architecture artifact 格式参考
type: review-architecture
task_id: feat-20260425-08
generated_at: 2026-04-25T13:45:00+0800
产出者: architecture-reviewer
status: accepted
关联:
  - architecture-feat-20260425-08.md
  - scope-lock-feat-20260425-08-1.md
  - scope-lock-feat-20260425-08-2.md
---

# review-architecture: feat-20260425-08 实时通知系统

## 审查结果：**条件通过** ⚠

主架构合理，但 scope-lock 拆分有 1 处 Critical 必须修复后才能进 implementer 阶段。

## 审查矩阵

| 维度 | 状态 | Critical | Warning |
|:--|:--:|:-:|:-:|
| 1. 模块边界清晰 | ✓ | 0 | 0 |
| 2. 接口契约可测 | ✓ | 0 | 1 |
| 3. 数据流闭环 | ✓ | 0 | 0 |
| 4. 失败模式覆盖 | ⚠ | 0 | 1 |
| 5. scope-lock 可执行 | ✗ | 1 | 0 |
| 6. 过度/欠工程平衡 | ✓ | 0 | 1 |

## 1. 模块边界（通过）

✓ 三模块清晰：
- `notification-producer`（事件源）
- `notification-bus`（消息队列 + 路由）
- `notification-delivery`（多渠道：push / email / sms）

✓ 边界用接口而非共享类型：`Notification` 通过 protobuf 定义，跨模块版本兼容

## 2. 接口契约（一处 Warning）

### Warning-1: 渠道扩展接口未来扩展性

`DeliveryChannel` 接口当前只支持 push/email/sms，未来要加 WebSocket / 飞书的话需扩接口。

**建议**：把 `send(notification: Notification): Result` 抽象一层，新渠道实现 trait 即可，不改既有调用方。

## 3. 数据流（通过）

✓ 完整闭环：
```
事件源 → producer → bus（持久化 + 重试）→ delivery → 收件人
                                          ↓
                                   ack callback → producer 标记完成
```

✓ ack 机制可保证至少一次送达
✓ 幂等键防重复（`notification_id` 5 分钟去重）

## 4. 失败模式（一处 Warning）

### Warning-2: bus 不可用时降级策略缺失

architecture 文档第 4.3 节提到"bus 高可用"，但未定义"bus 完全不可用时怎么办"。
现在的设计：producer 阻塞重试 60 秒后报错给业务。**这会反向阻塞业务请求**。

**建议补充**：
- 添加本地 fallback 队列（落盘）
- bus 恢复后批量重放
- 业务侧请求立刻返回成功（不阻塞用户）

## 5. scope-lock 可执行性（**Critical**）

### Critical-1: scope-lock-2 与 scope-lock-1 文件白名单冲突

- `scope-lock-feat-20260425-08-1.md` 白名单含 `src/notification/types.ts`
- `scope-lock-feat-20260425-08-2.md` 白名单**也**含 `src/notification/types.ts`

两个 implementer 并行跑会写冲突。**必须**：
- 方案 A：合并为单一 scope（拒绝并行，串行跑）
- 方案 B：拆 types.ts 为 `types-producer.ts` + `types-delivery.ts`，两个 scope 各自负责一份

scope-planner 必须在 scope-plan 中明确标注**Batch 1 独占类型文件，Batch 2 等 1 完成再启**。

## 6. 过度/欠工程（一处 Warning）

### Warning-3: 渠道注册用反射可能过度

architecture 第 5.1 节提议用动态反射注册 DeliveryChannel——这对当前 3 个渠道是 overkill。

**建议**：先用显式 Map<string, DeliveryChannel> + 工厂；如未来渠道 ≥10 再考虑反射注册。

## 总结

- **必须修**：Critical-1（scope-lock 文件冲突）—— 找 scope-planner 调整
- **建议修**：Warning-1/2/3 —— 不阻塞 implementer 启动，可在迭代中补
- 修完 Critical 后即可批准进入 implementer 阶段

## 下一步

派 `scope-planner`：解决 Critical-1（拆 types.ts 或调整 batch 顺序），重新产出 scope-plan-feat-20260425-08-2.md。
