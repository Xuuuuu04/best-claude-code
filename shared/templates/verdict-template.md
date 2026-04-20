---
name: verdict-template
description: 测试总监师裁决报告模板（三证据原则）
template: true
---

<harness-template>

<report type="verdict">
  <header>
    <task-id>TASK-{编号}</task-id>
    <time>{YYYY-MM-DD HH:MM}</time>
  </header>

  <three-evidence>
    <evidence name="功能测试报告" source="功能测试师" status="{已收到/缺失}">
      <path>test-reports/test-taskXXX-vN.md</path>
    </evidence>
    <evidence name="UI 证据" source="界面测试师" status="{已收到/缺失/N/A无前端}">
      <path>tests/screenshots/v{N}/</path>
    </evidence>
    <evidence name="安全审计结论" source="安全审计师" status="{已收到/缺失/N/A非里程碑}">
      <path>security-audits/audit-*.md</path>
    </evidence>
  </three-evidence>

  <evidence-review>
    <review-dimension name="功能正确性">{全绿 / 存在失败：列出}</review-dimension>
    <review-dimension name="UI 完整性">{截图完整+交互正常 / 发现问题：列出 / N/A}</review-dimension>
    <review-dimension name="安全无高危">{无高危 / 高危 N 个：列出}</review-dimension>
  </evidence-review>

  <verdict>
    <functional>{✓ / ✗}</functional>
    <ui>{✓ / ✗ / N/A}</ui>
    <security>{✓ / ✗}</security>
    <conclusion>{通过 / 有条件通过 / 打回}</conclusion>
    <rationale>{裁决的充分理由}</rationale>
  </verdict>

  <conditional-pass-terms>
    <!-- 仅"有条件通过"时填写 -->
    <condition deadline="{时间}">{需补齐的内容}</condition>
  </conditional-pass-terms>

  <rejection-items>
    <!-- 仅"打回"时填写 -->
    <rejection-item agent="{责任Agent名}">
      <problem>{具体问题}</problem>
      <fix-requirement>{可执行的修复步骤}</fix-requirement>
      <expected-time>{期望完成时间}</expected-time>
    </rejection-item>
  </rejection-items>
</report>

<!-- ===== 范例：有条件通过 ===== -->

<!--
<report type="verdict">
  <header>
    <task-id>TASK-003</task-id>
    <time>2026-04-17 18:00</time>
  </header>

  <three-evidence>
    <evidence name="功能测试报告" source="功能测试师" status="已收到">
      <path>test-reports/test-task003-v1.md</path>
    </evidence>
    <evidence name="UI 证据" source="界面测试师" status="已收到">
      <path>tests/screenshots/v1/</path>
    </evidence>
    <evidence name="安全审计结论" source="安全审计师" status="N/A非里程碑">
      <path>N/A</path>
    </evidence>
  </three-evidence>

  <evidence-review>
    <review-dimension name="功能正确性">8 用例中 7 通过 1 失败。失败项为验证码过期后提交返回 500 而非友好提示，属边界值处理缺陷，不影响核心注册流程。</review-dimension>
    <review-dimension name="UI 完整性">截图覆盖桌面+移动共 12 张。发现 2 个问题：验证码按钮 loading 态文字截断（高）、注册按钮无 loading 反馈（中）。注册主流程 UI 正确。</review-dimension>
    <review-dimension name="安全无高危">N/A — 非里程碑上线，安全审计未触发。代码审计师已在 code-review 中检查过 SQL 参数化和输入校验，无高危。</review-dimension>
  </evidence-review>

  <verdict>
    <functional>✗ 存在1个边界值失败（验证码过期500错误）</functional>
    <ui>✗ 存在2个问题（loading文字截断+注册无反馈）</ui>
    <security>N/A</security>
    <conclusion>有条件通过</conclusion>
    <rationale>核心注册流程功能正确，UI 主流程展示正常。3个问题均为边界态/交互反馈层面，不影响用户完成注册主流程。验证码过期500需修复但属防御性编程范畴，不阻塞交付。UI 问题可在后续迭代补齐。</rationale>
  </verdict>

  <conditional-pass-terms>
    <condition deadline="2026-04-18 18:00">修复验证码过期后空指针异常，返回友好提示（后端开发师）</condition>
    <condition deadline="2026-04-19 18:00">验证码按钮 loading 态文字截断修复（前端开发师）</condition>
    <condition deadline="2026-04-19 18:00">注册按钮增加 loading 反馈（前端开发师）</condition>
  </conditional-pass-terms>

  <rejection-items />
