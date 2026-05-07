---
name: bcc-init-project
description: 首次进入新项目时全面初始化。创建 .claude 目录结构，深度递归探索项目每个目录，理解架构/设计/API/集成。为每个子目录编写 CLAUDE.md（含导航路径/架构定位/功能设计/关键代码/对外API/文件索引/修改方向/外部对接/进度/变更日志）。根 CLAUDE.md 汇总全局架构。遇到不确定时主动追问用户。
argument-hint: "[项目简介？] (留空时自动扫描)"
disable-model-invocation: true
---

<skill name="bcc-init-project" type="system-init">

<overview>
首次进入新项目时全面初始化——创建 .claude 目录结构，深度递归探索项目每个目录，理解架构/设计/API/集成，为每个子目录编写 CLAUDE.md，根 CLAUDE.md 汇总全局架构。遇到不确定时主动追问用户。
</overview>

<phases>

<phase id="0" name="环境准备">

<instructions>

<step id="0.1" title="创建 .claude 目录结构">
按 <rule-ref>rules/_global/dotclaude-layout.md</rule-ref> 创建：
<directory-tree>
.claude/
├── artifacts/          # Agent 交接文件
├── agent-memory/       # Agent 跨任务记忆
├── logs/               # 日志
├── state/              # 运行时锁/状态
├── CLAUDE.md           # 根调度文档（本命令生成）
</directory-tree>
</step>

<step id="0.2" title=".gitignore 补全">
检查 .gitignore，追加（如未覆盖）：
<gitignore-append>
.claude/artifacts/
.claude/agent-memory/
.claude/logs/
.claude/state/
CLAUDE.local.md
</gitignore-append>
</step>

<step id="0.3" title="settings.local.json">
如 .claude/settings.local.json 不存在，生成模板。如存在，不覆盖。
</step>

<step id="0.4" title="已有 CLAUDE.md 处理">
如项目已有 CLAUDE.md（非 Agent Legion 格式）：
<branch>
  <case condition="旧内容与 Legion 架构兼容">融合旧内容到新模板的对应段落</case>
  <case condition="不兼容">旧文件归档为 CLAUDE.legacy.md，全新重写</case>
  <case condition="不确定">AskUserQuestion 让用户决策</case>
</branch>
处理前置：先通读旧文件，提取其中有价值的内容（项目描述、构建命令、关键约定）。
</step>

</instructions>

</phase>

<phase id="1" name="项目类型识别">

<instructions>

<step id="1.1" title="构建/配置文件识别">
读项目根目录的构建/配置文件，识别：
<detection-matrix>
  <detect key="语言">package.json→TS/JS, go.mod→Go, Cargo.toml→Rust, pyproject.toml→Python, pom.xml→Java, 等</detect>
  <detect key="框架">next.config→Next.js, vite.config→Vite, django→Django, spring→Spring, 等</detect>
  <detect key="类型">单体/微服务/monorepo/全栈/前端/后端/CLI/库</detect>
  <detect key="包管理器">npm/yarn/pnpm/cargo/pip/poetry/maven/gradle</detect>
  <detect key="数据库">prisma→检查 schema, docker-compose→检查 DB 镜像, ORM 配置</detect>
  <detect key="部署方式">Dockerfile, docker-compose, k8s config, Vercel/Netlify 配置</detect>
</detection-matrix>
</step>

<step id="1.2" title="monorepo 检测">
如果项目是多包 monorepo（packages/、apps/、services/ 等），标记为 monorepo 模式——每个子包视为独立项目，各自生成 .claude/CLAUDE.md。根 .claude/CLAUDE.md 汇总全 monorepo 架构。
</step>

</instructions>

</phase>

<phase id="2" name="深度递归探索">

<instructions>

<step id="2.1" title="目录遍历规则">
递归遍历所有目录，<skip-dirs>node_modules/ .git/ dist/ build/ __pycache__/ .next/ target/ vendor/ coverage/ .cache/ .turbo/ out/ .idea/ .vscode/</skip-dirs>。
</step>

<step id="2.2" title="每目录扫描清单">
对每个保留的目录：
<scan-checklist>
  <item order="1">读构建/配置文件（package.json/go.mod 等）</item>
  <item order="2">读源码文件（按优先级：入口→类型定义→核心逻辑→工具函数）</item>
  <item order="3">识别该目录的<em>架构角色</em>：表示层/业务层/数据层/基础设施层/工具层</item>
  <item order="4">识别<em>上游依赖</em>和<em>下游消费者</em></item>
  <item order="5">提取<em>对外 API</em>（导出函数/接口/HTTP endpoint/消息发布订阅）</item>
  <item order="6">识别<em>关键符号</em>（class/function/interface/enum/struct）</item>
</scan-checklist>
</step>

<step id="2.3" title="全局理解">
在完成逐目录扫描后，构建全局认知：
<global-view>
  <item>完整请求链路（从入口到数据库）</item>
  <item>模块依赖图</item>
  <item>数据流和状态管理</item>
  <item>关键设计模式和架构决策</item>
  <item>外部系统对接点</item>
</global-view>
</step>

</instructions>

</phase>

<phase id="3" name="子目录 CLAUDE.md 生成">

<instructions>

<step id="3.1" title="生成范围">
对每个含源码的目录生成 CLAUDE.md。跳过纯配置/资源目录。
</step>

<step id="3.2" title="子目录模板">
<template-output format="markdown">

# {目录名} — {一句话职责}

## 导航
- 父模块：{上级目录 CLAUDE.md 路径}
- 子模块：{子目录列表}
- 根：{相对路径到根 CLAUDE.md}

## 架构定位
- 层级：{表示层/业务层/数据层/基础设施层}
- 上游依赖：{依赖的模块及契约位置}
- 下游消费者：{被哪些模块依赖}
- 设计模式：{MVC/DDD/管道-过滤器/...}

