---
name: ui-review-template
description: 界面测试报告模板（截图矩阵+交互校验）
template: true
---

<harness-template>

<report type="ui-test">
  <header>
    <task-id>TASK-{编号}</task-id>
    <round>v{N}</round>
    <time>{YYYY-MM-DD HH:MM}</time>
    <screenshot-dir>tests/screenshots/v{N}/</screenshot-dir>
  </header>

  <screenshot-matrix>
    <!-- 每格填截图文件名，无法触发的状态填 N/A -->
    <page name="{页面名}">
      <viewport name="桌面">
        <state name="初始" file="{page}-desktop-initial.png" status="{✓/✗/N/A}" />
        <state name="空" file="{page}-desktop-empty.png" status="{✓/✗/N/A}" />
        <state name="加载" file="{page}-desktop-loading.png" status="{✓/✗/N/A}" />
        <state name="正常" file="{page}-desktop-normal.png" status="{✓/✗/N/A}" />
        <state name="错误" file="{page}-desktop-error.png" status="{✓/✗/N/A}" />
        <state name="成功" file="{page}-desktop-success.png" status="{✓/✗/N/A}" />
      </viewport>
      <viewport name="移动">
        <!-- 同上结构 -->
      </viewport>
    </page>
  </screenshot-matrix>

  <interaction-checks>
    <check name="Tab 顺序合理" page="{页面}" status="{✓/✗}">{备注}</check>
    <check name="Focus 可见" page="{页面}" status="{✓/✗}" />
    <check name="Hover 反馈" page="{页面}" status="{✓/✗}" />
    <check name="表单提交反馈" page="{页面}" status="{✓/✗/N/A}" />
    <check name="错误状态展示" page="{页面}" status="{✓/✗/N/A}" />
    <check name="响应式适配" page="{页面}" status="{✓/✗}" />
  </interaction-checks>

  <findings>
    <issue severity="{高/中/低}">
      <screenshot>{filename}</screenshot>
      <description>{具体问题}</description>
      <fix>{修复建议}</fix>
    </issue>
  </findings>
</report>

<!-- ===== 范例 ===== -->

<!--
<report type="ui-test">
  <header>
    <task-id>TASK-003</task-id>
    <round>v1</round>
    <time>2026-04-17 17:00</time>
    <screenshot-dir>tests/screenshots/v1/</screenshot-dir>
  </header>

  <screenshot-matrix>
    <page name="注册页">
      <viewport name="桌面">
        <state name="初始" file="register-desktop-initial.png" status="✓" />
        <state name="空" file="register-desktop-empty.png" status="✓" />
        <state name="加载" file="register-desktop-loading.png" status="✗" />
        <state name="正常" file="register-desktop-normal.png" status="✓" />
        <state name="错误" file="register-desktop-error.png" status="✓" />
        <state name="成功" file="register-desktop-success.png" status="✓" />
      </viewport>
      <viewport name="移动">
        <state name="初始" file="register-mobile-initial.png" status="✓" />
        <state name="空" file="register-mobile-empty.png" status="✓" />
        <state name="加载" file="register-mobile-loading.png" status="✗" />
        <state name="正常" file="register-mobile-normal.png" status="✓" />
        <state name="错误" file="register-mobile-error.png" status="✓" />
        <state name="成功" file="register-mobile-success.png" status="✓" />
      </viewport>
    </page>
  </screenshot-matrix>

  <interaction-checks>
    <check name="Tab 顺序合理" page="注册页" status="✓">手机号→获取验证码→验证码→注册按钮，顺序正确</check>
    <check name="Focus 可见" page="注册页" status="✓">输入框获得焦点时有蓝色边框</check>
    <check name="Hover 反馈" page="注册页" status="✓">注册按钮 hover 有颜色变化</check>
    <check name="表单提交反馈" page="注册页" status="✗">点击注册后按钮无 loading 状态，用户可能重复点击</check>
    <check name="错误状态展示" page="注册页" status="✓">错误信息显示在对应输入框下方，红色文字</check>
    <check name="响应式适配" page="注册页" status="✓">移动端布局正常，无横向滚动</check>
  </interaction-checks>

  <findings>
    <issue severity="高">
      <screenshot>register-desktop-loading.png</screenshot>
      <description>"获取验证码"按钮 loading 状态下文字被截断，只显示"获取验..."，桌面端和移动端均存在</description>
      <fix>按钮 loading 时将文字替换为"发送中..."或增加按钮最小宽度至 120px</fix>
    </issue>
    <issue severity="中">
      <screenshot>register-desktop-loading.png</screenshot>
      <description>点击"注册"按钮后无 loading 反馈，用户可能重复点击提交</description>
      <fix>注册按钮点击后显示 loading spinner 并 disabled，接口返回后恢复</fix>
    </issue>
  </findings>
</report>
-->

<!-- ===== 自检 ===== -->

<!--
提交前自检清单：
□ <screenshot-matrix> 每个页面都覆盖了桌面和移动两个视口
□ 每个视口至少覆盖了"初始""正常""错误"三个核心状态
□ 无法触发的状态标注 N/A 并说明原因（不是空着）
□ <interaction-checks> 六项逐项检查，不是全写 ✓
□ <findings> 每个问题都附了具体截图文件名
□ 截图文件确实存在于 screenshot-dir 指定的目录中
□ XML 标签全部正确闭合
-->

</harness-template>
