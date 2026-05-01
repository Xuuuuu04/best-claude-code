---
name: visual-test-protocol
description: 视觉测试协议。为 visual-tester 提供截图、视觉回归和关键交互验证方法。
when_to_use: 仅当 visual-tester Agent 在验证用户可见 UI 变更时加载（含截图、视觉回归、关键交互、暗色模式）。纯后端 / 接口 / 配置变更不应触发。
---

<skill name="visual-test-protocol">

<overview>
验证用户可见界面的布局、文案、状态、截图和关键交互是否符合预期。
</overview>

<principles>
  <principle priority="1">截图和步骤优先于主观判断</principle>
  <principle priority="2">所有可见状态都要覆盖，不只看 happy path</principle>
  <principle priority="3">视觉通过不替代功能通过</principle>
</principles>

<boundary-with-functional-test>
  <responsibility agent="visual-tester">可见性、布局、状态切换的视觉差异、暗色模式、响应式</responsibility>
  <responsibility agent="functional-tester">功能行为正确性、API 联通、权限控制</responsibility>
  <overlap-scenario name="可见但不可达的按钮">
视觉报"按钮显示正确"，功能报"点击无效"。两份证据各自独立，由 test-lead 合并裁决。
  </overlap-scenario>
</boundary-with-functional-test>

<pre-step name="UI 反馈精确定位（拿到截图必做）">
  <rule priority="critical">禁止凭"看起来像"猜元素位置。客户截图反馈到达后，先用文本反查找到精确 DOM。</rule>
  <instructions>
    <step priority="1">识别截图中可见的<emphasis>文字</emphasis>（按钮标签、列表项、提示文案、文案片段）</step>
    <step priority="2"><cmd>grep -rn "{文字}" --include="*.vue" --include="*.ts" --include="*.tsx"</cmd> 找到精确 HTML 位置</step>
    <step priority="3">读源码确认这段文字所在的 class / component / 父容器</step>
    <step priority="4"><emphasis>然后才</emphasis>改 CSS / 调整布局</step>
  </instructions>
  <fallback name="截图中没有可见文字（纯图标 / 纯样式问题）">
    <option>用截图中的颜色 / 尺寸 / 位置在源码里反查</option>
    <option>必要时让用户<emphasis>圈出截图中具体元素</emphasis>或提供 DOM hint</option>
    <rule>不要猜、不要假设"上次修过的地方就是这次目标"</rule>
  </fallback>
</pre-step>

<checklist>
  <item priority="critical">已用 grep 文字定位到精确 DOM（截图反馈场景必做）</item>
  <item priority="critical">关键页面/组件截图与预期一致</item>
  <item priority="critical">loading、empty、error、success 状态完整</item>
  <item priority="high">响应式布局无明显错位</item>
  <item priority="high">文案、按钮、交互可见且可达</item>
  <item priority="high">截图路径、复现步骤、环境信息可追溯</item>
</checklist>

<examples>
  <example type="critical" reason="关键按钮不可见或不可用"/>
  <example type="critical" reason="错误态/空态明显缺失"/>
  <example type="critical" reason="移动端响应式严重错位"/>
</examples>

<degradation-path name="截图不可达时的降级路径">
视觉测试依赖截图，但环境可能不可用。按以下顺序降级：

  <level condition="服务未启动 / 端口不通">
    <verdict>不算 PASS</verdict>
    <action>先尝试 <cmd>npm run dev</cmd> / <cmd>pnpm dev</cmd> / 项目对应启动命令；启动失败则升级到主会话</action>
    <required>在 review artifact 写明启动命令、错误日志</required>
  </level>

  <level condition="无 GUI 环境（headless / CI 容器）">
    <action>改用 Playwright/Puppeteer headless 截图；如不可用，用 <tool>mcp__plugin_playwright_playwright__browser_take_screenshot</tool></action>
    <required>在报告标记"headless 截图，未做眼校"</required>
  </level>

  <level condition="浏览器扩展 / Playwright 不可用">
    <action>降级到只读源码 + 反查 DOM</action>
    <required>产出 <warning>WARNING: 无法截图，仅做静态校验</warning></required>
    <rule priority="critical">禁止给 PASS，最高 CONDITIONAL PASS</rule>
  </level>

  <level condition="用户提供的截图不清晰">
    <action><tool>mcp__zai-mcp-server__extract_text_from_screenshot</tool> 提文字反查；仍不行则用 AskUserQuestion 让用户圈出</action>
    <rule>不要凭"看起来像"猜元素</rule>
  </level>

  <hard-rule priority="critical">无任何截图证据 = <verdict>BLOCKED</verdict>，绝不给 PASS。</hard-rule>
</degradation-path>

<output path=".claude/artifacts/review-visual-{task-id}.md">
必须包含证据链（截图路径 / 启动命令 / 反查 grep 结果）和 <verdict>PASS</verdict> / <verdict>CONDITIONAL</verdict> / <verdict>BLOCKED</verdict> 明确判定。
</output>

</skill>
