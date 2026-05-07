<rule id="git-workflow" severity="blocker">
  <rationale>适用于所有项目的 Git 操作规范。</rationale>

  <section id="commit-message">
    <requirement severity="blocker">
      遵循 Conventional Commits：
      <code-block language="text"><![CDATA[
<type>(<scope>): <subject>

<body>

<footer>
      ]]></code-block>
    </requirement>

    <subsection id="commit-type">
      <table>
| Type | 含义 |
|:--|:--|
| `feat` | 新功能 |
| `fix` | Bug 修复 |
| `docs` | 文档改动 |
| `style` | 代码格式化（不影响行为） |
| `refactor` | 重构（不改功能不修 bug） |
| `perf` | 性能优化 |
| `test` | 测试相关 |
| `build` | 构建系统或依赖变更 |
| `ci` | CI 配置变更 |
| `chore` | 其他杂项 |
      </table>
    </subsection>

    <subsection id="commit-scope">
      <note>Scope（可选）：模块名或影响范围：<value>auth</value>、<value>api</value>、<value>ui</value> 等。</note>
    </subsection>

    <subsection id="commit-subject">
      <constraint severity="blocker">
        Subject 规则：
        <list>
          <item>现在时、命令式（"add" 而非 "added" 或 "adds"）</item>
          <item>首字母小写</item>
          <item>不以句号结尾</item>
          <item>≤ 50 字符</item>
        </list>
      </constraint>
    </subsection>

    <subsection id="commit-body">
      <requirement>
        Body 规则：
        <list>
          <item>解释**为什么**，不只是**做了什么**</item>
          <item>每行 ≤ 72 字符</item>
          <item>段落间空行</item>
        </list>
      </requirement>
    </subsection>

    <subsection id="commit-footer">
      <requirement>
        Footer 格式：
        <list>
          <item><token>BREAKING CHANGE:</token> 破坏性变更</item>
          <item><token>Refs:</token> 相关 issue / PR / artifact</item>
          <item><token>Co-authored-by:</token> 协作者</item>
        </list>
      </requirement>
    </subsection>
  </section>

  <section id="branch-strategy">
    <subsection id="branch-naming">
      <requirement>
        <list>
          <item><pattern>main</pattern> / <pattern>master</pattern>：主分支</item>
          <item><pattern>feature/{task-id}-{short-desc}</pattern>：功能分支</item>
          <item><pattern>fix/{issue-id}-{short-desc}</pattern>：修复分支</item>
          <item><pattern>release/v{semver}</pattern>：发布分支</item>
          <item><pattern>hotfix/{issue-id}</pattern>：紧急修复</item>
        </list>
      </requirement>
    </subsection>

    <subsection id="branch-protection">
      <constraint severity="blocker">
        <list>
          <item><branch>main</branch> 不允许直接 push</item>
          <item>所有变更通过 PR / MR</item>
          <item>PR 必须通过 CI + 至少 1 次 review</item>
        </list>
      </constraint>
    </subsection>
  </section>

  <section id="commit-principles">
    <requirement>
      <list>
        <item>**小而专注**：一个 commit 做一件事</item>
        <item>**可构建**：每个 commit 应该可以 build、可以 run</item>
        <item>**可读**：历史对未来的你和队友有意义</item>
        <item>**可搜索**：commit message 包含关键词便于 <cmd>git log --grep</cmd></item>
      </list>
    </requirement>
  </section>

  <section id="pre-push-gate">
    <constraint severity="blocker">
      <cmd>git push</cmd> 前**必须**：
      <list>
        <item>本地编译通过（如 <cmd>npm run build</cmd> / <cmd>cargo build</cmd> / <cmd>go build</cmd> 项目对应命令）</item>
        <item>类型检查通过（如 <cmd>npm run type-check</cmd> / <cmd>tsc --noEmit</cmd> / <cmd>mypy</cmd>）</item>
        <item>Lint 通过（如 <cmd>npm run lint</cmd> / <cmd>eslint .</cmd> / <cmd>ruff</cmd>）</item>
      </list>
      <rationale>
        **禁止**："改完直接 push 让 CI 当编译器"。CI 失败会污染 commit 历史、阻塞团队，且让客户在测试环境看到 broken build。
      </rationale>
      <note>
        **双产物项目**（如 uni-app 同时输出 H5 + mp-weixin）：每个产物都要单独编译验证，不能只跑其中一个就推。
      </note>
    </constraint>
  </section>

  <section id="forbidden-operations">
    <subsection id="forbidden-absolute">
      <constraint severity="blocker">
        绝对禁止：
        <list>
          <item><cmd>git push --force</cmd> 到 <branch>main</branch> / <branch>master</branch> / 已发布的 release 分支</item>
          <item><cmd>git commit --amend</cmd> 已 push 的 commit</item>
          <item><cmd>git rebase -i</cmd> 已共享的分支</item>
          <item>使用 <flag>--no-verify</flag> 跳过 pre-commit hook（除非明确需要且评估风险）</item>
          <item><cmd>git reset --hard HEAD~N</cmd> 未 stash 的改动</item>
          <item>提交包含密钥、密码、token 的文件</item>
        </list>
      </constraint>
    </subsection>

    <subsection id="forbidden-needs-confirm">
      <constraint severity="warning">
        需要用户确认才能做：
        <list>
          <item><cmd>git push --force-with-lease</cmd>（安全的强推）到个人分支</item>
          <item><cmd>git filter-branch</cmd> / <cmd>git filter-repo</cmd> 历史重写</item>
          <item>删除分支（本地或远程）</item>
          <item>删除 tag</item>
        </list>
      </constraint>
    </subsection>
  </section>

  <section id="pr-mr">
    <subsection id="pr-title">
      <requirement>
        <list>
          <item>遵循 commit message 的 type 规范</item>
          <item>简洁清晰</item>
        </list>
      </requirement>
    </subsection>
    <subsection id="pr-description">
      <requirement>
        <list>
          <item>引用相关 issue / artifact</item>
          <item>说明"做了什么 + 为什么"</item>
          <item>列出测试方式</item>
          <item>截图（如 UI 变更）</item>
        </list>
      </requirement>
    </subsection>
    <subsection id="pr-review">
      <constraint severity="blocker">
        <list>
          <item>至少 1 人 approve</item>
          <item>所有评论响应或解决</item>
          <item>CI 全部通过</item>
        </list>
      </constraint>
    </subsection>
  </section>

  <section id="sensitive-info">
    <subsection id="sensitive-leaked-response">
      <requirement severity="blocker">
        已提交的秘密立即处理：
        <list type="ordered">
          <item>**立即轮换**（假设已泄露）</item>
          <item>使用 <cmd>git filter-repo</cmd> 或 BFG 清除历史</item>
          <item>Force push（经团队同意）</item>
          <item>通知可能受影响的方</item>
        </list>
      </requirement>
    </subsection>
    <subsection id="sensitive-prevention">
      <requirement>
        预防：
        <list>
          <item><path>.gitignore</path> 覆盖 <path>.env</path>、credentials.json、*.pem</item>
          <item><cmd>git-secrets</cmd> / <cmd>truffleHog</cmd> 扫描</item>
          <item>pre-commit hook 自动检查</item>
          <item>代码审查关注新增的 config 文件</item>
        </list>
      </requirement>
    </subsection>
  </section>

  <section id="tags-release">
    <requirement>
      <list>
        <item>Tag 用 annotated（<flag>-a</flag>）而非 lightweight</item>
        <item>版本遵循 SemVer</item>
        <item>发布前更新 CHANGELOG</item>
        <item>推送 tag：<cmd>git push origin v1.2.3</cmd></item>
      </list>
    </requirement>
  </section>

  <section id="undo-operations">
    <subsection id="undo-unpushed">
      <requirement>
        撤销本地未 push 的 commit：
        <code-block language="bash"><![CDATA[
git reset --soft HEAD~1   # 保留改动
git reset --hard HEAD~1   # 丢弃改动（谨慎）
        ]]></code-block>
      </requirement>
    </subsection>
    <subsection id="undo-pushed">
      <requirement>
        撤销已 push 的 commit：
        <code-block language="bash"><![CDATA[
git revert <commit>       # 创建新 commit 撤销
        ]]></code-block>
        **不要**用 <cmd>reset + force push</cmd> 撤销公共提交。
      </requirement>
    </subsection>
    <subsection id="undo-recover">
      <requirement>
        恢复误删：
        <code-block language="bash"><![CDATA[
git reflog                # 查找丢失的 commit
git cherry-pick <hash>    # 恢复
        ]]></code-block>
        <path>.git/objects</path> 中保留的内容可通过 reflog 恢复 ~30 天。
      </requirement>
    </subsection>
  </section>
</rule>
