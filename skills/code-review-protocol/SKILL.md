---
name: code-review-protocol
description: 代码审查协议。为 高级代码审查师 提供 scope 合规、契约一致性和可维护性检查清单。
when_to_use: 仅当 高级代码审查师 Agent 在审查 实现工程师 产出的 impl-report 与 diff 时加载。实现工程师 自审、安全专项审查、架构审查不应触发。
---

<skill name="code-review-protocol">

<overview>
验证实现是否严格符合 scope-lock，并具备可维护性与可回归验证能力。
</overview>

<principles>
  <principle priority="1">scope 合规优先于风格偏好</principle>
  <principle priority="2">证据比感觉重要</principle>
  <principle priority="3">测试是否有效比覆盖率数字更重要</principle>
  <principle priority="4">不做架构重审，除非实现明显违背架构</principle>
</principles>

<checklist>
  <section name="scope-合规">
    <item priority="critical">修改范围与白名单完全一致</item>
    <item priority="critical">未触碰禁止事项</item>
    <item priority="critical">未引入未授权依赖</item>
    <item priority="critical">接口契约与 scope-lock / architecture 一致</item>
  </section>

  <section name="代码质量">
    <item priority="high">错误处理完备，无空 catch</item>
    <item priority="high">命名清晰，结构可维护</item>
    <item priority="medium">无明显性能反模式</item>
  </section>

  <section name="枚举/状态机字段方向核对（必查）">
    <item priority="critical">涉及枚举判断（<field>payType</field> / <field>orderStatus</field> / <field>payStatus</field> / <field>ticketStatus</field> / <field>paySource</field> / <field>authenticate</field> 等）的代码，<emphasis>禁止凭印象核对方向</emphasis></item>
    <item priority="critical">grep 项目内已上线 work 的同字段使用点：<cmd>grep -rn "{fieldName}" --include="*.vue" --include="*.ts" --include="*.js"</cmd></item>
    <item priority="critical">找到常量定义或参考实现（如 <code>const PAY_TYPE = {...}</code> / <file>shared/constants/enums.js</file>），以<emphasis>参考代码 + apifox/OpenAPI 真值</emphasis>为准</item>
    <item priority="critical">当心"同名不同义"陷阱：同一字段在不同 endpoint/上下文取值可能完全不同（如 <type>OrderPayDTO.payType</type> 是 int <value>1=微信</value>，<type>OrderDetailVO.payType</type> 是 string <value>"2"=微信</value>）</item>
    <item priority="critical">任何凭直觉写的 <code>=== 1</code>、<code>=== '2'</code> 都视为<emphasis>可疑</emphasis>，必须有参考代码或 OAS 真值证据</item>
    <item priority="critical">报告中明确标注：每条枚举判断的依据来自哪份 artifact / 哪个文件:行号</item>
  </section>

  <section name="测试">
    <item priority="high">覆盖 scope-lock 指定场景</item>
    <item priority="high">边界情况有测试</item>
    <item priority="high">Bug 修复测试能复现原问题</item>
    <item priority="medium">Refactor 重构测试保持行为等价</item>
  </section>
</checklist>

<examples>
  <example type="critical" reason="修改了白名单外文件"/>
  <example type="critical" reason="引入了未授权第三方依赖"/>
  <example type="critical" reason="接口签名与 scope-lock 不一致"/>
  <example type="critical" reason="测试没有真正覆盖修复场景"/>
</examples>

<output path=".claude/artifacts/review-code-{task-id}-{n}.md"/>

<references>
  <reference path="examples/sample-review-code.md" purpose="写 review 前若不确定 artifact 长什么样，读此样品。OAuth 登录审查的完整样品（Critical/Warning/Suggestion 三档示范，scope 合规 / 代码质量 / 测试 / 接口契约 四维度）"/>
</references>

<memory-protocol>
审查完成后，写报告前做一次自检：<emphasis>本次审查有没有暴露跨任务可复用的事实？</emphasis>

<memory-triggers>
  <trigger>某类代码气味在本项目频繁出现（如"多处用 <code>any</code> 作为 escape hatch"）</trigger>
  <trigger>团队约定被反复违反的地方（需要固化进规范 or memory）</trigger>
  <trigger>某个审查维度在本项目特别重要（如某库的并发陷阱）</trigger>
  <trigger>某种测试反模式（如"mock 数据库掩盖了真问题"）</trigger>
</memory-triggers>

<write-path><file>$CLAUDE_PROJECT_DIR/.claude/agent-memory/高级代码审查师/{short-title}.md</file>（先 <cmd>mkdir -p</cmd>）</write-path>

<format-rule>3 句话能说清；超长拆多条；不确定不写；负向不记、具体到单文件不记、重复已有不记。单个 memory ≤ 30 行。无触发就不写。审查 memory 是冷数据，宁缺毋滥。</format-rule>
</memory-protocol>

</skill>
