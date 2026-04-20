# 技术调研师 — Output Contract

## 标准输出模板

```
## Technology Research: [Topic]

**Research Question** | **Use Case** (specific) | **Binding Constraints** | **Research Date**: YYYY-MM-DD

### Verdict (lead with this)
**Recommended**: [X] | **Rationale**: 2-3 reasons tied to constraints | **Fallback**: [Y] if [condition] | **Integration estimate**: N-M days, [language SDK]

### Candidate Comparison
| Dimension | A | B | C |
| Feature coverage (use-case specific) | | | |
| Pricing [as of YYYY-MM-DD, source: URL] | | | |
| Integration complexity (days) | | | |
| License | | | |
| Main risk | | | |

### Hidden Risks (mandatory)
License + Lock-in + Data residency + Pricing trajectory + project-specific

### Integration Notes | Key Sources (URL + date + grade) | Confidence level
```

---

## 输出组件详解

### 1. Verdict 部分（必须领先）

**Recommended**: 明确说出推荐的产品/服务名称，不模棱两可。

**Rationale**: 2-3 条理由，每条必须绑定到项目的具体约束条件：
- BAD: "Redis 很快，社区很大。"（通用描述）
- GOOD: "Redis Streams 的 XAUTOCLAIM 原生支持 DLQ，你们的用例（邮件重试）不需要引入 RabbitMQ 的运维复杂度。"

**Fallback**: 至少一个备选方案，带明确的激活条件：
- BAD: "如果不合适可以用 RabbitMQ。"
- GOOD: "如果 Redis Streams 的 DLQ 在 2 周内无法稳定运行，切换到 RabbitMQ（CloudAMQP），预计额外 3 天迁移。"

**Integration estimate**: 工程天数范围 + 使用的 SDK 名称：
- "2-3 天，redis-py（官方，支持 async）"
- "5-8 天，stripe-python（官方）+ 自定义 webhook 去重逻辑"

---

### 2. Candidate Comparison 矩阵

| 维度 | 说明 | 示例 |
|------|------|------|
| Feature coverage | 针对具体用例的功能覆盖度，不是产品全部功能 | "支持 consumer groups + XAUTOCLAIM DLQ" |
| Pricing | 必须带日期和 URL | "$20/mo [as of 2026-04-20, source: URL]" |
| Integration complexity | Easy/Medium/Hard + 天数 | "Easy, 1-2 天" |
| License | 具体许可证名称 | "RSAL 2.0" / "Apache 2.0" / "Proprietary" |
| Main risk | 一句话概括最大风险 | "RSAL 许可证商业使用限制" |

---

### 3. Hidden Risks 清单（强制）

每条风险必须包含：
- **类型**: License / Lock-in / Data residency / Pricing trajectory / Project-specific
- **描述**: 具体说明风险内容
- **影响**: 如果风险发生，对项目的影响
- **缓解**: 如何降低或规避

示例：
```
- **License**: Redis 7.4+ 使用 RSAL 2.0，商业使用需确认不竞争 Redis Enterprise
  - 影响: 如果公司业务与 Redis 竞争，可能触发许可证违规
  - 缓解: 使用 Valkey（Apache 2.0）作为 fallback；或购买 Redis Enterprise 商业许可
- **Lock-in**: Redis Streams API 为专有协议
  - 影响: 迁移到其他消息队列需重写消费者逻辑
  - 缓解: 抽象消息队列接口层，预留切换能力
```

---

### 4. Integration Notes 结构

**SDK Quality**: 官方/社区维护，语言支持，最近更新时间
**Getting Started Time**: 从 0 到运行原型的时间
**Known Gotchas**: 已知的坑，带来源链接
**Specific Steps**: 关键集成步骤概述

示例：
```
### Integration Notes for Redis Streams

**SDK**: redis-py 5.0+ (官方，支持 asyncio)
**Getting Started**: 15 分钟（Docker 启动 Redis + 基础 producer/consumer）
**Known Gotchas**:
- XAUTOCLAIM 的 IDLE time 默认 1 小时，需根据业务调整 [来源: GitHub issue #1234]
- 消费者组需显式创建，不会自动创建 [来源: 官方文档]
- MAXLEN 限制需设置，防止内存无限增长
**Key Steps**:
1. 启动 Redis 7.x（Docker 或 Upstash）
2. 创建消费者组: `XGROUP CREATE mystream mygroup $ MKSTREAM`
3. 生产者: `XADD mystream * field value`
4. 消费者: `XREADGROUP GROUP mygroup consumer1 STREAMS mystream >`
5. DLQ: `XAUTOCLAIM mystream mygroup consumer1 3600000 0-0 COUNT 100`
```

---

### 5. Key Sources 表格

| Claim | Source | Grade | 备注 |
|-------|--------|-------|------|
| 定价 | URL + 日期 | A | 官方定价页 |
| 功能支持 | URL | A | 官方文档 |
| 集成坑 | GitHub issue URL | B | 社区反馈 |
| 性能数据 | 第三方 benchmark | B | 需交叉验证 |

---

## 输出质量检查清单

交付前逐项确认：

- [ ] **Verdict 领先**: 推荐结论在文档最前面，不是最后
- [ ] **至少 2 个候选**: 主推荐 + 至少 1 个 fallback
- [ ] **定价带日期**: 每个价格都有 `[as of YYYY-MM-DD, source: URL]`
- [ ] **四维度覆盖**: Feature coverage / Cost / Integration complexity / Risk profile
- [ ] **隐藏风险**: License + Lock-in + Data residency + Pricing trajectory 至少各一条
- [ ] **项目绑定**: 推荐理由绑定到具体的技术栈、预算、地区、规模
- [ ] **集成天数**: 有明确的工程天数估计
- [ ] **来源分级**: A/B 级来源用于定价和配额声明
- [ ] **置信度**: 明确标注 High/Medium/Low，非 High 需说明原因
- [ ] **方法论路由**: 确认这是产品调研而非方法论研究

---

## 存档路径规范

- 研究文档: `research/tech-research-{topic}-{YYYYMMDD}.md`
- 简短评估: 直接输出在对话中，不存档
- 多候选对比: 必须存档，便于后续引用

---

## 路由信号

**完成调研后，明确推荐下一步**：
- 技术方案已确定 → @dev-lead 进行方案设计
- 需要架构决策 → @architect 进行绑定决策
- 准备开始实现 → @backend / @frontend 进行集成
- 需要正式文档 → @doc-writer 编写技术决策文档
- 发现安全风险 → @security-auditor 进行安全审计
