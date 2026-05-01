---
paths:
  - ".github/workflows/**"
  - ".gitlab-ci.yml"
  - ".circleci/**"
  - "Jenkinsfile*"
  - "azure-pipelines*.yml"
---

# CI/CD 配置规范

<rule name="pipeline-structure">
  <requirement>每个 PR / 推送触发以下典型流水线：Checkout → Setup（语言运行时、缓存）→ Install deps（用 lock 文件）→ Lint → Type check → Unit tests → Build → Integration tests → Security scan →（main / tag）Deploy。</requirement>
  <constraint severity="blocker">每步失败立即终止，使用 fail-fast: true。</constraint>
</rule>

<rule name="performance">
  <rule name="caching">
    <requirement>依赖缓存：node_modules、pip cache、~/.gradle。</requirement>
    <requirement>构建缓存：turbo、bazel 远程缓存。</requirement>
    <requirement>Docker layer cache：使用 cache-from / cache-to。</requirement>
  </rule>

  <rule name="parallelism">
    <requirement>独立任务并行执行（lint / test / build）。</requirement>
    <requirement>测试矩阵按文件或模块分片并行。</requirement>
  </rule>

  <rule name="timeout">
    <constraint severity="blocker">每个 job 和 step 必须设置超时，防止僵死。</constraint>
    <example type="good">
jobs:
  test:
    timeout-minutes: 10
    </example>
  </rule>
</rule>

<rule name="secret-management">
  <rule name="prohibitions">
    <constraint severity="blocker">禁止在 workflow 文件中硬编码密钥。</constraint>
    <constraint severity="blocker">禁止在日志中打印密钥，即使脱敏也不允许。</constraint>
    <constraint severity="blocker">禁止在分叉 PR 中暴露密钥（GitHub Actions 默认阻止，需确认设置）。</constraint>
  </rule>

  <rule name="correct-usage">
    <requirement>使用平台 secrets（GitHub Secrets、GitLab Variables）管理密钥。</requirement>
    <requirement>最小权限原则：每个 secret 只赋予需要它的 job。</requirement>
    <requirement>定期轮换密钥。</requirement>
    <requirement>审计日志记录密钥访问记录。</requirement>
  </rule>
</rule>

<rule name="permissions">
  <requirement>CI 权限遵循最小权限原则，按需扩展。</requirement>
  <example type="good">
permissions:
  contents: read   # 默认
  pull-requests: write  # 仅在需要时
  packages: write
  </example>
  <constraint severity="warning">GITHUB_TOKEN 使用后自动过期。避免使用 PAT（Personal Access Token），除非必要。</constraint>
</rule>

<rule name="trigger-conditions">
  <rule name="reasonable-triggers">
    <requirement>PR 触发：开发分支。</requirement>
    <requirement>Push 触发：main / develop。</requirement>
    <requirement>Tag 触发：release。</requirement>
    <requirement>Schedule：定时任务（nightly build、依赖扫描）。</requirement>
  </rule>

  <rule name="anti-patterns">
    <constraint severity="warning">避免 on: [push] 不限定分支——触发过多。</constraint>
    <constraint severity="warning">避免缺少路径过滤——非相关变更触发流水线浪费资源。</constraint>
  </rule>
</rule>

<rule name="deployment">
  <requirement>区分环境：staging 和 production，使用 environments 声明。</requirement>
  <example type="good">
environments:
  staging:
    url: https://staging.example.com
  production:
    url: https://example.com
    # 必需审批
  </example>
  <constraint severity="blocker">Production 环境必须：手动审批 + 限制部署人员 + 强制 PR review 状态。</constraint>
  <requirement>部署脚本必须幂等（重复执行安全），日志结构化，失败时提供明确错误信息。</requirement>
</rule>

<rule name="cache-poisoning-protection">
  <requirement>缓存 key 包含 lock 文件的 hash，确保依赖变更时缓存自动失效。</requirement>
  <example type="good">
cache:
  paths: ...
  key: ${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
  </example>
</rule>

<rule name="matrix-testing">
  <requirement>使用 matrix strategy 测试多版本/多平台组合。</requirement>
  <example type="good">
strategy:
  matrix:
    node-version: [18, 20]
    os: [ubuntu-latest, macos-latest]
  </example>
  <constraint severity="warning">注意笛卡尔积不可过度膨胀。</constraint>
</rule>

<rule name="notifications">
  <requirement>主分支失败：立即通知。</requirement>
  <requirement>PR 失败：仅通知作者。</requirement>
  <requirement>非紧急（依赖更新失败）：异步通知。</requirement>
</rule>

<rule name="logs-and-artifacts">
  <requirement>保留期默认 30 天。</requirement>
  <requirement>测试报告、覆盖率、构建产物作为 artifact 上传。</requirement>
  <constraint severity="blocker">敏感信息禁止进入日志。</constraint>
</rule>

<rule name="security-scanning">
  <requirement>依赖扫描：Dependabot / Renovate。</requirement>
  <requirement>SAST：CodeQL / Semgrep。</requirement>
  <requirement>容器扫描：Trivy / Snyk。</requirement>
  <requirement>Secret 扫描：pre-commit + CI 二次验证。</requirement>
  <constraint severity="blocker">扫描失败的阈值：严重漏洞阻断发布，警告级不阻断但须记录。</constraint>
</rule>

<rule name="reusability">
  <requirement>使用 Reusable workflow / composite action 复用流水线逻辑。</requirement>
  <requirement>参数化而非复制粘贴。</requirement>
  <requirement>版本固定：使用 SHA 而非 tag（tag 可被移动）。</requirement>
  <example type="good">
uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11  # v4.1.1
  </example>
  <constraint severity="warning">使用 SHA 比 tag 更安全——tag 可被移动而 SHA 不可变。</constraint>
</rule>

<rule name="local-validation">
  <requirement>使用 act（GitHub）或 gitlab-runner exec（GitLab）在本地运行 workflow 进行验证。</requirement>
  <requirement>大变更先在分支验证，再合入 main。</requirement>
</rule>
