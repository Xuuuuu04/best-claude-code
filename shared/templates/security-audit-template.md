---
name: security-audit-template
description: 安全审计报告模板（OWASP/CWE 结构化版）
template: true
---

<harness-template>

<!-- ===== 骨架 ===== -->

<report type="security-audit">
  <header>
    <scope>{全栈 / 模块名 / 功能名}</scope>
    <depth>{完整 OWASP / 基线过查 / 合规对齐}</depth>
    <time>{YYYY-MM-DD}</time>
    <code-snapshot>{commit hash 或 "当前 HEAD"}</code-snapshot>
  </header>

  <verdict>
    <conclusion>{通过 / 有条件通过 / 不通过}</conclusion>
    <critical-count>{N}</critical-count>
    <high-count>{N}</high-count>
    <medium-count>{N}</medium-count>
    <low-count>{N}</low-count>
  </verdict>

  <findings>
    <issue severity="{Critical/High/Medium/Low/Info}" cwe="CWE-{XXX}">
      <location file="{path}" line="{L}" />
      <description>{漏洞具体描述}</description>
      <exploit-path>{攻击者怎么做}</exploit-path>
      <fix>{修复建议}</fix>
    </issue>
  </findings>

  <owasp-top10>
    <item code="A01" name="权限控制失效">{✓ / ✗ / N/A}</item>
    <item code="A02" name="加密失败">{✓ / ✗ / N/A}</item>
    <item code="A03" name="注入">{✓ / ✗ / N/A}</item>
    <item code="A04" name="不安全设计">{✓ / ✗ / N/A}</item>
    <item code="A05" name="安全配置错误">{✓ / ✗ / N/A}</item>
    <item code="A06" name="脆弱过期组件">{✓ / ✗ / N/A}</item>
    <item code="A07" name="认证失败">{✓ / ✗ / N/A}</item>
    <item code="A08" name="数据完整性失败">{✓ / ✗ / N/A}</item>
    <item code="A09" name="日志监控不足">{✓ / ✗ / N/A}</item>
    <item code="A10" name="SSRF">{✓ / ✗ / N/A}</item>
  </owasp-top10>

  <dependency-scan>
    <tool name="{pip-audit / npm audit / go vuln}">{无漏洞 / N个高危 / N个中危}</tool>
    <tool name="gitleaks">{无泄露 / 发现：具体}</tool>
  </dependency-scan>

  <security-debt>
    <debt-item severity="{Medium/Low}" schedule="{版本/时间}">{中低危未修复项描述}</debt-item>
  </security-debt>
</report>

<!-- ===== 范例 ===== -->

<!--
<report type="security-audit">
  <header>
    <scope>全栈（用户模块 v2 上线前审计）</scope>
    <depth>完整 OWASP</depth>
    <time>2026-04-17</time>
    <code-snapshot>a3f7c2d</code-snapshot>
  </header>

  <verdict>
    <conclusion>不通过</conclusion>
    <critical-count>1</critical-count>
    <high-count>1</high-count>
    <medium-count>2</medium-count>
    <low-count>0</low-count>
  </verdict>

  <findings>
    <issue severity="Critical" cwe="CWE-89">
      <location file="src/api/user.py" line="47" />
      <description>登录接口 phone 参数直接拼入 SQL，可被 union-based 注入</description>
      <exploit-path>POST /api/login {"phone": "' UNION SELECT password FROM admin--"} 即可绕过认证</exploit-path>
      <fix>参数化查询 + 输入长度白名单校验（手机号必须 11 位数字）</fix>
    </issue>
    <issue severity="High" cwe="CWE-798">
      <location file="src/services/auth.py" line="12" />
      <description>JWT secret 硬编码为 "my-secret-key"</description>
      <exploit-path>源码泄露后攻击者可伪造任意用户 token</exploit-path>
      <fix>从环境变量 JWT_SECRET 读取，启动时检测未设置则拒绝启动</fix>
    </issue>
    <issue severity="Medium" cwe="CWE-532">
      <location file="src/api/user.py" line="31" />
      <description>登录失败日志包含完整手机号</description>
      <exploit-path>日志文件被读取后可批量提取用户手机号</exploit-path>
      <fix>脱敏为 138****5678 格式</fix>
    </issue>
    <issue severity="Medium" cwe="CWE-327">
      <location file="src/services/auth.py" line="8" />
      <description>密码哈希使用 SHA256，无 salt</description>
      <exploit-path>彩虹表可直接反查常见密码</exploit-path>
      <fix>换 bcrypt 或 argon2，cost factor ≥ 12</fix>
    </issue>
  </findings>

  <owasp-top10>
    <item code="A01" name="权限控制失效">✓ RBAC 中间件正常</item>
    <item code="A02" name="加密失败">✗ SHA256 做密码哈希</item>
    <item code="A03" name="注入">✗ SQL 注入</item>
    <item code="A04" name="不安全设计">✓</item>
    <item code="A05" name="安全配置错误">✗ JWT secret 硬编码</item>
    <item code="A06" name="脆弱过期组件">✓ pip-audit 无已知 CVE</item>
    <item code="A07" name="认证失败">✗ JWT secret 可被提取</item>
    <item code="A08" name="数据完整性失败">✓</item>
    <item code="A09" name="日志监控不足">✗ 日志含手机号</item>
    <item code="A10" name="SSRF">N/A 无外部 URL 请求</item>
  </owasp-top10>

  <dependency-scan>
    <tool name="pip-audit">无漏洞</tool>
    <tool name="gitleaks">发现 1 处：src/services/auth.py L12 疑似 JWT secret</tool>
  </dependency-scan>

  <security-debt>
    <debt-item severity="Medium" schedule="v2.1">登录失败日志脱敏（CWE-532）</debt-item>
  </security-debt>
</report>
-->

<!-- ===== 自检 ===== -->

<!--
提交前自检清单：
□ <verdict> 中的 conclusion 与 findings 严重度一致（有 Critical = 不通过）
□ <findings> 每个 issue 都有 CWE 编号 + exploit-path（不是"可能存在风险"）
□ <owasp-top10> 十项逐项有结论，不是全 N/A
□ <dependency-scan> 写了实际跑的工具名和结果，不是"已检查"
□ Critical/High 项在 notes 中明确标注"阻塞上线"
□ XML 标签全部正确闭合
-->

</harness-template>
