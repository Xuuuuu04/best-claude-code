---
name: review-template
description: 代码审查报告模板（结构化版）
template: true
---

<harness-template>

<!-- ===== 骨架：填这个 ===== -->

<report type="code-review">
  <header>
    <task-id>TASK-{编号}</task-id>
    <round>v{N}</round>
    <time>{YYYY-MM-DD HH:MM}</time>
    <files>{被审查文件路径列表}</files>
  </header>

  <verdict>
    <dimension name="需求层对照">{✓ 通过 / ✗ 偏差：说明}</dimension>
    <dimension name="方案层对照">{✓ 通过 / ✗ 偏差：说明}</dimension>
    <dimension name="实现层质量">{✓ 通过 / ✗ 偏差：说明}</dimension>
    <dimension name="变更范围">{✓ 未越界 / ✗ 越界：说明}</dimension>
    <dimension name="安全基线">{✓ 全过 / 发现问题}</dimension>
    <conclusion>{通过 / 不通过}</conclusion>
  </verdict>

  <findings>
    <issue severity="{高/中/低}" rule="{GP-XX 或无}">
      <location file="{path}" line="{L}" />
      <description>{问题具体描述}</description>
      <evidence>{代码片段}</evidence>
      <fix>{修复建议}</fix>
    </issue>
  </findings>

  <security-checklist>
    <item name="SQL 参数化">{✓ / ✗：具体位置}</item>
    <item name="XSS 转义">{✓ / ✗}</item>
    <item name="硬编码凭据">{✓ / ✗}</item>
    <item name="权限中间件">{✓ / ✗}</item>
    <item name="日志脱敏">{✓ / ✗}</item>
  </security-checklist>

  <notes>{通过的理由 / 打回原因 / 升级建议}</notes>
</report>

<!-- ===== 范例：参考这个 ===== -->

<!--
<report type="code-review">
  <header>
    <task-id>TASK-003</task-id>
    <round>v1</round>
    <time>2026-04-17 14:30</time>
    <files>src/api/user.py, src/services/auth.py</files>
  </header>

  <verdict>
    <dimension name="需求层对照">✓ 通过：实现了注册+登录，与业务描述一致</dimension>
    <dimension name="方案层对照">✗ 偏差：方案要求手机验证码走 SMS Service，实际硬编码了 123456</dimension>
    <dimension name="实现层质量">✗ 发现 1 个高危安全问题 + 1 个中危规范问题</dimension>
    <dimension name="变更范围">✓ 未越界，改动范围限于方案列出的两个文件</dimension>
    <dimension name="安全基线">✗ 发现问题</dimension>
    <conclusion>不通过</conclusion>
  </verdict>

  <findings>
    <issue severity="高" rule="GP-S01">
      <location file="src/api/user.py" line="47" />
      <description>SQL 查询使用 f-string 拼接用户输入的 phone 字段</description>
      <evidence>f"SELECT * FROM users WHERE phone = '{phone}'"</evidence>
      <fix>改为参数化查询：cursor.execute("SELECT * FROM users WHERE phone = %s", (phone,))</fix>
    </issue>
    <issue severity="中" rule="GP-C06">
      <location file="src/services/auth.py" line="23" />
      <description>except 块只做 pass，吞掉了数据库连接超时错误</description>
      <evidence>except Exception:\n    pass</evidence>
      <fix>捕获具体异常并记录日志：except ConnectionError as e:\n    logger.error(f"DB connection failed: {e}")\n    raise</fix>
    </issue>
  </findings>

  <security-checklist>
    <item name="SQL 参数化">✗：user.py L47 使用 f-string 拼接</item>
    <item name="XSS 转义">✓：API 层不涉及 HTML 渲染</item>
    <item name="硬编码凭据">✓</item>
    <item name="权限中间件">✓：login 路由不需要鉴权，register 同理，符合设计</item>
    <item name="日志脱敏">✓</item>
  </security-checklist>

  <notes>不通过。修复 SQL 注入（高）和空 except（中）后重新提交审查。方案层偏差（验证码硬编码）建议回到开发组长确认是否为临时方案。</notes>
</report>
-->

<!-- ===== 自检：提交前过一遍 ===== -->

<!--
提交前自检清单：
□ <verdict> 五个 dimension 每项都有明确结论（不是空的）
□ <findings> 中每个 issue 四个子标签都填了（location + description + evidence + fix）
□ <security-checklist> 五项逐项检查，不是全写 ✓ 就完事
□ 通过时 <notes> 写了"通过的理由"，不只是"没问题"
□ XML 标签全部正确闭合
-->

</harness-template>
