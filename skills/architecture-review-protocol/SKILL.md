---
name: architecture-review-protocol
description: 架构审查协议。为 architecture-reviewer 提供 design 与 scope-lock 的可执行性审查清单。
---

# 架构审查协议

## 目标

确保 architecture 与 scope-lock 能稳定指导实现，而不是把歧义继续传给 implementer。

## 通用原则

1. **设计不能把歧义下放**：下游 implementer 不应继续补需求
2. **scope-lock 是实现契约，不是提醒清单**
3. **架构与范围必须一致**：不能 architecture 说 A，scope-lock 写成 B
4. **可执行优于优雅**：设计可以普通，但必须稳定可实现

## 检查清单

### 技术选型
- [ ] 新旧技术栈选择有理由
- [ ] 没有明显过度工程
- [ ] 没有明显欠工程

### 契约
- [ ] 类型、签名、字段、错误路径完整
- [ ] 与 requirements 一致
- [ ] 与现有风格不冲突

### scope-lock 质量
- [ ] 精确到文件和关键函数
- [ ] 白名单与禁止事项都完整
- [ ] 验证命令可运行
- [ ] 完成标准可逐条勾选
- [ ] 推荐 implementer 合理

### 执行关系
- [ ] 并行依赖图清晰
- [ ] 没把多个无关任务强塞进一个 scope-lock

## Critical 示例

- ✗ “修改 auth 模块” —— 不够精确
- ✗ scope-lock 未列禁止事项 —— 越界风险过高
- ✗ architecture 与 requirements 冲突 —— 下游无从判断

## 输出

写入 `.claude/artifacts/review-architecture-{task-id}.md`。

## 参考样品

- `examples/sample-review-architecture.md` — 实时通知系统架构审查样品（6 维度矩阵 + scope-lock 文件冲突 Critical 处理 + 过度/欠工程平衡建议）
