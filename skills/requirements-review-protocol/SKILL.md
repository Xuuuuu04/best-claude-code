---
name: requirements-review-protocol
description: 需求审查协议。为 requirements-reviewer 提供完整性、可测试性、边界与风险审查清单。
when_to_use: 仅当 requirements-reviewer 或 product-analyst Agent 在审查 requirements-* artifact 时加载。需求收集阶段（client / product-analyst 还在写）不应触发。
---

# 需求审查协议

## 目标

确保 requirements artifact 可以作为可靠的下游输入。

## 通用原则

1. **Critical 一票否决**：需求模糊到影响架构阶段时，必须退回
2. **可测试优先**：不接受“优化体验”“支持导入”这类空泛描述
3. **边界先行**：空输入、失败路径、权限不足、并发条件都要显式出现
4. **依赖清晰**：Task 间依赖、外部系统、潜在冲突必须写出来

## 检查清单

### 完整性
- [ ] 每个 Task 都有明确目标和交付内容
- [ ] 业务目标清楚，不只是罗列改动
- [ ] 风险和待确认事项被显式列出

### 可测性
- [ ] 每个 Task 都有至少一条可测试验收标准
- [ ] 标准描述行为/结果，不描述实现方案
- [ ] 性能、安全、合规等隐性要求在需要时被显式化

### 边界
- [ ] 成功路径清晰
- [ ] 失败路径清晰
- [ ] 特殊输入被考虑（空、超长、异常值）
- [ ] 权限/角色边界被考虑（如适用）

### 依赖与冲突
- [ ] Task 间依赖被正确标注
- [ ] 与现有功能冲突已识别
- [ ] 外部依赖或前置条件已识别

## Critical 示例

- ✗ “提升搜索体验” —— 不可测
- ✗ “支持导入” —— 未说明格式、上限、失败处理
- ✗ “接入订单模块” —— 未说明交互和成功标准

## 输出

写入 `.claude/artifacts/review-requirements-{task-id}.md`，并按 `Critical / Warning / Suggestion / 未覆盖项` 结构组织。

## 参考样品

- `examples/sample-review-requirements.md` — 客户群发推送需求审查样品（4 维度矩阵：完整性 / 可测性 / 边界 / 风险，带 5 处具体 Issue + 修复建议）
