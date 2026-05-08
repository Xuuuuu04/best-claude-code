---
paths:
  - "**/*.{ts,tsx,js,jsx,py,go,rs,java,kt,swift,dart,cpp,c,h}"
---

<rule id="error-handling" severity="blocker">
  <rationale>适用于所有代码，不分语言。</rationale>

  <section id="core-principles">
    <subsection id="principle-1-fail-fast">
      <requirement severity="blocker">
        失败快于继续 —— 输入验证失败、不变量被破坏、资源不可用——立即抛错或返回错误，**不要**"尽量继续"：
        <example type="bad">
          <code-block language="ts"><![CDATA[
// 错误
function processOrder(order) {
  if (!order.items) order.items = [];  // 掩盖问题
  // ...
}
          ]]></code-block>
        </example>
        <example type="good">
          <code-block language="ts"><![CDATA[
// 正确
function processOrder(order) {
  if (!order.items || order.items.length === 0) {
    throw new ValidationError('Order must have at least one item');
  }
  // ...
}
          ]]></code-block>
        </example>
      </requirement>
    </subsection>

    <subsection id="principle-2-error-context">
      <requirement severity="blocker">
        错误信息有上下文 —— 错误消息必须让接收者能够**诊断**：
        <example type="bad">
          <code-block language="ts"><![CDATA[
// 错误
throw new Error('Not found');
          ]]></code-block>
        </example>
        <example type="good">
          <code-block language="ts"><![CDATA[
// 正确
throw new NotFoundError(`User not found: id=${userId}, tenant=${tenantId}`);
          ]]></code-block>
        </example>
      </requirement>
    </subsection>

    <subsection id="principle-3-exception-layers">
      <requirement>
        异常分层：
        <list>
          <item><definition>领域异常</definition>：业务规则违反（<type>InvalidOrderStateError</type>）</item>
          <item><definition>基础设施异常</definition>：外部依赖失败（<type>DatabaseConnectionError</type>）</item>
          <item><definition>验证异常</definition>：输入不合法（<type>ValidationError</type>）</item>
          <item><definition>未知异常</definition>：不在分类内的错误</item>
        </list>
        每层异常处理方式不同：领域异常返回用户友好消息；基础设施异常重试或降级；未知异常记录完整堆栈。
      </requirement>
    </subsection>

    <subsection id="principle-4-no-swallow">
      <constraint severity="blocker">
        不吞异常：
        <example type="bad">
          <code-block language="ts"><![CDATA[
// 错误
try {
  doSomething();
} catch (e) {
  // 空
}

// 也错误
try {
  doSomething();
} catch (e) {
  logger.error(e);
  // 然后继续？调用方以为成功了
}
          ]]></code-block>
        </example>
        <example type="good">
          <code-block language="ts"><![CDATA[
// 正确
try {
  doSomething();
} catch (e) {
  logger.error({ error: e, context: { ... } }, 'doSomething failed');
  throw new WrappedError('Processing failed', { cause: e });
}
          ]]></code-block>
        </example>
      </constraint>
    </subsection>

    <subsection id="principle-5-resource-cleanup">
      <constraint severity="blocker">
        资源清理 —— 即使在异常路径，资源也必须被释放：
        <example type="good">
          <code-block language="ts"><![CDATA[
// 模式 1: try-finally
const conn = await pool.getConnection();
try {
  return await doWork(conn);
} finally {
  conn.release();
}

// 模式 2: using / context manager
using resource = await acquireResource();
return await doWork(resource);

// Python
with open(path) as f:
    return process(f)
          ]]></code-block>
        </example>
      </constraint>
    </subsection>
  </section>

  <section id="error-message-content">
    <subsection id="error-should-include">
      <requirement>
        应该包含：
        <list>
          <item><definition>发生位置</definition>：函数、文件、操作类型</item>
          <item><definition>输入上下文</definition>：触发错误的输入（注意脱敏）</item>
          <item><definition>期望行为</definition>：应该是什么</item>
          <item><definition>实际行为</definition>：实际发生了什么</item>
          <item><definition>原因链</definition>：如果是包装错误，保留原始 cause</item>
        </list>
      </requirement>
    </subsection>
    <subsection id="error-should-not-include">
      <constraint severity="blocker">
        **不应**包含：
        <list>
          <item>密码、token、密钥</item>
          <item>个人身份信息（PII）未脱敏</item>
          <item>内部文件路径（对生产客户端返回的错误）</item>
          <item>完整堆栈（对生产客户端返回的错误）</item>
          <item>数据库结构细节</item>
          <item>内部系统 URL</item>
        </list>
      </constraint>
    </subsection>
  </section>

  <section id="error-propagation">
    <subsection id="propagation-wrap-with-cause">
      <requirement>
        包装错误保留原因：
        <code-block language="ts"><![CDATA[
try {
  await db.query(...);
} catch (dbError) {
  throw new OrderProcessingError('Failed to save order', { cause: dbError });
}
        ]]></code-block>
        读取 cause 链便于定位根因。
      </requirement>
    </subsection>

    <subsection id="propagation-abstraction-level">
      <requirement>
        向上层传递适当的抽象 —— 不要让下层细节泄露到上层：
        <example type="bad">
          <code-block language="ts"><![CDATA[
// 错误：SQL 错误直接返回给 API 客户端
catch (e) {
  res.status(500).json({ error: e.message });  // "syntax error near ..."
}
          ]]></code-block>
        </example>
        <example type="good">
          <code-block language="ts"><![CDATA[
// 正确：转换为适当抽象
catch (e) {
  logger.error({ error: e }, 'Database query failed');
  res.status(500).json({
    error: { code: 'INTERNAL_ERROR', message: 'Request could not be processed' }
  });
}
          ]]></code-block>
        </example>
      </requirement>
    </subsection>
  </section>

  <section id="retry-strategy">
    <subsection id="retry-retryable-vs-not">
      <requirement>
        <list>
          <item><definition>可重试</definition>：网络超时、临时不可用、限流</item>
          <item><definition>不可重试</definition>：参数错误、权限不足、资源不存在</item>
        </list>
      </requirement>
    </subsection>

    <subsection id="retry-params">
      <requirement>
        <list>
          <item>最大重试次数（通常 3-5 次）</item>
          <item>退避策略：指数退避 + jitter</item>
          <item>超时（每次 + 总体）</item>
          <item>只对幂等操作重试</item>
        </list>
        <example type="good">
          <code-block language="ts"><![CDATA[
async function withRetry(fn, { maxAttempts = 3, initialDelay = 1000 }) {
  let lastError;
  for (let i = 0; i < maxAttempts; i++) {
    try {
      return await fn();
    } catch (e) {
      lastError = e;
      if (!isRetryable(e) || i === maxAttempts - 1) throw e;
      const delay = initialDelay * Math.pow(2, i) + Math.random() * 1000;
      await sleep(delay);
    }
  }
}
          ]]></code-block>
        </example>
      </requirement>
    </subsection>
  </section>

  <section id="circuit-breaker-degradation">
    <subsection id="circuit-breaker">
      <requirement>
        当依赖服务持续失败时，停止调用一段时间，防止级联失败。
        状态：
        <list>
          <item><state>Closed</state>：正常调用</item>
          <item><state>Open</state>：失败率超阈值，快速拒绝</item>
          <item><state>Half-open</state>：尝试恢复</item>
        </list>
      </requirement>
    </subsection>

    <subsection id="degradation">
      <requirement>
        依赖失败时提供替代行为：
        <list>
          <item>缓存的旧数据</item>
          <item>默认值</item>
          <item>简化的功能（如关闭推荐，但保留主流程）</item>
          <item>明确的错误消息</item>
        </list>
      </requirement>
    </subsection>
  </section>

  <section id="logging">
    <requirement>
      <list>
        <item>错误在**捕获的最高抽象层**记录一次，避免重复记录</item>
        <item>包含结构化上下文（JSON 字段）</item>
        <item>级别：可恢复是 <level>WARN</level>，不可恢复是 <level>ERROR</level></item>
        <item>带关联 ID（<field>trace_id</field>、<field>request_id</field>）便于追踪</item>
      </list>
    </requirement>
  </section>

  <section id="user-visible-errors">
    <subsection id="user-visible-frontend">
      <requirement>
        <list>
          <item>不显示技术细节（堆栈、内部错误码）</item>
          <item>提供可操作的建议（重试、联系客服、检查输入）</item>
          <item>保留国际化能力</item>
        </list>
      </requirement>
    </subsection>

    <subsection id="user-visible-api">
      <requirement>
        使用统一错误格式：
        <code-block language="json"><![CDATA[
{
  "error": {
    "code": "VALIDATION_FAILED",
    "message": "Email format is invalid",
    "details": {
      "field": "email",
      "value": "not-an-email"
    }
  }
}
        ]]></code-block>
        错误码稳定（客户端依赖），消息人类可读。
      </requirement>
    </subsection>
  </section>

  <section id="testing-error-paths">
    <requirement>
      测试不应只覆盖 happy path：
      <list>
        <item>输入非法时的响应</item>
        <item>依赖失败时的行为</item>
        <item>超时时的行为</item>
        <item>并发冲突时的行为</item>
      </list>
      每个 <code>try/catch</code> 都应有对应的测试。
    </requirement>
  </section>
</rule>
