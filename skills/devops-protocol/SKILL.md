---
name: 高级运维工程师-protocol
description: 运维工作协议。覆盖构建、部署、CI/CD、发布、回滚、监控的方法论。
when_to_use: 仅当 高级运维工程师 Agent 处理构建 / 部署 / CI/CD 配置 / 发布 / 回滚 / 事故响应任务时加载。日常代码实现、本地调试、文档撰写不应触发。
---

<skill name="高级运维工程师-protocol">

<knowledge domain="core-principles">
<principle name="repeatable">**可重复**：任何部署能再次执行得到相同结果（Infrastructure as Code）</principle>
<principle name="rollbackable">**可回滚**：任何变更有明确的回退路径</principle>
<principle name="traceable">**可追踪**：每次变更有记录、时间戳、触发原因</principle>
</knowledge>

<knowledge domain="build">

<convention name="artifact-requirements">
<checklist>
  <item>**确定性**：相同源码 + 相同依赖 → 相同产物</item>
  <item>**可追溯**：产物带版本号、git commit hash、构建时间</item>
  <item>**最小化**：不包含开发依赖、不含源码 map（除非明确需要）</item>
  <item>**可验证**：产物完整性校验（checksum）</item>
</checklist>
</convention>

<convention name="build-timing">
<checklist>
  <item>本地开发：`npm run dev` / `cargo run` 等开发模式</item>
  <item>预览/测试：`npm run build:staging`</item>
  <item>生产：CI/CD 触发，**不手动构建产线**</item>
</checklist>
</convention>

<convention name="cache-strategy">
<checklist>
  <item>依赖缓存（node_modules、pip cache）加速 CI</item>
  <item>增量构建（turbo、nx、bazel）加速本地</item>
  <item>但生产构建应 clean build 确保无状态污染</item>
</checklist>
</convention>

</knowledge>

<knowledge domain="ci-cd">

<convention name="pipeline-structure">
<principle>流水线结构</principle>
<checklist>
  <item>Checkout</item>
  <item>Install deps (cached)</item>
  <item>Lint</item>
  <item>Type check</item>
  <item>Unit tests</item>
  <item>Build</item>
  <item>Integration tests</item>
  <item>Security scan</item>
  <item>(仅 main) Deploy staging</item>
  <item>(仅 tag) Deploy production</item>
</checklist>
<rule>每个阶段失败应快速终止整个流水线。</rule>
</convention>

<convention name="test-matrix">
<checklist>
  <item>多 Node / Python / 等语言版本（如项目声明支持多版本）</item>
  <item>多 OS（如有跨平台需求）</item>
</checklist>
<trap>代价：矩阵维度乘积不要超过实际价值</trap>
</convention>

<convention name="secret-management">
<checklist>
  <item>不在 workflow 文件中硬编码密钥</item>
  <item>使用 CI 平台的 secrets（GitHub Secrets / GitLab Variables）</item>
  <item>最小权限：每个 secret 只给需要它的 job</item>
</checklist>
</convention>

</knowledge>

<knowledge domain="versioning">

<knowledge domain="semver">
<convention name="MAJOR">破坏性变更</convention>
<convention name="MINOR">向后兼容的新功能</convention>
<convention name="PATCH">向后兼容的 bug 修复</convention>
<convention>对于应用（而非库），版本号也可以是日期（`2026.04.23`）或自增（`v127`）。</convention>
</knowledge>

<knowledge domain="git-tag">
<example>git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3</example>
</knowledge>

<knowledge domain="changelog">
<principle>遵循 Keep a Changelog 格式</principle>
<example>
## [1.2.3] - 2026-04-23
### Added
- 新功能 X
### Changed
- 修改 Y 行为
### Fixed
- 修复 Z bug
### Security
- 升级依赖解决 CVE-xxx
</example>
</knowledge>

</knowledge>

<knowledge domain="monitoring-and-alerting">

<knowledge domain="basic-monitoring">
<checklist>
  <item>系统：CPU、内存、磁盘、网络</item>
  <item>应用：请求延迟、错误率、流量、饱和度</item>
  <item>业务：关键业务指标</item>
</checklist>
</knowledge>

<knowledge domain="alerting-principles">
<principle>告警原则</principle>
<checklist>
  <item>**可操作**：每条告警对应明确的处理动作</item>
  <item>**可诊断**：告警信息包含上下文（时间、值、趋势、相关服务）</item>
  <item>**无噪音**：避免告警疲劳（已知问题自动静默）</item>
  <item>**分级**：紧急 vs 重要 vs 信息</item>
</checklist>
</knowledge>

<knowledge domain="slo-sli">
<convention>定义 SLO（服务等级目标）：如"99.9% 请求 < 200ms"</convention>
<convention>SLI 监控：实际达成率</convention>
<convention>Error Budget：超标时冻结变更，专注稳定性</convention>
</knowledge>

</knowledge>

<knowledge domain="security-operations">

<knowledge domain="dependency-management">
<checklist>
  <item>定期扫描（`npm audit`、`pip-audit`、Dependabot）</item>
  <item>关键 CVE 立即处理</item>
  <item>锁定版本（lock file 提交）</item>
  <item>镜像扫描（Trivy / Snyk）</item>
</checklist>
</knowledge>

<knowledge domain="secret-rotation">
<checklist>
  <item>定期轮换（90 天 / 180 天）</item>
  <item>泄露立即轮换</item>
  <item>使用 secret 管理服务</item>
</checklist>
</knowledge>

<knowledge domain="audit">
<checklist>
  <item>关键操作记录日志（谁、什么时候、做了什么）</item>
  <item>日志保留满足合规</item>
  <item>异常访问告警</item>
</checklist>
</knowledge>

</knowledge>

<reference path="references/deploy-patterns.md" desc="部署策略（蓝绿/金丝雀/滚动）、健康检查、文件传输 md5 校验、双产物编译" />
<reference path="references/rollback-emergency.md" desc="回滚（代码/DB/部分）、应急响应流程、不可逆操作铁律" />

</skill>
