# Webapp Testing Pitfalls

测试本地 Web 应用时最常见的 10 个陷阱与对策。

## 1. 测试服务未启动就报"通过"

**陷阱**：脚本跑了 0 个用例，因为目标服务没启动。日志显示 "0 passed, 0 failed"，被误读为 PASS。

**对策**：
```bash
curl -sf http://localhost:3000/health || { echo "Service not up"; exit 1; }
npm test
```

服务启动失败 → 报 BLOCKED 而不是 PASS。

## 2. 端口冲突（隐性）

**陷阱**：3000 端口已被占用，新启动的服务静默挂在另一个端口。测试访问 3000 拿到老服务返回。

**对策**：
```bash
lsof -i :3000 && { echo "Port already in use"; exit 1; }
PORT=3456 npm run dev
```

## 3. 缓存（浏览器 / Service Worker）

**陷阱**：客户报"我改了代码但没生效"，Service Worker 缓存了旧 JS。

**对策**：
- 测试用 incognito / private mode
- DevTools 关 cache（Network 面板 → Disable cache）
- 手动清 SW：`navigator.serviceWorker.getRegistrations().then(rs => rs.forEach(r => r.unregister()))`

## 4. 异步竞态

**陷阱**：测试断言在 fetch 完成前执行。结果时好时坏。

**对策**：
```js
// ❌ 错误
await user.click(button)
expect(screen.getByText('Done')).toBeInTheDocument()

// ✅ 正确：等元素出现
await user.click(button)
await waitFor(() => expect(screen.getByText('Done')).toBeInTheDocument())
```

## 5. 时区与日期

**陷阱**：测试在 UTC 跑，本地 dev 是 UTC+8，截图显示 8 小时偏差。

**对策**：
```bash
export TZ=Asia/Shanghai
# 或测试 mock 时间
jest.useFakeTimers().setSystemTime(new Date('2026-01-01'))
```

## 6. 网络依赖

**陷阱**：测试调用外部 API。CI 没网或限流，测试随机失败。

**对策**：
- 测试环境用 mock server（msw / wiremock）
- 真实网络测试单独标记 `@e2e`
- 限流场景用录制/回放（vcr / nock）

## 7. 数据库状态污染

**陷阱**：上一个测试留下的脏数据让下一个断言错误。

**对策**：
```js
beforeEach(async () => {
  await db.truncate(['users', 'orders'])
})
```

不要用"mock 整个 DB"替代——很多 bug 出在 SQL 行为，详见 feedback memory `integration tests must hit real DB`。

## 8. 客户截图不清晰

**陷阱**：客户报"按钮坏了"，截图是 1280×800 缩略图，看不清是哪个按钮。

**对策**：立即 AskUserQuestion 让用户：
- 圈出截图中的元素
- 提供完整步骤复现
- 截图原图（不是聊天工具压缩版）
- 给 console 报错截图

不要凭"看起来像"猜元素位置。详见 `visual-test-protocol` § 截图反查精确定位。

## 9. Console 报错被忽略

**陷阱**：UI 看起来正常，但 console 一堆 warnings / errors。客户用一段时间后报怪 bug。

**对策**：
```js
beforeEach(() => {
  vi.spyOn(console, 'error').mockImplementation(() => {})
  vi.spyOn(console, 'warn').mockImplementation(() => {})
})

afterEach(() => {
  expect(console.error).not.toHaveBeenCalled()
  expect(console.warn).not.toHaveBeenCalled()
})
```

## 10. A11y 冒烟没做

**陷阱**：交付后客户用屏幕阅读器测试，发现完全不可用。

**对策**：
```bash
npm install -D @axe-core/cli
npx axe http://localhost:3000 --tags wcag2aa
```

最低标准：键盘可达、对比度、alt text。详见 `evidence-template.md`。

## 失败处理硬规则

任何**测试基础设施**问题（端口冲突、服务未起、网络断）→ 报 `BLOCKED`，不是 FAILED 也不是 PASS。

参考 `agent-guardrails-protocol/references/failure-taxonomy.md`。
