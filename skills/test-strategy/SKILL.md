---
name: test-strategy
description: 测试策略与方法论。为 高级功能测试师、高级视觉测试师 和 实现工程师 提供测试分层、覆盖标准和边界构造方法。
when_to_use: 当 实现工程师 / tester 设计测试分层、决定单元/集成/e2e 比例、构造边界用例、补回归测试时；用户提"测试策略"、"测试金字塔"、"覆盖率"、"单元 vs 集成"、"补测试" 时自动加载。
---

<skill name="test-strategy">

<knowledge domain="test-pyramid">
<principle>合理的测试组合（从下到上、数量递减）</principle>

<convention name="unit" ratio="70%">
  <item>快、独立、确定</item>
  <item>覆盖纯函数、工具、hook、util</item>
  <item>每个测试 < 100ms</item>
</convention>

<convention name="integration" ratio="20%">
  <item>验证多个组件的协作</item>
  <item>用真实依赖（真实 DB、真实 HTTP mock）</item>
  <item>每个测试 < 5s</item>
</convention>

<convention name="e2e" ratio="10%">
  <item>验证关键用户路径</item>
  <item>Playwright / Cypress / Appium</item>
  <item>只覆盖核心流程，不追求全覆盖</item>
</convention>
</knowledge>

<knowledge domain="unit-testing">

<knowledge domain="what-to-test">
<convention name="worth-it">
  <item>有分支的纯函数</item>
  <item>复杂的数据转换</item>
  <item>工具函数（格式化、校验、计算）</item>
  <item>Hook / Composable 的行为</item>
  <item>状态机 / reducer</item>
</convention>
<convention name="not-worth-it">
  <item>简单的 getter / setter</item>
  <item>调用第三方库的薄包装</item>
  <item>UI 渲染像素对比（交给 E2E 或视觉回归）</item>
</convention>
</knowledge>

<convention name="naming">
<principle>清晰的测试名 = 活的文档</principle>
<example>
describe('validateEmail')
  it('returns true for valid emails')
  it('returns false for emails without @')
  it('returns false for empty input')
  it('returns false for emails exceeding 254 chars')
</example>
<rule>不要写 `it('works')` 或 `it('test 1')`。</rule>
</convention>

<convention name="aaa-pattern">
<principle>三段结构（AAA）</principle>
<example>
it('should refund when order is cancelled', () => {
  // Arrange
  const order = createOrder({ status: 'paid', amount: 100 });

  // Act
  const result = cancelOrder(order);

  // Assert
  expect(result.status).toBe('refunded');
  expect(result.refundAmount).toBe(100);
});
</example>
</convention>

<convention name="mock-boundaries">
  <item>Mock 外部依赖（网络、DB、文件系统），不 mock 被测对象本身</item>
  <item>Mock 越少测试越可信</item>
  <item>偏好"真实依赖的测试替身"（如内存 DB、模拟 HTTP server）而非纯 mock</item>
</convention>

</knowledge>

<knowledge domain="integration-testing">

<knowledge domain="backend-integration">
<checklist>
  <item>用真实数据库（测试专用实例，每次测试清理）</item>
  <item>用真实 HTTP 框架（不 mock Express / FastAPI）</item>
  <item>外部服务 mock（第三方 API）</item>
  <item>测试一个完整业务流程：请求 → 验证 → DB → 响应</item>
</checklist>
</knowledge>

<knowledge domain="frontend-integration">
<checklist>
  <item>用 Testing Library 渲染组件</item>
  <item>Mock 网络层（MSW / nock）</item>
  <item>测试用户交互：点击、输入、键盘</item>
  <item>测试 selector 优先级：`role` > `label` > `text` > `data-testid` > `className`</item>
</checklist>
</knowledge>

</knowledge>

<knowledge domain="e2e-testing">

<convention name="coverage-principle">
只测核心路径：
<checklist>
  <item>登录 / 注册</item>
  <item>主要业务流程（购买、发帖、搜索）</item>
  <item>关键权限场景</item>
</checklist>
不追求全覆盖——E2E 测试慢且易碎，不是单元测试的替代。
</convention>

