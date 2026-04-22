---
name: test-strategy
description: 测试策略与方法论。为 quality-guardian 和 implementer 提供测试分层、覆盖标准和边界构造方法。
---

# 测试策略

---

## 测试金字塔

合理的测试组合（从下到上、数量递减）：

1. **单元测试** — 70%
   - 快、独立、确定
   - 覆盖纯函数、工具、hook、util
   - 每个测试 < 100ms

2. **集成测试** — 20%
   - 验证多个组件的协作
   - 用真实依赖（真实 DB、真实 HTTP mock）
   - 每个测试 < 5s

3. **端到端测试** — 10%
   - 验证关键用户路径
   - Playwright / Cypress / Appium
   - 只覆盖核心流程，不追求全覆盖

---

## 单元测试

### 什么值得测

✓ 有分支的纯函数
✓ 复杂的数据转换
✓ 工具函数（格式化、校验、计算）
✓ Hook / Composable 的行为
✓ 状态机 / reducer

✗ 简单的 getter / setter
✗ 调用第三方库的薄包装
✗ UI 渲染像素对比（交给 E2E 或视觉回归）

### 命名

清晰的测试名 = 活的文档：

```
describe('validateEmail')
  it('returns true for valid emails')
  it('returns false for emails without @')
  it('returns false for empty input')
  it('returns false for emails exceeding 254 chars')
```

不要写 `it('works')` 或 `it('test 1')`。

### 三段结构（AAA）

```js
it('should refund when order is cancelled', () => {
  // Arrange
  const order = createOrder({ status: 'paid', amount: 100 });

  // Act
  const result = cancelOrder(order);

  // Assert
  expect(result.status).toBe('refunded');
  expect(result.refundAmount).toBe(100);
});
```

### Mock 的边界

- Mock 外部依赖（网络、DB、文件系统），不 mock 被测对象本身
- Mock 越少测试越可信
- 偏好"真实依赖的测试替身"（如内存 DB、模拟 HTTP server）而非纯 mock

---

## 集成测试

### 后端集成测试

- 用真实数据库（测试专用实例，每次测试清理）
- 用真实 HTTP 框架（不 mock Express / FastAPI）
- 外部服务 mock（第三方 API）
- 测试一个完整业务流程：请求 → 验证 → DB → 响应

### 前端集成测试

- 用 Testing Library 渲染组件
- Mock 网络层（MSW / nock）
- 测试用户交互：点击、输入、键盘
- 测试 selector 优先级：`role` > `label` > `text` > `data-testid` > `className`

---

## E2E 测试

### 覆盖原则

只测核心路径：
- 登录 / 注册
- 主要业务流程（购买、发帖、搜索）
- 关键权限场景

不追求全覆盖——E2E 测试慢且易碎，不是单元测试的替代。

### 稳定性

- 显式等待（`waitFor`）而非 `sleep`
- 用稳定的 selector（role、test-id）
- 隔离测试数据（每次测试独立数据）
- 失败时自动截图便于调试

### 视觉回归

- 对 UI 关键页面做截图对比（Playwright / Percy）
- 允许小容差（字体抗锯齿等）
- CI 失败时提供 diff 图

---

## 边界测试构造

对任何输入，构造以下边界：

### 数值
- 0
- 最大值（Int.MAX / Long.MAX）
- 最小值（负数、Int.MIN）
- 浮点精度（0.1 + 0.2）

### 字符串
- 空字符串
- 单字符
- 极长字符串（> 常规限制）
- Unicode（中文、emoji、零宽字符）
- 特殊字符（引号、反斜杠、换行、null 字节）
- 前后空格

### 集合
- 空数组/空对象
- 单元素
- 大数据量
- 重复元素
- null 混入

### 时间
- 过去、现在、未来
- 时区边界（UTC 0 点前后、夏令时切换）
- 闰年 2 月 29 日
- 月末（1/31, 3/31）

### 并发
- 同一资源的并发读
- 同一资源的并发写
- 读写混合
- 幂等性测试（重复提交）

### 失败路径
- 网络超时
- DB 连接失败
- 第三方服务返回 500
- 权限不足
- 资源不存在
- 资源已被删除（TOCTOU）

---

## 覆盖率

- **行覆盖率**：基础指标，>80% 是合理目标
- **分支覆盖率**：更严格，每个 if / switch 分支都要测
- **路径覆盖率**：对关键函数用
- **突变测试**（Mutation testing）：最严格，验证测试是否真的能捕捉代码变化

但：**覆盖率不等于质量**。100% 覆盖率的测试可能全是断言"不报错"的无效测试。

---

## 测试的味道（反模式）

✗ 测试只验证"不抛异常"，没有具体断言
✗ 断言过于笼统（`expect(result).toBeDefined()`）
✗ 测试之间共享可变状态
✗ 测试依赖外部系统（真 API、真时间、真随机）
✗ 测试顺序敏感（改变顺序就失败）
✗ Flaky test（偶尔失败）— 必须修复，不能忽略
✗ 测试覆盖了实现细节（改内部结构就失败，即使行为未变）

---

## UI 视觉验证（借助 Playwright MCP）

对 UI 变更，如调度器配置了 Playwright MCP：

1. 启动 Playwright，导航到被测页面
2. 截屏保存为 artifact
3. 与设计稿或原始截图对比
4. 列出视觉差异

如果没有 Playwright MCP，要求 implementer 提供截图并人工对比。

---

## 产出到审查报告

```markdown
## 测试结果
- 单元测试：15 passed / 2 failed
- 集成测试：8 passed
- 覆盖率：行 87%，分支 72%

### 失败详情
1. should handle empty input
   - 期望：throws ValidationError
   - 实际：returned null

### 未测试的重要场景
1. 并发写入同一资源（scope-lock 提到了但代码未防护）
2. Token 过期时的自动刷新
```
