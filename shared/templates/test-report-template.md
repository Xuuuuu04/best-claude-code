---
name: test-report-template
description: 功能测试报告模板（结构化版）
template: true
---

<harness-template>

<report type="functional-test">
  <header>
    <task-id>TASK-{编号}</task-id>
    <round>v{N}</round>
    <time>{YYYY-MM-DD HH:MM}</time>
    <basis>{业务描述段落引用，禁止从源码反推}</basis>
  </header>

  <verdict>
    <total>{N}</total>
    <passed>{N}</passed>
    <failed>{N}</failed>
    <conclusion>{全绿通过 / 存在失败}</conclusion>
  </verdict>

  <test-cases>
    <case id="1" name="{用例名}" type="{主流程/边界/错误/权限/幂等/并发}" status="{✓/✗}">
      <steps>{关键操作步骤}</steps>
      <expected>{来自业务描述的预期}</expected>
      <actual>{实际结果}</actual>
    </case>
    <!-- 按场景类型分组排列 -->
  </test-cases>

  <failed-details>
    <failure case-id="{N}">
      <type>{场景类型}</type>
      <operation>{做了什么}</operation>
      <expected>{应该怎样}</expected>
      <actual>{发生了什么}</actual>
      <clue>{错误信息 / 文件:行 / 日志片段}</clue>
    </failure>
  </failed-details>

  <coverage-check>
    <dimension name="主流程">{✓}</dimension>
    <dimension name="边界值">{✓ / ✗：未覆盖的边界}</dimension>
    <dimension name="错误处理">{✓ / ✗}</dimension>
    <dimension name="权限控制">{✓ / ✗ / N/A}</dimension>
    <dimension name="幂等性">{✓ / ✗ / N/A}</dimension>
    <dimension name="并发安全">{✓ / ✗ / N/A}</dimension>
  </coverage-check>
</report>

<!-- ===== 范例 ===== -->

<!--
<report type="functional-test">
  <header>
    <task-id>TASK-003</task-id>
    <round>v1</round>
    <time>2026-04-17 16:20</time>
    <basis>业务描述："用户可通过手机号+验证码注册账号，注册成功后自动登录并跳转首页。手机号必须为11位数字，验证码6位，60秒内不可重发。"</basis>
  </header>

  <verdict>
    <total>8</total>
    <passed>7</passed>
    <failed>1</failed>
    <conclusion>存在失败</conclusion>
  </verdict>

  <test-cases>
    <case id="1" name="正常注册" type="主流程" status="✓">
      <steps>输入11位手机号 → 点击获取验证码 → 输入6位验证码 → 点击注册</steps>
      <expected>注册成功，自动登录，跳转首页</expected>
      <actual>注册成功，自动登录，跳转首页</actual>
    </case>
    <case id="2" name="手机号不足11位" type="边界" status="✓">
      <steps>输入10位手机号 → 点击获取验证码</steps>
      <expected>提示"手机号格式不正确"，不发送验证码</expected>
      <actual>提示"手机号格式不正确"，未发送验证码</actual>
    </case>
    <case id="3" name="验证码不足6位" type="边界" status="✓">
      <steps>输入11位手机号 → 获取验证码 → 输入5位验证码 → 点击注册</steps>
      <expected>提示"验证码格式不正确"</expected>
      <actual>提示"验证码格式不正确"</actual>
    </case>
    <case id="4" name="60秒内重发验证码" type="主流程" status="✓">
      <steps>获取验证码 → 立即再次点击获取</steps>
      <expected>按钮置灰并显示倒计时，不可点击</expected>
      <actual>按钮置灰，显示"59秒后重试"</actual>
    </case>
    <case id="5" name="验证码错误" type="错误" status="✓">
      <steps>输入正确手机号 → 获取验证码 → 输入错误验证码 → 点击注册</steps>
      <expected>提示"验证码错误或已过期"</expected>
      <actual>提示"验证码错误或已过期"</actual>
    </case>
    <case id="6" name="已注册手机号重复注册" type="错误" status="✓">
      <steps>使用已注册的手机号再次注册</steps>
      <expected>提示"该手机号已注册"</expected>
      <actual>提示"该手机号已注册"</actual>
    </case>
    <case id="7" name="注册接口幂等" type="幂等" status="✓">
      <steps>对同一手机号并发发送2次注册请求</steps>
      <expected>只创建一个账号，第二次返回"已注册"</expected>
      <actual>第二次返回"该手机号已注册"，数据库仅一条记录</actual>
    </case>
    <case id="8" name="验证码过期后注册" type="边界" status="✗">
      <steps>获取验证码 → 等待6分钟 → 输入验证码 → 点击注册</steps>
      <expected>提示"验证码已过期，请重新获取"</expected>
      <actual>返回500错误，页面显示"系统异常"</actual>
    </case>
  </test-cases>

  <failed-details>
    <failure case-id="8">
      <type>边界</type>
      <operation>验证码过期（6分钟）后提交注册</operation>
      <expected>友好提示"验证码已过期"</expected>
      <actual>500错误，响应体：{"code": 500, "message": "Internal Server Error"}</actual>
      <clue>src/api/user.py:78 — 验证码查询返回 None 后未做空值判断，直接访问 .code 属性</clue>
    </failure>
  </failed-details>

  <coverage-check>
    <dimension name="主流程">✓ 正常注册 + 60秒重发限制</dimension>
    <dimension name="边界">✓ 手机号11位 + 验证码6位 + 过期场景（发现1个bug）</dimension>
    <dimension name="错误处理">✓ 错误验证码 + 重复注册</dimension>
    <dimension name="权限控制">N/A 注册为公开接口，无权限要求</dimension>
    <dimension name="幂等性">✓ 并发注册</dimension>
    <dimension name="并发安全">N/A 注册接口无共享状态竞争</dimension>
  </coverage-check>
</report>
-->

<!-- ===== 自检 ===== -->

<!--
提交前自检清单：
□ <header> 中 basis 引用了业务描述原文，不是从源码推断的
□ <verdict> 中 passed + failed = total，数字一致
□ <test-cases> 每条用例的 expected 来自业务描述或合理推导，不是看代码写的
□ <failed-details> 每个失败用例都有 clue（错误信息/文件:行/日志片段）
□ <coverage-check> 六个维度逐项有结论，N/A 必须附理由
□ 用例类型至少覆盖"主流程"和"边界"两种，不是全写"主流程"
□ XML 标签全部正确闭合
-->

</harness-template>