<convention name="stability">
<checklist>
  <item>显式等待（`waitFor`）而非 `sleep`</item>
  <item>用稳定的 selector（role、test-id）</item>
  <item>隔离测试数据（每次测试独立数据）</item>
  <item>失败时自动截图便于调试</item>
</checklist>
</convention>

<convention name="visual-regression">
<checklist>
  <item>对 UI 关键页面做截图对比（Playwright / Percy）</item>
  <item>允许小容差（字体抗锯齿等）</item>
  <item>CI 失败时提供 diff 图</item>
</checklist>
</convention>

</knowledge>

<knowledge domain="boundary-testing">
<principle>对任何输入，构造以下边界</principle>

<knowledge domain="numeric">
  <item>0</item>
  <item>最大值（Int.MAX / Long.MAX）</item>
  <item>最小值（负数、Int.MIN）</item>
  <item>浮点精度（0.1 + 0.2）</item>
</knowledge>

<knowledge domain="string">
  <item>空字符串</item>
  <item>单字符</item>
  <item>极长字符串（> 常规限制）</item>
  <item>Unicode（中文、emoji、零宽字符）</item>
  <item>特殊字符（引号、反斜杠、换行、null 字节）</item>
  <item>前后空格</item>
</knowledge>

<knowledge domain="collection">
  <item>空数组/空对象</item>
  <item>单元素</item>
  <item>大数据量</item>
  <item>重复元素</item>
  <item>null 混入</item>
</knowledge>

<knowledge domain="time">
  <item>过去、现在、未来</item>
  <item>时区边界（UTC 0 点前后、夏令时切换）</item>
  <item>闰年 2 月 29 日</item>
  <item>月末（1/31, 3/31）</item>
</knowledge>

<knowledge domain="concurrency">
  <item>同一资源的并发读</item>
  <item>同一资源的并发写</item>
  <item>读写混合</item>
  <item>幂等性测试（重复提交）</item>
</knowledge>

<knowledge domain="failure-paths">
  <item>网络超时</item>
  <item>DB 连接失败</item>
  <item>第三方服务返回 500</item>
  <item>权限不足</item>
  <item>资源不存在</item>
  <item>资源已被删除（TOCTOU）</item>
</knowledge>

</knowledge>

<knowledge domain="coverage">
<convention name="line">行覆盖率：基础指标，>80% 是合理目标</convention>
<convention name="branch">分支覆盖率：更严格，每个 if / switch 分支都要测</convention>
<convention name="path">路径覆盖率：对关键函数用</convention>
<convention name="mutation">突变测试（Mutation testing）：最严格，验证测试是否真的能捕捉代码变化</convention>
<principle>但：**覆盖率不等于质量**。100% 覆盖率的测试可能全是断言"不报错"的无效测试。</principle>
</knowledge>

<knowledge domain="test-smells">
<trap name="no-assertion">测试只验证"不抛异常"，没有具体断言</trap>
<trap name="vague-assertion">断言过于笼统（`expect(result).toBeDefined()`）</trap>
<trap name="shared-mutable-state">测试之间共享可变状态</trap>
<trap name="external-dependency">测试依赖外部系统（真 API、真时间、真随机）</trap>
<trap name="order-sensitive">测试顺序敏感（改变顺序就失败）</trap>
<trap name="flaky">Flaky test（偶尔失败）— 必须修复，不能忽略</trap>
<trap name="implementation-detail">测试覆盖了实现细节（改内部结构就失败，即使行为未变）</trap>
</knowledge>

<knowledge domain="ui-visual-verification">
<principle>UI 视觉验证（借助 Playwright MCP）</principle>
<checklist>
  <item>启动 Playwright，导航到被测页面</item>
  <item>截屏保存为 artifact</item>
  <item>与设计稿或原始截图对比</item>
  <item>列出视觉差异</item>
</checklist>
<convention>如果没有 Playwright MCP，要求 实现工程师 提供截图并人工对比。</convention>
</knowledge>

<convention name="report-output">
<principle>产出到审查报告的格式</principle>
<example>
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
</example>
</convention>

</skill>
