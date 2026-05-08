---
paths:
  - "**/package.json"
  - "**/Cargo.toml"
  - "**/pyproject.toml"
  - "**/go.mod"
---

<rule id="release-version-consistency" severity="warning">
  <rationale>
    发布时 README 徽章、CLAUDE.md 最近升级、LEGION changelog 和 EVOLVE-LOG 若版本不一致，用户无法判断当前系统真实版本。版本漂移应由确定性脚本拦截，而不是靠人工记忆。
  </rationale>

  <requirements>
    <requirement severity="warning">
      每次发布前必须确认以下文件指向同一版本号：
      <list>
        <item><path>README.md</path> 的 Status badge</item>
        <item><path>CLAUDE.md</path> 的“最近升级”备注</item>
        <item><path>LEGION.md</path> 的最新 changelog 小节</item>
        <item><path>EVOLVE-LOG.md</path> 的最新版本记录</item>
      </list>
    </requirement>

    <requirement severity="warning">
      发布前运行：
      <code-block language="bash"><![CDATA[
bash ~/.claude/bin/doctor.sh
      ]]></code-block>
      doctor 的 Release Readiness 章节不得出现版本漂移警告。
    </requirement>
  </requirements>
</rule>