## 功能设计
{这个模块做什么、核心业务流程、关键设计决策及理由}

## 关键代码与机制
- 入口点：{函数名 + 文件:行号}
- 核心类/函数/结构体：{名称 + 职责 + 位置}
- 关键算法/状态机：{描述 + 位置}
- 状态管理：{存储方式/缓存策略}

## 对外 API
| 接口 | 类型 | 契约位置 |
|------|------|---------|
| functionName(params) → returnType | 函数导出 | src/file.ts:42 |
| POST /api/path | HTTP endpoint | src/routes.ts:15 |
| 事件 order.created | 消息发布 | → 消费者: notification/ analytics/ |

## 文件与符号索引
| 文件 | 关键符号 | 类型 | 说明 |
|------|---------|------|------|
| src/service.ts | class UserService | class | 用户服务入口 |
| src/types.ts | interface User enum Role | type | 核心类型 |

## 修改/拓展指南
- **安全修改**：{哪些可以改、怎么改}
- **禁改区域**：{哪些绝对不能碰、为什么}
- **典型拓展场景**：{新增功能时从哪个文件/哪个函数开始}
- **pre-mortem 提示**：{这个模块最容易在哪里出 bug}

## 外部对接
| 对接方 | 方式 | 契约 | 影响 |
|--------|------|------|------|
| {模块名} | HTTP/import/MQ | {契约文件:行号} | {如果对接失败会怎样} |

## 进度
- 已完成：{功能清单}
- 未完成：{TODO/FIXME 位置}
- 已知问题：{技术债/bug}

## 变更日志
| 日期 | 变更 | 原因 |
|------|------|------|
| — | 初始文档 | bcc-init-project |

</template-output>
</step>

</instructions>

</phase>

<phase id="4" name="根 CLAUDE.md 生成">

<instructions>

<step id="4.1" title="规范依据">
严格遵循 <rule-ref>rules/_global/claudemd-standard.md</rule-ref>。总行数 ≤200。超出部分归入 .claude/skills/project-knowledge/SKILL.md。
</step>

<step id="4.2" title="必须包含的区块">
<section-list>
  <section order="1">项目身份（3-5 行）：名称、类型、核心业务</section>
  <section order="2">技术栈（3-8 行）：语言/框架/数据库/工具链 + 版本</section>
  <section order="3">构建/测试命令（5-10 行）：完整可执行命令</section>
  <section order="4">架构总览（Mermaid/ASCII 图）：层次 + 模块依赖</section>
  <section order="5">核心模块索引（每模块一行→子目录 CLAUDE.md）</section>
  <section order="6">数据流全景：请求→响应完整路径</section>
  <section order="7">外部系统对接：所有外部 API/DB/MQ/第三方</section>
  <section order="8">核心铁律（5-15 行）：绝对不能违反的规则</section>
  <section order="9">Agent 调度指引（15-30 行）：本项目可用的流水线、Agent 选择、特殊约束</section>
  <section order="10">@imports（3-5 行）：关键参考文件</section>
</section-list>
</step>

<step id="4.3" title="Agent 调度指引段模板">
<template-output format="markdown">

## Agent 调度指引

### 可用流水线
- 新功能：自然语言描述即可，调度器自判 large → 完整门控
- Bug 修复：自然语言描述，调度器走 fix-bug 流水线
- 快速修复：≤20 行单文件 → /bcc-fast-fix

### 特殊约束
- {项目特定的不可碰区域}
- {项目的构建顺序要求}
- {环境依赖（如需要 VPN/特定数据库）}

### 推荐 Agent
- 前端：高级前端工程师
- 后端：高级后端工程师
- {如涉及特殊平台（小程序/ML/移动端），注明专项 Agent}

</template-output>
</step>

</instructions>

</phase>

<phase id="5" name="project-knowledge Skill">

<instructions>

<step id="5.1" title="内容要求">
在 .claude/skills/project-knowledge/SKILL.md 写入：
<content-list>
  <item>详细技术栈说明（版本/配置/连接信息）</item>
  <item>代码约定（命名/格式/目录约定）</item>
  <item>环境配置（env 变量/密钥/服务依赖）</item>
  <item>常见开发场景（新增页面/API/模型/测试）</item>
  <item>已知坑与规避方法</item>
</content-list>
</step>

</instructions>

</phase>

<phase id="6" name="验证与收尾">

<instructions>

<step id="6.1" title="健康检查">
运行 <cmd>bash ~/.claude/bin/doctor.sh</cmd> 对项目执行健康检查。
</step>

<step id="6.2" title="行数验证">
验证根 CLAUDE.md 行数 ≤200。
</step>

<step id="6.3" title="子目录完整性">
验证所有子目录 CLAUDE.md 均有完整的 frontmatter 段。
</step>

</instructions>

</phase>

</phases>

<thresholds>

<ask-user-when>
以下情况必须 AskUserQuestion：
<item>项目类型/构建系统无法从代码确定</item>
<item>架构模式有歧义</item>
<item>旧 CLAUDE.md 内容与 Legion 格式冲突且无法判断是否应融合</item>
<item>关键设计决策缺上下文</item>
<item>monorepo 子包之间的依赖关系不明确</item>
</ask-user-when>

<never-ask>
能从代码 100% 确定的事实不问。
</never-ask>

</thresholds>

<output>
产出文件：
<artifact-list>
  <artifact>.claude/CLAUDE.md（根调度文档）</artifact>
  <artifact>.claude/skills/project-knowledge/SKILL.md</artifact>
  <artifact>各子目录 CLAUDE.md</artifact>
  <artifact>.claude/settings.local.json（如不存在）</artifact>
</artifact-list>
</output>

</skill>
