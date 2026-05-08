---
name: architecture-patterns
description: 架构设计模式与决策框架。为 资深系统架构师 提供模块解耦、接口设计、数据流、权衡取舍的专家视角。
when_to_use: 当 资深系统架构师 设计新模块 / 做技术选型 / 评估接口边界 / 考虑模块解耦时；用户提"架构设计"、"技术方案"、"模块边界"、"系统设计"、"重构方案"时自动加载。
paths: ["**/arch/**", "**/architecture/**", "**/*.arch.md"]
---

<skill name="architecture-patterns">

<knowledge domain="design-principles">

<knowledge domain="solid">
<principle name="S">单一职责：一个模块/类/函数只有一个改变的理由</principle>
<principle name="O">开闭原则：对扩展开放，对修改关闭（通过抽象和插件化）</principle>
<principle name="L">Liskov 替换：子类可以替换父类使用而不破坏程序</principle>
<principle name="I">接口隔离：多个专门接口优于一个通用接口</principle>
<principle name="D">依赖倒置：依赖抽象而非具体实现</principle>
</knowledge>

<knowledge domain="dry-wet-aha">
<principle name="DRY">**同一业务语义的**重复必须消除</principle>
<principle name="WET">看起来相似但语义不同的重复**允许存在**（过早抽象比重复更糟）</principle>
<principle name="AHA">抽象应该在第 3 次重复后才出现</principle>
</knowledge>

<principle name="error-isolation">错误传播不应该是默认行为——一个模块的失败不应该无保护地让整个系统崩溃。每个模块边界都应该有明确的错误处理策略：fail fast、降级、重试、熔断。</principle>

</knowledge>

<knowledge domain="layered-architecture">

<knowledge domain="classic-three-tier">
<convention name="Presentation">表示层：UI / API 端点</convention>
<convention name="Business-Logic">业务逻辑层：领域逻辑、用例</convention>
<convention name="Data-Access">数据访问层：DB / 第三方服务</convention>
<rule>每层只能调用**下一层**，不可反向或跨层。</rule>
</knowledge>

<knowledge domain="hexagonal">
<convention name="Core">领域逻辑，不依赖任何外部概念（HTTP、DB 都不出现）</convention>
<convention name="Ports">核心需要的抽象接口</convention>
<convention name="Adapters">外界到端口的具体实现</convention>
<principle>优势：核心可独立测试；替换基础设施不影响业务</principle>
</knowledge>

<knowledge domain="clean-architecture">
<convention name="Entity">业务实体</convention>
<convention name="Use-Case">业务用例</convention>
<convention name="Interface-Adapter">UI / 控制器 / Gateway</convention>
<convention name="Framework-Drivers">具体框架、数据库</convention>
<rule>依赖方向：始终向内（Framework 依赖 Interface Adapter，后者依赖 Use Case，最终依赖 Entity）</rule>
</knowledge>

</knowledge>

<knowledge domain="module-division">

<knowledge domain="by-business-capability">
<principle>按业务能力划分（推荐）</principle>
<example>
src/
├── order/           # 订单
├── user/            # 用户
├── payment/         # 支付
</example>
<convention>模块内部高内聚（所有订单相关在一起），模块间低耦合（订单不直接改用户数据）。</convention>
</knowledge>

<knowledge domain="by-tech-layer">
<principle>按技术层划分（不推荐作为一级划分）</principle>
<trap>改一个业务要在多个目录来回跳，模块边界模糊。</trap>
</knowledge>

<knowledge domain="hybrid">
<principle>混合：一级按业务，内部按技术层</principle>
<example>
src/
├── order/
│   ├── controller.ts
│   ├── service.ts
│   ├── repository.ts
│   └── types.ts
</example>
</knowledge>

</knowledge>

<knowledge domain="communication-patterns">

<knowledge domain="sync">
<item name="REST">简单、广泛支持、浏览器友好</item>
<item name="GraphQL">灵活查询、避免多次往返、适合复杂 UI</item>
<item name="gRPC">高性能、类型安全、适合内部服务</item>
</knowledge>

<knowledge domain="async">
<item name="message-queue">消息队列（Kafka / RabbitMQ / SQS）：解耦、削峰、异步任务</item>
<item name="event-bus">事件总线：领域事件驱动的架构</item>
<item name="webhook">Webhook：通知第三方</item>
</knowledge>

<reference name="selection-matrix">
| 需求 | 选择 |
|:--|:--|
| 简单 CRUD、浏览器直接调用 | REST |
| 前端需要自由组合数据 | GraphQL |
| 内部服务高性能 | gRPC |
| 解耦、异步处理 | 消息队列 |
| 通知第三方 | Webhook |
</reference>

</knowledge>

<knowledge domain="data-consistency">

<knowledge domain="strong-consistency">
<convention>单库事务：ACID 保证</convention>
<convention>分布式事务：XA / Saga（慎用，复杂度高）</convention>
<convention>适用：金融、账户、库存核心场景</convention>
</knowledge>

