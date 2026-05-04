---
paths:
  - "*.env"
  - "*.env.*"
  - ".env*"
  - "config/**"
  - "**/config.yml"
  - "**/config.yaml"
  - "**/config.json"
  - "**/config.toml"
---

# 环境配置规范

<rule name="env-var-principles">
  <rule name="should-be-env-var">
    <requirement>数据库连接串应作为环境变量。</requirement>
    <requirement>API Key、Secret 应作为环境变量。</requirement>
    <requirement>第三方服务 URL 应作为环境变量。</requirement>
    <requirement>Feature Flag 应作为环境变量。</requirement>
    <requirement>环境标识（NODE_ENV、ENV）应作为环境变量。</requirement>
  </rule>

  <rule name="should-not-be-env-var">
    <constraint severity="warning">代码逻辑分支不应用环境变量控制——用代码实现。</constraint>
    <constraint severity="warning">大量结构化配置不应用环境变量——用配置文件。</constraint>
    <constraint severity="warning">敏感业务参数（如支付费率）不应用环境变量——用配置服务。</constraint>
  </rule>
</rule>

<rule name="dotenv-files">
  <rule name="layering">
    <requirement>.env：本地默认配置，不进 git。</requirement>
    <requirement>.env.example：示例文件，进 git，敏感值使用占位符。</requirement>
    <requirement>.env.local：个人本地覆盖，不进 git。</requirement>
    <requirement>.env.staging / .env.production：环境特定配置，不进 git。</requirement>
  </rule>

  <rule name="gitignore">
    <constraint severity="blocker">必须在 .gitignore 中排除 .env、.env.local、.env.*.local。</constraint>
    <example type="good">
.env
.env.local
.env.*.local
    </example>
  </rule>

  <rule name="validation">
    <requirement>应用启动时必须验证全部必需环境变量，缺失时立即失败（fail fast），不可以用 undefined 启动。</requirement>
    <example type="good">
import { z } from 'zod';

const envSchema = z.object({
  DATABASE_URL: z.string().url(),
  JWT_SECRET: z.string().min(32),
  NODE_ENV: z.enum(['development', 'staging', 'production']),
  PORT: z.string().regex(/^\d+$/).transform(Number).default('3000'),
});

export const env = envSchema.parse(process.env);
    </example>
  </rule>
</rule>

<rule name="sensitive-information">
  <rule name="absolute-prohibitions">
    <constraint severity="blocker">禁止提交 .env 到 git，即使是开发环境。</constraint>
    <constraint severity="blocker">禁止在代码中硬编码任何密钥。</constraint>
    <constraint severity="blocker">禁止在日志中输出敏感配置，包括打印 process.env。</constraint>
    <constraint severity="blocker">禁止在错误消息中包含密钥。</constraint>
  </rule>

  <rule name="management">
    <requirement>本地：.env 文件，从密钥管理工具同步。</requirement>
    <requirement>生产：使用 Secret 管理服务（Vault / AWS Secrets Manager / Kubernetes Secrets）。</requirement>
    <requirement>CI：使用平台 secrets（GitHub Secrets / GitLab Variables）。</requirement>
  </rule>

  <rule name="rotation">
    <requirement>定期轮换密钥（周期 90-180 天）。</requirement>
    <constraint severity="blocker">发现泄露必须立即轮换。</constraint>
    <requirement>支持多密钥并存以平滑过渡。</requirement>
  </rule>
</rule>

<rule name="config-files">
  <requirement>结构化、非敏感配置适合使用配置文件管理。</requirement>

  <rule name="format-selection">
    <requirement>JSON：通用，但不支持注释。</requirement>
    <requirement>YAML：可读性好，支持注释，但需注意缩进陷阱。</requirement>
    <requirement>TOML：适合简单键值 + 段落结构。</requirement>
    <requirement>INI：简单但表达力弱。</requirement>
    <constraint severity="warning">.js / .ts 动态配置：谨慎使用，注意可执行代码风险。</constraint>
  </rule>

  <rule name="environment-split">
    <requirement>配置文件按环境分层：default.yaml 基础配置 + 环境特定覆盖。</requirement>
    <example type="good">
config/
├── default.yaml        # 基础配置
├── development.yaml    # 开发覆盖
├── staging.yaml
└── production.yaml
    </example>
    <requirement>加载时按 default + 环境覆盖合并。</requirement>
  </rule>

  <rule name="no-secrets-in-config">
    <constraint severity="blocker">配置文件可以提交到 git，因此绝对不能包含密钥。敏感值使用环境变量引用。</constraint>
    <example type="good">
database:
  host: ${DATABASE_HOST}
  port: ${DATABASE_PORT}
  # 密码从环境变量读取
    </example>
  </rule>
</rule>

<rule name="feature-flags">
  <requirement>使用场景：渐进发布、A/B 测试、紧急关闭问题功能、按用户/地区启用。</requirement>
  <requirement>简单实现：环境变量 / 配置文件。</requirement>
  <requirement>中等实现：数据库 + 缓存。</requirement>
  <requirement>高级实现：LaunchDarkly / Flagsmith / Unleash。</requirement>
  <constraint severity="blocker">Feature flag 成功发布后必须清理，避免变成技术债。每个 flag 必须有明确的过期日期。</constraint>
</rule>

<rule name="secret-scanning">
  <rule name="pre-commit">
    <requirement>使用 git-secrets 或 trufflehog 在 pre-commit 阶段扫描密钥。</requirement>
    <example type="good">
git secrets --install
git secrets --register-aws
git secrets --add-provider -- cat .git-secrets-patterns
    </example>
  </rule>

  <rule name="ci">
    <requirement>每次 CI 构建扫描变更中的密钥。</requirement>
    <example type="good">
- uses: trufflesecurity/trufflehog@main
  with:
    path: ./
    base: main
    </example>
  </rule>

  <rule name="leaked-secret-remediation">
    <constraint severity="blocker">已泄露的密钥处理流程：1) 立即轮换（假设已被利用）；2) 清除 git 历史（git filter-repo / BFG）；3) Force push（经团队同意）；4) 审计访问日志。</constraint>
  </rule>
</rule>

<rule name="twelve-factor-app">
  <requirement>III. Config：配置从代码中分离。</requirement>
  <requirement>IV. Backing services：所有服务（DB、缓存、队列）作为可配置资源。</requirement>
  <requirement>V. Build, release, run：构建、发布、运行三阶段分离。</requirement>
  <requirement>XI. Logs：日志作为事件流，不写文件。</requirement>
</rule>

<rule name="review-checklist">
  <requirement>高级安全审计师 审查 env 和 config 变更时必须逐项检查：</requirement>
  <check>没有密钥硬编码</check>
  <check>.env 没有被提交到 git</check>
  <check>.env.example 已更新（新增变量时）</check>
  <check>敏感变量已在 CI secrets 中配置</check>
  <check>应用启动时验证了必需变量</check>
  <check>日志不打印敏感配置</check>
</rule>
