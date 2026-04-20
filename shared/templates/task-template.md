---
name: task-template
description: Task 文件标准模板（XML 结构化版）
template: true
---

<harness-template>

<!-- ===== 骨架：填这个 ===== -->

<task id="TASK-{编号}">
  <meta>
    <status>{待分析|开发中|审查中|测试中|待裁决|已完成|已关闭}</status>
    <priority>{P0|P1|P2}</priority>
    <type>{开发|文档|调研|设计}</type>
    <created>{YYYY-MM-DD}</created>
    <updated>{YYYY-MM-DD}</updated>
    <depends-on>{依赖的Task编号，无则填"无"}</depends-on>
    <blocks>{依赖此Task的编号，无则填"无"}</blocks>
  </meta>

  <business-description>
    {由项目管理师编写。从用户视角描述：用户做什么操作，看到什么界面，系统如何响应。
     此部分一旦编写完成，其他Agent不得修改。如有歧义，通过BLOCKED机制上报项目管理师修订。}
  </business-description>

  <tech-solution>
    {由开发组长编写。包含后端和/或前端的具体实现方案。
     含：in-scope / out-of-scope / 涉及文件清单 / 技术选型}
  </tech-solution>

  <architecture>
    {由架构师编写。仅在复杂Task中存在，简单Task删除此节。}
  </architecture>

  <review-log>
    {由代码审计师逐轮追加。每轮新增一个 <round>，不删除已有记录。}
    <round n="{N}" time="{YYYY-MM-DD HH:MM}">
      <verdict>{通过|不通过}</verdict>
      <summary>{审查摘要：通过理由 或 打回原因}</summary>
      <report-path>reviews/review-taskXXX-vN.md</report-path>
    </round>
  </review-log>

  <test-log>
    {由功能测试师 / 界面测试师 逐轮追加。每轮新增一个 <round>。}
    <round n="{N}" time="{YYYY-MM-DD HH:MM}" agent="{功能测试师|界面测试师}">
      <verdict>{全绿通过|存在失败}</verdict>
      <summary>{测试摘要}</summary>
      <report-path>{报告文件路径}</report-path>
    </round>
  </test-log>

  <iteration-log>
    {由测试总监师逐轮追加裁决。每轮新增一个 <round>，不删除已有记录。}
    <round n="{N}" time="{YYYY-MM-DD HH:MM}">
      <verdict>{通过|有条件通过|打回}</verdict>
      <rationale>{裁决理由}</rationale>
      <conditions>{有条件通过的待补项，打回时为空}</conditions>
      <rejection-fixes>{打回时的可执行修复建议，通过时为空}</rejection-fixes>
    </round>
  </iteration-log>
</task>

<!-- ===== 范例 ===== -->

<!--
<task id="TASK-003">
  <meta>
    <status>待裁决</status>
    <priority>P1</priority>
    <type>开发</type>
    <created>2026-04-16</created>
    <updated>2026-04-17</updated>
    <depends-on>无</depends-on>
    <blocks>TASK-010</blocks>
  </meta>

  <business-description>
    用户可通过手机号+验证码注册账号。用户在注册页输入11位手机号，点击"获取验证码"，
    系统发送6位数字验证码到该手机号，用户输入验证码后点击"注册"。
    注册成功后自动登录并跳转首页。60秒内不可重发验证码。
    手机号格式不正确时提示"手机号格式不正确"。已注册手机号提示"该手机号已注册"。
  </business-description>

  <tech-solution>
    In-scope：注册接口 POST /api/register、验证码发送接口 POST /api/sms/send、
    前端注册页面（手机号输入+验证码输入+注册按钮）
    Out-of-scope：验证码SDK集成（用mock返回123456）、第三方登录、密码注册

    涉及文件：
    - 后端：src/api/user.py、src/services/auth.py、src/services/sms.py
    - 前端：src/pages/Register.vue、src/api/user.ts

    技术选型：验证码存 Redis（key=phone, TTL=5min）、密码用 bcrypt、
    JWT token（HS256, 24h 过期）
  </tech-solution>

  <architecture />
  <review-log>
    <round n="1" time="2026-04-17 10:30">
      <verdict>不通过</verdict>
      <summary>SQL注入（高）+ 空 except（中）。验证码硬编码为临时方案，回到开发组长确认。</summary>
      <report-path>reviews/review-task003-v1.md</report-path>
    </round>
    <round n="2" time="2026-04-17 14:00">
      <verdict>通过</verdict>
      <summary>SQL参数化已修复，except 已添加日志记录。验证码硬编码经开发组长确认为 v1 临时方案。</summary>
      <report-path>reviews/review-task003-v2.md</report-path>
    </round>
  </review-log>

  <test-log>
    <round n="1" time="2026-04-17 15:00" agent="功能测试师">
      <verdict>存在失败</verdict>
      <summary>8 用例中 7 通过 1 失败：验证码过期后提交返回 500 而非友好提示</summary>
      <report-path>tests/reports/func-report-v1.md</report-path>
    </round>
    <round n="1" time="2026-04-17 15:30" agent="界面测试师">
      <verdict>存在失败</verdict>
      <summary>验证码按钮 loading 态文字截断（高）、注册按钮无 loading 反馈（中）</summary>
      <report-path>tests/screenshots/v1/interaction-check.md</report-path>
    </round>
  </test-log>

  <iteration-log>
    <round n="1" time="2026-04-17 18:00">
      <verdict>有条件通过</verdict>
      <rationale>核心注册流程功能正确，UI主流程正常。3个问题均为边界态/交互反馈层面，不阻塞核心流程。</rationale>
      <conditions>
        1. [2026-04-18 18:00] 修复验证码过期空指针异常（后端开发师）
        2. [2026-04-19 18:00] 验证码按钮 loading 文字截断修复（前端开发师）
        3. [2026-04-19 18:00] 注册按钮增加 loading 反馈（前端开发师）
      </conditions>
      <rejection-fixes />
    </round>
  </iteration-log>
</task>
-->

<!-- ===== 自检 ===== -->

<!--
提交前自检清单：
□ <meta> 中 status 与实际进度一致（不是"开发中"但代码已经提交了）
□ <business-description> 是从用户视角写的（有"用户做什么操作"），不是技术描述
□ <business-description> 仅由项目管理师修改，其他 Agent 不改
□ <tech-solution> 包含 in-scope / out-of-scope / 涉及文件
□ <review-log> / <test-log> / <iteration-log> 是逐轮追加，不删除历史记录
□ 每个 <round> 都有时间戳和明确 verdict
□ XML 标签全部正确闭合
-->

</harness-template>
