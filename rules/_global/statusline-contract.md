<rule id="statusline-contract" severity="warning">
  <rationale>
    statusline 是主会话判断现场状态的第一屏信号。它必须准确、紧凑、可降级，不能为了展示更多信息而挤掉活跃代理、任务阶段、门控和最终确认状态。
  </rationale>

  <layout-contract>
    <requirement severity="warning">
      第 1 行只放运行态核心信息：
      <list>
        <item>LEGION brand</item>
        <item>活跃 Subagent 摘要</item>
        <item>Agent Teams 状态（如有活跃团队）</item>
        <item>模型</item>
        <item>权限模式</item>
      </list>
    </requirement>

    <requirement severity="warning">
      第 2 行只放任务闭环信息：
      <list>
        <item>任务 ID</item>
        <item>阶段</item>
        <item>风险</item>
        <item>门控状态</item>
        <item>理解 / 迭代 / 最终确认</item>
        <item>上下文和时间</item>
      </list>
    </requirement>

    <requirement severity="warning">
      窄屏必须优先保留核心状态，允许压缩标签、任务 ID、多代理显示和上下文条。不得为了目录、分支、成本等次要信息遮挡核心状态。
    </requirement>

    <requirement severity="warning">
      活跃 Subagent 文件必须可精确清理；读取到明显陈旧状态时必须忽略或清理，不能展示假的活跃代理。
    </requirement>
  </layout-contract>
</rule>