</report>
-->

<!-- ===== 范例：打回 ===== -->

<!--
<report type="verdict">
  <header>
    <task-id>TASK-005</task-id>
    <time>2026-04-17 19:00</time>
  </header>

  <three-evidence>
    <evidence name="功能测试报告" source="功能测试师" status="已收到">
      <path>test-reports/test-task005-v2.md</path>
    </evidence>
    <evidence name="UI 证据" source="界面测试师" status="已收到">
      <path>tests/screenshots/v2/</path>
    </evidence>
    <evidence name="安全审计结论" source="安全审计师" status="已收到">
      <path>security-audits/audit-v1-20260417.md</path>
    </evidence>
  </three-evidence>

  <evidence-review>
    <review-dimension name="功能正确性">6 用例中 2 失败。登录接口密码错误返回 500（应返回 401），JWT token 未校验过期导致过期 token 仍可访问。</review-dimension>
    <review-dimension name="UI 完整性">登录页截图正常，无严重 UI 问题。</review-dimension>
    <review-dimension name="安全无高危">高危 1 个：JWT secret 硬编码（CWE-798）。中危 2 个：密码哈希用 SHA256（CWE-327）、日志含手机号（CWE-532）。</review-dimension>
  </evidence-review>

  <verdict>
    <functional>✗ 核心登录流程存在2个失败</functional>
    <ui>✓ 无严重问题</ui>
    <security>✗ 存在1个高危安全问题</security>
    <conclusion>打回</conclusion>
    <rationale>安全审计发现 JWT secret 硬编码（高危），功能测试发现 2 个核心流程失败。高危安全问题一票否决，功能缺陷阻断核心流程。不打回=上线后用户 token 可被伪造。</rationale>
  </verdict>

  <conditional-pass-terms />

  <rejection-items>
    <rejection-item agent="后端开发师">
      <problem>JWT secret 硬编码为 "my-secret-key"（CWE-798）</problem>
      <fix-requirement>从环境变量 JWT_SECRET 读取，启动时检测未设置则拒绝启动</fix-requirement>
      <expected-time>2026-04-18 12:00</expected-time>
    </rejection-item>
    <rejection-item agent="后端开发师">
      <problem>密码错误时返回 500 而非 401</problem>
      <fix-requirement>捕获认证异常返回 401 + "手机号或密码错误"（不区分是哪个错）</fix-requirement>
      <expected-time>2026-04-18 12:00</expected-time>
    </rejection-item>
    <rejection-item agent="后端开发师">
      <problem>JWT 过期 token 仍可访问受保护接口</problem>
      <fix-requirement>在 token 校验中间件中检查 exp 字段，过期返回 401</fix-requirement>
      <expected-time>2026-04-18 12:00</expected-time>
    </rejection-item>
  </rejection-items>
</report>
-->

<!-- ===== 自检 ===== -->

<!--
提交前自检清单：
□ <three-evidence> 三项逐项标注来源和状态，缺失 → 必须写 BLOCKED 而不是强行裁决
□ <evidence-review> 三个维度每项都有实质性评语（不是"看起来没问题"）
□ <verdict> 中 functional/ui/security 三项独立判定，conclusion 三选一
□ 有条件通过时 <conditional-pass-terms> 每个 condition 有 deadline 且内容可被 PM 直接建 Task
□ 打回时 <rejection-items> 每项有具体问题 + 可执行修复步骤 + 期望时间
□ 裁决理由不使用"看起来""应该""大概"，必须是可追溯的事实
□ XML 标签全部正确闭合
-->

</harness-template>
