<rule id="hook-scripts-pattern" severity="blocker">
  <rationale>
    适用于所有 Claude Code hook 脚本（位于 <path>.claude/hooks/</path> 或 <path>~/.claude/hooks/</path>）。这些规范来自 Agent Legion 实战中踩过的坑，每条都有过真实事故。
  </rationale>

  <section id="rule-1-shebang">
    <requirement severity="blocker">
      脚本头部：用 <code>set -uo pipefail</code>，**不**用 <code>-e</code>
      <example type="good">
        <code-block language="bash"><![CDATA[
#!/bin/bash
set -uo pipefail
        ]]></code-block>
      </example>
      <rationale>
        **为什么不用 <code>-e</code>**：Claude Code hook 接收一条 stdin JSON 后可能调用 git / jq / 其他命令。在空 git 仓库、无 jq 环境等常见边界场景，这些命令会非零退出。<code>set -e</code> 会**立即杀死脚本**，stderr 还没写入任何内容，UI 显示 <token>"Failed with non-blocking status code: No stderr output"</token> 让问题极难排查。

        保留 <code>-u</code>（未定义变量报错）和 <code>-o pipefail</code>（管道任一失败则整管道失败）提供语法层安全网，而**不**强制终止正常的非零返回。
      </rationale>
    </requirement>
  </section>

  <section id="rule-2-defensive">
    <requirement severity="blocker">
      每个可能失败的命令后加容错：
      <example type="good">
        <code-block language="bash"><![CDATA[
# 好：允许失败，用 fallback
BRANCH="$(git branch --show-current 2>/dev/null || echo '')"
LIST="$(ls *.md 2>/dev/null | head -10 || true)"
        ]]></code-block>
      </example>
      <example type="bad">
        <code-block language="bash"><![CDATA[
# 坏：失败就炸
BRANCH="$(git branch --show-current)"
        ]]></code-block>
      </example>
      通用模式：
      <list>
        <item>读取但不关键 → <code>|| true</code></item>
        <item>读取有 fallback → <code>|| echo "default"</code></item>
        <item>stdout 不可为空 → <code>|| echo ""</code></item>
      </list>
    </requirement>
  </section>

  <section id="rule-3-exit-zero">
    <requirement severity="blocker">
      末尾显式 <code>exit 0</code>：
      <example type="good">
        <code-block language="bash"><![CDATA[
# ...
exit 0
        ]]></code-block>
      </example>
      <rationale>
        即使前面所有命令都成功，也显式 exit 0。这让"hook 正常结束"和"某条中间命令意外失败但被 <code>|| true</code> 吞掉导致脚本走完"两种情况的退出码都是 0，行为一致。
      </rationale>
    </requirement>
  </section>

  <section id="rule-4-jsonl-jq-c">
    <constraint severity="blocker">
      写 JSONL 文件必须用 <cmd>jq -c</cmd>：
      <example type="good">
        <code-block language="bash"><![CDATA[
# 好：一行一条记录
jq -c -n --arg ts "$TIMESTAMP" --arg evt "$EVENT" \
  '{timestamp: $ts, event: $evt}' >> "$LOG" 2>/dev/null
        ]]></code-block>
      </example>
      <example type="bad">
        <code-block language="bash"><![CDATA[
# 坏：jq 默认 pretty-print，一条记录占 10+ 行，破坏 JSONL 格式
jq -n --arg ts "$TIMESTAMP" ... >> "$LOG"
        ]]></code-block>
      </example>
      <rationale>
        破坏的 JSONL 无法用 <cmd>tail | jq</cmd> 或 <cmd>grep | jq</cmd> 流式处理。<code>jq -c</code> 强制紧凑单行输出，是 JSONL 格式的硬性要求。
      </rationale>
    </constraint>
  </section>

  <section id="rule-5-no-env-var-glob-in-if">
    <constraint severity="blocker">
      不在 <field>if:</field> 字段使用环境变量通配符：
      <example type="bad">
        <description>settings.json 示例（错误）：</description>
        <code-block language="json"><![CDATA[
"if": "Bash(rm -rf $HOME*)"
        ]]></code-block>
        <rationale>
          <code>$HOME</code> 会被展开为 <path>/Users/&lt;username&gt;</path>，然后 glob <path>/Users/&lt;username&gt;*</path> 会匹配**所有** <cmd>cd /Users/username/...</cmd> 类合法命令，把整个会话卡死。
        </rationale>
      </example>
      <example type="good">
        <description>正确做法：</description>
        <list>
          <item>写具体路径：<code>Bash(rm -rf /)</code> / <code>Bash(rm -rf /usr/*)</code></item>
          <item>或在 hook 脚本内部做判断（通过 exit 2 阻止），不靠 <field>if:</field> 做复杂过滤</item>
        </list>
      </example>
    </constraint>
  </section>

  <section id="rule-6-test-outside-repo">
    <constraint severity="blocker">
      测试时不要用 repo 本身作 <env>CLAUDE_PROJECT_DIR</env>：
      <example type="bad">
        <code-block language="bash"><![CDATA[
# 坏：在 repo 里测会把 runtime 文件写入 repo
cd ~/.claude && CLAUDE_PROJECT_DIR=$PWD bash hooks/some-hook.sh
        ]]></code-block>
      </example>
      <example type="good">
        <code-block language="bash"><![CDATA[
# 好：在临时目录测
TEST_DIR="$(mktemp -d)"
mkdir -p "$TEST_DIR/.claude"
CLAUDE_PROJECT_DIR="$TEST_DIR" bash hooks/some-hook.sh
rm -rf "$TEST_DIR"
        ]]></code-block>
      </example>
      <rationale>
        Hook 产出的 log 文件（cost-log.txt、hook-errors.log 等）若生成在 repo 目录，会被 git 捕获并在不经意间提交。<path>.gitignore</path> 是第二道防线，第一道是**测试时不要用 repo 目录**。
      </rationale>
    </constraint>
  </section>

  <section id="rule-7-real-event-fixtures">
    <constraint severity="blocker">
      测试用真实事件样本，不要用脑补的 mock：
      <rationale>
        Claude Code 真实 hook 事件字段集可能与文档例子不同（文档示例常是"理论完整版"而实际事件字段更精简）。正确流程：
      </rationale>
      <list type="ordered">
        <item>让 hook 写一条原始 JSON 到日志（例如 <cmd>cat &gt; /tmp/last-event.json</cmd>）</item>
        <item>跑一次真实事件（派遣一个 subagent 等）</item>
        <item>用捕获到的 JSON 作 test fixture</item>
        <item>然后再写处理逻辑</item>
      </list>
      <note>不要基于文档"假定"字段存在——直接验证。</note>
    </constraint>
  </section>

  <section id="rule-8-hook-profile">
    <requirement>
      所有 hook 都通过 <path>hooks/_lib/run-with-logging.sh</path> 包装执行。该 wrapper 在调用真 hook 前会 source <path>hooks/_lib/hook-flags.sh</path>，根据两个环境变量决定是否执行：
      <table>
| 变量 | 取值 | 作用 |
|:--|:--|:--|
| `CLAUDE_HOOK_PROFILE` | `minimal` / `standard` / `strict`（默认 `standard`） | 按档位全局调节，越严越包含 |
| `CLAUDE_DISABLED_HOOKS` | 逗号分隔的 hook id | 黑名单，优先于 profile |
      </table>
      <rationale>
        每个 hook 的最低 profile 在 <path>hooks/_lib/hook-flags.sh</path> 的 <code>_HOOK_MIN_PROFILE</code> 数组中登记。<code>minimal</code> 只放行生命周期必需（<value>session-start</value> / <value>pre-compact</value> / <value>post-compact</value> / <value>subagent-start-mark</value>），<code>standard</code> 加入审计/安全/质量（<value>scope-lock-guard</value> / <value>artifact-write-guard</value> / <value>post-edit-lint</value> / <value>subagent-stop-log</value> / <value>instructions-audit</value>）。
      </rationale>
    </requirement>

    <subsection id="hook-registration">
      <requirement>
        新增 hook 的登记流程：
        <list type="ordered">
          <item>在 <path>hooks/</path> 中新增 <path>my-hook.sh</path>，遵守本规范第 1–7 条</item>
          <item>在 <path>hooks/_lib/hook-flags.sh</path> 的 <code>_HOOK_MIN_PROFILE</code> 数组增加 <value>"my-hook:minimal"</value>（或 <value>standard</value>/<value>strict</value>）</item>
          <item>在 <path>settings.json</path> 注册事件 → 仍然通过 <path>run-with-logging.sh</path> 调用</item>
          <item>跑 <cmd>bash bin/test-hook-flags.sh</cmd> 确认登记数 ≥ 9（自动断言）</item>
          <item>跑 <cmd>bash bin/doctor.sh</cmd>，第 14 节会提示 hooks/ 脚本数与登记数是否一致</item>
        </list>
        <note>**不要**在 hook 内部重复 profile 判断——wrapper 已集中处理。</note>
      </requirement>
    </subsection>

    <subsection id="hook-when-to-disable">
      <note>
        何时关 hook：
        <list>
          <item><env>CLAUDE_HOOK_PROFILE=minimal</env>：调试 hook 本身、compaction 流程调优、或发现 hook 异常耗时想临时关闭审计链</item>
          <item><env>CLAUDE_DISABLED_HOOKS=post-edit-lint</env>：当某个 hook 在当前项目误报且来不及修时</item>
        </list>
      </note>
    </subsection>
  </section>

  <section id="review-checklist">
    <requirement>
      <agent>高级代码审查师</agent> 与 <agent>高级安全审计师</agent> 在审查 hook 脚本修改时，除了通用代码审查，还要对照本规范：
      <checklist>
        <check id="hook-shebang">脚本头部是 <code>set -uo pipefail</code>，没有单独的 <code>set -e</code></check>
        <check id="hook-defensive">每个 git / jq / 外部命令都有容错</check>
        <check id="hook-exit-zero">末尾有 <code>exit 0</code></check>
        <check id="hook-jsonl-jq-c">JSONL 写入用 <cmd>jq -c</cmd></check>
        <check id="hook-no-env-var-glob">若涉及 settings.json <field>if:</field> 字段，模式精确、不含环境变量通配</check>
        <check id="hook-test-outside-repo">测试脚本不在 repo 目录内跑</check>
        <check id="hook-real-fixtures">测试 fixture 来源于真实捕获，非手造 JSON</check>
        <check id="hook-profile-registered">新 hook 在 <path>hooks/_lib/hook-flags.sh</path> 登记了最低 profile，且通过 <path>run-with-logging.sh</path> 包装</check>
      </checklist>
    </requirement>
  </section>
</rule>
