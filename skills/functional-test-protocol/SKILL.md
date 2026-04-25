---
name: functional-test-protocol
description: 功能测试协议。为 functional-tester 提供验收标准验证、边界构造和回归检查步骤。
---

# 功能测试协议

## 目标

验证实现满足 requirements 中的验收标准，并且没有引入明显回归。

## 通用原则

1. **以验收标准为准，而不是以实现者报告为准**
2. **边界场景必须主动构造**
3. **回归验证不可省略**

## 执行步骤

1. 运行项目测试套件与必要的集成命令
2. 逐条对照 requirements 的验收标准
3. 构造空输入、极限输入、失败路径、权限不足等边界场景
4. 对 bug 修复验证回归场景，对重构验证行为等价性

## Critical 示例

- ✗ 测试套件失败
- ✗ 关键验收标准未被验证
- ✗ 回归场景未覆盖

## 输出

写入 `.claude/artifacts/review-functional-{task-id}.md`。

## 参考样品

- `examples/sample-review-functional.md` — 并发 bug 修复的功能验证样品（验收标准矩阵 / 边界场景表 / 回归历史复现 / 验收建议）
