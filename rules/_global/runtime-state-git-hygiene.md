<rule id="runtime-state-git-hygiene" severity="blocker">
  <rationale>
    Agent Legion 会在本地生成 ticket、clarification pending、日志、备份和运行态文件。运行态文件若进入仓库，会泄露本地上下文、制造假状态，并污染发布提交。
  </rationale>

  <requirements>
    <requirement severity="blocker">
      禁止提交以下运行态文件：
      <list>
        <item><path>settings.json.bak*</path>、任何本地配置备份</item>
        <item><path>state/clarification-pending-*.json</path></item>
        <item><path>logs/</path>、<path>sessions/</path>、<path>projects/</path>、<path>tasks/</path>、<path>shell-snapshots/</path></item>
        <item><path>history.jsonl</path>、<path>stats-cache.json</path>、<path>telemetry/</path></item>
      </list>
    </requirement>

    <requirement severity="warning">
      允许提交明确的发布态票据，例如 <path>state/legion-session.json</path>，前提是已经过 <cmd>bin/validate-dispatch-ticket.sh</cmd> 校验，且不含用户隐私、密钥、外部项目路径或 transient session 内容。
    </requirement>

    <requirement severity="warning">
      发布前运行：
      <code-block language="bash"><![CDATA[
git status --short
bash ~/.claude/bin/doctor.sh
      ]]></code-block>
      doctor 的 Git Hygiene 章节不得提示运行态文件可能被提交。
    </requirement>
  </requirements>
</rule>
