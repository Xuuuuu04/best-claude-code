---
name: auto-check-hooks
description: GP-S* / GP-C* [AUTO] 项的工具层自动化配置指南
guide: true
---

<harness-guide>
  <section id="overview">
    <title>概述</title>
    <content>
<p>output-style 中标记为 <code>[AUTO]</code> 的 GP 规则可以通过工具层自动化拦截，减少人工审查负担。本文档提供推荐的工具配置方案。</p>
    </content>
  </section>

  <section id="gp-s-auto">
    <title>GP.SECURITY [AUTO] 项推荐工具</title>
    <content>
<table>
<tr><th>规则</th><th>推荐工具</th><th>检测内容</th></tr>
<tr><td>GP-S01 SQL 参数化</td><td><code>semgrep</code></td><td>字符串拼接 SQL、raw query</td></tr>
<tr><td>GP-S02 命令执行参数化</td><td><code>semgrep</code></td><td>shell=True、eval、exec</td></tr>
<tr><td>GP-S05 硬编码凭据</td><td><code>gitleaks</code></td><td>git 历史和当前文件中的密钥泄露</td></tr>
<tr><td>GP-S08 日志脱敏</td><td><code>semgrep</code> / grep</td><td>日志中包含 password/token/secret</td></tr>
<tr><td>GP-S11 资源泄漏</td><td>linter (ruff/flake8/ESLint)</td><td>未关闭的文件/连接</td></tr>
<tr><td>GP-S12 反序列化</td><td><code>semgrep</code></td><td>pickle.loads/yaml.load 等危险调用</td></tr>
</table>
    </content>
  </section>

  <section id="gp-c-auto">
    <title>GP.CODE [AUTO] 项推荐工具</title>
    <content>
<table>
<tr><th>规则</th><th>推荐工具</th><th>检测内容</th></tr>
<tr><td>GP-C01 函数长度</td><td>linter (ruff/eslint)</td><td>函数超过 50 行</td></tr>
<tr><td>GP-C02 嵌套深度</td><td>linter</td><td>嵌套超过 4 层</td></tr>
<tr><td>GP-C04 文档字符串</td><td>linter (ruff/pydocstyle)</td><td>公开函数/类缺少 docstring</td></tr>
<tr><td>GP-C05 类型注解</td><td>mypy / pyright</td><td>缺少类型注解</td></tr>
<tr><td>GP-C06 空 catch</td><td><code>semgrep</code> / linter</td><td>裸 except / 空 catch</td></tr>
<tr><td>GP-C08 导入排序</td><td>isort / ruff</td><td>导入未按标准分组</td></tr>
<tr><td>GP-C09 TODO 规范</td><td>grep / 自定义脚本</td><td>无说明的 TODO/FIXME</td></tr>
</table>
    </content>
  </section>

  <section id="config">
    <title>推荐配置方式</title>
    <content>
<h3>方式 1：Claude Code Hooks（推荐）</h3>
<p>在项目的 <code>.claude/settings.json</code> 中配置 hook，在代码提交前自动检查：</p>
<pre><code>{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [
        {"command": "semgrep --config auto --quiet $FILE", "timeout": 30}
      ]
    }]
  }
}</code></pre>

<h3>方式 2：pre-commit（项目级）</h3>
<p>在 <code>.pre-commit-config.yaml</code> 中配置：</p>
<pre><code>repos:
  - repo: https://github.com/returntocorp/semgrep
    rev: v1.52.0
    hooks:
      - id: semgrep
        args: ['--config', 'auto', '--quiet']
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks</code></pre>

<h3>方式 3：CI/CD 集成</h3>
<p>在 CI 流水线中加入 <code>semgrep ci</code> 和 <code>gitleaks detect</code> 步骤。</p>
    </content>
  </section>

  <section id="priority">
    <title>实施优先级</title>
    <content>
<ol>
<li><strong>P0 立即接入</strong>：GP-S05（gitleaks 密钥扫描）、GP-S01（semgrep SQL 注入）</li>
<li><strong>P1 推荐接入</strong>：GP-C06（空 catch）、GP-S02（shell=True）</li>
<li><strong>P2 按需接入</strong>：其余 AUTO 项</li>
</ol>
    </content>
  </section>
</harness-guide>
