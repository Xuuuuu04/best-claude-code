# Agent 设计模式

> 状态：[骨架] 待模式 A 填充
> 创建日期：2026-04-18
> 最后更新：2026-04-18

---

## 单 Agent 模式

> [待验证] 待填充

### ReAct（Reason + Act）
- 交替进行推理（Thought）和行动（Action）
- 工具调用循环

### Plan-and-Execute
- 先制定完整计划，再逐步执行
- 与 ReAct 的权衡：规划先行 vs 动态调整

### Reflexion
- 生成 → 执行 → 反思 → 修正闭环
- 自我评估机制

## 多 Agent 模式

> [待验证] 待填充

### Supervisor 模式
- 主控 Agent 分配任务给专职子 Agent
- 本 Harness 团队采用的核心模式

### Swarm 模式
- 去中心化，Agent 间直接传递任务
- OpenAI Swarm 框架

### Mixture-of-Agents（MoA）
- 多个 LLM 独立生成，聚合者综合结果
- 提升输出质量

## 人机协作（HITL）

> [待验证] 待填充

- Interrupt 节点设计
- Approval Gate（高风险操作审批）
- 分歧处理（Agent 意见不一致时上升人工）

## 参考文献

> [待验证] 待填充

---

*待模式 A 启动时从 Anthropic Agents 系列博客 / LangGraph 文档 / arXiv 填充。*
