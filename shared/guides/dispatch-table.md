---
name: dispatch-table
description: 调度信号表单一真源 — 33 Agent 完整映射（CLAUDE.md 为精简索引，本文件为完整版）
guide: true
---

<harness-guide>
  <section id="dispatch-table">
    <title>调度信号表（单一真源）</title>
    <content>

> 本文件是调度信号表的**唯一完整版本**。`~/.claude/CLAUDE.md` 保留精简索引供快速查阅。
> 其他文件（output-style / governance）中的调度表已废弃，不再维护。

| 领域 | Agent 名称 | 文件名 | 模型 | 颜色 | 触发信号 | 指令类型 |
|------|-----------|--------|------|------|---------|---------|
| AI 情报 | AI 领航大师 | ai-navigator.md | opus | purple | AI 框架、模型选型、DeepSeek、LangChain、Qwen、AI 行业动态、prompt 范式、which model should I use | 调研, 研究 |
| 实现 | Android 开发师 | android-dev.md | sonnet | cyan | Android、Kotlin、Jetpack Compose、Google Play、FCM、华为推送、小米推送、NDK | 新建, 修改, 修复 |
| 设计 | 架构师 | architect.md | opus | blue | 整体架构、从零搭建、跨模块重构、架构撑不住了、基础设施引入、system architecture、module boundaries、service split decision | 设计 |
| 实现 | 后端开发师 | backend.md | sonnet | blue | 写接口、后端实现、API 实现、业务逻辑、服务端代码、修复后端 bug | 新建, 修改, 修复 |
| 外部输入 | 客户沟通师 | client.md | sonnet | purple | 客户发来需求、帮我整理一下、接单评估、售后问题、帮我写提案、客户说的是什么意思 | 新建, 修改(需求) |
| 审查 | 代码审计师 | code-review.md | sonnet | red | 审代码、code review、审查实现、development complete, pending review | 审查 |
| 创意 | 创意策划师 | creative.md | sonnet | pink | 取名、App 名称、Slogan、品牌调性、文案方向、视觉风格方向、Logo 设计方向、功能命名 | 创意, 新建 |
| 实现 | 跨平台移动开发师 | crossplatform-mobile-dev.md | sonnet | cyan | Flutter、React Native、跨平台、Dart、双端、Fastlane、Codemagic、MethodChannel | 新建, 修改, 修复 |
| 数据 | 数据工程师 | data-engineer.md | sonnet | blue | ETL、数仓、Spark、Flink、ClickHouse、数据管道、数据质量、Delta Lake | 新建, 修改, 设计 |
| 数据 | 数据库工程师 | database.md | opus | blue | 加表、改字段、迁移脚本、建索引、PII 分级、Schema 设计、add table、migration | 设计, 新建, 修改 |
| 实现 | 桌面端开发师 | desktop-dev.md | sonnet | cyan | Electron、Tauri、Qt、桌面应用、macOS signing、Windows code signing、auto-update、系统托盘 | 新建, 修改, 修复 |
| 设计 | 开发组长 | dev-lead.md | sonnet | purple | 技术方案、怎么实现、拆分到文件级、方案设计、接口约定、scheme design | 设计 |
| 部署 | 运维部署工程师 | devops.md | sonnet | blue | 部署、上线、写 Dockerfile、docker-compose、CI/CD、GitHub Actions、K8s、Nginx 配置 | 部署 |
| 文档 | 文档工程师 | doc-writer.md | sonnet | orange | 写 API 文档、用户手册、部署说明、论文草稿、阶段报告、写交付文档、API docs、deployment guide | 文档 |
| 实现 | 嵌入式开发师 | embedded-dev.md | sonnet | green | STM32、ESP32、FreeRTOS、Zephyr、驱动、firmware、OTA、低功耗 | 新建, 修改, 修复 |
| 实现 | 前端开发师 | frontend.md | sonnet | cyan | 写页面、实现组件、前端实现、前端对接接口 | 新建, 修改, 修复 |
| 版本控制 | Git 版本控制大师 | git-master.md | haiku | yellow | rebase、squash commits、cherry-pick、bisect、git history、conflict resolution、branch strategy、prepare PR | 修改, 修复, 审查 |
| 实现 | 鸿蒙开发师 | harmonyos-dev.md | sonnet | green | 鸿蒙、HarmonyOS、ArkTS、ArkUI、华为应用、AppGallery、原子化服务、分布式 | 新建, 修改, 修复 |
| 实现 | iOS 开发师 | ios-dev.md | sonnet | cyan | iOS、Swift、SwiftUI、UIKit、App Store 上架、TestFlight、Core Data、SwiftData | 新建, 修改, 修复 |
| 实现 | 小程序开发师 | miniprogram-dev.md | sonnet | cyan | 写小程序、uni-app、微信登录、微信支付、分包优化、小程序发布、云函数、云数据库 | 新建, 修改, 修复 |
| 实现 | 机器学习工程师 | ml-engineer.md | sonnet | blue | 训练模型、fine-tune、LoRA、QLoRA、SFT、DPO、模型评估、failure analysis | 训练, 新建, 修改, 修复 |
| 调度 | 项目管理师 | pm.md | opus | yellow | 下一步、推进到哪、拆需求、任务状态 | 设计(拆解), 综合 |
| 元工程 | 提示词工程师 | prompt-engineer.md | sonnet | pink | 改 prompt、调 agent 规格、agent 跑偏、新增 agent、调度信号不清晰、CLAUDE.md 更新、output-style 优化、agent 职责冲突 | 修改 |
| 研究 | 深度研究员 | researcher.md | opus | yellow | 文献综述、研究现状、related work、方法论对比、深度竞品分析、领域调研、A 和 B 哪个好、能不能用 | 研究, 调研 |
| 安全 | 安全审计师 | security-auditor.md | sonnet | red | 安全审计、上线前检查、OWASP、STRIDE、CVE扫描、penetration test、合规检查 | 审查 |
| 仿真 | 仿真工程师 | simulation-engineer.md | sonnet | green | Simulink、HIL、SIL、Embedded Coder、Unity 仿真、Unreal 仿真、数字孪生、digital twin | 新建, 修改, 调研 |
| 测试 | 功能测试师 | test-func.md | sonnet | green | 测功能、走主流程、验收测试、API 能跑通吗、functional test、end-to-end test、black-box test | 测试 |
| 裁决 | 测试总监师 | test-lead.md | opus | red | 能不能验收、能不能上线、做最终裁决、综合验收、milestone delivery review、release gate | 审查 |
| 测试 | 界面测试师 | test-ui.md | haiku | orange | 截图、看界面、交互校验、UI 证据、tab 顺序、focus 可见、screenshot、UI test | 测试 |
| 视觉 | 视觉设计师 | visual-designer.md | opus | pink | 设计系统、design tokens、UI 规范、组件规范、spacing scale、色板、字阶、暗色模式 | 设计 |
| 实现 | AI 编排大师 | workflow-orchestrator.md | sonnet | cyan | n8n、Dify、Coze、LangFlow、Flowise、工作流编排、自动化工作流、搭工作流 | 新建, 修改, 修复 |

<h3>信号不明时的默认路由</h3>
<p>信号不匹配任何触发关键词时，默认派 <strong>项目管理师</strong> 做判断。PM 有责任在 3 轮内识别出正确调度路径。</p>

<h3>信号不明时的调度策略</h3>
<p>当用户输入无法匹配任何触发信号时，默认路由为 <strong>项目管理师</strong>。PM 负责在 3 轮内识别正确调度路径，或向用户澄清需求边界。</p>

    </content>
  </section>
</harness-guide>