<knowledge domain="eventual-consistency">
<convention>事件驱动</convention>
<convention>幂等消费 + 重试</convention>
<convention>适用：非关键路径、大部分业务</convention>
</knowledge>

<knowledge domain="cap">
<convention name="CP">一致性优先，可能降低可用性</convention>
<convention name="AP">可用性优先，最终一致</convention>
<principle>不同系统选择不同（支付 CP；社交 AP）</principle>
</knowledge>

</knowledge>

<knowledge domain="interface-design">

<knowledge domain="backward-compatibility">
<convention name="add-field">新增字段：可选字段默认为安全值</convention>
<convention name="modify-field">修改字段：先双写双读，再切换，再下线</convention>
<convention name="remove-field">删除字段：标记 deprecated → 等待客户端升级 → 下线</convention>
<convention name="breaking-change">破坏性变更：版本号升级</convention>
</knowledge>

<knowledge domain="error-contract">
<convention>错误码稳定（客户端可依赖）</convention>
<convention>错误码有命名空间（避免全局冲突）</convention>
<convention>错误响应统一结构</convention>
<convention>特殊情况有明确处理方式（限流、鉴权失败、资源不存在）</convention>
</knowledge>

<knowledge domain="type-constraints">
<convention>所有字段类型显式</convention>
<convention>枚举值显式（不要用 magic number）</convention>
<convention>长度/范围/格式约束在接口层声明</convention>
<convention>Null / 缺失 / 空字符串的语义区分</convention>
</knowledge>

</knowledge>

<knowledge domain="performance">

<knowledge domain="read-heavy">
<convention>缓存（Redis、CDN）</convention>
<convention>读副本</convention>
<convention>物化视图</convention>
</knowledge>

<knowledge domain="write-heavy">
<convention>批处理</convention>
<convention>异步队列</convention>
<convention>分片</convention>
</knowledge>

<knowledge domain="large-data">
<convention>分页（游标分页 > offset 分页）</convention>
<convention>流式处理</convention>
<convention>冷热数据分离</convention>
</knowledge>

<knowledge domain="high-concurrency">
<convention>异步处理</convention>
<convention>限流 / 熔断</convention>
<convention>无状态化（便于水平扩展）</convention>
</knowledge>

</knowledge>

<knowledge domain="observability-design">
<principle>在设计阶段就考虑</principle>
<checklist>
  <item>**日志点**：关键业务事件、错误、慢操作</item>
  <item>**指标**：业务指标（下单数、成功率）+ 系统指标（延迟、错误率）</item>
  <item>**追踪**：跨服务的 trace ID 贯穿</item>
</checklist>
<rule>**不要**等系统出问题再加可观测性。</rule>
</knowledge>

<knowledge domain="common-pitfalls">

<trap name="over-engineering">
  <item>为了"扩展性"添加了永远用不上的抽象层</item>
  <item>为单机系统引入了分布式架构</item>
  <item>为简单需求使用了复杂的消息队列 / CQRS</item>
</trap>

<trap name="under-engineering">
  <item>核心金融操作没有事务</item>
  <item>高并发场景没有幂等设计</item>
  <item>缺乏可观测性，出问题无法定位</item>
</trap>

<trap name="architecture-impl-gap">
  <item>架构图看起来合理，但 scope-lock 没有落地</item>
  <item>接口契约描述模糊，开发者自行发挥</item>
</trap>

</knowledge>

<convention name="scope-lock-requirements">
<principle>一份好的 scope-lock 应该</principle>
<checklist>
  <item>**精确到文件和函数**：不接受"修改 auth 模块"</item>
  <item>**显式的禁止事项**：不只列白名单，也列黑名单</item>
  <item>**完整的接口契约**：类型定义、错误码、边界值</item>
  <item>**可执行的验证命令**：开发者可以复制粘贴运行</item>
  <item>**可逐条勾选的完成标准**：不留解释空间</item>
</checklist>
<convention>对照 `architecture-review-protocol` Skill 的架构审查检查清单自检。</convention>
</convention>

<knowledge domain="decision-framework">
<principle>面对多个方案时的决策框架</principle>
<checklist>
  <item>**必须满足的约束**是什么？（硬约束）</item>
  <item>**偏好的取舍**是什么？（软约束）</item>
  <item>各方案如何满足/违反约束？</item>
  <item>长期维护成本？</item>
  <item>可逆性？不可逆的决策要更保守</item>
</checklist>

<convention name="adr">
<principle>写入 ADR（架构决策记录）</principle>
<checklist>
  <item>背景</item>
  <item>选项</item>
  <item>选择</item>
  <item>理由</item>
  <item>代价</item>
</checklist>
<principle>下次遇到类似问题时，ADR 让你不必重新推导。</principle>
</convention>
</knowledge>

</skill>
